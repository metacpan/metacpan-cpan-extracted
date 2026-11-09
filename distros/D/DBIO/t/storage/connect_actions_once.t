# ABSTRACT: the connection actions of a storage run once for every connection it opens
use strict;
use warnings;

use Test::More;

use DBI;
use DBIO;
use DBIO::Schema;
use DBIO::Storage::DBI;
use DBIO::Storage::Composed;

# OFFLINE (karr k309). on_connect_call and on_connect_do set a connection up:
# a search path, a session mode, a role. They belong to the connection, so
# they run once for each one the storage opens -- not twice, which repeats a
# statement that may not be repeatable, and not zero times, which leaves a
# connection that was never set up.
#
# Two places run them. _populate_dbh does after it connected, unless the
# connection was opened from inside the driver determination; then
# _determine_driver does, after _init. A storage of a DECLARED class (the
# driver component or a driver shortcut pins storage_type, ADR 0059) whose
# first use is a connect went through both: _populate_dbh had connected,
# _determine_driver took the handle for one it had opened itself and ran the
# actions, and _populate_dbh ran them again. A driver-driven schema is always
# a declared one, so this was the common case.
#
# What this file pins, for the declared class, also with a connection
# coderef and under a storage layer (a schema always declares its driver,
# ADR 0067; no driver is found through the DSN):
#   1. whatever the first use is -- a connect, or something that needs the
#      driver and no connection -- every connection gets the actions once;
#   2. a driver determination that connects on its own (the hook of a
#      declared class) still gets them once: the second place to run them is
#      not surplus;
#   3. they run after _init;
#   4. a reconnect is a new connection and gets them again, once.
#
# THE SUBSTITUTIONS: a fake driver DBIO::K309Drv with a storage class defined
# here, registered for a DBD name no DBD carries; DBI->connect returns a fake
# handle that numbers itself and records what is done on it. The mock storage
# DBIO::Test::Storage has a driver determination of its own and is no subject
# for this.

my (@EVENTS, @CONNECTS);
my $HANDLES = 0;

{
  package T::K309::DBH;
  sub new {
    my ($class, $dbd) = @_;
    bless {
      Active => 1, AutoCommit => 1, RaiseError => 1, CachedKids => {},
      Driver => { Name => $dbd },
      k309_number => ++$HANDLES,
    }, $class;
  }
  sub FETCH { $_[0]{$_[1]} }
  sub ping { 1 }
  sub disconnect { $_[0]{Active} = 0; 1 }
  sub do {
    my ($self, $sql) = @_;
    push @EVENTS, [ do => $self->{k309_number}, $sql ];
    return '0E0';
  }
}

# The driver's base storage: what a schema declares, registered for the DBD
# 'K309Native'.
{
  package DBIO::K309Drv::Storage;
  use base 'DBIO::Storage::DBI';
  use mro 'c3';
  DBIO::Storage::DBI->register_driver(K309Native => __PACKAGE__);
  $INC{'DBIO/K309Drv/Storage.pm'} = __FILE__;

  our ($HOOK);
  sub _adapt_to_access_path {
    my ($self, $dbd) = @_;
    $HOOK->($self, $dbd) if $HOOK;
  }
  sub _init {
    push @EVENTS, [ 'init' ];
    $_[0]->next::method;
  }
  sub connect_call_k309_note {
    push @EVENTS, [ call => $_[0]->_dbh->{k309_number} ];
  }
}

# A storage holds its schema weakly: every schema connected here is kept
# alive to the end of the file.
{
  package T::K309::SchemaBase;
  use base 'DBIO::Schema';
  our @KEEP;
  sub connect {
    my $schema = shift->SUPER::connect(@_);
    push @KEEP, $schema;
    return $schema;
  }
}

{ package T::K309::Layer; sub k309_layer { 'layer' } }

# The shortcut stub of the fake driver, as a driver dist ships one.
BEGIN {
  package DBIO::Shortcut::k309drv;
  sub apply { DBIO->apply_driver($_[1], 'K309Drv') }
  $INC{'DBIO/Shortcut/k309drv.pm'} = __FILE__;
}

{
  package T::K309::ShortcutSchema;
  use DBIO 'Schema', -k309drv;
  our @KEEP;
  sub connect {
    my $schema = shift->next::method(@_);
    push @KEEP, $schema;
    return $schema;
  }
}

no warnings 'redefine';
local *DBI::connect = sub {
  push @CONNECTS, $_[1];
  my ($dbd) = $_[1] =~ /^dbi:(\w*)/i;
  return T::K309::DBH->new($dbd);
};
use warnings 'redefine';

my $DECLARED = 'DBIO::K309Drv::Storage';
my $DSN      = 'dbi:K309Native:db=t';
my $SQL      = 'SET k309_session = 1';

my %ACTIONS = ( on_connect_call => 'k309_note', on_connect_do => [ $SQL ] );

my $schema_count = 0;
sub schema_class {
  my (%arg) = @_;
  my $class = 'T::K309::Schema' . ++$schema_count;
  { no strict 'refs'; @{"${class}::ISA"} = ('T::K309::SchemaBase') }
  $class->storage_type("+$DECLARED") if $arg{declared};
  $class->register_storage_layer('T::K309::Layer') if $arg{layered};
  return $class;
}

# a storage with both kinds of action configured, nothing used yet
sub storage_for {
  my (%arg) = @_;
  @EVENTS = @CONNECTS = ();
  $HANDLES = 0;
  my $class = $arg{schema_class} || schema_class(%arg);
  my @info  = $arg{connect_info} ? ( $arg{connect_info} ) : ( $DSN, 'u', 'p' );
  return $class->connect(@info, { %ACTIONS })->storage;
}

sub coderef_info { sub { push @CONNECTS, 'coderef'; T::K309::DBH->new('K309Native') } }

# the numbers of the handles each kind of action ran on, in order
sub calls { [ map { $_->[1] } grep { $_->[0] eq 'call' } @EVENTS ] }
sub dos   { [ map { $_->[1] } grep { $_->[0] eq 'do'   } @EVENTS ] }
sub order { [ map { $_->[0] } @EVENTS ] }

# One connection, the actions once on it, after _init.
sub one_connection_once {
  my ($what) = @_;
  is scalar(@CONNECTS), 1, "$what: one connection is opened";
  is_deeply calls(), [ 1 ], "$what: on_connect_call runs once on it";
  is_deeply dos(),   [ 1 ], "$what: on_connect_do runs once on it";
  is_deeply order(), [qw( init call do )],
    "$what: _init first, then the actions, in their order";
}

# --- a declared class whose first use is a connect --------------------------
{
  my $storage = storage_for(declared => 1);
  is ref($storage), $DECLARED, 'a schema that declares its driver gets that class';
  is_deeply \@EVENTS, [], 'connect alone opens nothing and runs nothing';

  $storage->ensure_connected;
  one_connection_once('declared, ensure_connected first');
  is_deeply [ map { $_->[2] } grep { $_->[0] eq 'do' } @EVENTS ], [ $SQL ],
    '... and what ran is the statement of on_connect_do';

  $storage->ensure_connected;
  $storage->dbh;
  $storage->sql_maker;
  one_connection_once('declared, used further on the same connection');
}

{
  my $storage = storage_for(declared => 1);
  $storage->dbh;
  one_connection_once('declared, dbh first');
}

{
  my $storage = storage_for(declared => 1);
  $storage->dbh_do(sub { 1 });
  one_connection_once('declared, dbh_do first');
}

{
  is(T::K309::ShortcutSchema->storage_type, "+$DECLARED",
    "the shortcut declares the driver's base storage class");
  my $storage = storage_for(schema_class => 'T::K309::ShortcutSchema');
  $storage->ensure_connected;
  one_connection_once('declared by shortcut, ensure_connected first');
}

# --- a declared class whose driver is determined before it connects ---------
{
  my $storage = storage_for(declared => 1);
  $storage->sql_maker;
  ok $storage->_driver_determined, 'sql_maker determines the driver';
  is_deeply \@CONNECTS, [], '... without a connection';
  is_deeply order(), [ 'init' ], '... so no action has run yet';

  $storage->ensure_connected;
  one_connection_once('declared, driver determined first, then connected');
}

# --- a declared class whose hook connects on its own ------------------------
for my $first_use (qw( sql_maker ensure_connected )) {
  my $seen;
  local $DBIO::K309Drv::Storage::HOOK = sub {
    $seen = $_[0]->_get_dbh->{k309_number};
  };

  my $storage = storage_for(declared => 1);
  $storage->$first_use;
  is $seen, 1, "a hook that connects reads its handle ($first_use first)";
  one_connection_once("declared, the hook connects, $first_use first");
}

# --- a declared class connected through a coderef --------------------------
# A connection coderef names no DBD; the declared class does not need one, and
# its determination does not run the coderef.
for my $first_use (qw( sql_maker ensure_connected )) {
  my $storage = storage_for(declared => 1, connect_info => coderef_info());
  $storage->$first_use;
  is ref($storage), $DECLARED, "a connection coderef keeps the declared class ($first_use first)";
  $storage->ensure_connected;
  one_connection_once("declared, connection coderef, $first_use first");
}

# --- a reconnect is a new connection ----------------------------------------
for my $case (
  [ 'declared, connected first',         sub { $_[0]->ensure_connected }, declared => 1 ],
  [ 'declared, driver determined first', sub { $_[0]->sql_maker },        declared => 1 ],
) {
  my ($what, $first_use, %arg) = @$case;

  my $storage = storage_for(%arg);
  $storage->$first_use;
  $storage->ensure_connected;
  $storage->disconnect;
  is_deeply calls(), [ 1 ], "$what: disconnect runs no connect action";

  $storage->ensure_connected;
  is scalar(@CONNECTS), 2, "$what: connecting after a disconnect opens a second connection";
  is_deeply calls(), [ 1, 2 ], "$what: on_connect_call ran once on each";
  is_deeply dos(),   [ 1, 2 ], "$what: on_connect_do ran once on each";

  # a handle that died under the storage
  $storage->_dbh->{Active} = 0;
  $storage->dbh;
  is scalar(@CONNECTS), 3, "$what: a dead handle is replaced by a third connection";
  is_deeply calls(), [ 1, 2, 3 ], "$what: on_connect_call ran once on each of the three";
  is_deeply dos(),   [ 1, 2, 3 ], "$what: on_connect_do ran once on each of the three";
  is_deeply [ grep { $_ eq 'init' } @{ order() } ], [ 'init' ],
    "$what: _init belongs to the storage and ran once";
}

# --- under a storage layer --------------------------------------------------
{
  my $storage = storage_for(declared => 1, layered => 1);
  is(DBIO::Storage::Composed->composition_of(ref $storage)->{base}, $DECLARED,
    'a layered schema composes its layer over the declared class');

  $storage->ensure_connected;
  isa_ok $storage, 'T::K309::Layer', 'the connected storage';
  one_connection_once('declared under a layer, ensure_connected first');
}

done_testing;
