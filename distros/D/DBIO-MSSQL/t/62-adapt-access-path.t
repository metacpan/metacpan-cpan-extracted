use strict;
use warnings;

use Test::More;
use Test::Exception;

use DBI;
use DBIO;
use DBIO::Schema;
use DBIO::Storage::DBI;
use DBIO::Storage::DBI::ODBC;
use DBIO::Storage::Composed;
use DBIO::MSSQL::Storage;
use DBIO::MSSQL::Storage::ODBC;
use DBIO::AccessBroker::Static;

# OFFLINE (karr k37; core k301, ADR 0059). A schema declares this driver by
# loading the MSSQL component or by the -ms shortcut, and both pin
# DBIO::MSSQL::Storage -- the transport-neutral base, which fits neither DBD
# that reaches SQL Server. Without a hook such a storage would stay the base
# on every DSN, and core would say so at its first use ("Driver mismatch for
# declared storage class DBIO::MSSQL::Storage").
#
# DBIO::MSSQL::Storage::_adapt_to_access_path is what core calls. This
# file pins what it does, through core's own driver determination -- a schema,
# a connect, a first use -- and not by calling the hook:
#
#   1. dbi:ODBC: makes the storage DBIO::MSSQL::Storage::ODBC, dbi:Sybase:
#      DBIO::MSSQL::Storage::Sybase, and neither is reported as a mismatch --
#      not with driver_strict either;
#   2. a schema without a declared driver is refused at connect (core ADR
#      0067), before anything is connected, and DBIO->driver_for -- what
#      names the driver of a DSN -- names this driver for neither DSN:
#      dbi:ODBC: throws, dbi:Sybase: names the Sybase ASE driver. The
#      declaration is what makes a storage this driver's;
#   3. it asks the server nothing the storage does not ask anyway. No
#      SQL_DBMS_NAME, no sp_server_info: the declared class never leaves this
#      driver;
#   4. DBIO::Sybase is optional. Without it a dbi:Sybase: DSN throws, saying
#      what is missing, and the storage stays what it was;
#   5. the DBD of another driver is still reported by core, and a DBD nothing
#      is registered for is not;
#   6. only the declared base moves. A private subclass pinned by hand stays
#      what it is (core would throw if it were moved out of itself), and a
#      storage pinned to one of the two access-path classes already is one;
#   7. storage layers survive;
#   8. a connection coderef names no DBD until it has run, so the hook runs
#      it; connect info without a DSN is refused by core at connect (karr k306,
#      core ADR 0057 addendum 2026-10-12) -- a schema that only writes SQL
#      names a DSN, and over dbi:ODBC: nothing is connected to;
#   9. _connect_params_dsn is asked at connect_info, on the declared base and
#      before any of this -- so the base's form decides which DBD a storage
#      connected with connection parameters adapts to -- and after the
#      adaptation the class the storage became is asked.
#
# NOTHING HERE CONNECTS. DBI->connect is replaced and returns a fake handle
# naming the DBD of its DSN; the DBD::Sybase one answers what the storage asks
# of a client library (syb_oc_version, a placeholder probe). So this file
# shows which class a storage becomes and what it asks on the way, and not
# that a server works with it: t/60-connect-params-live.t and
# t/61-txn-freetds-live.t do that for DBD::Sybase.
#
# THE ODBC BRANCH IS PROVEN WITHOUT A SERVER HERE. No ODBC driver for SQL
# Server was on the host this was written on, so no connection through
# DBD::ODBC was made with the adapted class. What is claimed here for it is
# the class and the absence of a warning, both decided without a connection;
# t/72-adapt-access-path-odbc-live.t holds the same live (karr k54).

my $BASE   = 'DBIO::MSSQL::Storage';
my $ODBC   = 'DBIO::MSSQL::Storage::ODBC';
my $SYBASE = 'DBIO::MSSQL::Storage::Sybase';

# What the fake client library answers; set per case.
our $OC_VERSION   = 'freetds v1.3.17';
our $PLACEHOLDERS = 1;

my (@CONNECTS, @STATEMENTS);

{
  package T::K37A::DBH;

  sub new {
    my ($class, $dbd) = @_;
    bless {
      Active => 1, AutoCommit => 1, RaiseError => 1, PrintError => 0,
      Driver => { Name => $dbd },
      ( $dbd eq 'Sybase' ? ( syb_oc_version => $OC_VERSION ) : () ),
    }, $class;
  }
  sub FETCH { $_[0]{$_[1]} }
  sub ping { 1 }
  sub disconnect { 1 }

  # The placeholder probe of DBIO::Storage::DBI is a do() with a bind value.
  sub do {
    my ($self, $sql) = @_;
    push @STATEMENTS, $sql;
    die "this connection takes no placeholders\n"
      if $sql =~ /\?/ and not $PLACEHOLDERS;
    return 1;
  }

  # Recorded, so the cases can show that the product is never asked for.
  sub selectrow_arrayref {
    my ($self, $sql) = @_;
    push @STATEMENTS, $sql;
    return $sql =~ /sp_server_info/
      ? [ 1, 'DBMS_NAME', 'Microsoft SQL Server' ]
      : undef;
  }
}

no warnings 'redefine';
local *DBI::connect = sub {
  shift;
  push @CONNECTS, [ @_ ];
  my ($dbd) = $_[0] =~ /^dbi:(\w*)/i;
  return T::K37A::DBH->new($dbd);
};
use warnings 'redefine';

# A storage holds its schema weakly, and the two switches are read off the
# schema: every schema connected here is kept alive to the end of the file.
{
  package T::K37A::SchemaBase;
  use base 'DBIO::Schema';
  our @KEEP;
  sub connect {
    my $schema = shift->SUPER::connect(@_);
    push @KEEP, $schema;
    return $schema;
  }
}

{
  package T::K37A::Shortcut;
  use DBIO 'Schema', -ms;
}

{ package T::K37A::Private::Storage; use base 'DBIO::MSSQL::Storage'; use mro 'c3'; }
{ package T::K37A::Private::ODBC; use base 'DBIO::MSSQL::Storage::ODBC'; use mro 'c3'; }
{ package T::K37A::Layer; sub k37_layer { 'layer' } }

# A new schema class each time: the storage type, the layers and the switches
# are class data.
my $schema_count = 0;
sub schema_class {
  my $class = 'T::K37A::Schema' . ++$schema_count;
  { no strict 'refs'; @{"${class}::ISA"} = ('T::K37A::SchemaBase') }
  return $class;
}

# declared by the component
sub declared {
  my $class = schema_class();
  $class->load_components('MSSQL');
  return $class;
}

# pinned by hand to a class of one's own choosing
sub pinned_to {
  my $class = schema_class();
  $class->storage_type("+$_[0]");
  return $class;
}

sub reset_records { @CONNECTS = @STATEMENTS = () }

# The DBD::Sybase class announces its FreeTDS workaround once per process;
# that is the class talking, and no finding of this file.
my $FREETDS_NOTICE = qr/compiled against buggy FreeTDS version/;

sub warnings_of (&) {
  my $code = shift;
  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, @_ };
  $code->();
  return grep { $_ !~ $FREETDS_NOTICE } @warnings;
}

my $MISMATCH = qr/Driver mismatch for declared storage class/;

# ---------------------------------------- 4. DBIO::Sybase is not installed
#
# First, while nothing has loaded it: with DBIO/Sybase/* out of reach the
# DBD::Sybase class of this driver cannot be loaded either, and a schema
# whose DSN leads through DBD::Sybase has no class to become. It must hear
# that, and not Perl's "Base class package ... is empty".

{
  ok !$INC{'DBIO/Sybase/Storage.pm'},
    '(nothing has loaded DBIO::Sybase so far: this file loads the base and '
  . 'the ODBC class only)';

  local @INC = (
    sub {
      die "Can't locate $_[1] in \@INC (hidden by $0)\n"
        if $_[1] =~ m{\ADBIO/Sybase(?:/|\.pm\z)};
      return;
    },
    @INC,
  );

  reset_records();
  my $schema  = declared()->connect('dbi:Sybase:server=k37srv', 'k37user', 'sekrit37');
  my $storage = $schema->storage;

  throws_ok { $storage->sql_maker } qr/DBIO::Sybase\b.*\bnot installed/s,
    'without DBIO::Sybase a dbi:Sybase: DSN throws at the first use, naming '
  . 'the distribution that is missing';
  my $error = "$@";

  like $error, qr/DBD::ODBC|dbi:ODBC:/, '... and the way that needs none';
  unlike $error, qr/sekrit37|k37user|k37srv/,
    '... and nothing of the connect info';
  is ref $storage, $BASE, '... the storage is still the declared class';
  ok !$storage->_driver_determined,
    '... and undetermined: installing DBIO::Sybase is all it takes';
  is_deeply \@CONNECTS, [], '... no connection was opened to find that out';

  reset_records();
  $storage = declared()->connect('dbi:ODBC:DSN=k37')->storage;
  lives_ok { $storage->sql_maker }
    'without DBIO::Sybase a dbi:ODBC: DSN is not affected';
  is ref $storage, $ODBC, '... and adapts to its own class';
}

# ---------------------------------------------------- 1 + 3. over DBD::ODBC

for my $how (
  [ 'the MSSQL component', sub { declared() } ],
  [ 'the -ms shortcut',    sub { 'T::K37A::Shortcut' } ],
) {
  my ($by, $class) = @$how;

  reset_records();
  my $schema  = $class->()->connect('dbi:ODBC:DSN=k37', 'k37user', 'sekrit37');
  my $storage = $schema->storage;

  is ref $storage, $BASE, "declared by $by: connect gives the declared class";
  ok !$storage->_driver_determined, '... lazily: nothing is decided at connect';

  my @warnings = warnings_of { $storage->sql_maker };

  is ref $storage, $ODBC,
    "declared by $by: at the first use a dbi:ODBC: DSN makes it the DBD::ODBC "
  . 'class of this driver';
  isa_ok $storage, 'DBIO::Storage::DBI::ODBC', '... which';
  is $storage->_declared_storage_class, $BASE,
    '... and the declared class is still known as the one declared';
  is_deeply \@warnings, [],
    '... without a warning: this is the driver the schema declared';
  is_deeply \@CONNECTS, [],
    '... and without a connection -- so nobody asked the server for '
  . 'SQL_DBMS_NAME, the server is not asked what it is';
  is ref $storage->sql_maker, 'DBIO::MSSQL::SQLMaker',
    '... and its SQL is this driver\'s';
}

{
  reset_records();
  my $schema = declared()->connect('dbi:ODBC:DSN=k37');
  $schema->driver_strict(1);
  lives_ok { $schema->storage->sql_maker }
    'over DBD::ODBC, with driver_strict: nothing to throw about';
  is ref $schema->storage, $ODBC, '... adapted all the same';
}

# ------------------------------------------------ 1 + 2 + 3. over DBD::Sybase

my $HAVE_SYBASE = eval { require DBIO::Sybase::Storage; 1 };

# Only "not installed" is a reason to skip. With DBIO::Sybase there, this
# distribution's own class not loading is a failure.
die $@ unless $HAVE_SYBASE or $@ =~ m{\ACan't locate DBIO/Sybase/Storage\.pm };

SKIP: {
  skip 'DBIO::Sybase is not installed (optional, cpanfile recommends)', 1
    unless $HAVE_SYBASE;

  require DBIO::MSSQL::Storage::Sybase;

  for my $client (
    [ 'FreeTDS, placeholders',     'freetds v1.3.17',    1,
      "${SYBASE}::FreeTDS" ],
    [ 'FreeTDS, no placeholders',  'freetds v1.3.17',    0,
      "${SYBASE}::NoBindVars::FreeTDS" ],
    [ 'Open Client, placeholders', 'Sybase Client-Library/15.7', 1,
      $SYBASE ],
    [ 'Open Client, no placeholders', 'Sybase Client-Library/15.7', 0,
      "${SYBASE}::NoBindVars" ],
  ) {
    (my $name, local $OC_VERSION, local $PLACEHOLDERS, my $expect) = @$client;
    local $ENV{DBIO_MSSQL_FREETDS_LOWVER_NOWARN} = 1;

    reset_records();
    my $schema  = declared()->connect('dbi:Sybase:server=k37srv', 'k37user', 'sekrit37');
    my $storage = $schema->storage;
    $schema->driver_strict(1);

    my @warnings;
    lives_ok { @warnings = warnings_of { $storage->sql_maker } }
      "over DBD::Sybase ($name), with driver_strict: nothing to throw about";

    is ref $storage, $expect,
      "over DBD::Sybase ($name): the declared storage becomes $expect";
    isa_ok $storage, $_, '... which' for $BASE, 'DBIO::Sybase::Storage';
    is_deeply \@warnings, [], '... without a warning';
    is scalar @CONNECTS, 1,
      '... over one connection: the client library is what decides here, and '
    . 'it is asked through the handle';
    is_deeply [ grep { /sp_server_info/ } @STATEMENTS ], [],
      '... and without sp_server_info: the server is not asked what it is';
    is scalar( grep { /\?/ } @STATEMENTS ), 1,
      '... and the placeholder decision is made once: one probe statement';
  }

  # The capability forced before the first use, as t/10 does it and as a
  # user would for a client library whose probe lies.
  {
    local $ENV{DBIO_MSSQL_FREETDS_LOWVER_NOWARN} = 1;

    reset_records();
    my $storage = declared()->connect('dbi:Sybase:server=k37srv')->storage;
    $storage->_use_typeless_placeholders(0);
    $storage->sql_maker;

    is ref $storage, "${SYBASE}::NoBindVars::FreeTDS",
      'told before the first use that the connection has no placeholders, '
    . 'the declared storage becomes the NoBindVars class';
    is_deeply [ grep { /\?/ } @STATEMENTS ], [],
      '... and does not probe for what it was told';
  }

  # The key of a new row: the FreeTDS workaround that read @@identity
  # session-wide (a trigger overwrites it, karr k39) is gone; the class asks
  # SCOPE_IDENTITY() of the INSERT's own scope, as the base class does.
  {
    my $storage = declared()->connect('dbi:Sybase:server=k37srv')->storage;
    $storage->sql_maker;

    ok !$storage->_identity_method && !$storage->_no_scope_identity_query,
      'adapted over FreeTDS, the declared storage asks SCOPE_IDENTITY() '
    . 'and has no @@identity fallback (karr k39)';
    ok $storage->disable_sth_caching,
      '... statement caching stays off (the other FreeTDS workaround)';
  }
}

# ----------------------------------- 2. a schema without a declared driver
#
# Core ADR 0067: the DSN does not find a driver for a schema. A schema that
# declares none is refused at connect, and the function that answers which
# driver a DSN names does not name this one: the declaration is the only way
# into this driver's classes.

{
  for my $dsn ('dbi:Sybase:server=k37srv', 'dbi:ODBC:DSN=k37') {
    reset_records();
    my $class = schema_class();

    throws_ok { $class->connect($dsn, 'k37user', 'sekrit37') }
      qr/\Q$class\E declares no driver.*ADR 0067.*-<driver>.*storage_type/s,
      "a schema without a declared driver on $dsn is refused at connect, "
    . 'naming the class, ADR 0067 and how to declare the driver';
    is_deeply \@CONNECTS, [], '... nothing is connected';
    is_deeply \@STATEMENTS, [], '... and no server is asked what it is';
  }

  reset_records();

  throws_ok { DBIO->driver_for('dbi:ODBC:DSN=k37', 'k37user', 'sekrit37') }
    qr/DBD::ODBC names no DBIO driver.*ADR 0067.*Declare the driver/s,
    'DBIO->driver_for on dbi:ODBC: throws: DBD::ODBC names no driver, the '
  . 'schema has to declare it';

  is(DBIO->driver_for('dbi:Sybase:server=k37srv', 'k37user', 'sekrit37'),
    'Sybase',
    'DBIO->driver_for on dbi:Sybase: names the Sybase ASE driver, not this '
  . 'one: the DSN alone does not lead to MSSQL, the declaration does');
  is_deeply \@CONNECTS, [], '... and neither answer connects';
}

# ------------------------------------------------ 5. the DBD of another driver

for my $foreign (
  [ 'dbi:Pg:dbname=k37',     'Pg',     'DBIO::PostgreSQL::Storage' ],
  [ 'dbi:SQLite:dbname=k37', 'SQLite', 'DBIO::SQLite::Storage' ],
) {
  my ($dsn, $dbd, $registered) = @$foreign;

  reset_records();
  my $schema  = declared()->connect($dsn, 'k37user', 'sekrit37');
  my $storage = $schema->storage;
  my @warnings = warnings_of { $storage->sql_maker };

  is scalar @warnings, 1, "a schema declaring MSSQL on $dsn warns, once";
  like $warnings[0], qr/$MISMATCH \Q$BASE\E: .*DBD::$dbd.*\Q$registered\E/,
    '... naming the declared class, the DBD and the driver it belongs to';
  is ref $storage, $BASE, '... and the storage stays the declared class';
  is_deeply \@CONNECTS, [], '... nothing was connected to for it';

  $schema = declared()->connect($dsn);
  $schema->driver_strict(1);
  throws_ok { $schema->storage->sql_maker } qr/$MISMATCH.*DBD::$dbd/s,
    "... and with driver_strict $dsn throws";
}

{
  reset_records();
  my $schema  = declared()->connect('dbi:K37Nobody:db=k37');
  my $storage = $schema->storage;
  $schema->driver_strict(1);

  lives_ok { $storage->sql_maker }
    'a DBD nothing is registered for (a proxy, a mock) is not judged';
  is ref $storage, $BASE, '... and the storage stays the declared class';
  is_deeply \@CONNECTS, [], '... unconnected';
}

# --------------------------------------------------- 6. only the base moves
#
# Core checks the hook's one rule after it: the storage must still be an
# instance of the class that was declared. For a private subclass that class
# is the subclass, and neither access-path class of this driver inherits it --
# moved there, the storage would be put back and every use would throw.

{
  my $dsn = 'dbi:ODBC:DSN=k37';
  reset_records();
  my $storage
    = pinned_to('T::K37A::Private::Storage')->connect($dsn)->storage;

  my @warnings;
  lives_ok { @warnings = warnings_of { $storage->sql_maker } }
    "a private subclass of the base on $dsn: the first use does not throw";
  is ref $storage, 'T::K37A::Private::Storage', '... and it stays what it is';
  is scalar @warnings, 1, '... with one warning';
  like $warnings[0], qr/$MISMATCH T::K37A::Private::Storage: .*DBD::/,
    '... core\'s, and a true one: a class that is neither access-path class '
  . 'is not the one this DBD needs';
  is_deeply \@CONNECTS, [], '... and without a connection';
}

# Over DBD::Sybase a private subclass of the base is refused (karr k42, k43;
# ADR 0008): the base is transport-neutral and has none of what the Sybase
# class does for this DBD -- transaction statements, the bind limit, reading
# binary values. Measured: COMMIT/ROLLBACK never arrive, txn_do runs its body
# twice, a long value is cut to 4000 bytes without an error.
{
  my $dsn = 'dbi:Sybase:server=k37srv';

  for my $strict (0, 1) {
    reset_records();
    my $schema = pinned_to('T::K37A::Private::Storage')->connect($dsn, 'k37user', 'sekrit37');
    my $storage = $schema->storage;
    $schema->driver_strict($strict);
    $schema->driver_warnings(0);

    throws_ok { $storage->sql_maker }
      qr/T::K37A::Private::Storage.*DBD::Sybase.*\Q$SYBASE\E.*DBD::ODBC/s,
      'a private subclass of the base on dbi:Sybase: throws at the first use '
    . '(driver_strict ' . ( $strict ? 'on' : 'off' ) . ', warnings silenced), '
    . 'naming the class to derive from and the other way';
    unlike "$@", qr/sekrit37|k37user|k37srv/, '... and nothing of the connect info';
    is ref $storage, 'T::K37A::Private::Storage',
      '... the storage is back in the class it was pinned to';
    is_deeply \@CONNECTS, [], '... and nothing was connected';
  }

  # The refusal does not look at the DBIO::Sybase check first: it holds
  # without DBIO::Sybase, too -- the advice to install it would not help.
  reset_records();
  my $class = pinned_to('T::K37A::Private::Storage');
  $class->register_storage_layer('T::K37A::Layer');
  throws_ok { $class->connect($dsn)->storage->sql_maker }
    qr/T::K37A::Private::Storage.*\Q$SYBASE\E/s,
    'a layered private subclass is refused the same way';

  # a connection coderef: the hook runs it and reads the DBD off the handle
  reset_records();
  throws_ok {
    pinned_to('T::K37A::Private::Storage')
      ->connect(sub { T::K37A::DBH->new('Sybase') })->storage->sql_maker
  } qr/\Q$SYBASE\E/, '... also when the DBD is only known from a connection coderef';
}

# The DBD::ODBC class (or a derivation of it) over DBD::Sybase is refused as
# well -- but not with the advice for a derivation of the base ("derive from
# ::Sybase", "connect through DBD::ODBC"): the contradiction is the news, an
# ODBC class on a DBD::Sybase handle (karr k42).
for my $pin (
  [ $ODBC,                    'pinned to the DBD::ODBC class itself' ],
  [ 'T::K37A::Private::ODBC', 'pinned to a private subclass of the DBD::ODBC class' ],
) {
  my ($class, $what) = @$pin;

  reset_records();
  my $storage = pinned_to($class)->connect('dbi:Sybase:server=k37srv', 'k37user', 'sekrit37')->storage;
  throws_ok { $storage->sql_maker }
    qr/\Q$class\E.*DBD::ODBC.*DBD::Sybase/s,
    "$what over dbi:Sybase: throws, naming the contradiction";
  unlike "$@", qr/connect through DBD::ODBC|Derive from/i,
    '... without the advice meant for a derivation of the base';
  unlike "$@", qr/sekrit37|k37user|k37srv/, '... and nothing of the connect info';
}

for my $pin (
  [ $ODBC,                    'pinned to the DBD::ODBC class itself' ],
  [ 'T::K37A::Private::ODBC', 'pinned to a private subclass of the DBD::ODBC class' ],
) {
  my ($class, $what) = @$pin;

  reset_records();
  my $schema  = pinned_to($class)->connect('dbi:ODBC:DSN=k37');
  my $storage = $schema->storage;
  $schema->driver_strict(1);

  lives_ok { $storage->sql_maker } "$what: nothing to throw about";
  is ref $storage, $class, '... and nothing to change';
  is_deeply \@CONNECTS, [], '... unconnected';
}

SKIP: {
  skip 'DBIO::Sybase is not installed (optional, cpanfile recommends)', 1
    unless $HAVE_SYBASE;

  local $ENV{DBIO_MSSQL_FREETDS_LOWVER_NOWARN} = 1;

  # a derivation of the Sybase class is not refused: it is the way
  # (set up at run time: `use base` here would load DBIO::Sybase at compile
  # time, before section 4 has hidden it)
  { no strict 'refs'; @{'T::K37A::Private::Sybase::ISA'} = ($SYBASE) }
  mro::set_mro('T::K37A::Private::Sybase', 'c3');
  reset_records();
  my $derived = pinned_to('T::K37A::Private::Sybase')->connect('dbi:Sybase:server=k37srv');
  $derived->driver_strict(1);
  lives_ok { $derived->storage->sql_maker }
    'pinned to a private subclass of the DBD::Sybase class: not refused';
  isa_ok $derived->storage, $SYBASE, '... it';

  for my $placeholders (1, 0) {
    local $PLACEHOLDERS = $placeholders;

    reset_records();
    my $schema  = pinned_to($SYBASE)->connect('dbi:Sybase:server=k37srv');
    my $storage = $schema->storage;
    $schema->driver_strict(1);

    lives_ok { $storage->sql_maker }
      'pinned to the DBD::Sybase class itself: nothing to throw about';
    is ref $storage,
      $SYBASE . ( $placeholders ? '' : '::NoBindVars' ) . '::FreeTDS',
      '... and it gets the placeholder decision the declared base gets ('
    . ( $placeholders ? 'placeholders' : 'none' ) . ')';
    is_deeply [ grep { /sp_server_info/ } @STATEMENTS ], [],
      '... without sp_server_info';
  }
}

# ------------------------------------------------------- 7. layers survive

{
  reset_records();
  my $class = declared();
  $class->register_storage_layer('T::K37A::Layer');
  my $storage = $class->connect('dbi:ODBC:DSN=k37')->storage;

  is(DBIO::Storage::Composed->composition_of(ref $storage)->{base}, $BASE,
    'a layered schema composes its layers over the declared class');

  my @warnings = warnings_of { $storage->sql_maker };

  my $entry = DBIO::Storage::Composed->composition_of(ref $storage);
  is $entry->{base}, $ODBC,
    'a layered declared storage on dbi:ODBC: is recomposed over the '
  . 'DBD::ODBC class';
  is_deeply $entry->{layers}, [ 'T::K37A::Layer' ], '... with its layer';
  is $storage->k37_layer, 'layer', '... which still answers';
  is_deeply \@warnings, [], '... and nothing is reported';
}

SKIP: {
  skip 'DBIO::Sybase is not installed (optional, cpanfile recommends)', 1
    unless $HAVE_SYBASE;

  local $ENV{DBIO_MSSQL_FREETDS_LOWVER_NOWARN} = 1;

  for my $placeholders (1, 0) {
    local $PLACEHOLDERS = $placeholders;

    reset_records();
    my $class = declared();
    $class->register_storage_layer('T::K37A::Layer');
    my $storage = $class->connect('dbi:Sybase:server=k37srv')->storage;

    my @warnings = warnings_of { $storage->sql_maker };

    isa_ok $storage,
      $SYBASE . ( $placeholders ? '' : '::NoBindVars' ),
      'a layered declared storage on dbi:Sybase: ('
        . ( $placeholders ? 'placeholders' : 'none' ) . ')';
    isa_ok $storage, 'DBIO::Sybase::Storage::FreeTDS', '... with FreeTDS, it';
    is $storage->k37_layer, 'layer', '... and its layer still answers';
    is_deeply \@warnings, [], '... and nothing is reported';
  }
}

# -------------------------------------- 8. no DBD named: a coderef, or nothing

{
  reset_records();
  my $ran = 0;
  my $schema = declared()->connect(sub { $ran++; T::K37A::DBH->new('ODBC') });
  my $storage = $schema->storage;
  $schema->driver_strict(1);

  lives_ok { $storage->sql_maker }
    'a connection coderef: the hook is handed no DBD, and the first use lives';
  is ref $storage, $ODBC,
    '... the storage is the class for the DBD of the handle the coderef made';
  is $ran, 1, '... which the hook ran itself, once -- core does not';
}

SKIP: {
  skip 'DBIO::Sybase is not installed (optional, cpanfile recommends)', 1
    unless $HAVE_SYBASE;

  reset_records();
  my $ran = 0;
  my $storage
    = declared()->connect(sub { $ran++; T::K37A::DBH->new('Sybase') })->storage;

  $storage->sql_maker;

  is ref $storage, "${SYBASE}::FreeTDS",
    'a connection coderef for a DBD::Sybase handle: the DBD::Sybase class';
  is $ran, 1, '... through one connection';
}

{
  reset_records();
  my $ran = 0;
  my $storage
    = declared()->connect(sub { $ran++; T::K37A::DBH->new('K37Nobody') })->storage;

  my @warnings = warnings_of { $storage->sql_maker };

  is ref $storage, $BASE,
    'a connection coderef for a handle of neither DBD: the declared class stays';
  is_deeply \@warnings, [], '... and a DBD nothing is registered for is not judged';
}

{
  reset_records();

  throws_ok { declared()->connect }
    qr/Connect info without a DSN \(no arguments\)/,
    'no connect info at all is refused at connect: $ENV{DBI_DSN} is not read '
  . 'and a storage without a DSN has no driver to adapt';
  is_deeply \@CONNECTS, [], '... and nothing is connected to';

  # a schema that only writes SQL names its DSN; nothing is opened before the
  # first use that needs a connection
  my $storage = declared()->connect('dbi:ODBC:')->storage;

  my @warnings;
  lives_ok { @warnings = warnings_of { $storage->sql_maker } }
    'a schema that only writes SQL, named by a bare DSN: the first use lives';
  is ref $storage, 'DBIO::MSSQL::Storage::ODBC',
    '... the storage is the class the DSN names, from the DSN alone';
  is ref $storage->sql_maker, 'DBIO::MSSQL::SQLMaker', '... with its SQL maker';
  is_deeply \@warnings, [], '... and nothing is reported';
  is_deeply \@CONNECTS, [], '... and nothing is connected to';
}

# ------------------------- 9. the DSN seam is asked first, on the declared base
#
# connect_info runs when the schema connects; the driver is determined at the
# first use. So for connection parameters the seam of the BASE builds the DSN
# (t/59 pins its form), and that DSN is what the hook then reads the DBD
# from. Connection parameters therefore always lead to DBD::Sybase: the ODBC
# class would refuse them, and it is never the one asked first.

sub broker {
  return DBIO::AccessBroker::Static->new(
    username => 'k37user', password => 'sekrit37', @_,
  );
}

SKIP: {
  skip 'DBIO::Sybase is not installed (optional, cpanfile recommends)', 1
    unless $HAVE_SYBASE;

  reset_records();
  my $broker  = broker(dbname => 'app', host => 'mssql.example', port => 1433);
  my $storage = declared()->connect($broker)->storage;

  is $storage->_dbi_connect_info->[0],
    'dbi:Sybase:host=mssql.example;port=1433;database=app',
    'connection parameters are a DSN once the schema is connected';
  is ref $storage, $BASE,
    '... built by the declared base: the storage has not adapted to anything';
  ok !$storage->_driver_determined, '... its driver is not determined';
  is_deeply \@CONNECTS, [], '... and nothing is connected';

  $storage->sql_maker;

  is ref $storage, "${SYBASE}::FreeTDS",
    'at the first use the storage adapts to the DBD the base put into that DSN';
  is +( $CONNECTS[-1] || [] )->[0], 'dbi:Sybase:host=mssql.example;port=1433;database=app',
    '... and connects with it';

  # Every connection asks the broker anew, and the seam with it -- now the one
  # of the class the storage became.
  $broker->host('standby.example');
  $storage->disconnect;
  $storage->ensure_connected;

  is +( $CONNECTS[-1] || [] )->[0], 'dbi:Sybase:host=standby.example;port=1433;database=app',
    'a reconnect of the adapted storage builds the same form from what the '
  . 'broker answers then: the DBD::Sybase class has the seam of the base';
}

{
  reset_records();
  my $broker  = broker(dbname => 'dbi:ODBC:DSN=k37');
  my $storage = declared()->connect($broker)->storage;
  $storage->sql_maker;

  is ref $storage, $ODBC,
    'a broker whose dbname is a whole dbi:ODBC: DSN: the storage adapts to '
  . 'DBD::ODBC';

  $broker->dbname('app');
  $broker->host('mssql.example');
  $broker->port(1433);

  throws_ok { $storage->_connect } qr/Cannot build a DBD::ODBC DSN/,
    '... and from then on refuses connection parameters, as t/59 pins for '
  . 'the class: a storage that runs on DBD::ODBC does not reconnect through '
  . 'DBD::Sybase';
}

done_testing;
