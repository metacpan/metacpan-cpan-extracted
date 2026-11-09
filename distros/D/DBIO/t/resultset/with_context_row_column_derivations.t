use strict;
use warnings;
use Test::More;
use Test::Exception;

use DBIO::Test;
use DBIO::Test::Future ();
use DBIO::Test::Storage;
use DBIO::SQLMaker;
use DBIO::Storage::Async;
use DBIO::Storage::DBI;

# ADR 0045 section 3 / karr k325: what is derived from a context-bound ROW or
# COLUMN carries the pinned async context, like what is derived from a bound
# resultset (karr k195, k281). Before k325 these dropped it, because they build
# a fresh resultset (or a fresh row) instead of deriving from the bound object:
#
#   - Row: self_rs, clean_rs, the synchronous get_from_storage /
#     discard_changes / copy, a many_to_many add_to_<name>, the sibling methods
#     of DBIO::Ordered, the changelog of DBIO::ChangeLog;
#   - ResultSetColumn bound directly with with_context: func_rs (and min_rs /
#     max_rs / sum_rs), _resultset;
#   - ResultSet: the rows of a result class that has its own inflate_result.
#
# A *_async on the result was not refused; it ran on a pool connection, outside
# the transaction. The worst of them is discard_changes: it took the binding
# off the very row it was called on.
#
# As in t/resultset/with_context_fresh_derivations.t, what is asserted is where
# the statement RAN, never that a slot is set:
#   - inside the transaction: BEGIN, the statement and COMMIT all on the one
#     transaction connection, nothing on the pool;
#   - held past the transaction: refused ('no longer active'), nothing sent;
#   - derived from an unbound object: on the pool, as before.
#
# The harness is the synchronous fake transport of that file. A derivation that
# is itself synchronous (get_from_storage, copy, ...) reads and writes through
# the fake sync storage, which is not on this wire.

{
  package Test::SyncPool;
  sub new { bless { released => [], txns => 0 }, shift }
  sub acquire     { DBIO::Test::Future->done('POOL') }
  sub acquire_txn { DBIO::Test::Future->done('TXN' . ++$_[0]->{txns}) }
  sub release     { push @{ $_[0]->{released} }, $_[1]; 1 }
  sub shutdown    { 1 }
}

{
  package Test::CtxBackend;
  use base 'DBIO::Storage::Async';

  sub new {
    my ($class, $schema) = @_;
    my $self = $class->SUPER::new($schema);
    $self->{captured}  = [];
    $self->{next_rows} = [];
    return $self;
  }
  sub future_class    { 'DBIO::Test::Future' }
  sub sql_maker_class { 'DBIO::SQLMaker' }
  sub _sql_maker_args { (quote_char => '"', name_sep => '.') }
  sub _transform_sql   { $_[1] }
  sub _post_insert_sql { ' RETURNING *' }
  sub pool { $_[0]->{pool} ||= Test::SyncPool->new }

  # A statement that reaches _query_async left for the pool; one that reaches
  # _query_async_pinned names the connection it was pinned to.
  sub _query_async {
    my ($self, $sql, $bind) = @_;
    push @{ $self->{captured} }, { sql => $sql, on => 'the pool' };
    return $self->future_class->done(@{ $self->{next_rows} });
  }
  sub _query_async_pinned {
    my ($self, $conn, $sql, $bind) = @_;
    push @{ $self->{captured} }, { sql => $sql, on => $conn };
    return $self->future_class->done(@{ $self->{next_rows} });
  }
}

DBIO::Storage::DBI->register_async_mode( row_column_derivations_backend => 'Test::CtxBackend' );

# A result class that inflates its own rows -- the documented way to rebless a
# row into a subclass (DBIO::Manual::Cookbook, "Dynamic Sub-classing").
{
  package Test::OwnInflateArtist;
  use base 'DBIO::Test::Schema::Artist';

  sub inflate_result {
    my $class = shift;
    return $class->next::method(@_);
  }
}

# A source with DBIO::ChangeLog, as in t/changelog/01-basic.t.
{
  package Test::CL::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('ChangeLog::Schema');
}
{
  package Test::CL::Schema::Result::Artist;
  use base 'DBIO::Core';

  __PACKAGE__->load_components('ChangeLog');
  __PACKAGE__->table('artist');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer', is_auto_increment => 1 },
    name => { data_type => 'varchar', size => 100 },
  );
  __PACKAGE__->set_primary_key('id');
}
Test::CL::Schema->register_class( Artist => 'Test::CL::Schema::Result::Artist' );

sub changelog_schema {
  Test::CL::Schema->storage_type('+DBIO::Test::Storage');
  my $schema = Test::CL::Schema->connect(sub { });
  $schema->storage(DBIO::Test::Storage->new($schema));
  $schema->_changelog_sources_registered(0);
  $schema->_register_changelog_sources;
  return $schema;
}

sub wired {
  my ($schema) = @_;
  $schema ||= DBIO::Test->init_schema;
  $schema->storage->_async_mode('row_column_derivations_backend');
  delete $schema->storage->{_async_storage_obj};
  return ($schema, $schema->storage->_async_storage);
}

# What went over the wire, in order: [ first word of the statement, where ].
sub wire {
  my ($backend) = @_;
  return [ map { [ ($_->{sql} =~ /(\w+)/)[0], $_->{on} ] } @{ $backend->{captured} } ];
}

sub statement {
  my ($backend, $re) = @_;
  return grep { $_->{sql} =~ $re } @{ $backend->{captured} };
}

# A row as the application holds it: in storage, and bound to the context if
# there is one.
sub row {
  my ($schema, $ctx, $source, $cols) = @_;
  my $row = $schema->resultset($source)->new_result($cols);
  $row->in_storage(1);
  return $ctx ? $row->with_context($ctx) : $row;
}

sub artist   { row(@_[0, 1], Artist   => { artistid => 1, name => 'Miles Davis' }) }
sub employee { row(@_[0, 1], Employee => { employee_id => 1, position => 2, name => 'Ada' }) }

# A column, bound directly if there is a context -- not taken from a bound
# resultset, which was right all along.
sub rank_column {
  my ($schema, $ctx) = @_;
  my $column = $schema->resultset('Artist')->get_column('rank');
  return $ctx ? $column->with_context($ctx) : $column;
}

my $all = sub { $_[0]->all_async };

# The write-back on a derived row; the fake transport answers "one row".
my $update = sub {
  my ($row, $backend) = @_;
  $backend->{next_rows} = [ 1 ];
  return $row->update_async({ name => 'changed' });
};

my @EMPLOYEE_ROW = ( 2, 3, undef, undef, undef, 'Grace', undef );

# The write-back is no measure for a row of DBIO::Ordered: its update is an
# override with no update_async beside it, which a bound row refuses (karr
# k331). What the derivations assert is the binding of the row that comes
# back, and a re-read shows that as well.
my $reload = sub {
  my ($row, $backend) = @_;
  $backend->{next_rows} = [ [ @EMPLOYEE_ROW ] ];
  return $row->discard_changes_async;
};

# Each derivation: how it is derived (from the schema, the backend and the
# context -- undef when nothing is bound), the async call on what comes back,
# the statement that call sends and what it looks like. derive_sends lists what
# the derivation itself sends over the async wire before that.
my @derivations = (
  {
    name   => 'Row self_rs',
    derive => sub { artist(@_)->self_rs },
    call   => $all,
    sends  => 'SELECT',
    sql    => qr/FROM "artist" "me" WHERE \( "me"\."artistid" = \? \)$/,
  },
  {
    name   => 'Row clean_rs',
    derive => sub { artist(@_)->clean_rs },
    call   => $all,
    sends  => 'SELECT',
    sql    => qr/FROM "artist" "me"$/,
  },
  {
    name   => 'Row get_from_storage (the row it returns)',
    derive => sub {
      my ($schema) = @_;
      $schema->storage->mock(qr/FROM "artist"/, [ [ 1, 'Miles Davis', 13, undef ] ]);
      return artist(@_)->get_from_storage;
    },
    call   => $update,
    sends  => 'UPDATE',
    sql    => qr/^UPDATE "artist" SET "name" = \? WHERE "artistid" = \?$/,
  },
  {
    name   => 'Row discard_changes (the row itself, afterwards)',
    derive => sub {
      my ($schema) = @_;
      $schema->storage->mock(qr/FROM "artist"/, [ [ 1, 'Miles Davis', 13, undef ] ]);
      my $row = artist(@_);
      $row->discard_changes;
      return $row;
    },
    call   => $update,
    sends  => 'UPDATE',
    sql    => qr/^UPDATE "artist" SET "name" = \? WHERE "artistid" = \?$/,
  },
  {
    name   => 'Row copy (the copy)',
    derive => sub { row(@_[0, 1], Money => { id => 5, amount => '1.00' })->copy({ amount => '2.00' }) },
    call   => sub {
      my ($copy, $backend) = @_;
      $backend->{next_rows} = [ 1 ];
      return $copy->update_async({ amount => '3.00' });
    },
    sends  => 'UPDATE',
    sql    => qr/^UPDATE "money_test" SET "amount" = \?/,
  },
  {
    name   => 'many_to_many add_to_<name> (the row it returns)',
    derive => sub {
      row(@_[0, 1], CD => { cdid => 10, artist => 1, title => 'Kind of Blue', year => 1959 })
        ->add_to_producers({ name => 'Teo Macero' });
    },
    call   => $update,
    sends  => 'UPDATE',
    sql    => qr/^UPDATE "producer" SET "name" = \?/,
  },
  ( map {
      my $method = $_;
      {
        name   => "Ordered $method",
        derive => sub { employee(@_)->$method },
        call   => $all,
        sends  => 'SELECT',
        sql    => qr/FROM "employee" "me" WHERE/,
      },
    } qw( siblings previous_siblings next_siblings )
  ),
  ( map {
      my $method = $_;
      {
        name   => "Ordered $method (the row it returns)",
        derive => sub {
          my ($schema) = @_;
          $schema->storage->mock(qr/FROM "employee"/, [ [ @EMPLOYEE_ROW ] ]);
          return employee(@_)->$method;
        },
        call   => $reload,
        sends  => 'SELECT',
        sql    => qr/FROM "employee" "me" WHERE/,
      },
    } qw( previous_sibling first_sibling next_sibling last_sibling )
  ),
  {
    name   => 'ChangeLog changelog',
    schema => \&changelog_schema,
    derive => sub { row(@_[0, 1], Artist => { id => 50, name => 'Art Blakey' })->changelog },
    call   => $all,
    sends  => 'SELECT',
    sql    => qr/FROM "artist_changelog" "me" WHERE \( "row_id" = \? \)$/,
  },
  ( map {
      my ($name, $derive) = @$_;
      {
        name   => "ResultSetColumn $name",
        derive => $derive,
        call   => $all,
        sends  => 'SELECT',
        sql    => qr/^SELECT MAX\( "me"\."rank" \) FROM "artist" "me"$/,
      },
    }
    [ func_rs => sub { rank_column(@_)->func_rs('MAX') } ],
    [ max_rs  => sub { rank_column(@_)->max_rs } ],
  ),
  {
    name   => 'ResultSetColumn _resultset',
    derive => sub { rank_column(@_)->_resultset },
    call   => $all,
    sends  => 'SELECT',
    sql    => qr/^SELECT "me"\."rank" FROM "artist" "me"$/,
  },
  {
    name   => 'ResultSetColumn _resultset, built on the column before it was bound',
    derive => sub {
      my ($schema, $ctx) = @_;
      my $column = $schema->resultset('Artist')->get_column('rank');
      $column->_resultset;
      return ( $ctx ? $column->with_context($ctx) : $column )->_resultset;
    },
    call   => $all,
    sends  => 'SELECT',
    sql    => qr/^SELECT "me"\."rank" FROM "artist" "me"$/,
  },
  {
    name   => 'a row of a result class with its own inflate_result',
    derive => sub {
      my ($schema, $ctx, $backend) = @_;
      my $rs = $schema->resultset('Artist');
      $rs = $rs->with_context($ctx) if $ctx;
      $backend->{next_rows} = [ [ 1, 'Miles Davis', 13, undef ] ];
      my ($row) = $rs->search_rs(undef, { result_class => 'Test::OwnInflateArtist' })
                     ->all_async->get;
      return $row;
    },
    derive_sends => [ 'SELECT' ],
    call   => $update,
    sends  => 'UPDATE',
    sql    => qr/^UPDATE "artist" SET "name" = \? WHERE "artistid" = \?$/,
  },
);

for my $d (@derivations) {
  my $name = $d->{name};
  my @before = @{ $d->{derive_sends} || [] };
  my $schema_for = $d->{schema} || sub { undef };

  # Inside the transaction: on its connection, between BEGIN and COMMIT.
  {
    my ($schema, $backend) = wired($schema_for->());

    $backend->txn_do_async(sub {
      my ($ctx) = @_;
      my $derived = $d->{derive}->($schema, $ctx, $backend);
      return $d->{call}->($derived, $backend);
    })->get;

    is scalar( statement($backend, $d->{sql}) ), 1, "$name: its statement was sent";
    is_deeply wire($backend),
      [ map { [ $_ => 'TXN1' ] } 'BEGIN', @before, $d->{sends}, 'COMMIT' ],
      "$name: it ran inside the transaction, on its connection, nothing on the pool";
  }

  # Held past the transaction: refused, not sent to the pool.
  {
    my ($schema, $backend) = wired($schema_for->());

    my $held;
    $backend->txn_do_async(sub {
      my ($ctx) = @_;
      $held = $d->{derive}->($schema, $ctx, $backend);
      return DBIO::Test::Future->done;
    })->get;

    throws_ok { $d->{call}->($held, $backend) } qr/no longer active/,
      "$name: held past the transaction it is refused";
    is_deeply wire($backend),
      [ map { [ $_ => 'TXN1' ] } 'BEGIN', @before, 'COMMIT' ],
      "$name: and nothing was sent in its place";
  }

  # Nothing bound: the pool, as before.
  {
    my ($schema, $backend) = wired($schema_for->());

    my $derived = $d->{derive}->($schema, undef, $backend);
    $d->{call}->($derived, $backend)->get;

    is scalar( statement($backend, $d->{sql}) ), 1, "$name, unbound: its statement was sent";
    is_deeply wire($backend),
      [ map { [ $_ => 'the pool' ] } @before, $d->{sends} ],
      "$name, unbound: on the pool";
  }
}

# ---------------------------------------------------------------------------
# Binding a column binds the clone, not the column it was cloned from: the two
# share nothing that carries the context.
# ---------------------------------------------------------------------------
{
  my ($schema, $backend) = wired();
  my $column = $schema->resultset('Artist')->get_column('rank');

  $backend->txn_do_async(sub {
    my ($ctx) = @_;
    my $bound = $column->with_context($ctx);
    return $bound->func_rs('MAX')->all_async->then(sub {
      $column->func_rs('MIN')->all_async;
    });
  })->get;

  is_deeply wire($backend),
    [ [ BEGIN => 'TXN1' ], [ SELECT => 'TXN1' ], [ SELECT => 'the pool' ], [ COMMIT => 'TXN1' ] ],
    'the column a bound one was cloned from stays unbound: its func_rs goes to the pool';
}

# ---------------------------------------------------------------------------
# Not covered, and not decided (ADR 0045, addendum 2026-10-08): the related
# rows a multi-create builds from nested data. Row::new builds them from an
# unbound resultset before new_result has bound the row they are nested in. The
# assertion marked IST holds what happens today and is no promise; it is here
# so that the decision flips a visible test.
# ---------------------------------------------------------------------------
{
  my ($schema, $backend) = wired();

  $backend->txn_do_async(sub {
    my ($ctx) = @_;
    my $cd = $schema->resultset('CD')->with_context($ctx)->new_result({
      title  => 'Kind of Blue',
      year   => 1959,
      artist => { name => 'Miles Davis' },
    });
    $backend->{next_rows} = [ [ 1, 'Miles Davis', 13, undef ] ];
    return $cd->artist->insert_async;
  })->get;

  # IST, no promise.
  is_deeply wire($backend),
    [ [ BEGIN => 'TXN1' ], [ INSERT => 'the pool' ], [ COMMIT => 'TXN1' ] ],
    'IST multi-create: the row nested in a bound row is not bound, its insert goes to the pool';
}

done_testing;
