use strict;
use warnings;
use Test::More;

use DBIO::Test::Storage;
use DBIO::Test::Future ();
use DBIO::SQLMaker;
use DBIO::Storage::Async;
use DBIO::Storage::DBI;

# karr k331 (5): insert_async / update_async / delete_async called the
# backend directly and so ran past every override of insert / update / delete
# further up the class's MRO -- Timestamp never stamped, UUIDColumns never
# generated, FilterColumn never filtered, Ordered / ChangeLog / a user's own
# override never ran.
#
# What is asserted:
#
#   - the components whose work lies BEFORE the write (Timestamp,
#     UUIDColumns, FilterColumn) do it through Row's prepare_insert /
#     prepare_update / prepare_delete hooks, which the synchronous and the
#     asynchronous path both call, once: *_async sends the statement and
#     leaves the row exactly as the synchronous method does -- unbound, bound
#     to a transaction, and bound in the 'immediate' mode;
#   - a class whose package defines insert / update / delete itself but not
#     the *_async sibling (Ordered, ChangeLog, a user class, Moo `around`) has
#     the override run: unbound the write goes through the synchronous method
#     and the Future is settled with its result; bound it is refused, an
#     exception naming the class and the method;
#   - a class that uses the hooks instead runs fully async, hook once.

{
  package Test::Ov::Schema;
  use base 'DBIO::Schema';
}

# ---- Timestamp -------------------------------------------------------------
{
  package Test::Ov::Schema::Result::Stamped;
  use base 'DBIO::Core';

  __PACKAGE__->load_components('Timestamp');
  __PACKAGE__->table('stamped');
  __PACKAGE__->add_columns(
    id         => { data_type => 'integer', is_auto_increment => 1 },
    title      => { data_type => 'varchar', size => 50 },
    created_at => { data_type => 'varchar', size => 30, is_nullable => 1, set_on_create => 1 },
    updated_at => { data_type => 'varchar', size => 30, is_nullable => 1, set_on_create => 1, set_on_update => 1 },
  );
  __PACKAGE__->set_primary_key('id');

  sub get_timestamp { '2026-10-10 12:00:00' }
}

# ---- FilterColumn ----------------------------------------------------------
{
  package Test::Ov::Schema::Result::Filtered;
  use base 'DBIO::Core';

  __PACKAGE__->load_components('FilterColumn');
  __PACKAGE__->table('filtered');
  __PACKAGE__->add_columns(
    id    => { data_type => 'integer', is_auto_increment => 1 },
    label => { data_type => 'varchar', size => 50 },
    note  => { data_type => 'varchar', size => 50, is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->filter_column(label => {
    filter_to_storage   => sub { uc $_[1] },
    filter_from_storage => sub { lc $_[1] },
  });
}

# ---- Ordered ---------------------------------------------------------------
{
  package Test::Ov::Schema::Result::Ranked;
  use base 'DBIO::Core';

  __PACKAGE__->load_components('Ordered');
  __PACKAGE__->table('ranked');
  __PACKAGE__->add_columns(
    id       => { data_type => 'integer', is_auto_increment => 1 },
    position => { data_type => 'integer', position => 1 },
    name     => { data_type => 'varchar', size => 50 },
  );
  __PACKAGE__->set_primary_key('id');
}

# ---- a user class with plain overrides ------------------------------------
{
  package Test::Ov::Schema::Result::Own;
  use base 'DBIO::Core';

  __PACKAGE__->table('own');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer', is_auto_increment => 1 },
    name => { data_type => 'varchar', size => 50 },
  );
  __PACKAGE__->set_primary_key('id');

  our @CALLS;
  sub insert { my $self = shift; push @CALLS, 'insert'; $self->name(uc $self->name); $self->next::method(@_) }
  sub update { my $self = shift; push @CALLS, 'update'; $self->next::method(@_) }
  sub delete { my $self = shift; push @CALLS, 'delete'; $self->next::method(@_) }
}

# ---- a user class that carries its own *_async sibling --------------------
{
  package Test::Ov::Schema::Result::Sibling;
  use base 'DBIO::Core';

  __PACKAGE__->table('sibling');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer', is_auto_increment => 1 },
    name => { data_type => 'varchar', size => 50 },
  );
  __PACKAGE__->set_primary_key('id');

  our @CALLS;
  sub insert       { my $self = shift; push @CALLS, 'insert';       $self->next::method(@_) }
  sub insert_async { my $self = shift; push @CALLS, 'insert_async'; $self->next::method(@_) }
}

# ---- a user class that uses the hooks -------------------------------------
{
  package Test::Ov::Schema::Result::Hooked;
  use base 'DBIO::Core';

  __PACKAGE__->table('hooked');
  __PACKAGE__->add_columns(
    id     => { data_type => 'integer', is_auto_increment => 1 },
    name   => { data_type => 'varchar', size => 50 },
    secret => { data_type => 'varchar', size => 50, is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');

  our @CALLS;
  sub prepare_insert {
    my $self = shift;
    push @CALLS, 'prepare_insert';
    $self->name('hooked-' . $self->name);
    return $self->next::method(@_);
  }
  sub prepare_update {
    my ($self, $upd) = @_;
    push @CALLS, 'prepare_update';
    # in place: the key leaves the hashref and is set another way
    $self->secret('s-' . delete $upd->{secret}) if $upd and exists $upd->{secret};
    return $self->next::method($upd);
  }
  sub prepare_delete {
    my $self = shift;
    push @CALLS, 'prepare_delete';
    return $self->next::method(@_);
  }
}

Test::Ov::Schema->register_class(Stamped  => 'Test::Ov::Schema::Result::Stamped');
Test::Ov::Schema->register_class(Filtered => 'Test::Ov::Schema::Result::Filtered');
Test::Ov::Schema->register_class(Ranked   => 'Test::Ov::Schema::Result::Ranked');
Test::Ov::Schema->register_class(Own      => 'Test::Ov::Schema::Result::Own');
Test::Ov::Schema->register_class(Sibling  => 'Test::Ov::Schema::Result::Sibling');
Test::Ov::Schema->register_class(Hooked   => 'Test::Ov::Schema::Result::Hooked');

# ---- UUIDColumns, where a UUID backend is installed ------------------------
my $HAVE_UUID = eval { require DBIO::UUIDColumns; 1 };
if ($HAVE_UUID) {
  eval q{
    package Test::Ov::Schema::Result::Tagged;
    use base 'DBIO::Core';

    __PACKAGE__->load_components('UUIDColumns');
    __PACKAGE__->table('tagged');
    __PACKAGE__->add_columns(
      id   => { data_type => 'varchar', size => 36, uuid_on_create => 1 },
      name => { data_type => 'varchar', size => 50 },
    );
    __PACKAGE__->set_primary_key('id');

    sub get_uuid { '11111111-2222-3333-4444-555555555555' }
    1;
  } or die $@;
  Test::Ov::Schema->register_class(Tagged => 'Test::Ov::Schema::Result::Tagged');
}

# ---- Moo `around`, where Moo is installed ----------------------------------
my $HAVE_MOO = eval { require Moo; require DBIO::Moo; 1 };
if ($HAVE_MOO) {
  eval q{
    package Test::Ov::Schema::Result::Mooed;
    use DBIO::Moo;

    __PACKAGE__->table('mooed');
    __PACKAGE__->add_columns(
      id   => { data_type => 'integer', is_auto_increment => 1 },
      name => { data_type => 'varchar', size => 50 },
    );
    __PACKAGE__->set_primary_key('id');

    around insert => sub { my ($orig, $self, @rest) = @_; $self->name(uc $self->name); $self->$orig(@rest) };
    around update => sub { my ($orig, $self, @rest) = @_; $self->$orig(@rest) };
    around delete => sub { my ($orig, $self, @rest) = @_; $self->$orig(@rest) };
    1;
  } or die $@;
  Test::Ov::Schema->register_class(Mooed => 'Test::Ov::Schema::Result::Mooed');
}

# ---- ChangeLog (a schema of its own) --------------------------------------
{
  package Test::Ov::CL::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('ChangeLog::Schema');
}
{
  package Test::Ov::CL::Schema::Result::Logged;
  use base 'DBIO::Core';

  __PACKAGE__->load_components('ChangeLog');
  __PACKAGE__->table('logged');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer', is_auto_increment => 1 },
    name => { data_type => 'varchar', size => 100 },
  );
  __PACKAGE__->set_primary_key('id');
}
Test::Ov::CL::Schema->register_class(Logged => 'Test::Ov::CL::Schema::Result::Logged');

# ---- the fake async backend ----------------------------------------------
{
  package Test::SyncPool;
  sub new { bless { txns => 0 }, shift }
  sub acquire     { DBIO::Test::Future->done('POOL') }
  sub acquire_txn { DBIO::Test::Future->done('TXN' . ++$_[0]->{txns}) }
  sub release     { 1 }
  sub shutdown    { 1 }
}
{
  package Test::OvBackend;
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

  # An INSERT is answered with the new key, an UPDATE / DELETE with one row.
  sub _answer {
    my ($self, $sql, $bind, $on) = @_;
    push @{ $self->{captured} }, { sql => $sql, bind => $bind, on => $on };
    # (RETURNING would hand back the id the statement carried; a table whose
    # key is given by the row has nothing to add)
    return $self->future_class->done(
      $sql =~ /^INSERT INTO "tagged"/ ? {} : $sql =~ /^INSERT/ ? { id => 1 } : 1
    );
  }
  sub _query_async        { $_[0]->_answer(@_[1, 2], 'the pool') }
  sub _query_async_pinned { $_[0]->_answer(@_[2, 3], $_[1]) }
}

DBIO::Storage::DBI->register_async_mode( async_overrides_backend => 'Test::OvBackend' );

sub immediate_schema {
  my ($class) = @_;
  my $schema = ($class || 'Test::Ov::Schema')->clone;
  $schema->storage_type('+DBIO::Test::Storage');
  $schema = $schema->connect(sub { });
  $schema->storage(DBIO::Test::Storage->new($schema));
  if ($schema->can('_register_changelog_sources')) {
    $schema->_changelog_sources_registered(0);
    $schema->_register_changelog_sources;
  }
  return $schema;
}

sub backend_schema {
  my $schema = immediate_schema(@_);
  $schema->storage->_async_mode('async_overrides_backend');
  delete $schema->storage->{_async_storage_obj};
  return ($schema, $schema->storage->_async_storage);
}

sub wire {
  my ($backend) = @_;
  return [ map { [ ($_->{sql} =~ /(\w+)/)[0], $_->{on} ] } @{ $backend->{captured} } ];
}

sub synced {
  my ($schema) = @_;
  return [ map { ($_->{sql} =~ /(\w+)/)[0] } $schema->storage->captured_queries ];
}

# The statement of a verb as [ sql, bind values ], from either side.
sub statement {
  my ($verb, @queries) = @_;
  my ($q) = grep { $_->{sql} =~ /^$verb\b/ } @queries;
  return undef unless $q;
  ( my $sql = $q->{sql} ) =~ s/ RETURNING \*$//;
  return [ $sql, [ map { ref $_ eq 'ARRAY' ? $_->[1] : $_ } @{ $q->{bind} || [] } ] ];
}

sub failure_of {
  my ($future) = @_;
  return undef if eval { $future->get; 1 };
  return "$@";
}

sub state_of {
  my ($row) = @_;
  return {
    columns    => { $row->get_columns },
    dirty      => { $row->get_dirty_columns },
    in_storage => $row->in_storage ? 1 : 0,
  };
}

# A row in storage and clean, as a search hands it out.
sub stored {
  my ($schema, $source, $cols) = @_;
  my $rsrc = $schema->source($source);
  return $rsrc->result_class->inflate_result($rsrc, { %$cols });
}

sub fresh {
  my ($schema, $source, $cols) = @_;
  return $schema->resultset($source)->new_result({ %$cols });
}

# One call, four ways: synchronous, unbound on the backend, bound to a
# transaction on the backend, bound in the 'immediate' mode. Returns for each
# the statement the verb sent and the state the row is left in.
#   $build->($schema) -> the row;  $call->($row, $suffix) runs it
sub measure {
  my ($verb, $build, $call, $schema_class) = @_;
  my %got;

  {
    my $schema = immediate_schema($schema_class);
    my $row = $build->($schema);
    $schema->storage->reset_captured;
    $call->($row, '');
    $got{sync} = { stmt => statement($verb, $schema->storage->captured_queries), state => state_of($row) };
  }
  {
    my ($schema, $backend) = backend_schema($schema_class);
    my $row = $build->($schema);
    $call->($row, '_async')->get;
    $got{unbound} = { stmt => statement($verb, @{ $backend->{captured} }), state => state_of($row),
                      wire => wire($backend), synced => synced($schema) };
  }
  {
    my ($schema, $backend) = backend_schema($schema_class);
    my $row;
    $backend->txn_do_async(sub {
      my ($ctx) = @_;
      $row = $build->($schema)->with_context($ctx);
      return $call->($row, '_async');
    })->get;
    $got{bound} = { stmt => statement($verb, @{ $backend->{captured} }), state => state_of($row),
                    wire => wire($backend), synced => synced($schema) };
  }
  {
    my $schema = immediate_schema($schema_class);
    my $row;
    $schema->storage->txn_do_async(sub {
      my ($ctx) = @_;
      $row = $build->($schema)->with_context($ctx);
      return $call->($row, '_async');
    })->get;
    $got{immediate} = { stmt => statement($verb, $schema->storage->captured_queries), state => state_of($row),
                        synced => synced($schema) };
  }
  return \%got;
}

sub same_as_sync {
  my ($got, $name) = @_;
  for my $mode (qw( unbound bound immediate )) {
    is_deeply $got->{$mode}{stmt}, $got->{sync}{stmt}, "$name, $mode: the statement the synchronous method sends";
    is_deeply $got->{$mode}{state}, $got->{sync}{state}, "$name, $mode: the row is left as the synchronous method leaves it";
  }
  is_deeply $got->{unbound}{synced}, [], "$name, unbound: nothing through the synchronous storage";
}

# ---------------------------------------------------------------------------
# Components that do their work before the write: hooks, async like sync.
# ---------------------------------------------------------------------------
{
  my $got = measure(INSERT =>
    sub { fresh($_[0], Stamped => { title => 'T' }) },
    sub { my $m = "insert$_[1]"; $_[0]->$m },
  );
  same_as_sync($got, 'Timestamp insert');
  is $got->{sync}{state}{columns}{created_at}, '2026-10-10 12:00:00', 'Timestamp insert: created_at is set (sync)';
  is $got->{unbound}{state}{columns}{updated_at}, '2026-10-10 12:00:00', 'Timestamp insert: updated_at is set (async)';
  ok scalar( grep { defined $_ && $_ eq '2026-10-10 12:00:00' } @{ $got->{unbound}{stmt}[1] } ) == 2,
    'Timestamp insert: both stamps are in the INSERT the backend got';
  is_deeply $got->{bound}{wire}, [ [ BEGIN => 'TXN1' ], [ INSERT => 'TXN1' ], [ COMMIT => 'TXN1' ] ],
    'Timestamp insert, bound: one INSERT inside the transaction';
}

{
  my $got = measure(UPDATE =>
    sub { stored($_[0], Stamped => { id => 1, title => 'T', created_at => 'old', updated_at => 'old' }) },
    sub { my $m = "update$_[1]"; $_[0]->$m({ title => 'U' }) },
  );
  same_as_sync($got, 'Timestamp update');
  is $got->{sync}{state}{columns}{updated_at}, '2026-10-10 12:00:00', 'Timestamp update: updated_at is refreshed (sync)';
  is $got->{unbound}{state}{columns}{updated_at}, '2026-10-10 12:00:00', 'Timestamp update: updated_at is refreshed (async)';
  like $got->{unbound}{stmt}[0], qr/"updated_at"/, 'Timestamp update: it is in the UPDATE the backend got';
  is_deeply $got->{bound}{wire}, [ [ BEGIN => 'TXN1' ], [ UPDATE => 'TXN1' ], [ COMMIT => 'TXN1' ] ],
    'Timestamp update, bound: one UPDATE inside the transaction';

  # the timestamp wins over a value passed in the update hashref
  my $won = measure(UPDATE =>
    sub { stored($_[0], Stamped => { id => 1, title => 'T', created_at => 'old', updated_at => 'old' }) },
    sub { my $m = "update$_[1]"; $_[0]->$m({ title => 'U', updated_at => 'mine' }) },
  );
  same_as_sync($won, 'Timestamp update with a value for the stamped column');
  is $won->{unbound}{state}{columns}{updated_at}, '2026-10-10 12:00:00',
    'Timestamp update: the timestamp wins over the passed value';
}

SKIP: {
  skip 'No UUID backend installed', 12 unless $HAVE_UUID;
  my $got = measure(INSERT =>
    sub { fresh($_[0], Tagged => { name => 'n' }) },
    sub { my $m = "insert$_[1]"; $_[0]->$m },
  );
  same_as_sync($got, 'UUIDColumns insert');
  is $got->{unbound}{state}{columns}{id}, '11111111-2222-3333-4444-555555555555',
    'UUIDColumns insert: the id is generated (async)';
  is_deeply $got->{bound}{wire}, [ [ BEGIN => 'TXN1' ], [ INSERT => 'TXN1' ], [ COMMIT => 'TXN1' ] ],
    'UUIDColumns insert, bound: one INSERT inside the transaction';
}

{
  my $got = measure(UPDATE =>
    sub { stored($_[0], Filtered => { id => 1, label => 'old', note => 'n' }) },
    sub { my $m = "update$_[1]"; $_[0]->$m({ label => 'new', note => 'm' }) },
  );
  same_as_sync($got, 'FilterColumn update');
  is_deeply $got->{sync}{stmt}[1], [ 'NEW', 'm', 1 ], 'FilterColumn update: the filtered value is what is stored (sync)';
  is_deeply $got->{unbound}{stmt}[1], [ 'NEW', 'm', 1 ], 'FilterColumn update: and what the backend gets (async)';
  is $got->{unbound}{state}{columns}{label}, 'NEW', 'FilterColumn update: the stored form is on the row';
  is $got->{unbound}{state}{dirty}->{label}, undef, 'FilterColumn update: nothing left dirty';
  is_deeply $got->{bound}{wire}, [ [ BEGIN => 'TXN1' ], [ UPDATE => 'TXN1' ], [ COMMIT => 'TXN1' ] ],
    'FilterColumn update, bound: one UPDATE inside the transaction';
}

# ---------------------------------------------------------------------------
# A class using the hooks: async, each hook once, on the wire.
# ---------------------------------------------------------------------------
{
  my $calls = \@Test::Ov::Schema::Result::Hooked::CALLS;

  my ($schema, $backend) = backend_schema();
  @$calls = ();
  my $row = fresh($schema, Hooked => { name => 'a' });
  $row->insert_async->get;
  is_deeply $calls, ['prepare_insert'], 'prepare_insert runs once on insert_async';
  is_deeply statement(INSERT => @{ $backend->{captured} })->[1], ['hooked-a'], 'and its work is in the INSERT';
  is_deeply wire($backend), [ [ INSERT => 'the pool' ] ], 'the write went async';

  @$calls = ();
  $row->update_async({ name => 'b', secret => 'x' })->get;
  is_deeply $calls, ['prepare_update'], 'prepare_update runs once on update_async';
  my $upd = statement(UPDATE => @{ $backend->{captured} });
  like $upd->[0], qr/"secret"/, 'the key the hook moved out of the hashref is written';
  is $row->secret, 's-x', 'and set by the hook';
  is_deeply wire($backend), [ [ INSERT => 'the pool' ], [ UPDATE => 'the pool' ] ], 'the write went async';

  @$calls = ();
  $row->delete_async->get;
  is_deeply $calls, ['prepare_delete'], 'prepare_delete runs once on delete_async';
  is_deeply [ map { $_->[0] } @{ wire($backend) } ], [ qw( INSERT UPDATE DELETE ) ], 'the write went async';

  # bound: not refused
  my ($bs, $bb) = backend_schema();
  @$calls = ();
  my $err = failure_of($bb->txn_do_async(sub {
    my ($ctx) = @_;
    return fresh($bs, Hooked => { name => 'c' })->with_context($ctx)->insert_async;
  }));
  is $err, undef, 'bound: a class on the hooks is not refused';
  is_deeply wire($bb), [ [ BEGIN => 'TXN1' ], [ INSERT => 'TXN1' ], [ COMMIT => 'TXN1' ] ],
    'bound: one INSERT inside the transaction';
  is_deeply $calls, ['prepare_insert'], 'bound: the hook once';

  # the synchronous methods call them once as well
  my $ss = immediate_schema();
  @$calls = ();
  my $srow = fresh($ss, Hooked => { name => 'a' });
  $srow->insert;
  $srow->update({ name => 'b' });
  $srow->delete;
  is_deeply $calls, [ qw( prepare_insert prepare_update prepare_delete ) ], 'the synchronous methods call each hook once';
}

# A row that is already in storage, and one that carries its own sibling.
{
  my ($schema, $backend) = backend_schema();
  my $calls = \@Test::Ov::Schema::Result::Hooked::CALLS;
  @$calls = ();
  stored($schema, Hooked => { id => 1, name => 'x' })->insert_async->get;
  is_deeply $calls, [], 'insert_async of a row already in storage runs no hook';
  is_deeply wire($backend), [], 'and sends nothing';
}
{
  my ($schema, $backend) = backend_schema();
  my $calls = \@Test::Ov::Schema::Result::Hooked::CALLS;
  my @own = \@Test::Ov::Schema::Result::Sibling::CALLS;
  @{ $own[0] } = ();
  my $err = failure_of($backend->txn_do_async(sub {
    my ($ctx) = @_;
    return fresh($schema, Sibling => { name => 'a' })->with_context($ctx)->insert_async;
  }));
  is $err, undef, 'an override with its *_async sibling in the same package is not refused';
  is_deeply $own[0], ['insert_async'], 'its sibling is what runs';
  is_deeply wire($backend), [ [ BEGIN => 'TXN1' ], [ INSERT => 'TXN1' ], [ COMMIT => 'TXN1' ] ],
    'and the write goes through the backend';
}

# A plain class (CascadeActions in its MRO, nothing else) is not touched by
# the gate: bound, the statement goes out on the connection.
{
  my ($schema, $backend) = backend_schema();
  my $err = failure_of($backend->txn_do_async(sub {
    my ($ctx) = @_;
    return stored($schema, Hooked => { id => 1, name => 'x' })->with_context($ctx)->delete_async;
  }));
  is $err, undef, 'a class with only CascadeActions around delete is not refused';
  is_deeply wire($backend), [ [ BEGIN => 'TXN1' ], [ DELETE => 'TXN1' ], [ COMMIT => 'TXN1' ] ],
    'and deletes through the backend';
}

# ---------------------------------------------------------------------------
# An override without its *_async sibling: unbound it runs (synchronously,
# the Future settled), bound it is refused naming class and method.
# ---------------------------------------------------------------------------
my @gate = (
  { name => 'Ordered', schema => 'Test::Ov::Schema', source => 'Ranked', table => 'ranked',
    class => 'DBIO::Ordered',
    insert => sub { fresh($_[0], Ranked => { position => 3, name => 'a' }) },
    stored => sub { stored($_[0], Ranked => { id => 1, position => 2, name => 'a' }) },
    update => { name => 'b' },
  },
  { name => 'ChangeLog', schema => 'Test::Ov::CL::Schema', source => 'Logged', table => 'logged',
    class => 'DBIO::ChangeLog',
    insert => sub { fresh($_[0], Logged => { name => 'a' }) },
    stored => sub { stored($_[0], Logged => { id => 1, name => 'a' }) },
    update => { name => 'b' },
  },
  { name => 'user class', schema => 'Test::Ov::Schema', source => 'Own', table => 'own',
    class => 'Test::Ov::Schema::Result::Own',
    insert => sub { fresh($_[0], Own => { name => 'a' }) },
    stored => sub { stored($_[0], Own => { id => 1, name => 'a' }) },
    update => { name => 'b' },
  },
  ( $HAVE_MOO ? ( { name => 'Moo around', schema => 'Test::Ov::Schema', source => 'Mooed', table => 'mooed',
    class => 'Test::Ov::Schema::Result::Mooed',
    insert => sub { fresh($_[0], Mooed => { name => 'a' }) },
    stored => sub { stored($_[0], Mooed => { id => 1, name => 'a' }) },
    update => { name => 'b' },
  } ) : () ),
);

for my $g (@gate) {
  for my $op (qw( insert update delete )) {
    my $name = "$g->{name} $op";
    my $build = $op eq 'insert' ? $g->{insert} : $g->{stored};
    my @args  = $op eq 'update' ? ($g->{update}) : ();
    my $verb  = uc $op;
    # the write itself, not the changelog's own rows
    my $table = qr/^(?:INSERT INTO|UPDATE|DELETE FROM) "\Q$g->{table}\E"/;

    # synchronous: the measure
    my $sync_state;
    {
      my $schema = immediate_schema($g->{schema});
      my $row = $build->($schema);
      $row->$op(@args);
      $sync_state = state_of($row);
    }

    # unbound: the override runs, the write goes through the sync storage
    {
      my ($schema, $backend) = backend_schema($g->{schema});
      my $row = $build->($schema);
      my $m = "${op}_async";
      my $future = $row->$m(@args);
      my $err = failure_of($future);
      is $err, undef, "$name, unbound: resolves";
      is_deeply state_of($row), $sync_state, "$name, unbound: the row is left as the synchronous method leaves it";
      is scalar( grep { $_->{sql} =~ $table } @{ $backend->{captured} } ), 0,
        "$name, unbound: the write did not go through the backend";
      ok scalar( grep { $_->{sql} =~ $table } $schema->storage->captured_queries ),
        "$name, unbound: it went through the synchronous method";
    }

    # bound to a transaction: refused, named
    {
      my ($schema, $backend) = backend_schema($g->{schema});
      my $m = "${op}_async";
      my $err = failure_of($backend->txn_do_async(sub {
        my ($ctx) = @_;
        return $build->($schema)->with_context($ctx)->$m(@args);
      }));
      like $err, qr/\Q${op}_async\E cannot run on a bound async context/, "$name, bound: refused";
      like $err, qr/\Q$g->{class}\E/, "$name, bound: naming the class";
      like $err, qr/overrides \Q$op\E and has no \Q${op}_async\E sibling/, "$name, bound: naming the method";
      is_deeply wire($backend), [ [ BEGIN => 'TXN1' ], [ ROLLBACK => 'TXN1' ] ],
        "$name, bound: nothing was written";
    }

    # bound in the 'immediate' mode: refused the same way
    {
      my $schema = immediate_schema($g->{schema});
      my $m = "${op}_async";
      my $err = failure_of($schema->storage->txn_do_async(sub {
        my ($ctx) = @_;
        return $build->($schema)->with_context($ctx)->$m(@args);
      }));
      like $err, qr/\Q${op}_async\E cannot run on a bound async context/, "$name, bound in the immediate mode: refused";
      like $err, qr/\Q$g->{class}\E/, "$name, bound in the immediate mode: naming the class";
      is scalar( grep { $_ =~ /^(?:INSERT|UPDATE|DELETE)$/ } @{ synced($schema) } ), 0,
        "$name, bound in the immediate mode: nothing was written";
    }
  }
}

done_testing;
