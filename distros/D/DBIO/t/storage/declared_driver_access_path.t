# ABSTRACT: a declared driver storage adapts itself to the access path and never leaves its driver
use strict;
use warnings;

use Test::More;
use Test::Exception;

use DBI;
use Scalar::Util ();
use DBIO;
use DBIO::Schema;
use DBIO::Storage::DBI;
use DBIO::Storage::Composed;
use DBIO::Replicated::Storage;
use DBIO::Test;
use DBIO::Test::Storage;

# OFFLINE (karr k301, ADR 0059). A schema declares its driver: the driver
# component, or a driver shortcut through DBIO->apply_driver, pins the
# driver's base storage class as storage_type. For a driver with more than one
# access path (the same engine over its native DBD, over ODBC, over another
# client library) that base class fits none of them (dbio-sybase k64,
# dbio-mssql k37), so the declared class gets a hook to move to the class of
# its access path.
#
# The decision this file pins:
#   1. the declared class stands, and it gets a hook of its own,
#      _adapt_to_access_path($dbd), called lazily during driver determination
#      -- by either way of declaring -- with the DBD core knows WITHOUT
#      connecting, and before _init;
#   2. the generic storage does not get it: it has no driver, and a schema
#      that declares none is refused at connect (ADR 0067);
#   3. the hook specialises within its driver only. A storage that left the
#      declared class is put back and core throws, whatever the switches say;
#   4. storage layers survive the hook;
#   5. a DBD the registry gives to another driver is reported, and so is what
#      a driver reports itself, through one method, _driver_mismatch: a
#      warning by default, an error with driver_strict, nothing with
#      driver_warnings(0), and strict wins;
#   6. core asks no server and opens no connection for any of it; a hook that
#      connects on its own does so cleanly;
#   7. the mock storage and the replicated storage are not part of this.
#
# THE SUBSTITUTIONS: a fake driver DBIO::K301Drv with storage classes defined
# here and registered for DBD names no DBD carries; DBI->connect records its
# arguments and returns a fake handle naming the DBD of its DSN.

my (@CONNECTS, @HOOK, @INIT, @ACTIONS);

{
  package T::K301::DBH;
  sub new {
    my ($class, $dbd) = @_;
    bless {
      Active => 1, AutoCommit => 1, RaiseError => 1,
      Driver => { Name => $dbd },
    }, $class;
  }
  sub FETCH { $_[0]{$_[1]} }
  sub ping { 1 }
  sub disconnect { 1 }
}

# The declared class: the driver's base storage, registered for its native DBD.
{
  package DBIO::K301Drv::Storage;
  use base 'DBIO::Storage::DBI';
  use mro 'c3';
  DBIO::Storage::DBI->register_driver(K301Native => __PACKAGE__);
  $INC{'DBIO/K301Drv/Storage.pm'} = __FILE__;   # DBIO::Test requires it by file

  our $HOOK;
  sub _adapt_to_access_path {
    my ($self, $dbd) = @_;
    push @HOOK, [ ref $self, $dbd ];
    $HOOK->($self, $dbd) if $HOOK;
  }
  sub _init { push @INIT, ref $_[0]; $_[0]->next::method }
  sub connect_call_note { push @ACTIONS, ref $_[0] }
}

# The class core's registry gives the DBD 'K301Odbc' to: a transport base of
# no particular driver, as DBIO::Storage::DBI::ODBC is for 'ODBC'.
{
  package T::K301::OdbcBase;
  use base 'DBIO::Storage::DBI';
  use mro 'c3';
  DBIO::Storage::DBI->register_driver(K301Odbc => __PACKAGE__);
}

# The driver's class for that access path: the transport base and the driver.
{
  package DBIO::K301Drv::Storage::Odbc;
  use base qw( T::K301::OdbcBase DBIO::K301Drv::Storage );
  use mro 'c3';
}

# A compatible family: a subclass of the driver registered for a DBD of its
# own, as DBIO::MySQL::Storage::MariaDB is for 'MariaDB'.
{
  package DBIO::K301Drv::Storage::Compat;
  use base 'DBIO::K301Drv::Storage';
  use mro 'c3';
  DBIO::Storage::DBI->register_driver(K301Compat => __PACKAGE__);
}

# Another driver altogether.
{
  package T::K301::Other::Storage;
  use base 'DBIO::Storage::DBI';
  use mro 'c3';
  DBIO::Storage::DBI->register_driver(K301Other => __PACKAGE__);
}

# A DBD registered for a driver that is not installed.
DBIO::Storage::DBI->register_driver(
  K301Missing => 'T::K301::NotInstalled::Storage'
);

# A declared class that has no hook of its own.
{
  package T::K301::NoHook::Storage;
  use base 'DBIO::Storage::DBI';
  use mro 'c3';
  sub _init { push @INIT, ref $_[0]; $_[0]->next::method }
}

# A storage holds its schema weakly, and the two switches are read off the
# schema: every schema connected here is kept alive to the end of the file.
{
  package T::K301::SchemaBase;
  use base 'DBIO::Schema';
  our @KEEP;
  sub connect {
    my $schema = shift->SUPER::connect(@_);
    push @KEEP, $schema;
    return $schema;
  }
}

{ package T::K301::Layer; sub k301_layer { 'layer' } }
{ package T::K301::NotAStorage; sub new { bless {}, shift } }

# The shortcut stub of the fake driver, as a driver dist ships one.
BEGIN {
  package DBIO::Shortcut::k301drv;
  sub apply { DBIO->apply_driver($_[1], 'K301Drv') }
  $INC{'DBIO/Shortcut/k301drv.pm'} = __FILE__;
}

{
  package T::K301::ShortcutSchema;
  use DBIO 'Schema', -k301drv;
}

no warnings 'redefine';
local *DBI::connect = sub {
  push @CONNECTS, [ @_ ];
  my ($dbd) = $_[1] =~ /^dbi:(\w*)/i;
  return T::K301::DBH->new($dbd);
};
use warnings 'redefine';

my $schema_count = 0;
sub schema_class {
  my ($storage_type) = @_;
  my $class = 'T::K301::Schema' . ++$schema_count;
  { no strict 'refs'; @{"${class}::ISA"} = ('T::K301::SchemaBase') }
  $class->storage_type($storage_type) if $storage_type;
  return $class;
}

sub reset_records { @CONNECTS = @HOOK = @INIT = @ACTIONS = () }

sub warnings_of (&) {
  my $code = shift;
  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, @_ };
  $code->();
  return @warnings;
}

my $DECLARED = 'DBIO::K301Drv::Storage';
my $ODBC     = 'DBIO::K301Drv::Storage::Odbc';

# what a driver's hook does: pick its own class for the access path
my $specialise = sub {
  my ($self, $dbd) = @_;
  bless $self, $ODBC if defined $dbd and $dbd eq 'K301Odbc';
};

# --- 1. the hook, lazily, for a class declared through storage_type ---------
{
  reset_records();
  my $schema = schema_class("+$DECLARED")
    ->connect('dbi:K301Native:db=t', 'u', 'p');
  my $storage = $schema->storage;

  is ref($storage), $DECLARED, 'connect instantiates the declared class';
  is_deeply \@HOOK, [], 'connect alone does not determine the driver';
  ok !$storage->_driver_determined, '... it is not determined yet';

  my @warnings = warnings_of { $storage->sql_maker };

  is_deeply \@HOOK, [ [ $DECLARED, 'K301Native' ] ],
    'the first use that needs the driver calls the hook, once, with the DBD of the DSN';
  ok $storage->_driver_determined, '... and the driver is determined';
  is ref($storage), $DECLARED, 'a hook that does nothing leaves the declared class';
  is_deeply \@INIT, [ $DECLARED ], '_init runs once, on it';
  is_deeply \@CONNECTS, [], 'core opened no connection for it';
  is_deeply \@warnings, [], 'the DBD of the declared driver is no finding';

  $storage->sql_maker;
  $storage->_determine_driver;
  is scalar(@HOOK), 1, 'the hook is called once per storage';
}

# --- 1b. ... and for a class declared through a shortcut or apply_driver ----
{
  reset_records();
  is(T::K301::ShortcutSchema->storage_type, "+$DECLARED",
    "the shortcut declares the driver's base storage class");

  my $schema  = T::K301::ShortcutSchema->connect('dbi:K301Native:db=t');
  my $storage = $schema->storage;
  $storage->_determine_driver;
  is_deeply \@HOOK, [ [ $DECLARED, 'K301Native' ] ],
    'the hook is called for a driver declared by shortcut';
  is ref($storage), $DECLARED, '... which stays its declared class';

  reset_records();
  my $class = schema_class();
  DBIO->apply_driver($class, 'K301Drv');
  $storage = $class->connect('dbi:K301Native:db=t')->storage;
  $storage->_determine_driver;
  is_deeply \@HOOK, [ [ $DECLARED, 'K301Native' ] ],
    'the hook is called for a driver declared through apply_driver';
}

# --- 2. no declaration: no driver, and no detection (ADR 0067) --------------
{
  reset_records();
  throws_ok { schema_class()->connect('dbi:K301Native:db=t') }
    qr/declares no driver/,
    'no declaration: refused at connect, though the DBD has a registered driver';
  is_deeply \@HOOK,     [], '... the hook is not called';
  is_deeply \@INIT,     [], '... nor _init';
  is_deeply \@CONNECTS, [], '... and nothing connects';
}

# --- the default hook, and a declared class without one ---------------------
{
  ok(DBIO::Storage::DBI->can('_adapt_to_access_path'), 'the base hook exists');
  lives_ok { DBIO::Storage::DBI->_adapt_to_access_path('Anything') }
    '... and does nothing';

  reset_records();
  my $storage = schema_class('+T::K301::NoHook::Storage')
    ->connect('dbi:K301Nobody:db=t')->storage;
  my @warnings = warnings_of { $storage->_determine_driver };

  is ref($storage), 'T::K301::NoHook::Storage',
    'a declared class without a hook stays what it is';
  is_deeply \@INIT, [ 'T::K301::NoHook::Storage' ], '_init runs as before';
  is_deeply \@CONNECTS, [], 'no connection is opened';
  is_deeply \@warnings, [], 'a DBD nothing is registered for is not judged';
}

# --- 3. specialising within the driver --------------------------------------
{
  reset_records();
  local $DBIO::K301Drv::Storage::HOOK = $specialise;

  my $storage = schema_class("+$DECLARED")
    ->connect('dbi:K301Odbc:DSN=t')->storage;
  my @warnings = warnings_of { $storage->_determine_driver };

  is ref($storage), $ODBC, "the hook put the storage into the driver's class for the access path";
  is_deeply \@INIT, [ $ODBC ], '_init runs on the specialised class';
  is_deeply \@CONNECTS, [], 'without a connection';
  is_deeply \@warnings, [],
    'a DBD whose registered class the adapted class inherits is no finding';
  is $storage->_declared_storage_class, $DECLARED,
    'the storage remembers the class that was declared';
}

# --- 4. layers survive -------------------------------------------------------
{
  reset_records();
  local $DBIO::K301Drv::Storage::HOOK = $specialise;

  my $class = schema_class("+$DECLARED");
  $class->register_storage_layer('T::K301::Layer');
  my $storage = $class->connect('dbi:K301Odbc:DSN=t')->storage;

  my $composed = ref $storage;
  is(DBIO::Storage::Composed->composition_of($composed)->{base}, $DECLARED,
    'a layered schema composes its layers over the declared class');

  $storage->_determine_driver;

  is_deeply \@HOOK, [ [ $composed, 'K301Odbc' ] ],
    'the hook is called on the layered storage';
  isa_ok $storage, $ODBC, 'the layered storage after the hook';
  isa_ok $storage, 'T::K301::Layer', '... still';
  my $entry = DBIO::Storage::Composed->composition_of(ref $storage);
  is $entry->{base}, $ODBC, 'the same layers are composed over the specialised class';
  is_deeply $entry->{layers}, [ 'T::K301::Layer' ], '... all of them';
  is_deeply \@INIT, [ ref $storage ], '_init runs on that composition';
  is $storage->_declared_storage_class, $DECLARED,
    'the declared class of a layered storage is the base, not the composition';

  reset_records();
  local $DBIO::K301Drv::Storage::HOOK;
  $storage = $class->connect('dbi:K301Native:db=t')->storage;
  $storage->_determine_driver;
  is ref($storage), $composed, 'a hook that does nothing leaves the composition alone';
}

# --- 3. the hook must stay within its driver --------------------------------
for my $case (
  [ 'another driver',        'T::K301::Other::Storage', 1 ],
  [ 'another driver, with driver_warnings off', 'T::K301::Other::Storage', 0 ],
  [ 'a class that is no storage at all', 'T::K301::NotAStorage', 1 ],
) {
  my ($what, $foreign, $driver_warnings) = @$case;

  reset_records();
  local $DBIO::K301Drv::Storage::HOOK = sub { bless $_[0], $foreign };

  my $schema = schema_class("+$DECLARED")->connect('dbi:K301Native:db=t');
  $schema->driver_warnings($driver_warnings);
  my $storage = $schema->storage;

  throws_ok { $storage->_determine_driver }
    qr/\Q$DECLARED\E.*reblessed the storage into \Q$foreign\E/s,
    "a hook that reblesses into $what throws, naming both classes";
  is ref($storage), $DECLARED, '... the storage is the declared class again';
  ok !$storage->_driver_determined, '... and its driver is not determined';
  is_deeply \@INIT, [], '... _init did not run on a failed adaptation';
}

{
  reset_records();
  local $DBIO::K301Drv::Storage::HOOK
    = sub { bless $_[0], 'T::K301::Other::Storage' };

  my $class = schema_class("+$DECLARED");
  $class->register_storage_layer('T::K301::Layer');
  my $storage = $class->connect('dbi:K301Native:db=t')->storage;
  my $composed = ref $storage;

  throws_ok { $storage->_determine_driver } qr/reblessed the storage into/,
    'the same on a layered storage';
  is ref($storage), $composed, '... which gets its composition back';
}

{
  reset_records();
  local $DBIO::K301Drv::Storage::HOOK = sub {
    bless $_[0], $ODBC;
    die "client library not usable\n";
  };

  my $storage = schema_class("+$DECLARED")
    ->connect('dbi:K301Odbc:DSN=t')->storage;

  throws_ok { $storage->_determine_driver } qr/client library not usable/,
    'an exception from the hook reaches the caller';
  is ref($storage), $DECLARED, '... and leaves the storage in the declared class';
  ok !$storage->_driver_determined, '... undetermined, to be tried again';
}

# --- 5. the DBD of another driver -------------------------------------------
{
  my $connect = sub {
    my ($dsn, %switch) = @_;
    my $class = schema_class("+$DECLARED");
    $class->driver_strict($switch{class_strict}) if exists $switch{class_strict};
    my $schema = $class->connect($dsn, 'k301user', 'sekrit301');
    $schema->$_($switch{$_}) for grep { exists $switch{$_} }
      qw(driver_strict driver_warnings);
    return $schema;
  };

  is(DBIO::Schema->driver_strict, 0, 'driver_strict is off by default');
  is(DBIO::Schema->driver_warnings, 1, 'driver_warnings is on by default');

  # default: a warning
  reset_records();
  my $schema  = $connect->('dbi:K301Other:db=t');
  my $storage = $schema->storage;
  my @warnings = warnings_of { $storage->_determine_driver };

  is scalar(@warnings), 1, 'a DSN through the DBD of another driver warns, once';
  like $warnings[0],
    qr/Driver mismatch for declared storage class \Q$DECLARED\E: .*DBD::K301Other.*T::K301::Other::Storage/,
    '... naming the declared class, the DBD and the class it is registered for';
  like $warnings[0], qr/driver_strict\b.*\bdriver_warnings\b/s,
    '... and the two switches';
  unlike $warnings[0], qr/sekrit301|k301user|db=t/,
    '... and nothing of the connect info';
  is ref($storage), $DECLARED, 'the storage stays the declared class';
  ok $storage->_driver_determined, '... and is determined: a warning stops nothing';
  is_deeply \@INIT, [ $DECLARED ], '... _init ran';
  is_deeply \@CONNECTS, [], '... and core asked no server';

  # driver_strict: an error
  reset_records();
  $storage = $connect->('dbi:K301Other:db=t', driver_strict => 1)->storage;
  @warnings = ();
  throws_ok { @warnings = warnings_of { $storage->_determine_driver } }
    qr/Driver mismatch for declared storage class \Q$DECLARED\E: .*DBD::K301Other.*driver_strict/s,
    'with driver_strict the same finding throws';
  is_deeply \@warnings, [], '... instead of warning';
  ok !$storage->_driver_determined, '... and the driver is not determined';
  throws_ok { $storage->sql_maker } qr/Driver mismatch/,
    '... so every use that needs the driver throws';

  # the switch is inherited class data
  $storage = $connect->('dbi:K301Other:db=t', class_strict => 1)->storage;
  throws_ok { $storage->_determine_driver } qr/Driver mismatch/,
    'driver_strict set on the schema class holds for its connections';

  # driver_warnings(0): nothing
  reset_records();
  $storage = $connect->('dbi:K301Other:db=t', driver_warnings => 0)->storage;
  @warnings = warnings_of { $storage->_determine_driver };
  is_deeply \@warnings, [], 'driver_warnings(0) silences the finding';
  ok $storage->_driver_determined, '... and the driver is determined';

  # strict wins
  $storage = $connect->(
    'dbi:K301Other:db=t', driver_strict => 1, driver_warnings => 0,
  )->storage;
  throws_ok { $storage->_determine_driver } qr/Driver mismatch/,
    'driver_strict wins over driver_warnings(0)';

  # what is no finding
  for my $quiet (
    [ 'dbi:K301Compat:db=t', "a DBD registered for a subclass of the declared class" ],
    [ 'dbi:K301Nobody:db=t', 'a DBD nothing is registered for' ],
    [ 'dbi:K301Native:db=t', "the declared driver's own DBD" ],
  ) {
    my ($dsn, $what) = @$quiet;
    reset_records();
    my $storage = $connect->($dsn, driver_strict => 1)->storage;
    lives_ok { $storage->_determine_driver } "$what is no finding, even with driver_strict";
    is ref($storage), $DECLARED, '... the storage stays the declared class';
  }

  # the inheritance of the adapted class is the declaration
  reset_records();
  $storage = $connect->('dbi:K301Odbc:DSN=t')->storage;
  @warnings = warnings_of { $storage->_determine_driver };
  like $warnings[0], qr/DBD::K301Odbc.*T::K301::OdbcBase/,
    'a transport the driver has not adapted to is a finding';
  {
    local $DBIO::K301Drv::Storage::HOOK = $specialise;
    $storage = $connect->('dbi:K301Odbc:DSN=t', driver_strict => 1)->storage;
    lives_ok { $storage->_determine_driver }
      '... and none once the hook specialises into a class inheriting its registered class';
  }

  # a registered class that cannot be loaded is no relative
  reset_records();
  $storage = $connect->('dbi:K301Missing:db=t')->storage;
  @warnings = warnings_of { $storage->_determine_driver };
  like $warnings[0], qr/DBD::K301Missing.*T::K301::NotInstalled::Storage/,
    'a DBD registered for a driver that is not installed is a finding';

  # a connection coderef: nothing to judge, and no connection for the sake of it
  reset_records();
  my $ran = 0;
  $storage = schema_class("+$DECLARED")
    ->connect(sub { $ran++; T::K301::DBH->new('K301Other') })->storage;
  $storage->schema->driver_strict(1);
  lives_ok { $storage->_determine_driver }
    'a connection coderef that has not run is not judged';
  is_deeply \@HOOK, [ [ $DECLARED, undef ] ], '... the hook gets no DBD';
  is $ran, 0, '... and core does not run the coderef to find one';

  # ... but the handle of a storage that is already connected names its DBD
  reset_records();
  $storage = schema_class("+$DECLARED")
    ->connect(sub { T::K301::DBH->new('K301Other') })->storage;
  @warnings = warnings_of { $storage->ensure_connected };
  is_deeply \@HOOK, [ [ $DECLARED, 'K301Other' ] ],
    'on a connected storage the hook gets the DBD of the handle';
  is scalar(@warnings), 1, '... and that DBD is judged';
}

# --- 5. the driver reports what it noticed itself ---------------------------
{
  my $hook = sub {
    my ($self, $dbd) = @_;
    $specialise->($self, $dbd);
    $self->_driver_mismatch('the server answers as another product');
  };
  local $DBIO::K301Drv::Storage::HOOK = $hook;

  reset_records();
  my $storage = schema_class("+$DECLARED")
    ->connect('dbi:K301Odbc:DSN=t')->storage;
  my @warnings = warnings_of { $storage->_determine_driver };
  is scalar(@warnings), 1, 'a finding of the driver warns by default';
  like $warnings[0],
    qr/Driver mismatch for declared storage class \Q$DECLARED\E: the server answers as another product/,
    '... through the same message, naming the declared class and not the specialised one';
  is ref($storage), $ODBC, '... and the adaptation stands';

  my $schema = schema_class("+$DECLARED")->connect('dbi:K301Odbc:DSN=t');
  $schema->driver_strict(1);
  $storage = $schema->storage;
  throws_ok { $storage->_determine_driver }
    qr/the server answers as another product.*driver_strict/s,
    'with driver_strict it throws';
  is ref($storage), $DECLARED, '... and the storage is the declared class again';

  $schema = schema_class("+$DECLARED")->connect('dbi:K301Odbc:DSN=t');
  $schema->driver_warnings(0);
  @warnings = warnings_of { $schema->storage->_determine_driver };
  is_deeply \@warnings, [], 'with driver_warnings(0) it is silent';

  # the method is the driver's to call at any time, not only from the hook
  local $DBIO::K301Drv::Storage::HOOK;
  $storage = schema_class("+$DECLARED")
    ->connect('dbi:K301Native:db=t')->storage;
  $storage->_determine_driver;
  @warnings = warnings_of { $storage->_driver_mismatch('noticed later') };
  like $warnings[0], qr/declared storage class \Q$DECLARED\E: noticed later/,
    'a finding reported after determination reads the same';

  # no schema: the default
  $storage = $DECLARED->new(undef);
  @warnings = warnings_of { $storage->_driver_mismatch('no schema here') };
  like $warnings[0], qr/Driver mismatch.*no schema here/,
    'a storage without a schema warns';
}

# --- 6. a hook that connects on its own -------------------------------------
{
  reset_records();
  my $seen;
  local $DBIO::K301Drv::Storage::HOOK = sub {
    my ($self, $dbd) = @_;
    $seen = $self->_get_dbh->{Driver}{Name};
    bless $self, $ODBC;
  };

  my $storage = schema_class("+$DECLARED")->connect(
    'dbi:K301Odbc:DSN=t', 'u', 'p', { on_connect_call => 'note' },
  )->storage;

  lives_ok { $storage->sql_maker } 'a hook may connect to learn more';
  is $seen, 'K301Odbc', '... and reads its handle';
  is scalar(@CONNECTS), 1, '... through one connection';
  is scalar(@HOOK), 1, '... without being called again from inside it';
  is_deeply \@INIT, [ $ODBC ], '_init runs once, on the specialised class';
  is_deeply \@ACTIONS, [ $ODBC ],
    'the connection actions run once, after the adaptation';
  ok $storage->_driver_determined, 'the driver is determined';
}

# --- 7. the mock storage and the replicated storage -------------------------
{
  reset_records();
  local $DBIO::K301Drv::Storage::HOOK = sub { die "the hook was called\n" };

  my @warnings = warnings_of {
    my $schema = DBIO::Test->init_schema(
      no_deploy => 1, storage_type => $DECLARED,
    );
    $schema->storage->_determine_driver;
    $schema->storage->sql_maker;
  };
  is_deeply \@HOOK, [], 'the mock storage over a driver class never asks the hook';
  is_deeply \@warnings, [], '... and reports nothing';

  isnt(DBIO::Test::Storage->can('_determine_driver'),
    DBIO::Storage::DBI->can('_determine_driver'),
    'the mock storage has a driver determination of its own');
  isnt(DBIO::Replicated::Storage->can('_determine_driver'),
    DBIO::Storage::DBI->can('_determine_driver'),
    '... and so has the replicated storage');

  # a DSN whose DBD belongs to a driver neither class is related to
  @warnings = warnings_of {
    my $schema  = schema_class('+DBIO::Test::Storage')->connect(sub { });
    my $storage = DBIO::Replicated::Storage->new($schema, {
      backend_storage_class => 'DBIO::Test::Storage',
    });
    $storage->connect_info([ 'dbi:K301Other:db=t', '', '' ]);
    $storage->_determine_driver;
    $storage->sql_maker;
    is ref($storage), 'DBIO::Replicated::Storage',
      'the replicated storage stays what it is';
    ok !defined $storage->_declared_storage_class,
      '... and is not taken for a declared driver';
  };
  is_deeply \@warnings, [], 'the replicated storage reports nothing';
}

# --- 8. only a registered driver class is judged (karr k301, 2026-10-09) -----
# A private subclass of DBIO::Storage::DBI set through storage_type by hand has
# no registered origin: the DBD check has nothing to compare it with.
{
  package T::K301::Private::Storage;
  use base 'DBIO::Storage::DBI';
  use mro 'c3';
}
{
  package T::K301::Private::Child::Storage;
  use base 'DBIO::K301Drv::Storage';
  use mro 'c3';
}

{
  reset_records();
  my $schema = schema_class('+T::K301::Private::Storage')
    ->connect('dbi:K301Other:db=t');
  $schema->driver_strict(1);
  my $storage = $schema->storage;
  my @warnings;
  lives_ok { @warnings = warnings_of { $storage->_determine_driver } }
    'a private subclass of the generic storage is not judged, even with driver_strict';
  is_deeply \@warnings, [], '... and does not warn';
  ok $storage->_driver_determined, '... its driver is determined';

  # a subclass of a registered driver class stays judged
  $schema = schema_class('+T::K301::Private::Child::Storage')
    ->connect('dbi:K301Other:db=t');
  $schema->driver_strict(1);
  throws_ok { $schema->storage->_determine_driver }
    qr/Driver mismatch for declared storage class T::K301::Private::Child::Storage/,
    'a subclass of a registered driver class is still judged';

  # the driver's own report is not affected
  $schema = schema_class('+T::K301::Private::Storage')
    ->connect('dbi:K301Other:db=t');
  $schema->driver_strict(1);
  throws_ok { $schema->storage->_driver_mismatch('the server is another product') }
    qr/another product/, 'a driver reporting for itself is not subject to the registry';
}

# --- 9. a storage without a schema inherits the switches --------------------
{
  my $parent_schema = schema_class("+$DECLARED")->connect('dbi:K301Native:db=t');
  my $parent = $parent_schema->storage;

  my $child = $DECLARED->new(undef);
  Scalar::Util::weaken($child->{_parent_storage} = $parent);

  my @w = warnings_of { $child->_driver_mismatch('from the child') };
  is scalar(@w), 1, 'a child without schema warns by the default of its parent';

  $parent_schema->driver_strict(1);
  throws_ok { $child->_driver_mismatch('from the child') }
    qr/from the child.*driver_strict/s, 'the parent schema driver_strict throws for the child';

  $parent_schema->driver_strict(0);
  $parent_schema->driver_warnings(0);
  @w = warnings_of { $child->_driver_mismatch('from the child') };
  is_deeply \@w, [], 'the parent schema driver_warnings(0) silences the child';

  # the grandchild walks up
  my $grandchild = $DECLARED->new(undef);
  Scalar::Util::weaken($grandchild->{_parent_storage} = $child);
  $parent_schema->driver_warnings(1);
  $parent_schema->driver_strict(1);
  throws_ok { $grandchild->_driver_mismatch('deep') } qr/deep.*driver_strict/s,
    'the switches are found along the whole parent chain';

  # a child with its own schema uses it
  my $own = schema_class("+$DECLARED")->connect('dbi:K301Native:db=t');
  $own->driver_strict(0);
  my $mixed = $own->storage;
  Scalar::Util::weaken($mixed->{_parent_storage} = $parent);
  @w = warnings_of { $mixed->_driver_mismatch('own schema') };
  is scalar(@w), 1, "a child with a schema of its own uses that one, not the parent's";

  # a cycle does not hang
  my ($ca, $cb) = ($DECLARED->new(undef), $DECLARED->new(undef));
  Scalar::Util::weaken($ca->{_parent_storage} = $cb);
  Scalar::Util::weaken($cb->{_parent_storage} = $ca);
  @w = warnings_of { $ca->_driver_mismatch('cycle') };
  is scalar(@w), 1, 'a parent cycle ends in the default';

  ok(DBIO::Storage::DBI->can('_parent_storage'),
    'core declares the _parent_storage accessor');
}

# --- 10. the switches are no connect attributes ------------------------------
{
  for my $name (qw( driver_strict driver_warnings )) {
    my $storage = DBIO::Storage::DBI->new(undef);
    throws_ok {
      $storage->connect_info(
        [ 'dbi:K301Native:db=t', 'u', 'p', { $name => 'SECRET-k301' } ]
      );
    } qr/Unknown connect attribute\(s\) '\Q$name\E'.*schema accessor.*\Q$name\E\(/s,
      "$name as a connect attribute is refused and the accessor named";
    unlike $@, qr/SECRET-k301/, '... never the value';
  }

  my $storage = DBIO::Storage::DBI->new(undef);
  throws_ok {
    $storage->connect_info(
      [ 'dbi:K301Native:db=t', 'u', 'p', { driver_strict => 1, driver_warnings => 0, zzz_k301 => 1 } ]
    );
  } qr/'driver_strict', 'driver_warnings', 'zzz_k301'.*schema accessors.*driver_strict\(1\) and \$schema->driver_warnings\(0\)/s,
    'all keys named, plural hint';

  throws_ok {
    $storage->connect_info(
      [ 'dbi:K301Native:db=t', 'u', 'p', { zzz_k301 => 1 } ]
    );
  } qr/Unknown connect attribute/, 'the other refusal is unchanged';
  unlike $@, qr/schema accessor/, '... and carries no hint';

  # beside an AccessBroker the same mistake gets the same hint
  require DBIO::AccessBroker::Static;
  my $broker = DBIO::AccessBroker::Static->new(
    dbname => 'db=t', username => 'u', password => 'p',
  );
  $storage = $DECLARED->new(undef);
  $storage->connect_info([ $broker, { driver_strict => 'SECRET-k301' } ]);
  throws_ok { $storage->ensure_connected }
    qr/driver_strict.*schema accessor/s,
    'driver_strict beside a broker is refused with the hint';
  unlike $@, qr/SECRET-k301/, '... never the value';
}

done_testing;
