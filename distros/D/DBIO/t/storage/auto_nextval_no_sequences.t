# ABSTRACT: auto_nextval on a storage without sequences is refused by DBIO, before anything is sent
use strict;
use warnings;

use Test::More;

use DBI;
use DBIO;
use DBIO::Core;
use DBIO::Schema;
use DBIO::Storage::DBI;
use DBIO::Storage::DBI::UniqueIdentifier;
use DBIO::Test::Storage;

# OFFLINE (karr k302). A column marked auto_nextval gets its value from a
# sequence before the INSERT is built: the storage looks the sequence up
# (_dbh_get_autoinc_seq, unless the column info names it) and fetches its next
# value (_sequence_fetch). The base storage calls both and defines neither --
# they are a driver's, and only a driver whose engine has sequences brings
# them. On every other driver a create() that left the column out died of
#   Can't locate object method "_dbh_get_autoinc_seq" via package "<storage>"
# a Perl error that says nothing about the column, the attribute or the way
# out, and that no handler catching DBIO exceptions sees as one.
#
# What this file pins:
#   1. a storage without the sequence methods refuses such an insert with a
#      DBIO exception naming the column, its source and the storage class --
#      whether the sequence would have had to be looked up or is named in the
#      column info, and whether the column was left out or given as literal
#      SQL (a literal does not replace the fetch: the fetched value wins);
#   2. it refuses before anything is sent, and without opening a connection:
#      whether a storage has sequences is a fact about its class;
#   3. each of the two methods is asked for only when it is needed, and the
#      one that is missing is the one the exception names;
#   4. a storage that has them is not refused -- one that inherits them, one
#      its driver moves to the class of its access path (the question is
#      asked of the class the driver determination left, never of the declared
#      class that was there before it), one under a storage layer;
#   5. a value the caller gives ends the matter on every storage: no fetch,
#      no refusal;
#   6. a GUID column on a storage that generates GUIDs is filled by that
#      storage and never reaches the question.
#
# THE SUBSTITUTIONS: for what is inserted, subclasses of the mock storage
# DBIO::Test::Storage, which captures every statement. The mock is always
# "connected" and has a driver determination of its own, so for 2 and for the
# access-path adaptation of 4 there are two fake drivers with storage classes
# defined here, registered for DBD names no DBD carries, over a DBI->connect
# that returns a fake handle and records that it was asked. A schema always
# declares its driver (ADR 0067); none is found through the DSN.

my (@CONNECTS, @ON_HANDLE, @LOOKUPS, @FETCHES, @EXECUTED);
my $NEXTVAL = 40;

sub reset_records { @CONNECTS = @ON_HANDLE = @LOOKUPS = @FETCHES = @EXECUTED = () }

# --- the mock storages ------------------------------------------------------

# a driver whose engine has no sequences: the mock as it comes
{ package T::K302::NoSeq; use base 'DBIO::Test::Storage'; }

# a driver that has both methods
{
  package T::K302::WithSeq;
  use base 'DBIO::Test::Storage';
  sub _dbh_get_autoinc_seq {
    my ($self, $dbh, $source, $col) = @_;
    push @LOOKUPS, [ $source->name, $col ];
    return "seq_of_$col";
  }
  sub _sequence_fetch {
    my ($self, $function, $sequence) = @_;
    push @FETCHES, [ $function, $sequence ];
    return ++$NEXTVAL;
  }
}

# ... and one that has them from its parent only
{ package T::K302::InheritsSeq; use base 'T::K302::WithSeq'; }

# half a driver, either way round
{
  package T::K302::FetchOnly;
  use base 'DBIO::Test::Storage';
  sub _sequence_fetch { push @FETCHES, [ @_[1, 2] ]; return ++$NEXTVAL }
}
{
  package T::K302::LookupOnly;
  use base 'DBIO::Test::Storage';
  sub _dbh_get_autoinc_seq { push @LOOKUPS, [ $_[2]->name, $_[3] ]; return 'seq_of_' . $_[3] }
}

# a storage that generates GUIDs and has no sequences
{
  package T::K302::Guid;
  use base qw( DBIO::Storage::DBI::UniqueIdentifier DBIO::Test::Storage );
  use mro 'c3';
}

# --- the fake drivers -------------------------------------------------------

{
  package T::K302::DBH;
  sub new {
    my ($class, $dbd) = @_;
    bless {
      Active => 1, AutoCommit => 1, RaiseError => 1, CachedKids => {},
      Driver => { Name => $dbd },
    }, $class;
  }
  sub FETCH { $_[0]{$_[1]} }
  sub ping { 1 }
  sub disconnect { $_[0]{Active} = 0; 1 }
  sub do { push @ON_HANDLE, $_[1]; return '0E0' }
  sub prepare { push @ON_HANDLE, $_[1]; die "nothing is prepared in this file\n" }
  sub prepare_cached { push @ON_HANDLE, $_[1]; die "nothing is prepared in this file\n" }
}

{
  package DBIO::K302NoSeq::Storage;
  use base 'DBIO::Storage::DBI';
  use mro 'c3';
  DBIO::Storage::DBI->register_driver(K302NoSeq => __PACKAGE__);
  $INC{'DBIO/K302NoSeq/Storage.pm'} = __FILE__;
}

# The driver with sequences. Its declared class has none: the class of its
# access path has them, and the driver determination moves the storage there
# (ADR 0059). Its INSERT is not sent anywhere: _execute records the values it
# was handed, which is where a fetched value has to have arrived.
{
  package DBIO::K302Seq::Storage;
  use base 'DBIO::Storage::DBI';
  use mro 'c3';
  DBIO::Storage::DBI->register_driver(K302Seq => __PACKAGE__);
  $INC{'DBIO/K302Seq/Storage.pm'} = __FILE__;

  sub _adapt_to_access_path {
    my ($self, $dbd) = @_;
    bless $self, 'DBIO::K302Seq::Storage::Native'
      if defined $dbd and $dbd eq 'K302Seq';
  }
}
{
  package DBIO::K302Seq::Storage::Native;
  use base 'DBIO::K302Seq::Storage';
  use mro 'c3';

  sub _dbh_get_autoinc_seq {
    my ($self, $dbh, $source, $col) = @_;
    push @LOOKUPS, [ $source->name, $col, ref $dbh ];
    return "seq_of_$col";
  }
  sub _sequence_fetch {
    my ($self, $function, $sequence) = @_;
    push @FETCHES, [ $function, $sequence ];
    return ++$NEXTVAL;
  }
  sub _execute {
    my ($self, $op, $source, $values) = @_;
    push @EXECUTED, [ $op, { %$values } ];
    return (1, undef);
  }
}

{ package T::K302::Layer; sub k302_layer { 'layer' } }

no warnings 'redefine';
local *DBI::connect = sub {
  push @CONNECTS, $_[1];
  my ($dbd) = $_[1] =~ /^dbi:(\w*)/i;
  return T::K302::DBH->new($dbd);
};
use warnings 'redefine';

# --- schemas ----------------------------------------------------------------

# The lookup caches what it found in the column info, and a column info is
# shared by every schema of its result class: each case gets a result class of
# its own, so none of them inherits a sequence an earlier one looked up.
my $classes = 0;
sub result_class {
  my (%columns) = @_;
  my $class = 'T::K302::Result' . ++$classes;
  eval "package $class; use base 'DBIO::Core'; 1" or die $@;
  $class->table("k302_t$classes");
  $class->add_columns(
    %columns,
    name => { data_type => 'varchar', size => 100, is_nullable => 1 },
  );
  $class->set_primary_key('id');
  return $class;
}

# the column under test is the key: looked up, or named in the column info
sub looked_up { result_class(id => { data_type => 'integer', auto_nextval => 1 }) }
sub named {
  result_class(id => { data_type => 'integer', auto_nextval => 1, sequence => 'k302_seq' });
}

my @KEEP;   # a storage holds its schema weakly
sub schema_class {
  my ($result_class) = @_;
  my $class = 'T::K302::Schema' . ++$classes;
  eval "package $class; use base 'DBIO::Schema'; 1" or die $@;
  $class->register_class(Thing => $result_class);
  return $class;
}

# a schema on one of the mock storages
sub mock_schema {
  my ($storage_class, $result_class) = @_;
  reset_records();
  my $class = schema_class($result_class);
  $class->storage_type('+DBIO::Test::Storage');
  my $schema = $class->connect(sub { });
  $schema->storage($storage_class->new($schema));
  push @KEEP, $schema;
  return $schema;
}

# a schema on one of the fake drivers, declared
sub driver_schema {
  my ($result_class, %arg) = @_;
  reset_records();
  my $class = schema_class($result_class);
  $class->storage_type("+$arg{declared}") if $arg{declared};
  $class->register_storage_layer('T::K302::Layer') if $arg{layered};
  my $schema = $class->connect($arg{dsn}, 'u', 'p');
  push @KEEP, $schema;
  return $schema;
}

sub inserts { grep { $_->{op} eq 'insert' } $_[0]->storage->captured_queries }

# The insert is refused by DBIO: an exception object, not Perl's own error,
# that names the column, where it is and the storage that cannot do it.
sub refused_ok {
  my ($schema, $values, $what, %expect) = @_;

  my $row = eval { $schema->resultset('Thing')->create($values) };
  my $error = $@;
  my $source = $schema->source('Thing');

  ok !$row, "$what: no row comes back";
  isa_ok $error, 'DBIO::Exception', "$what: what is thrown";
  unlike "$error", qr/Can't locate object method/,
    "$what: ... and it is not Perl failing to find a method";
  like "$error", qr/column 'id' of Thing \(table @{[ $source->name ]}\)/,
    "$what: it names the column, its source and its table";
  like "$error", qr/auto_nextval/, "$what: ... the attribute that asked for a sequence";
  like "$error", qr/\Q@{[ ref $schema->storage ]}\E has no sequence support/,
    "$what: ... and the storage class that has none";
  like "$error", qr/or remove auto_nextval/, "$what: ... and a way out";

  # a caller who gave literal SQL is not told to "give a value"
  my $literal = ref $values->{id} ? 1 : 0;
  is "$error" =~ /Literal SQL for the column does not stand in for the sequence/ ? 1 : 0,
    $literal, "$what: a literal is spoken of exactly when one was given";
  is "$error" =~ /Give the column a value on insert/ ? 1 : 0, 1 - $literal,
    "$what: ... and a missing value exactly when none was";

  for my $method (qw( _sequence_fetch _dbh_get_autoinc_seq )) {
    my $names_it = "$error" =~ /\b\Q$method\E\b/ ? 1 : 0;
    is $names_it, ( grep { $_ eq $method } @{ $expect{missing} } ) ? 1 : 0,
      "$what: $method is named exactly when it is the one missing";
  }

  return "$error";
}

# === 1. refused: the sequence would have to be looked up ====================
{
  my $schema = mock_schema('T::K302::NoSeq', looked_up());
  refused_ok($schema, { name => 'a' }, 'no sequences, sequence not named',
    missing => [qw( _sequence_fetch _dbh_get_autoinc_seq )]);
  is_deeply [ $schema->storage->captured_queries ], [],
    '... and no statement was sent';
}

# === 1. refused: the sequence is named in the column info ===================
{
  my $schema = mock_schema('T::K302::NoSeq', named());
  refused_ok($schema, { name => 'a' }, 'no sequences, sequence named',
    missing => [qw( _sequence_fetch )]);
  is_deeply [ $schema->storage->captured_queries ], [],
    '... and no statement was sent';
}

# === 1. refused: the column is given as literal SQL =========================
for my $case (
  [ 'sequence not named', \&looked_up, [qw( _sequence_fetch _dbh_get_autoinc_seq )] ],
  [ 'sequence named',     \&named,     [qw( _sequence_fetch )] ],
) {
  my ($which, $result, $missing) = @$case;
  my $schema = mock_schema('T::K302::NoSeq', $result->());
  refused_ok(
    $schema, { id => \'next_id()', name => 'a' },
    "no sequences, literal SQL for the column, $which", missing => $missing,
  );
  is_deeply [ $schema->storage->captured_queries ], [],
    '... and no statement was sent';
}

# === 3. half a driver: each method is asked for only when it is needed ======
{
  my $schema = mock_schema('T::K302::FetchOnly', looked_up());
  refused_ok($schema, { name => 'a' }, 'fetch but no lookup, sequence not named',
    missing => [qw( _dbh_get_autoinc_seq )]);
  is_deeply \@FETCHES, [], '... and nothing was fetched on the way';
  is_deeply [ $schema->storage->captured_queries ], [], '... and no statement was sent';
}

{
  my $schema = mock_schema('T::K302::FetchOnly', named());
  my $row = $schema->resultset('Thing')->create({ name => 'a' });
  is_deeply \@FETCHES, [ [ NEXTVAL => 'k302_seq' ] ],
    'fetch but no lookup, sequence named: the lookup is not needed, the value is fetched';
  is $row->id, $NEXTVAL, '... and is the row\'s key';
}

for my $case ( [ 'sequence not named', \&looked_up ], [ 'sequence named', \&named ] ) {
  my ($which, $result) = @$case;
  my $schema = mock_schema('T::K302::LookupOnly', $result->());
  refused_ok($schema, { name => 'a' }, "lookup but no fetch, $which",
    missing => [qw( _sequence_fetch )]);
  is_deeply \@LOOKUPS, [],
    '... before the sequence is looked up: there would be nothing to do with it';
  is_deeply [ $schema->storage->captured_queries ], [], '... and no statement was sent';
}

# === 4. a storage with sequences still fetches ==============================
for my $storage_class (qw( T::K302::WithSeq T::K302::InheritsSeq )) {
  my $inherited = $storage_class eq 'T::K302::InheritsSeq' ? ' (inherited)' : '';

  {
    my $schema = mock_schema($storage_class, looked_up());
    my $table  = $schema->source('Thing')->name;
    my $row = $schema->resultset('Thing')->create({ name => 'a' });

    is_deeply \@LOOKUPS, [ [ $table, 'id' ] ],
      "with sequences$inherited: the sequence of the column is looked up";
    is_deeply \@FETCHES, [ [ NEXTVAL => 'seq_of_id' ] ],
      '... and its next value fetched';
    is $row->id, $NEXTVAL, '... which is the row\'s key';

    my ($insert, @more) = inserts($schema);
    ok $insert && !@more, '... one INSERT is sent';
    is_deeply [ sort map { $_->[1] } @{ $insert->{bind} } ], [ sort $NEXTVAL, 'a' ],
      '... carrying the fetched value';

    $schema->resultset('Thing')->create({ name => 'b' });
    is_deeply \@LOOKUPS, [ [ $table, 'id' ] ],
      '... and the sequence is looked up once, then known';
    is scalar(@FETCHES), 2, '... while every insert fetches';
  }

  {
    my $schema = mock_schema($storage_class, named());
    my $row = $schema->resultset('Thing')->create({ name => 'a' });
    is_deeply \@LOOKUPS, [], "with sequences$inherited, sequence named: nothing to look up";
    is_deeply \@FETCHES, [ [ NEXTVAL => 'k302_seq' ] ], '... the named one is fetched';
    is $row->id, $NEXTVAL, '... into the row\'s key';
  }

  {
    my $schema = mock_schema($storage_class, named());
    my $row = $schema->resultset('Thing')->create({ id => \'next_id()', name => 'a' });
    is_deeply \@FETCHES, [ [ NEXTVAL => 'k302_seq' ] ],
      "with sequences$inherited, literal SQL for the column: the sequence is fetched all the same";
    is $row->id, $NEXTVAL, '... and its value is what is inserted';
  }
}

# === 5. a value from the caller ends the matter =============================
for my $storage_class (qw( T::K302::NoSeq T::K302::WithSeq )) {
  for my $result (\&looked_up, \&named) {
    my $schema = mock_schema($storage_class, $result->());
    my $row = eval { $schema->resultset('Thing')->create({ id => 7, name => 'a' }) };
    is $@, '', "$storage_class, the caller gives the value: no error";
    is $row && $row->id, 7, '... the value is the row\'s key';
    is_deeply [ \@LOOKUPS, \@FETCHES ], [ [], [] ], '... and no sequence is asked';
    is scalar( inserts($schema) ), 1, '... one INSERT is sent';
  }
}

# === 6. a storage that generates GUIDs ======================================
{
  my $guids = 0;
  my $result = result_class(
    id    => { data_type => 'integer' },
    token => { data_type => 'uniqueidentifier', auto_nextval => 1, is_nullable => 1 },
  );
  my $schema = mock_schema('T::K302::Guid', $result);
  $schema->storage->new_guid(sub { 'guid-' . ++$guids });

  my $row = eval { $schema->resultset('Thing')->create({ id => 1, name => 'a' }) };
  is $@, '', 'GUID storage, auto_nextval on a GUID column: no error';
  is $row && $row->token, 'guid-1', '... the column gets a generated GUID';
  my ($insert) = inserts($schema);
  ok scalar( grep { defined $_->[1] and $_->[1] eq 'guid-1' } @{ $insert->{bind} } ),
    '... and the INSERT carries it';
}

# ... which is no sequence: a column of another type is refused there as well
{
  my $schema = mock_schema('T::K302::Guid', looked_up());
  $schema->storage->new_guid(sub { 'guid' });
  my $error = refused_ok($schema, { name => 'a' },
    'GUID storage, auto_nextval on a column that is no GUID',
    missing => [qw( _sequence_fetch _dbh_get_autoinc_seq )]);
  like $error, qr/DBIO::Storage::DBI::UniqueIdentifier/,
    '... and the message points at the GUID storage for a GUID column';
}

# === 2. refused without a connection ========================================
for my $case (
  [ 'declared', dsn => 'dbi:K302NoSeq:db=t', declared => 'DBIO::K302NoSeq::Storage' ],
) {
  my ($how, %arg) = @$case;
  for my $result (\&looked_up, \&named) {
    my $schema = driver_schema($result->(), %arg);
    my $error = refused_ok($schema, { name => 'a' },
      "driver without sequences, $how",
      missing => $result == \&named
        ? [qw( _sequence_fetch )] : [qw( _sequence_fetch _dbh_get_autoinc_seq )]);

    is ref($schema->storage), 'DBIO::K302NoSeq::Storage',
      '... the storage is the driver\'s, and that is the class the message named';
    is_deeply \@CONNECTS, [], '... no connection was opened to find that out';
    ok !$schema->storage->_dbh, '... the storage holds no handle';
    is_deeply \@ON_HANDLE, [], '... and nothing was sent';
  }
}

# under a storage layer the composed class is asked, and answers the same
{
  my $schema = driver_schema(looked_up(), dsn => 'dbi:K302NoSeq:db=t',
    declared => 'DBIO::K302NoSeq::Storage', layered => 1);
  refused_ok($schema, { name => 'a' }, 'driver without sequences under a storage layer',
    missing => [qw( _sequence_fetch _dbh_get_autoinc_seq )]);
  ok $schema->storage->isa('DBIO::K302NoSeq::Storage'), '... composed over the driver';
  ok $schema->storage->can('k302_layer'), '... with the layer';
  is_deeply \@CONNECTS, [], '... and no connection was opened';
}

# a storage that never got connect info never determines a driver: a generic
# storage built by hand answers for itself
{
  my $schema = mock_schema('DBIO::Storage::DBI', looked_up());
  refused_ok($schema, { name => 'a' }, 'no connect info, the generic storage',
    missing => [qw( _sequence_fetch _dbh_get_autoinc_seq )]);
  is ref($schema->storage), 'DBIO::Storage::DBI', '... which stays what it was';
  is_deeply \@CONNECTS, [], '... and no connection was opened';
}

# === 4. a driver with sequences on the class of its access path ============
# Before the insert the storage is the declared class, which has no sequence
# method. The question must be asked after the driver determination.
for my $layered (0, 1) {
  my $what = 'driver with sequences on its access path'
    . ( $layered ? ', under a storage layer' : '' );

  my $schema = driver_schema(looked_up(), dsn => 'dbi:K302Seq:db=t',
    declared => 'DBIO::K302Seq::Storage', layered => $layered);
  my $table  = $schema->source('Thing')->name;
  ok !$schema->storage->can('_sequence_fetch'),
    "$what: before its first use the storage has no sequence method";

  my $row = eval { $schema->resultset('Thing')->create({ name => 'a' }) };
  is $@, '', "$what: the insert is not refused";
  ok $schema->storage->isa('DBIO::K302Seq::Storage::Native'),
    '... the storage became the class of its access path';
  is !!$schema->storage->can('k302_layer'), !!$layered, '... with the layers it had';
  is_deeply \@LOOKUPS, [ [ $table, 'id', 'T::K302::DBH' ] ],
    '... the lookup got a handle to ask with';
  is scalar(@CONNECTS), 1, '... from the one connection that was opened for it';
  is_deeply \@FETCHES, [ [ NEXTVAL => 'seq_of_id' ] ], '... the next value was fetched';
  is_deeply \@EXECUTED, [ [ insert => { id => $NEXTVAL, name => 'a' } ] ],
    '... and went into the INSERT';
  is $row && $row->id, $NEXTVAL, '... and into the row';
}

# a declared driver with sequences, sequence named: nothing needs a connection
{
  my $schema = driver_schema(named(),
    dsn => 'dbi:K302Seq:db=t', declared => 'DBIO::K302Seq::Storage');
  my $row = eval { $schema->resultset('Thing')->create({ name => 'a' }) };
  is $@, '', 'declared driver with sequences, sequence named: the insert is not refused';
  is_deeply \@FETCHES, [ [ NEXTVAL => 'k302_seq' ] ], '... the named sequence is fetched';
  is_deeply \@EXECUTED, [ [ insert => { id => $NEXTVAL, name => 'a' } ] ],
    '... and its value goes into the INSERT';
}

done_testing;
