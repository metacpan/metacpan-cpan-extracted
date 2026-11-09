use strict;
use warnings;
use Test::More;
use Test::Exception;

use DBIO::Test::Storage;
use DBIO::Test::Future ();
use DBIO::SQLMaker;
use DBIO::Storage::Async;
use DBIO::Storage::DBI;

# karr k282, point 2: Row::insert_async (and ResultSet::create_async through
# it) asked "is anything in _relationship_data or _inflated_column?" where the
# question is "would this insert send more than one statement?". Both slots
# hold more than multi-create data:
#
#   - an object for a column with an inflator sits in _inflated_column until
#     get_columns deflates it;
#   - a related row that is already in storage only lends its key.
#
# Neither is a cascade, and both took the cascade's way out: on an unbound row
# the synchronous insert instead of the backend, on a row bound to an async
# context (ADR 0045) an exception naming a "related-object multi-create" that
# was not there.
#
# What is asserted:
#   - such a row goes out as ONE INSERT through the backend: on the pool when
#     unbound, on the transaction's connection when bound, and nothing through
#     the synchronous storage either way;
#   - the INSERT is the one the synchronous insert sends for the same data --
#     same columns, same deflated value, same foreign key;
#   - a real cascade is still refused on a bound context, naming what makes it
#     one, and still runs synchronously when unbound.

{
  package Test::Tag;
  sub new   { bless { value => $_[1] }, $_[0] }
  sub value { $_[0]{value} }
}

{
  package Test::Inf::Schema;
  use base 'DBIO::Schema';
}
{
  package Test::Inf::Schema::Result::Author;
  use base 'DBIO::Core';

  __PACKAGE__->table('author');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer', is_auto_increment => 1 },
    name => { data_type => 'varchar', size => 100 },
  );
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->has_many(notes => 'Test::Inf::Schema::Result::Note', 'author');
}
{
  package Test::Inf::Schema::Result::Note;
  use base 'DBIO::Core';

  __PACKAGE__->table('note');
  __PACKAGE__->add_columns(
    id        => { data_type => 'integer', is_auto_increment => 1 },
    body      => { data_type => 'varchar', size => 100 },
    tag       => { data_type => 'varchar', size => 20, is_nullable => 1 },
    author    => { data_type => 'integer', is_nullable => 1 },
    editor_id => { data_type => 'integer', is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');

  # A column with an inflator: the row holds the object, the table the string.
  __PACKAGE__->inflate_column(tag => {
    inflate => sub { Test::Tag->new($_[0] =~ s/^tag://r) },
    deflate => sub { 'tag:' . $_[0]->value },
  });

  # Two belongs_to: one named like its column (the related row sits in
  # _inflated_column), one named differently (it sits in _relationship_data).
  __PACKAGE__->belongs_to(author => 'Test::Inf::Schema::Result::Author');
  __PACKAGE__->belongs_to(editor => 'Test::Inf::Schema::Result::Author', 'editor_id');
}
Test::Inf::Schema->register_class(Author => 'Test::Inf::Schema::Result::Author');
Test::Inf::Schema->register_class(Note   => 'Test::Inf::Schema::Result::Note');

{
  package Test::SyncPool;
  sub new { bless { txns => 0 }, shift }
  sub acquire     { DBIO::Test::Future->done('POOL') }
  sub acquire_txn { DBIO::Test::Future->done('TXN' . ++$_[0]->{txns}) }
  sub release     { 1 }
  sub shutdown    { 1 }
}
{
  package Test::CtxBackend;
  use base 'DBIO::Storage::Async';

  sub new {
    my ($class, $schema) = @_;
    my $self = $class->SUPER::new($schema);
    $self->{captured} = [];
    return $self;
  }
  sub future_class     { 'DBIO::Test::Future' }
  sub sql_maker_class  { 'DBIO::SQLMaker' }
  sub _sql_maker_args  { (quote_char => '"', name_sep => '.') }
  sub _transform_sql   { $_[1] }
  sub _post_insert_sql { ' RETURNING *' }
  sub pool { $_[0]->{pool} ||= Test::SyncPool->new }

  # A statement that reaches _query_async left for the pool; one that reaches
  # _query_async_pinned names the connection it was pinned to. An INSERT is
  # answered with what RETURNING would add to the data sent: the new key.
  sub _answer {
    my ($self, $sql, $bind, $on) = @_;
    push @{ $self->{captured} }, { sql => $sql, bind => $bind, on => $on };
    return $self->future_class->done( $sql =~ /^INSERT/ ? { id => 1 } : () );
  }
  sub _query_async        { $_[0]->_answer(@_[1, 2], 'the pool') }
  sub _query_async_pinned { $_[0]->_answer(@_[2, 3], $_[1]) }
}

DBIO::Storage::DBI->register_async_mode( insert_async_inflated_backend => 'Test::CtxBackend' );

# A schema over the fake synchronous storage ('immediate' is its default mode).
sub immediate_schema {
  Test::Inf::Schema->storage_type('+DBIO::Test::Storage');
  my $schema = Test::Inf::Schema->connect(sub { });
  $schema->storage(DBIO::Test::Storage->new($schema));
  return $schema;
}

# The same, with the fake async backend behind it.
sub backend_schema {
  my $schema = immediate_schema();
  $schema->storage->_async_mode('insert_async_inflated_backend');
  delete $schema->storage->{_async_storage_obj};
  return ($schema, $schema->storage->_async_storage);
}

# What went over the async wire, in order: [ first word, where ].
sub wire {
  my ($backend) = @_;
  return [ map { [ ($_->{sql} =~ /(\w+)/)[0], $_->{on} ] } @{ $backend->{captured} } ];
}

# What went through the synchronous storage, in order: first words.
sub synced {
  my ($schema) = @_;
  return [ map { ($_->{sql} =~ /(\w+)/)[0] } $schema->storage->captured_queries ];
}

# An INSERT INTO "note" as [ sql, bind values ], whichever side sent it.
sub note_insert {
  my (@queries) = @_;
  my ($insert) = grep { $_->{sql} =~ /^INSERT INTO "note"/ } @queries;
  return undef unless $insert;
  ( my $sql = $insert->{sql} ) =~ s/ RETURNING \*$//;
  return [ $sql, [ map { ref $_ eq 'ARRAY' ? $_->[1] : $_ } @{ $insert->{bind} || [] } ] ];
}

# What a Future failed with, or undef if it did not.
sub failure_of {
  my ($future) = @_;
  return undef if eval { $future->get; 1 };
  return "$@";
}

# What a Future resolved with. A failed one is a failed assertion here, not a
# dead test file.
sub resolved {
  my ($future, $name) = @_;
  my $value;
  return $value if eval { $value = $future->get; 1 };
  fail "$name: it resolves";
  diag $@;
  return undef;
}

# What a row looks like to its user once it is inserted: its columns, what is
# still dirty, and how many statements it takes to hand out the related rows it
# was given (none if it kept them, one each if it reads them again).
sub after_insert {
  my ($schema, $note, @accessors) = @_;
  return undef unless $note;
  $schema->storage->reset_captured;
  $note->$_ for @accessors;
  return {
    columns    => { $note->get_columns },
    dirty      => { $note->get_dirty_columns },
    in_storage => $note->in_storage,
    reads      => scalar( grep { $_ eq 'SELECT' } @{ synced($schema) } ),
  };
}

sub stored_author {
  my ($schema) = @_;
  my $author = $schema->resultset('Author')->new_result({ id => 7, name => 'Ada' });
  $author->in_storage(1);
  return $author;
}

# ---------------------------------------------------------------------------
# One INSERT: the data carries something for the two slots, and none of it is
# a statement of its own. Each entry builds the data for a schema and names the
# INSERT the synchronous insert sends for it.
# ---------------------------------------------------------------------------
my @single = (
  {
    name   => 'an object for a column with an inflator',
    data   => sub { { body => 'b', tag => Test::Tag->new('x') } },
    insert => [ 'INSERT INTO "note" ("body", "tag") VALUES (?, ?)', [ 'b', 'tag:x' ] ],
    check  => sub {
      my ($note, $name) = @_;
      is $note->get_column('tag'), 'tag:x', "$name: the row holds the deflated value";
      is $note->tag->value, 'x', "$name: and still hands out the object";
    },
  },
  {
    name   => 'a stored row for a belongs_to named like its column',
    data   => sub { { body => 'b', author => stored_author($_[0]) } },
    access => [ 'author' ],
    insert => [ 'INSERT INTO "note" ("author", "body") VALUES (?, ?)', [ 7, 'b' ] ],
    check  => sub {
      my ($note, $name) = @_;
      is $note->get_column('author'), 7, "$name: the row holds the foreign key";
    },
  },
  {
    name   => 'a stored row for a belongs_to with its own name',
    data   => sub { { body => 'b', editor => stored_author($_[0]) } },
    access => [ 'editor' ],
    insert => [ 'INSERT INTO "note" ("body", "editor_id") VALUES (?, ?)', [ 'b', 7 ] ],
    check  => sub {
      my ($note, $name) = @_;
      is $note->editor_id, 7, "$name: the row holds the foreign key";
    },
  },
  {
    name   => 'an inflator object and two stored rows at once',
    data   => sub {
      { body => 'b', tag => Test::Tag->new('x'), author => stored_author($_[0]), editor => stored_author($_[0]) };
    },
    access => [ 'author', 'editor' ],
    insert => [
      'INSERT INTO "note" ("author", "body", "editor_id", "tag") VALUES (?, ?, ?, ?)',
      [ 7, 'b', 7, 'tag:x' ],
    ],
  },
);

for my $case (@single) {
  my $name   = $case->{name};
  my @access = @{ $case->{access} || [] };
  my $sync_state;

  # The synchronous insert is the measure: this is the INSERT it sends.
  {
    my $schema = immediate_schema();
    my $note = $schema->resultset('Note')->create( $case->{data}->($schema) );

    is_deeply note_insert($schema->storage->captured_queries), $case->{insert},
      "$name: the synchronous insert sends this INSERT";
    is scalar( grep { $_ eq 'INSERT' || $_ eq 'SELECT' } @{ synced($schema) } ), 1,
      "$name: and no other statement beside it";

    $sync_state = after_insert($schema, $note, @access);
  }

  # Unbound, on a backend: through the backend, on the pool.
  {
    my ($schema, $backend) = backend_schema();
    my $data = $case->{data}->($schema);

    my $note = resolved($schema->resultset('Note')->create_async($data), "$name, unbound");

    is_deeply wire($backend), [ [ INSERT => 'the pool' ] ],
      "$name, unbound: one INSERT, through the backend";
    is_deeply synced($schema), [],
      "$name, unbound: nothing through the synchronous storage";
    is_deeply note_insert(@{ $backend->{captured} }), $case->{insert},
      "$name, unbound: the INSERT the synchronous insert sends";
    ok $note && $note->in_storage, "$name, unbound: the row is in storage";
    is $note && $note->id, 1, "$name, unbound: with the key that came back";
    $case->{check}->($note, "$name, unbound") if $note && $case->{check};
    is_deeply after_insert($schema, $note, @access), $sync_state,
      "$name, unbound: the row is left as the synchronous insert leaves it";
  }

  # Bound to a transaction: on its connection, between BEGIN and COMMIT.
  {
    my ($schema, $backend) = backend_schema();
    my $data = $case->{data}->($schema);

    my $note = resolved($backend->txn_do_async(sub {
      my ($ctx) = @_;
      return $schema->resultset('Note')->with_context($ctx)->create_async($data);
    }), "$name, bound");

    is_deeply wire($backend),
      [ [ BEGIN => 'TXN1' ], [ INSERT => 'TXN1' ], [ COMMIT => 'TXN1' ] ],
      "$name, bound: one INSERT, inside the transaction, on its connection";
    is_deeply synced($schema), [],
      "$name, bound: nothing through the synchronous storage";
    is_deeply note_insert(@{ $backend->{captured} }), $case->{insert},
      "$name, bound: the INSERT the synchronous insert sends";
    ok $note && $note->in_storage, "$name, bound: the row is in storage";
    $case->{check}->($note, "$name, bound") if $note && $case->{check};
    is_deeply after_insert($schema, $note, @access), $sync_state,
      "$name, bound: the row is left as the synchronous insert leaves it";
  }

  # Bound in the 'immediate' mode, where the context is the storage (ADR 0055)
  # and every statement runs in-process: the same INSERT, inside its
  # transaction.
  {
    my $schema = immediate_schema();
    my $data = $case->{data}->($schema);

    my $note = resolved($schema->storage->txn_do_async(sub {
      my ($ctx) = @_;
      return $schema->resultset('Note')->with_context($ctx)->create_async($data);
    }), "$name, bound in the immediate mode");

    is_deeply synced($schema), [ qw( BEGIN INSERT COMMIT ) ],
      "$name, bound in the immediate mode: one INSERT, inside the transaction";
    is_deeply note_insert($schema->storage->captured_queries), $case->{insert},
      "$name, bound in the immediate mode: the INSERT the synchronous insert sends";
    ok $note && $note->in_storage, "$name, bound in the immediate mode: the row is in storage";
    $case->{check}->($note, "$name, bound in the immediate mode") if $note && $case->{check};
    is_deeply after_insert($schema, $note, @access), $sync_state,
      "$name, bound in the immediate mode: the row is left as the synchronous insert leaves it";
  }
}

# ---------------------------------------------------------------------------
# The same through the row: a value put on a new row afterwards, by accessor,
# lands in _inflated_column as well.
# ---------------------------------------------------------------------------
{
  my ($schema, $backend) = backend_schema();

  $backend->txn_do_async(sub {
    my ($ctx) = @_;
    my $note = $schema->resultset('Note')->with_context($ctx)->new_result({ body => 'b' });
    $note->tag( Test::Tag->new('later') );
    return $note->insert_async;
  });

  is_deeply wire($backend),
    [ [ BEGIN => 'TXN1' ], [ INSERT => 'TXN1' ], [ COMMIT => 'TXN1' ] ],
    'an inflator object set by accessor, bound: one INSERT inside the transaction';
  is_deeply note_insert(@{ $backend->{captured} }),
    [ 'INSERT INTO "note" ("body", "tag") VALUES (?, ?)', [ 'b', 'tag:later' ] ],
    'an inflator object set by accessor, bound: deflated into the INSERT';
}

# ---------------------------------------------------------------------------
# A cascade stays a cascade: more than one statement, so a bound context
# refuses it and names what makes it one; unbound it runs synchronously, as
# before.
# ---------------------------------------------------------------------------
my @cascade = (
  {
    name   => 'an unstored row for a belongs_to',
    data   => sub { { body => 'b', author => $_[0]->resultset('Author')->new_result({ name => 'New' }) } },
    reason => qr/the row for 'author' is looked up or inserted before this one/,
  },
  {
    name   => 'a hashref for a belongs_to',
    data   => sub { { body => 'b', editor => { name => 'New' } } },
    reason => qr/the row for 'editor' is looked up or inserted before this one/,
  },
  {
    name   => 'an arrayref of rows for a has_many',
    source => 'Author',
    data   => sub { { name => 'Ada', notes => [ { body => 'one' }, { body => 'two' } ] } },
    reason => qr/the rows for 'notes' are linked and inserted after this one/,
  },
);

for my $case (@cascade) {
  my $name   = $case->{name};
  my $source = $case->{source} || 'Note';

  {
    my ($schema, $backend) = backend_schema();

    my $txn = $backend->txn_do_async(sub {
      my ($ctx) = @_;
      return $schema->resultset($source)->with_context($ctx)
                    ->create_async( $case->{data}->($schema) );
    });

    my $error = failure_of($txn);
    like $error, qr/insert_async cannot run on a bound async context/,
      "$name, bound: refused";
    like $error, qr/related-object multi-create is a transactional cascade/,
      "$name, bound: as the multi-create it is";
    like $error, $case->{reason}, "$name, bound: naming what makes it one";
    is_deeply wire($backend), [ [ BEGIN => 'TXN1' ], [ ROLLBACK => 'TXN1' ] ],
      "$name, bound: nothing was inserted, the transaction rolled back";
  }

  {
    my ($schema, $backend) = backend_schema();

    my $row = $schema->resultset($source)->create_async( $case->{data}->($schema) )->get;

    ok $row->in_storage, "$name, unbound: the synchronous cascade still runs";
    is_deeply wire($backend), [], "$name, unbound: none of it through the backend";
    is scalar( grep { $_ eq 'INSERT' } @{ synced($schema) } ), ( $source eq 'Author' ? 3 : 2 ),
      "$name, unbound: every row of it through the synchronous storage";
  }
}

# ---------------------------------------------------------------------------
# Not decided (ADR 0045, addenda 2026-10-08): two things the cascade above
# brings with it. The assertions marked IST hold what happens today and are no
# promise; they are here so that a decision flips a visible test.
# ---------------------------------------------------------------------------

# A hashref for a belongs_to is looked up while the row is BUILT -- Row::new
# asks an unbound resultset of the related source -- so a synchronous SELECT
# has gone out, outside the transaction, by the time insert_async refuses.
{
  my ($schema, $backend) = backend_schema();

  $backend->txn_do_async(sub {
    my ($ctx) = @_;
    return $schema->resultset('Note')->with_context($ctx)
                  ->create_async({ body => 'b', editor => { id => 8, name => 'New' } });
  });

  # IST, no promise.
  is_deeply synced($schema), [ 'SELECT' ],
    'IST hashref for a belongs_to, bound: its lookup ran through the synchronous storage, outside the transaction';
}

# A stored row put on a new row AFTERWARDS (accessor, set_inflated_columns) is
# not flagged the way one passed to new_result is. The synchronous insert looks
# such a row up again before it inserts; insert_async follows it and treats the
# insert as a cascade.
{
  my $sync = immediate_schema();
  my $sync_note = $sync->resultset('Note')->new_result({ body => 'b' });
  $sync_note->author( stored_author($sync) );
  $sync_note->insert;

  # IST, no promise.
  is_deeply [ grep { $_ eq 'SELECT' || $_ eq 'INSERT' } @{ synced($sync) } ], [ qw( SELECT INSERT ) ],
    'IST stored row set by accessor: the synchronous insert looks it up again first';

  my ($schema, $backend) = backend_schema();
  my $txn = $backend->txn_do_async(sub {
    my ($ctx) = @_;
    my $note = $schema->resultset('Note')->with_context($ctx)->new_result({ body => 'b' });
    $note->author( stored_author($schema) );
    return $note->insert_async;
  });

  # IST, no promise.
  like failure_of($txn), qr/the row for 'author' is looked up or inserted before this one/,
    'IST stored row set by accessor, bound: refused as the cascade the synchronous insert makes of it';
}

done_testing;
