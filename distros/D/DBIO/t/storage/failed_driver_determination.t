# ABSTRACT: a driver determination that throws leaves the storage as it came in, without a handle
use strict;
use warnings;

use Test::More;
use Test::Exception;
use Scalar::Util 'refaddr';

use DBI;
use DBIO;
use DBIO::Schema;
use DBIO::Storage::DBI;
use DBIO::Storage::Composed;

# OFFLINE (karr k312, k313). Driver determination is lazy and it can fail: the
# hook of a declared class finds its client library unusable or its server does
# not answer, _init throws, the schema is driver_strict and the DSN leads
# through another driver's DBD. Whatever
# throws, the storage is used again afterwards -- an application catches the
# error and retries, a pool hands the storage on.
#
# A determination that stopped half way left what it had done so far:
#   * the storage stayed blessed into the class the hook had moved it to, still
#     undetermined. The next use took that class for the DECLARED one (ADR 0059)
#     and ran the access-path hook on it (k313);
#   * the handle stayed in the storage -- the one _populate_dbh had just
#     opened, or one the determination had opened itself -- without
#     on_connect_do / on_connect_call ever having run on it. ensure_connected,
#     dbh and dbh_do took the storage for connected and used it (k312);
#   * a throwing _init left the storage marked as determined, so _init never
#     ran again.
#
# What this file pins, for a declared class, also under a storage layer, and
# for the generic storage, which has no driver and is refused at every use
# (ADR 0067):
#   1. a determination that throws leaves the storage in the class it came in
#      and undetermined; the next use starts over, through the same branch
#      (ADR 0059 says so for the hook; it holds for _init too);
#   2. it leaves no handle behind: no connection is used that the connection
#      actions have not run on. The next connection gets them once, after
#      _init;
#   3. a failure that does not go away throws at every use;
#   4. the error reaches the caller as it was thrown;
#   5. a failed connection ACTION is not a failed determination.
#
# THE SUBSTITUTIONS: a fake driver DBIO::K312Drv, its storage classes defined
# here and registered for DBD names no DBD carries; DBI->connect returns a fake
# handle that numbers itself and records what is asked of it. The scaffolding
# is that of t/storage/connect_actions_once.t (karr k309), which pins the
# successful determination.

my (@EVENTS, @CONNECTS, %SEEN, %GONE);
my ($HANDLES, $CASE) = (0, 0);

{
  package T::K312::STH;
  sub new { bless { dbh => $_[1], sql => $_[2] }, $_[0] }
  sub execute { $_[0]{dbh}->k312_note(execute => $_[0]{sql}); '0E0' }
  sub fetchrow_array { () }
  sub finish { 1 }
}

{
  package T::K312::DBH;
  sub new {
    my ($class, $dbd) = @_;
    bless {
      Active => 1, AutoCommit => 1, RaiseError => 1, CachedKids => {},
      Driver => { Name => $dbd },
      k312_number => ++$HANDLES, k312_case => $CASE,
    }, $class;
  }
  sub FETCH { $_[0]{$_[1]} }
  sub ping { 1 }
  sub disconnect { $_[0]{Active} = 0; 1 }

  # everything a server would get to see of this handle
  sub k312_note {
    my ($self, $what, $sql) = @_;
    return unless $self->{k312_case} == $CASE;
    push @EVENTS, [ $what => $self->{k312_number}, $sql ];
    push @{ $SEEN{ $self->{k312_number} } }, $what;
  }
  sub do {
    my ($self, $sql) = @_;
    $self->k312_note(do => $sql);
    die "k312: the statement failed\n" if $sql =~ /k312_fails/;
    return '0E0';
  }
  sub get_info { $_[0]->k312_note('get_info'); 'K312 Engine' }
  sub prepare_cached { T::K312::STH->new(@_[0, 1]) }
  sub DESTROY { $GONE{ $_[0]{k312_number} } = 1 if $_[0]{k312_case} == $CASE }
}

# What the test makes a step of the determination do, and that it ran.
my %STEP;
sub step {
  my ($step, $storage, @args) = @_;
  push @EVENTS, [ $step ];
  $STEP{$step}->($storage, @args) if $STEP{$step};
}

# The driver's base storage: what a schema declares, registered for the DBD
# 'K312Native'.
{
  package DBIO::K312Drv::Storage;
  use base 'DBIO::Storage::DBI';
  use mro 'c3';
  DBIO::Storage::DBI->register_driver(K312Native => __PACKAGE__);
  $INC{'DBIO/K312Drv/Storage.pm'} = __FILE__;

  sub _adapt_to_access_path { main::step(hook => @_) }
  sub _init { main::step(init => @_); $_[0]->next::method }
  sub connect_call_k312_note {
    push @EVENTS, [ call => $_[0]->_dbh->{k312_number} ];
  }
}

# Another driver altogether, for the DSN a driver_strict schema refuses.
{
  package T::K312::Other::Storage;
  use base 'DBIO::Storage::DBI';
  use mro 'c3';
  DBIO::Storage::DBI->register_driver(K312Other => __PACKAGE__);
}

# A storage holds its schema weakly: every schema connected here is kept
# alive to the end of the file.
{
  package T::K312::SchemaBase;
  use base 'DBIO::Schema';
  our @KEEP;
  sub connect {
    my $schema = shift->SUPER::connect(@_);
    push @KEEP, $schema;
    return $schema;
  }
}

{ package T::K312::Layer; sub k312_layer { 'layer' } }

no warnings 'redefine';
local *DBI::connect = sub {
  push @CONNECTS, $_[1];
  my ($dbd) = $_[1] =~ /^dbi:(\w*)/i;
  return T::K312::DBH->new($dbd);
};
use warnings 'redefine';

my $DRIVER  = 'DBIO::K312Drv::Storage';
my $DSN     = 'dbi:K312Native:db=t';
my $SQL     = 'SET k312_session = 1';
my $BOOM    = 'k312: the determination failed';

my $schema_count = 0;
sub schema_class {
  my (%arg) = @_;
  my $class = 'T::K312::Schema' . ++$schema_count;
  { no strict 'refs'; @{"${class}::ISA"} = ('T::K312::SchemaBase') }
  $class->storage_type("+$DRIVER") if $arg{declared};
  $class->register_storage_layer('T::K312::Layer') if $arg{layered};
  return $class;
}

# a storage with both kinds of connection action configured, nothing used yet
sub storage_for {
  my (%arg) = @_;
  @EVENTS = @CONNECTS = ();
  %SEEN = %GONE = ();
  $HANDLES = 0;
  $CASE++;
  my @info = (
    $arg{dsn} || $DSN, 'u', 'p',
    { on_connect_call => 'k312_note', on_connect_do => [ $arg{sql} || $SQL ] },
  );
  my $schema = schema_class(%arg)->connect(@info);
  $schema->$_($arg{$_}) for grep { exists $arg{$_} }
    qw( driver_strict exception_action );
  return $schema->storage unless $arg{generic};

  # the generic storage, built by hand: no schema can have it (ADR 0067)
  my $storage = DBIO::Storage::DBI->new($schema);
  $storage->connect_info(\@info);
  return $storage;
}

# a step that throws: the first $times times it runs, or always
sub throwing {
  my ($times) = @_;
  return sub {
    return if defined $times and $times-- <= 0;
    $_[0]->throw_exception($BOOM);
  };
}

# ... after it has opened the connection on its own, as a hook does that
# asks the server what it is
sub connecting_then {
  my ($then) = @_;
  return sub { $_[0]->_get_dbh; $then->(@_) };
}

sub count { my $type = shift; scalar grep { $_->[0] eq $type } @EVENTS }
sub on    { my $type = shift; [ map { $_->[1] } grep { $_->[0] eq $type } @EVENTS ] }
sub seen  { [ @{ $SEEN{ $_[0] } || [] } ] }

# what happened from the last _init on
sub since_init {
  my @types = map { $_->[0] } grep { $_->[0] =~ /^(?:init|call|do|execute)$/ } @EVENTS;
  my ($last) = grep { $types[$_] eq 'init' } reverse 0 .. $#types;
  return [ @types[ $last .. $#types ] ];
}

# the driver class under the layers, if there are any
sub base_of {
  my $composition = DBIO::Storage::Composed->composition_of(ref $_[0]);
  return $composition ? $composition->{base} : ref $_[0];
}

my %USE = (
  ensure_connected => sub { $_[0]->ensure_connected },
  dbh              => sub { $_[0]->dbh },
  sql_maker        => sub { $_[0]->sql_maker },
  select_single    => sub { $_[0]->select_single('t', [ 'c' ], {}, {}) },
);
# the uses that open the connection before the driver is asked for
my %CONNECTS_FIRST = ( ensure_connected => 1, dbh => 1 );

# --- 1 + 2. a step that throws once ------------------------------------------
# The step fails at the first use and works at the second. The storage is then
# used for a statement.
for my $entry (
  [ 'declared',          [qw( hook init )],    declared => 1 ],
  [ 'declared, layered', [qw( hook init )],    declared => 1, layered => 1 ],
) {
  my ($kind, $steps, %arg) = @$entry;

  for my $step (@$steps) {
    for my $use (qw( ensure_connected dbh sql_maker select_single )) {
      my $what = "$kind, $step throws, $use first";

      local $STEP{$step} = throwing(1);
      my $storage = storage_for(%arg);
      my $entry_class = ref $storage;
      is base_of($storage), $DRIVER, "$what: the storage starts as the declared class";

      throws_ok { $USE{$use}->($storage) } qr/\Q$BOOM\E/, "$what: the first use throws";

      # what the failed attempt left
      is ref($storage), $entry_class, "$what: the storage is in the class it came in";
      ok !$storage->_driver_determined, "$what: ... and undetermined";
      ok !defined $storage->_dbh, "$what: ... and holds no handle";

      my $opened = $CONNECTS_FIRST{$use} ? 1 : 0;
      is $HANDLES, $opened, "$what: the failed attempt opened $opened connection(s)";
      if ($opened) {
        is_deeply seen(1), [], "$what: its handle was asked nothing";
        ok $GONE{1}, "$what: ... and is released";
      }

      # the next use starts over
      lives_ok { $USE{$use}->($storage) } "$what: the second use lives";
      $USE{select_single}->($storage) unless $use eq 'select_single';

      is base_of($storage), $DRIVER, "$what: the storage ends in the driver class";
      isa_ok $storage, 'T::K312::Layer', "$what: the storage" if $arg{layered};
      ok $storage->_driver_determined, "$what: ... determined";

      is count('hook'), 2, "$what: the hook ran again";
      is count('init'), ( $step eq 'init' ? 2 : 1 ),
        "$what: _init ran " . ( $step eq 'init' ? 'again' : 'once, after the step succeeded' );

      my $last = $opened + 1;
      is scalar(@CONNECTS), $last, "$what: $last connection(s) were opened in all";
      is $storage->_dbh->{k312_number}, $last, "$what: the storage holds the last one";
      is_deeply on('call'), [ $last ], "$what: on_connect_call ran once, on it";
      is_deeply on('do'),   [ $last ], "$what: on_connect_do ran once, on it";
      is_deeply on('execute'), [ $last ], "$what: the statement ran on it";
      is_deeply since_init(), [qw( init call do execute )],
        "$what: _init, then the actions, then the statement";

      $storage->dbh;
      is scalar(@CONNECTS), $last, "$what: a handle that got its actions is kept";
    }
  }
}

# --- 2. the determination opens the connection itself, then throws -----------
# _populate_dbh is not the caller here: the handle is the determination's own.
for my $entry (
  [ 'declared',          [qw( hook init )],    declared => 1 ],
  [ 'declared, layered', [qw( hook init )],    declared => 1, layered => 1 ],
) {
  my ($kind, $steps, %arg) = @$entry;

  for my $step (@$steps) {
    my $what = "$kind, $step connects and throws";

    local $STEP{$step} = connecting_then(throwing(1));
    my $storage = storage_for(%arg);
    my $entry_class = ref $storage;

    throws_ok { $storage->sql_maker } qr/\Q$BOOM\E/, "$what: the use throws";
    is $HANDLES, 1, "$what: the step had opened a connection";
    ok !defined $storage->_dbh, "$what: the storage does not keep it";
    ok $GONE{1}, "$what: ... it is released";
    is_deeply seen(1), [], "$what: ... and was asked nothing";
    is ref($storage), $entry_class, "$what: the storage is in the class it came in";
    ok !$storage->_driver_determined, "$what: ... and undetermined";

    lives_ok { $storage->sql_maker } "$what: the second use lives";
    is scalar(@CONNECTS), 2, "$what: ... on a second connection";
    is_deeply on('call'), [ 2 ], "$what: on_connect_call ran once, on the second";
    is_deeply on('do'),   [ 2 ], "$what: on_connect_do ran once, on the second";
    is_deeply since_init(), [qw( init call do )], "$what: ... after _init";

    # only the handle of a FAILED determination goes
    ok !$GONE{2}, "$what: the second connection, which got its actions, is kept";
    $storage->dbh;
    is scalar(@CONNECTS), 2, "$what: ... and used from then on";
  }
}

# --- 3. a failure that stays -------------------------------------------------
# Every use throws again. Before, the second one found a handle in the storage
# and went on with it: undetermined, unchecked, without its actions.
for my $entry (
  [ 'declared, driver_strict and the DBD of another driver', qr/Driver mismatch/,
    declared => 1, driver_strict => 1, dsn => 'dbi:K312Other:db=t' ],
  [ 'the same under a layer', qr/Driver mismatch/,
    declared => 1, driver_strict => 1, dsn => 'dbi:K312Other:db=t', layered => 1 ],
  [ 'declared, the hook always throws', qr/\Q$BOOM\E/, declared => 1, step => 'hook' ],
  [ 'declared, _init always throws',    qr/\Q$BOOM\E/, declared => 1, step => 'init' ],
  [ 'the generic storage, which has no driver', qr/DBIO::Storage::DBI has no driver/,
    declared => 1, generic => 1 ],
) {
  my ($kind, $error, %arg) = @$entry;

  for my $use (qw( ensure_connected dbh dbh_do sql_maker select_single )) {
    my $what = "$kind, $use";

    local $STEP{ $arg{step} } = throwing() if $arg{step};
    my $storage = storage_for(%arg);
    my $entry_class = ref $storage;

    my $ran = 0;
    my $code = $use eq 'dbh_do'
      ? sub { $_[0]->dbh_do(sub { $ran++ }) }
      : $USE{$use};

    for my $attempt (1 .. 3) {
      my $got;
      throws_ok { $got = $code->($storage) } $error, "$what: use $attempt throws";
      ok !defined $got, "$what: ... and hands nothing out";
      ok !defined $storage->_dbh, "$what: ... and leaves no handle in the storage";
      is ref($storage), $entry_class, "$what: ... which stays the class it came in";
    }

    is $ran, 0, "$what: the code handed to dbh_do never ran" if $use eq 'dbh_do';
    is_deeply [ map { @{ seen($_) } } 1 .. $HANDLES ], [],
      "$what: none of the $HANDLES connection(s) opened on the way was asked anything";
    is_deeply [ grep { ! $GONE{$_} } 1 .. $HANDLES ], [], "$what: ... and none is kept";
    is count('call'), 0, "$what: no connection action ran: no connection was fit to use";
  }
}

# --- 2. dbh_do retries over the lost connection ------------------------------
# dbh_do runs its code again, once, when the storage is not connected after a
# failure -- as it does over a connection that died, and over a connection
# action that failed. A determination that throws once therefore does not reach
# its caller. Before, the handle stayed, dbh_do saw a connected storage and
# gave up.
for my $entry (
  [ 'declared, the hook throws once', 'hook', declared => 1 ],
  [ 'declared, _init throws once',    'init', declared => 1 ],
) {
  my ($what, $step, %arg) = @$entry;

  local $STEP{$step} = throwing(1);
  my $storage = storage_for(%arg);

  my @ran_on;
  lives_ok { $storage->dbh_do(sub { push @ran_on, $_[1]{k312_number} }) }
    "$what: dbh_do gets over it";
  is_deeply \@ran_on, [ 2 ], "$what: its code runs once, on the second connection";
  is_deeply seen(1), [], "$what: the first connection was asked nothing";
  ok $GONE{1}, "$what: ... and is released";
  is_deeply on('call'), [ 2 ], "$what: on_connect_call ran once, on the second";
  is_deeply on('do'),   [ 2 ], "$what: on_connect_do ran once, on the second";
}

# --- 4. the error is the caller's, as it was thrown --------------------------
for my $entry (
  [ 'declared, the hook', 'hook', declared => 1 ],
  [ 'declared, _init',    'init', declared => 1 ],
) {
  my ($kind, $step, %arg) = @$entry;

  for my $use (qw( ensure_connected sql_maker )) {
    my $what = "$kind, $use";

    my ($thrown, $reported) = (undef, 0);
    local $STEP{$step} = sub {
      eval { $_[0]->throw_exception($BOOM) };
      die( $thrown = $@ );
    };
    my $storage = storage_for(%arg, exception_action => sub { $reported++; die $_[0] });

    eval { $USE{$use}->($storage) };
    my $caught = $@;

    isa_ok $caught, 'DBIO::Exception', "$what: what the caller catches";
    is refaddr($caught), refaddr($thrown), "$what: ... is the object that was thrown";

    # the declared branch throws a hook's error again itself (ADR 0059): one
    # more report there, and none from the places this file is about
    my $expected = $step eq 'hook' ? 2 : 1;
    is $reported, $expected,
      "$what: exception_action hears of it $expected time(s), not once per frame it passes";
  }
}

# a driver that dies with a plain string: the determination passes it on
{
  local $STEP{init} = sub { die "k312: a plain string\n" };
  my $storage = storage_for(declared => 1);

  eval { $storage->ensure_connected };
  is $@, "k312: a plain string\n", 'a string an _init died with reaches the caller as that string';
  ok !defined $storage->_dbh, '... and the handle is dropped all the same';
  is ref($storage), $DRIVER, '... and the storage stays the class it came in';
  ok !$storage->_driver_determined, '... undetermined';
}

# --- 5. a failed connection action is not a failed determination -------------
# The driver is found and stays found; only the connection is given up, as
# before (the rule of _do_connection_actions).
for my $entry (
  [ 'declared, the actions run by _populate_dbh', sub { $_[0]->ensure_connected }, declared => 1 ],
  [ 'declared, the actions run by the determination', sub { $_[0]->sql_maker },
    step => 'hook', declared => 1 ],
) {
  my ($what, $use, %arg) = @$entry;

  # the step opens the connection, so the determination runs the actions
  local $STEP{ $arg{step} } = sub { $_[0]->_get_dbh } if $arg{step};
  my $storage = storage_for(%arg, sql => 'SET k312_fails = 1');

  throws_ok { $use->($storage) } qr/k312: the statement failed/,
    "$what: a failing on_connect_do throws";
  is base_of($storage), $DRIVER, "$what: the storage is the driver class";
  ok $storage->_driver_determined, "$what: ... and determined";
  ok !defined $storage->_dbh, "$what: ... and the connection is given up";
  is_deeply seen(1), [ 'do' ], "$what: ... after the action was tried on it";

  throws_ok { $storage->ensure_connected } qr/k312: the statement failed/,
    "$what: the next connection gets the actions again";
  is count('init'), 1, "$what: _init is not repeated";
  is count('hook'), 1, "$what: ... nor the determination";
}

done_testing;
