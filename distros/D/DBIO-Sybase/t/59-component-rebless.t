use strict;
use warnings;

use Test::More;
use Test::Exception;

use DBI;
use DBIO;
use DBIO::Schema;
use DBIO::Storage::DBI::ODBC;
use DBIO::Storage::Composed;
use DBIO::Sybase::Storage;
use DBIO::Sybase::Storage::ASE;
use DBIO::Sybase::SQLMaker;
use DBIO::AccessBroker::Static;

# OFFLINE (karr k64; core k301, ADR 0059). A schema declares this driver by
# loading the Sybase component or by the -syb shortcut, and both pin
# DBIO::Sybase::Storage -- the base, which has nothing of ASE: no GenericSubQ
# SQL maker, no [ ] quoting, no _init with its writer storage, none of the
# capabilities declared on the ASE class.
#
# DBIO::Sybase::Storage::_adapt_to_access_path is what core calls. This file
# pins what it does, through core's own driver determination -- a schema, a
# connect, a first use -- and not by calling the hook:
#
#   1. a declared storage on a dbi:Sybase: DSN becomes
#      DBIO::Sybase::Storage::ASE, with the Sybase SQL maker and with ASE's
#      _init behind it, lazily -- at the first use, not at connect;
#   2. the server is NOT asked what it is (no sp_server_info); the schema has
#      said which driver it uses, and that is taken at its word;
#   3. the storage then takes the placeholder decision -- placeholders,
#      auto_cast, NoBindVars, the FreeTDS class -- from the client library;
#   4. it never becomes DBIO::MSSQL::Storage::Sybase, although that class
#      inherits this one and core's own check would let it pass. A server
#      DBD::Sybase found to be Microsoft SQL Server when it logged in is
#      reported through core's _driver_mismatch, and the storage stays here;
#   5. the hook can run again: the writer storage ASE's _init makes is built
#      with (ref $self)->new, goes through the declared branch itself, without
#      a schema, and is left as it is (it decides nothing: its parent did);
#   6. only the declared base moves. A private subclass pinned by hand stays
#      what it is, and so does a storage pinned to the NoBindVars class. (A
#      storage pinned to the ASE class stays it on a connection that needs
#      neither auto_cast nor NoBindVars -- what the fake client library
#      answers here; on one that does, it gets the placeholder decision, held
#      in t/92-pinned-ase-placeholders.t.);
#   7. storage layers survive the hook -- over the ASE class, over a NoBindVars
#      class and, under FreeTDS, ahead of the FreeTDS trait class _init builds
#      (karr k77): the composition is <ASE class>::FreeTDS with the same
#      layers, and core still knows it;
#   8. the DBD of another driver is left alone and reported by core; a
#      connection coderef names no DBD until it has run, so the hook runs it;
#   9. connection parameters without a DSN lead here too.
#
# A schema that names no storage_type is refused at connect: a schema always
# has a driver (ADR 0067). The way from a DSN to a driver is a function,
# DBIO->driver_for, which names this driver, and the schema DBIO->schema_for
# makes of it is a declared one: its storage becomes the ASE class, without
# sp_server_info.
#
# NOTHING HERE CONNECTS. DBI->connect is replaced, and the handle it returns
# answers what the driver asks a client library and a server: syb_oc_version,
# syb_dynamic_supported, the placeholder probes, and
# syb_server_version_string -- what DBD::Sybase keeps of the "select
# @@version" it sends by itself at every login. So this file shows which class
# a storage becomes and what it asks on the way, and not that a server works
# with it: t/62-component-rebless-live.t does that, against a real ASE.
#
# NOT VERIFIED ANYWHERE: what syb_server_version_string holds on a connection
# to Microsoft SQL Server. The string used below is that product's @@version
# as its documentation shows it; no such server was connected to from here.

my $BASE = 'DBIO::Sybase::Storage';
my $ASE  = 'DBIO::Sybase::Storage::ASE';

my $DSN = 'dbi:Sybase:host=ase.example;port=5000;database=app';

my $OPEN_CLIENT = 'Sybase Client-Library/16.0/P/x86_64/Linux';
my $FREETDS     = 'freetds v1.3.17';

my %VERSION_STRING = (
  ase   => 'Adaptive Server Enterprise/16.0 SP02 PL02/EBF 25320 SMP/P/x86_64/'
         . 'Enterprise Linux/ase160sp02plx/2492/64-bit/FBO/Sat Nov 21 2015',
  mssql => 'Microsoft SQL Server 2022 (RTM) - 16.0.1000.6 (X64) Oct  8 2022 '
         . 'Copyright (C) 2022 Microsoft Corporation',
);

# What the fake client library and the fake server answer; set per case.
our $OC_VERSION   = $OPEN_CLIENT;
our $DYNAMIC      = 1;       # syb_dynamic_supported
our $PLACEHOLDERS = 1;       # select ?
our $TYPELESS     = 1;       # select 1 where 1 = ?
our $PRODUCT      = 'ase';

my (@CONNECTS, @ASKED, @DONE);

{
  package T::K64A::DBH;

  sub new {
    my ($class, $dbd) = @_;
    bless {
      Active => 1, AutoCommit => 1, RaiseError => 1, PrintError => 0,
      Driver => { Name => $dbd },
      ( $dbd eq 'Sybase' ? (
        syb_oc_version            => $OC_VERSION,
        syb_dynamic_supported     => $DYNAMIC,
        syb_server_version_string => $VERSION_STRING{$PRODUCT},
      ) : () ),
    }, $class;
  }

  sub FETCH      { $_[0]{$_[1]} }
  sub ping       { 1 }
  sub disconnect { $_[0]{Active} = 0; 1 }

  # The placeholder probes of DBIO::Storage::DBI are a do() with a bind value.
  sub do {
    my ($self, $sql) = @_;
    push @DONE, $sql;
    die "this connection binds no value without a type\n"
      if $sql =~ /where 1 = \?/ and not $TYPELESS;
    die "this connection takes no placeholders\n"
      if $sql =~ /\?/ and not $PLACEHOLDERS;
    return 1;
  }

  # Recorded, so the cases can show that the server is never asked what it is.
  sub selectrow_arrayref {
    my ($self, $sql) = @_;
    push @ASKED, $sql;
    return [ 1, 'DBMS_NAME',
      $PRODUCT eq 'mssql' ? 'Microsoft SQL Server' : 'SQL Server' ];
  }
}

no warnings 'redefine';
local *DBI::connect = sub {
  shift;
  push @CONNECTS, [ @_ ];
  my ($dbd) = $_[0] =~ /^dbi:(\w*)/i;
  return T::K64A::DBH->new($dbd);
};
use warnings 'redefine';

# The FreeTDS notice of the ASE class is given once per process and is no
# finding of this file.
$ENV{DBIO_SYBASE_FREETDS_NOWARN} = 1;

{
  package T::K64A::Shortcut;
  use DBIO 'Schema', -syb;
}

{ package T::K64A::Private::Storage; use base 'DBIO::Sybase::Storage'; use mro 'c3'; }

{
  package T::K64A::Layer;
  our $TEXTSIZE_SET = 0;
  sub k64_layer { 'layer' }
  # A public method the FreeTDS class has too: the layer has to be asked first.
  sub set_textsize { $TEXTSIZE_SET++; shift->maybe::next::method(@_) }
}

# A new schema class each time: the storage type, the layers and the switches
# are class data.
my $schema_count = 0;
sub schema_class {
  my $class = 'T::K64A::Schema' . ++$schema_count;
  { no strict 'refs'; @{"${class}::ISA"} = ('DBIO::Schema') }
  return $class;
}

sub by_component {
  my $class = schema_class();
  $class->load_components('Sybase');
  return $class;
}

sub pinned_to {
  my $class = schema_class();
  $class->storage_type("+$_[0]");
  return $class;
}

# A storage holds its schema weakly, and the two switches are read off the
# schema: every schema connected here is kept alive to the end of the file.
my @KEEP;
sub connected_schema {
  my $class  = shift;
  my $schema = $class->connect(@_);
  push @KEEP, $schema;
  return $schema;
}

sub reset_records { @CONNECTS = @ASKED = @DONE = () }

sub asked_what_it_is { scalar grep { /\Asp_server_info\b/ } @ASKED }
sub probed           { scalar grep { /\?/ } @DONE }

sub warnings_of (&) {
  my $code = shift;
  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, @_ };
  $code->();
  return @warnings;
}

# A guard for the whole file. The hook and the placeholder decision run once
# per storage, and each of them blesses the storage and then goes on: the place
# where a method ends up calling itself on the class it has just made. Such a
# run does not fail, it grows until the memory is gone. Here it dies at depth
# $MAX_DEPTH, and the test that made the call fails.
my $MAX_DEPTH = 5;
our %DEPTH;
my @GUARDED;

for my $guarded (
  [ $BASE, '_adapt_to_access_path' ],
  [ $ASE,  '_adapt_to_placeholder_support' ],
) {
  my $name = join '::', @$guarded;

  no strict 'refs';
  my $code = defined &$name ? \&$name : next;

  no warnings 'redefine';
  *$name = sub {
    local $DEPTH{$name} = ( $DEPTH{$name} || 0 ) + 1;
    die "$name called itself $DEPTH{$name} deep: it does not end\n"
      if $DEPTH{$name} > $MAX_DEPTH;
    return $code->(@_);
  };

  push @GUARDED, $name;
}

is scalar @GUARDED, 2,
  '(the hook and the placeholder decision are guarded against calling '
. 'themselves without end)'
  or diag "guarded: @GUARDED";

my $MISMATCH = qr/Driver mismatch for declared storage class \Q$BASE\E:/;

my @DECLARED = (
  [ "load_components('Sybase')", sub { by_component() } ],
  [ "use DBIO 'Schema', -syb",   sub { 'T::K64A::Shortcut' } ],
);

# -------------------------------------- the control: no storage_type named

{
  reset_records();
  my $class = schema_class();

  throws_ok { connected_schema($class, $DSN, 'sa', 's3cret') }
    qr/\QSchema class $class declares no driver\E.*\(ADR 0067\)/s,
    'no storage_type named, on a dbi:Sybase: DSN: connect refuses the schema '
  . '-- a schema always has a driver (ADR 0067)';
  is_deeply \@CONNECTS, [], '... before anything is connected to';
  ok !asked_what_it_is(),
    '... and nobody asks the server what it is (no sp_server_info)';

  is +DBIO->driver_for($DSN, 'sa', 's3cret'), 'Sybase',
    'DBIO->driver_for names this driver for a dbi:Sybase: DSN';
  is_deeply \@CONNECTS, [], '... read off the DSN, without connecting';

  my $schema = DBIO->schema_for($DSN, 'sa', 's3cret');
  push @KEEP, $schema;
  my $storage = $schema->storage;

  is ref $storage, $BASE,
    'DBIO->schema_for: a schema with this driver declared, its storage the '
  . 'declared class';
  $storage->ensure_connected;
  is ref $storage, $ASE, '... which becomes the ASE class at the first use';
  ok !asked_what_it_is(), '... without sp_server_info';
  isa_ok $storage->sql_maker, 'DBIO::Sybase::SQLMaker', '... and its sql_maker';
}

# -------------------------------------------- 1 + 2. the driver, declared

for my $how (@DECLARED) {
  my ($by, $class) = @$how;

  reset_records();
  my $schema  = connected_schema($class->(), $DSN, 'sa', 's3cret');
  my $storage = $schema->storage;

  is ref $storage, $BASE, "$by: connect gives the declared class";
  ok !$storage->_driver_determined, '... lazily: nothing is decided at connect';
  is_deeply \@CONNECTS, [], '... and nothing is connected to';

  my @warnings = warnings_of { $storage->ensure_connected };

  isa_ok $storage, $ASE, "$by: the storage, once connected,"
    or diag 'it is a ' . ref $storage;
  is ref $storage, $ASE,
    '... the ASE class itself: Open Client with placeholders needs no other';

  ok !asked_what_it_is(),
    "$by: the server was NOT asked what it is (no sp_server_info) -- the "
  . 'schema declared its driver, and that is taken at its word'
    or diag "asked: @ASKED";

  my $sql_maker = $storage->sql_maker;

  isa_ok $sql_maker, 'DBIO::Sybase::SQLMaker', "$by: its sql_maker"
    or diag 'it is a ' . ref $sql_maker;
  is_deeply $storage->sql_quote_char, [ '[', ']' ],
    '... and names are quoted with [ ]';

  ok scalar( grep { /\AmaxConnect=256\z/ } split /;/, $storage->_dbi_connect_info->[0] ),
    "$by: ASE's _init ran on it -- the stored DSN carries maxConnect=256";
  my $writer = $storage->can('_writer_storage') && $storage->_writer_storage;
  isa_ok $writer, $ASE, '... and its writer storage';

  is $storage->_declared_storage_class, $BASE,
    '... and the class the schema declared is still known as the one declared';
  is_deeply \@warnings, [], "$by: nothing is reported";
}

# The first use need not be a connect: the hook asks the client library, and
# opens the connection for that itself.
{
  reset_records();
  my $schema  = connected_schema(by_component(), $DSN, 'sa', 's3cret');
  my $storage = $schema->storage;
  $schema->driver_strict(1);

  my $sql_maker;
  lives_ok { $sql_maker = $storage->sql_maker }
    'the first use is sql_maker, with driver_strict: nothing to throw about';
  isa_ok $sql_maker, 'DBIO::Sybase::SQLMaker', '... and it';
  is ref $storage, $ASE, '... of a storage that is the ASE class by then';
  ok scalar @CONNECTS, '... which connected to find its client library';
  ok !asked_what_it_is(), '... and did not ask the server what it is';
}

# ------------------------------- 3. the client library decides the rest

for my $client (
  [ 'Open Client, placeholders',
    $OPEN_CLIENT, 1, 1, 1, $ASE, 0 ],
  [ 'Open Client, no placeholder without a type',
    $OPEN_CLIENT, 1, 1, 0, $ASE, 1 ],
  [ 'Open Client, no dynamic SQL',
    $OPEN_CLIENT, 0, 1, 1, "${ASE}::NoBindVars", 0 ],
  [ 'FreeTDS, placeholders',
    $FREETDS, 1, 1, 1, "${ASE}::FreeTDS", 0 ],
  [ 'FreeTDS, no placeholder without a type',
    $FREETDS, 1, 1, 0, "${ASE}::FreeTDS", 1 ],
  [ 'FreeTDS, no placeholders',
    $FREETDS, 1, 0, 0, "${ASE}::NoBindVars::FreeTDS", 0 ],
) {
  (my $name, local $OC_VERSION, local $DYNAMIC, local $PLACEHOLDERS,
    local $TYPELESS, my $expect, my $auto_cast) = @$client;

  for my $how (@DECLARED) {
    my ($by, $class) = @$how;

    reset_records();
    my $schema  = connected_schema($class->(), $DSN, 'sa', 's3cret');
    my $storage = $schema->storage;
    $schema->driver_strict(1);

    my @warnings;
    lives_ok { @warnings = warnings_of { $storage->ensure_connected } }
      "$name, $by: the first use lives, with driver_strict";

    is ref $storage, $expect, "$name, $by: the storage becomes $expect";
    is +( $storage->can('auto_cast') && $storage->auto_cast ) ? 1 : 0, $auto_cast,
      '... auto_cast is ' . ( $auto_cast ? 'on' : 'off' );
    is ref( $storage->can('_writer_storage') && $storage->_writer_storage ),
      $expect, '... and its writer storage is one of the same class';
    ok !asked_what_it_is(), '... without sp_server_info';
    is_deeply \@warnings, [], '... and without a warning';
  }
}

# The capability forced before the first use, as a user would for a client
# library whose probe lies. Under FreeTDS: with Open Client the ASE class goes
# by syb_dynamic_supported and not by the capability.
{
  local $OC_VERSION = $FREETDS;

  reset_records();
  my $storage = connected_schema(by_component(), $DSN, 'sa', 's3cret')->storage;
  $storage->_use_typeless_placeholders(0);
  $storage->_use_placeholders(0);
  $storage->ensure_connected;

  is ref $storage, "${ASE}::NoBindVars::FreeTDS",
    'told before the first use that the connection has no placeholders, the '
  . 'declared storage becomes the NoBindVars class';
  ok !probed(), '... and does not probe for what it was told';
}

# ---------------------------- 5. the hook again: the writer storage, and twice

{
  local ($OC_VERSION, $TYPELESS) = ($FREETDS, 0);

  reset_records();
  my $storage = connected_schema(by_component(), $DSN, 'sa', 's3cret')->storage;
  $storage->ensure_connected;

  my $class  = ref $storage;
  my $writer = $storage->_writer_storage;

  is $class, "${ASE}::FreeTDS", '(the storage is the ASE class with FreeTDS)';
  is ref $writer, $class,
    'the writer storage is made of the class the declared storage became';
  ok !$writer->_driver_determined,
    '... and has its own driver determination ahead of it';
  ok !$writer->schema, '... which it goes through without a schema';

  reset_records();
  my @warnings;
  lives_ok { @warnings = warnings_of { $writer->ensure_connected } }
    'the writer storage connects: the hook runs on a storage that is no '
  . 'declared base';

  ok $writer->_driver_determined, '... its driver is determined';
  is ref $writer, $class, '... and it is the class it was';
  ok $writer->auto_cast, '... with the auto_cast its parent decided on';
  ok !asked_what_it_is(), '... the server was not asked what it is';
  ok !probed(), '... and the placeholders were not probed a second time';
  ok !$writer->_writer_storage, '... and it was given no writer of its own';
  is_deeply \@warnings, [], '... and nothing was reported';

  # Core calls the hook once per storage. Called again it has nothing to do.
  reset_records();
  $storage->_adapt_to_access_path('Sybase');

  is ref $storage, $class,
    'the hook called again on the adapted storage leaves its class alone';
  is_deeply [ @ASKED, @DONE ], [], '... and asks nothing';
}

# --------------------------------- 4. a server that is Microsoft SQL Server

{
  local $PRODUCT = 'mssql';

  for my $how (@DECLARED) {
    my ($by, $class) = @$how;

    reset_records();
    my $storage = connected_schema($class->(), $DSN, 'sa', 's3cret')->storage;

    my @warnings = warnings_of { $storage->ensure_connected };

    is scalar @warnings, 1,
      "$by, the server being Microsoft SQL Server: one warning";
    like $warnings[0], qr/$MISMATCH .*Microsoft SQL Server/,
      '... a driver mismatch, naming the declared class and the product';
    unlike $warnings[0], qr/ase\.example|s3cret/,
      '... and nothing of the connect info';
    is ref $storage, $ASE,
      '... the storage is the ASE class: the declared driver stands';
    ok !$storage->isa('DBIO::MSSQL::Storage'),
      '... and no storage of the other product, although '
    . 'DBIO::MSSQL::Storage::Sybase inherits the declared class';
    ok !asked_what_it_is(),
      '... known from what DBD::Sybase read at login, not from a question '
    . 'put for it (no sp_server_info)';
  }

  {
    reset_records();
    my $schema  = connected_schema(by_component(), $DSN, 'sa', 's3cret');
    my $storage = $schema->storage;
    $schema->driver_strict(1);

    throws_ok { $storage->ensure_connected } qr/$MISMATCH .*Microsoft SQL Server/,
      'with driver_strict the same server is an error';
    is ref $storage, $BASE, '... the storage is still the declared class';
    ok !$storage->_driver_determined, '... and undetermined';
    throws_ok { $storage->sql_maker } $MISMATCH,
      '... so the next use throws again: as if the combination did not work';
  }

  {
    reset_records();
    my $schema  = connected_schema(by_component(), $DSN, 'sa', 's3cret');
    my $storage = $schema->storage;
    $schema->driver_warnings(0);

    my @warnings = warnings_of { $storage->ensure_connected };

    is_deeply \@warnings, [], 'with driver_warnings off nothing is said';
    is ref $storage, $ASE, '... and the storage is the ASE class all the same';
  }

}

# -------------------------------------------- 6. only the declared base moves

for my $pin (
  [ 'T::K64A::Private::Storage', 'a private subclass of the declared class' ],
  [ $ASE,                        'the ASE class itself (a connection that needs no decision)' ],
  [ "${ASE}::NoBindVars",        'the NoBindVars class' ],
) {
  my ($class, $what) = @$pin;

  reset_records();
  my $schema  = connected_schema(pinned_to($class), $DSN, 'sa', 's3cret');
  my $storage = $schema->storage;
  $schema->driver_strict(1);

  my @warnings;
  lives_ok { @warnings = warnings_of { $storage->ensure_connected } }
    "pinned to $what: the first use lives, with driver_strict";
  is ref $storage, $class, '... and the storage stays what it is';
  ok !asked_what_it_is(), '... the server is not asked what it is';
  is_deeply \@warnings, [], '... and nothing is reported';
}

# ---------------------------------------------------- 7. layers survive

for my $client (
  [ 'Open Client',                $OPEN_CLIENT, 1, 1, 1, $ASE ],
  [ 'Open Client, no dynamic SQL', $OPEN_CLIENT, 0, 1, 1, "${ASE}::NoBindVars" ],
  [ 'FreeTDS',                    $FREETDS,     1, 1, 1, "${ASE}::FreeTDS" ],
  [ 'FreeTDS, no placeholders',   $FREETDS,     1, 0, 0,
    "${ASE}::NoBindVars::FreeTDS" ],
) {
  (my $name, local $OC_VERSION, local $DYNAMIC, local $PLACEHOLDERS,
    local $TYPELESS, my $expect_base) = @$client;
  local $T::K64A::Layer::TEXTSIZE_SET = 0;

  reset_records();
  my $class = by_component();
  $class->register_storage_layer('T::K64A::Layer');
  my $storage = connected_schema($class, $DSN, 'sa', 's3cret')->storage;

  is(DBIO::Storage::Composed->composition_of(ref $storage)->{base}, $BASE,
    "$name: a layered schema composes its layers over the declared class");

  my @warnings = warnings_of { $storage->ensure_connected };

  my $freetds = $expect_base =~ /FreeTDS/;

  isa_ok $storage, $ASE, "$name: the layered storage, once connected,";
  isa_ok $storage, 'DBIO::Sybase::Storage::FreeTDS', '... with FreeTDS, it'
    if $freetds;
  is $storage->k64_layer, 'layer', '... and its layer still answers';
  isa_ok $storage->sql_maker, 'DBIO::Sybase::SQLMaker', '... and its sql_maker';
  ok !asked_what_it_is(), '... without sp_server_info';
  is_deeply \@warnings, [], '... and nothing is reported';

  # Under FreeTDS _init builds its trait class over the base of the
  # composition and puts the layers back over it (karr k77): the layers stay
  # ahead of the driver, the FreeTDS class included, and core knows the class.
  my $entry = DBIO::Storage::Composed->composition_of(ref $storage) || {};

  is $entry->{base}, $expect_base,
    "$name: the layers are composed over $expect_base";
  is_deeply $entry->{layers}, [ 'T::K64A::Layer' ],
    '... and the composition is one core still knows';

  ok $T::K64A::Layer::TEXTSIZE_SET,
    'FreeTDS: a method of the layer that the FreeTDS class has too is the '
  . 'layer\'s -- the layers stay ahead of the driver, the FreeTDS class '
  . 'included'
    if $freetds;

  ok scalar( grep { /\ASET TEXTSIZE\b/ } @DONE ),
    'FreeTDS: (the FreeTDS class itself is in effect: it set the text size)'
    if $freetds;
}

# ------- 7b. the same for the storage of Microsoft SQL Server (dbio-mssql)

# DBIO::MSSQL::Storage::Sybase inherits this _init, so the layers of a schema
# pinned to it stay ahead of the FreeTDS trait class as well (karr k77).
SKIP: {
  skip 'dbio-mssql is not installed', 4
    unless eval { require DBIO::MSSQL::Storage::Sybase; 1 };

  my $MSSQL = 'DBIO::MSSQL::Storage::Sybase';
  local $OC_VERSION = $FREETDS;
  local $PRODUCT    = 'mssql';
  local $T::K64A::Layer::TEXTSIZE_SET = 0;

  reset_records();
  my $class = pinned_to($MSSQL);
  $class->register_storage_layer('T::K64A::Layer');
  my $storage = connected_schema($class, $DSN, 'sa', 's3cret')->storage;
  my $ok; warnings_of { $ok = eval { $storage->ensure_connected; 1 } };
  ok $ok, 'MSSQL over FreeTDS, with a layer: the first use lives'
    or diag $@;

  isa_ok $storage, 'DBIO::Sybase::Storage::FreeTDS', 'MSSQL storage';
  my $entry = DBIO::Storage::Composed->composition_of(ref $storage) || {};
  is $entry->{base}, "${MSSQL}::FreeTDS",
    '... the layers are composed over the FreeTDS class of the MSSQL class';
  is_deeply $entry->{layers}, [ 'T::K64A::Layer' ],
    '... and core knows the composition';
}

# ------------------------------- 8. another DBD, a coderef, a DBD of nobody

{
  reset_records();
  my $storage = connected_schema(by_component(), 'dbi:ODBC:DSN=k64')->storage;

  my @warnings = warnings_of { $storage->sql_maker };

  is ref $storage, $BASE,
    'declared, on a dbi:ODBC: DSN: the storage stays the declared class -- '
  . 'the ASE class is built on DBD::Sybase';
  is scalar @warnings, 1, '... with one warning';
  like $warnings[0], qr/$MISMATCH .*DBD::ODBC.*DBIO::Storage::DBI::ODBC/,
    '... core\'s: that DBD belongs to another storage class';
  is_deeply \@CONNECTS, [], '... and nothing was connected to for it';
}

{
  reset_records();
  my $schema  = connected_schema(by_component(), 'dbi:K64Nobody:db=k64');
  my $storage = $schema->storage;
  $schema->driver_strict(1);

  lives_ok { $storage->sql_maker }
    'declared, on a DBD nothing is registered for (a proxy, a mock): not judged';
  is ref $storage, $BASE, '... and the storage stays the declared class';
  is_deeply \@CONNECTS, [], '... unconnected';
}

{
  reset_records();
  my $ran = 0;
  my $storage = connected_schema(
    by_component(), sub { $ran++; T::K64A::DBH->new('Sybase') }
  )->storage;

  $storage->sql_maker;

  is ref $storage, $ASE,
    'a connection coderef names no DBD: the hook runs it, finds a DBD::Sybase '
  . 'handle, and the storage becomes the ASE class';
  is $ran, 1, '... through one connection, the one the storage goes on using';
  ok !asked_what_it_is(), '... and without sp_server_info';
}

{
  reset_records();
  my $storage = connected_schema(
    by_component(), sub { T::K64A::DBH->new('K64Nobody') }
  )->storage;

  my @warnings = warnings_of { $storage->sql_maker };

  is ref $storage, $BASE,
    'a connection coderef for a handle of another DBD: the declared class stays';
  is_deeply \@warnings, [], '... and a DBD nothing is registered for is not judged';
}

# -------------------------------- 9. connection parameters without a DSN

{
  reset_records();
  my $broker = DBIO::AccessBroker::Static->new(
    username => 'sa', password => 's3cret',
    host => 'ase.example', port => 5000, dbname => 'app',
  );
  my $storage = connected_schema(by_component(), $broker)->storage;

  is $storage->_dbi_connect_info->[0], $DSN,
    'connection parameters are a DSN once the schema is connected, built by '
  . 'the declared class';
  is ref $storage, $BASE, '... which the storage still is';

  $storage->ensure_connected;

  is ref $storage, $ASE,
    'at the first use the storage adapts to the DBD of that DSN';
  is +( $CONNECTS[0] || [] )->[0], $DSN, '... and connected with it';
}

done_testing;
