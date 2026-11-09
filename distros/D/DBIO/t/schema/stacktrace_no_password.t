# ABSTRACT: No stack trace DBIO writes quotes a password
use strict;
use warnings;

# the stack trace is switched on case by case; DBIO_TRACE has a file of its
# own, t/schema/stacktrace_no_password_dbio_trace.t
BEGIN { $ENV{DBIO_TRACE} = 0 }

use Test::More;

use Carp ();
use overload ();
use DBIO::Carp ();
use DBIO::Util ();
use DBIO::Base;
use DBIO::Exception;
use DBIO::Schema;
use DBIO::Test::Storage;

# OFFLINE (karr k304; found while working k297, maintainer's go 2026-10-06).
# k297 keeps the password out of every MESSAGE DBIO writes connect info into.
# A stack trace is another way out, and another mechanism: with stacktrace(1)
# or DBIO_TRACE=1 Carp writes the arguments of every live frame, and a schema
# is connected by handing it the password as an argument. An exception thrown
# while that frame lives -- the card's case: a storage_type that cannot be
# loaded -- read
#
#   DBIO::Schema::connection(..., "dbi:Pg:dbname=app", "app", "<the password>")
#
# The decision is k297's, applied here: what DBIO writes never quotes
# credentials. Only the secret becomes '***'; frames, files, lines, the DSN,
# the user name and every other argument stay, so the trace remains a trace.
#
# What this file claims:
#   1. Every stack trace DBIO writes is built in one place,
#      DBIO::Util::masked_longmess and its siblings. It finds the connect info in
#      the arguments of the live frames -- no storage is needed, the card's
#      case has none -- and masks with DBIO::Util::mask_connect_secrets, so
#      what k297 can mask in a message is masked in an argument.
#   2. The password argument is masked in connect() and connection(), in
#      whichever class's connection() the frame is (a driver component
#      overrides it and hands on with next::method), with any DSN beside it.
#   3. A password inside a DSN is masked before Carp shortens the argument.
#   4. The same password in the frames of the caller is masked: as an argument
#      of its own, and inside a longer one.
#   5. The hash form never showed a password and still does not -- not even
#      when the caller has Carp spell references out.
#   6. Once the connect frames are gone there is nothing to mask and the trace
#      is what it was.
#   7. The other places that write a trace are covered: the callsite DBIO::Carp
#      falls back to when the whole stack is in a namespace it skips,
#      emit_loud_diag, a scope guard that dies, the exception_action panic.
#   8. Only arguments are touched, only in a trace DBIO writes, and nothing
#      is installed in Carp, before or after. Without a stack trace the message
#      is what it was.
#
# THE SUBSTITUTIONS: none for Carp -- the traces are the real ones. The
# storage that cannot be loaded is a class name without a file; where a
# connection has to succeed the storage is DBIO::Test::Storage. No database
# and no real password: the secrets are marker strings, and each starts with
# the same marker so that a leak shows however Carp escapes or shortens it.

my $SECRET = qr/k304-secret/;
my $AS_ARG = 'k304-secret-as-argument';
my $IN_DSN = 'k304-secret-in-the-dsn';
my $USER   = 'k304-user';
my $DSN    = 'dbi:K304:dbname=app;host=db.example';
my @DBI    = ($DSN, $USER, $AS_ARG);
my $FILE   = quotemeta __FILE__;
my $HASH   = qr/HASH\(0x[0-9a-f]+\)/;

{
  package T::K304::Unloadable;    # the card: its storage class cannot be loaded
  use base 'DBIO::Schema';
  __PACKAGE__->storage_type('+T::K304::NoSuchStorage');
  __PACKAGE__->stacktrace(1);

  package T::K304::Quiet;         # the same, without a stack trace
  use base 'DBIO::Schema';
  __PACKAGE__->storage_type('+T::K304::NoSuchStorage');

  package T::K304::Driver;        # declares its driver the way a driver component does
  use base 'DBIO::Base';
  sub connection {
    my $self = shift;
    $self->storage_type('+T::K304::NoSuchStorage');
    return $self->next::method(@_);
  }

  package T::K304::Declared;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('+T::K304::Driver');
  __PACKAGE__->stacktrace(1);

  package T::K304::Connected;     # a schema that does connect
  use base 'DBIO::Schema';
  __PACKAGE__->storage_type('+DBIO::Test::Storage');
}

# What the code dies with. The code comes as a closure, so that no frame of
# this file holds a password unless the case puts one there.
sub trace_of (&) {
  my $code = shift;
  my $lived = eval { $code->(); 1 };
  return $lived ? undef : "$@";
}

sub no_secret {
  my ($trace, $what) = @_;
  ok defined $trace && $trace =~ /\bcalled at\b/, "$what: there is a stack trace"
    or diag $trace;
  unlike $trace, $SECRET, "$what: ... without the password";
}

# ---------------------------------------------------------------------------
# 1./2. The card: storage_type cannot be loaded, stacktrace(1).
# ---------------------------------------------------------------------------
{
  my $trace = trace_of { T::K304::Unloadable->connect(@DBI, { AutoCommit => 1 }) };

  like $trace, qr/Unable to load storage class T::K304::NoSuchStorage/,
    'the card: dies of the storage class that cannot be loaded';
  no_secret($trace, 'the card, stacktrace(1) on the class');

  like $trace,
    qr/^\tDBIO::Schema::connection\(T::K304::Unloadable=$HASH, "\Q$DSN\E", "\Q$USER\E", "\*\*\*", $HASH\) called at \S*Schema\.pm line \d+$/m,
    'the card: connection() stands, the password masked, DSN, user name and attributes as they were';
  like $trace,
    qr/^\tDBIO::Schema::connect\("T::K304::Unloadable", "\Q$DSN\E", "\Q$USER\E", "\*\*\*", $HASH\) called at $FILE line \d+$/m,
    'the card: connect() stands, the password masked, with the file and line of the caller';
}

# -- stacktrace(1) on the schema object ---------------------------------------
{
  my $schema = T::K304::Quiet->clone;
  $schema->stacktrace(1);
  my $trace = trace_of { $schema->connect(@DBI) };

  no_secret($trace, 'stacktrace(1) on the schema object');
  like $trace, qr/^\tDBIO::Schema::connect\(T::K304::Quiet=$HASH, "\Q$DSN\E", "\Q$USER\E", "\*\*\*"\) called at $FILE line \d+$/m,
    'stacktrace(1) on the schema object: connect() with the password masked';
}

# -- a component that overrides connection() ----------------------------------
# The frame is the component's, not DBIO::Schema's: knowing two sub names by
# their package would not be enough.
{
  my $trace = trace_of { T::K304::Declared->connect(@DBI) };

  no_secret($trace, 'connection() overridden by a component');
  like $trace, qr/^\tT::K304::Driver::connection\(T::K304::Declared=$HASH, "\Q$DSN\E", "\Q$USER\E", "\*\*\*"\) called at /m,
    'connection() overridden by a component: its own frame, the password masked';
  like $trace, qr/^\tDBIO::Schema::connection\(T::K304::Declared=$HASH, "\Q$DSN\E", "\Q$USER\E", "\*\*\*"\) called at $FILE line \d+$/m,
    'connection() overridden by a component: the frame it hands on to as well';
}

# -- a first argument that is no dbi: DSN --------------------------------------
# The password is found by its place in connect(), not by the look of the DSN.
{
  my $libpq = 'host=db.example dbname=app';   # as in k297: a libpq string where a DSN belongs
  my $trace = trace_of { T::K304::Unloadable->connect($libpq, $USER, $AS_ARG) };
  no_secret($trace, 'a first argument that is no DSN');
  like $trace, qr/^\tDBIO::Schema::connect\("T::K304::Unloadable", "\Q$libpq\E", "\Q$USER\E", "\*\*\*"\) called at /m,
    'a first argument that is no DSN: the password is masked by its place';

  $trace = trace_of { T::K304::Unloadable->connect(undef, $USER, $AS_ARG) };
  no_secret($trace, 'no DSN at all');
  like $trace, qr/^\tDBIO::Schema::connect\("T::K304::Unloadable", undef, "\Q$USER\E", "\*\*\*"\) called at /m,
    'no DSN at all: the password is masked by its place';
}

# -- a password Carp does not show as it is -------------------------------------
# Carp puts a backslash before " \ $ and @ in an argument, and shortens it.
# Looked for in the finished trace, such a password would not be found the way
# it was given.
for my $case (
  [ 'a password Carp escapes',  'k304-secret-p@ss$w"or\\d' ],
  [ 'a password Carp shortens', 'k304-secret-' . 'x' x 80 ],
) {
  my ($what, $password) = @$case;
  my $trace = trace_of { T::K304::Unloadable->connect($DSN, $USER, $password) };

  no_secret($trace, $what);
  like $trace, qr/^\tDBIO::Schema::connect\("T::K304::Unloadable", "\Q$DSN\E", "\Q$USER\E", "\*\*\*"\) called at /m,
    "$what: masked as a whole";
}

# ---------------------------------------------------------------------------
# 3. A password inside the DSN.
# ---------------------------------------------------------------------------
{
  my $long = "$IN_DSN-and-long-enough-for-carp-to-cut-it-somewhere-in-the-middle";
  my @IN_DSN = (
    # [ what, the DSN, as the trace shows it ]
    [ 'a DSN part',
      "dbi:K304:dbname=app;password=$IN_DSN;host=db.example",
      '"dbi:K304:dbname=app;password=***;host=db.example"' ],
    [ 'the last DSN part',
      "dbi:K304:dbname=app;host=db.example;PWD=$IN_DSN",
      '"dbi:K304:dbname=app;host=db.example;PWD=***"' ],
    [ 'a password with spaces in it',
      "dbi:K304:dbname=app;password=k304-secret one k304-secret two;host=db.example",
      '"dbi:K304:dbname=app;password=***;host=db.example"' ],
    [ 'the password of a URI',
      "dbi:K304:postgresql://$USER:$IN_DSN\@db.example:5432/app",
      qq{"dbi:K304:postgresql://$USER:***\\\@db.example:5432/app"} ],
    # Carp shows the first 61 characters of an argument: masked afterwards,
    # the start of this password would stand and nothing would say where it ends
    [ 'a DSN part Carp would cut in the middle of the password',
      "dbi:K304:dbname=app;host=db.example;password=$long",
      '"dbi:K304:dbname=app;host=db.example;password=***"' ],
    [ 'the password of a URI Carp would cut in the middle',
      "postgresql://$USER:$long\@db.example:5432/app",
      qq{"postgresql://$USER:***\\\@db.example:5432/app"} ],
  );

  for my $case (@IN_DSN) {
    my ($what, $dsn, $shown) = @$case;
    my $trace = trace_of { T::K304::Unloadable->connect($dsn, $USER) };

    no_secret($trace, "in the DSN, $what");
    like $trace, qr/^\tDBIO::Schema::connect\("T::K304::Unloadable", \Q$shown\E, "\Q$USER\E"\) called at /m,
      "in the DSN, $what: the key and the rest of the DSN stand";
  }
}

# ---------------------------------------------------------------------------
# 4. The frames of the caller.
# ---------------------------------------------------------------------------
sub open_schema   { T::K304::Unloadable->connect(@_) }
sub with_password { my ($password) = @_; T::K304::Unloadable->connect($DSN, $USER, $password) }
sub with_login    { my ($user, $password) = split /:/, $_[0]; T::K304::Unloadable->connect($DSN, $user, $password) }
sub with_attribute { T::K304::Unloadable->connect($DSN, $USER, undef, { Password => $_[0] }) }
{
  my $trace = trace_of { open_schema(@DBI) };
  no_secret($trace, 'a caller handing the connect info on');
  like $trace, qr/^\tmain::open_schema\("\Q$DSN\E", "\Q$USER\E", "\*\*\*"\) called at $FILE line \d+$/m,
    'a caller handing the connect info on: its frame, the password masked';

  $trace = trace_of { with_password($AS_ARG, 'k304-plain-argument') };
  no_secret($trace, 'a caller holding the password alone');
  like $trace, qr/^\tmain::with_password\("\*\*\*", "k304-plain-argument"\) called at /m,
    'a caller holding the password alone: masked as the same value, the argument beside it as it was';

  $trace = trace_of { with_login("$USER:$AS_ARG") };
  no_secret($trace, 'a caller holding the password inside a longer argument');
  like $trace, qr/^\tmain::with_login\("\Q$USER\E:\*\*\*"\) called at /m,
    'a caller holding the password inside a longer argument: masked where the argument repeats it';

  $trace = trace_of { with_attribute($AS_ARG) };
  no_secret($trace, 'a caller holding the Password attribute');
  like $trace, qr/^\tmain::with_attribute\("\*\*\*"\) called at /m,
    'a caller holding the Password attribute: masked as the same value';
}

# ---------------------------------------------------------------------------
# 5. The hash form.
# ---------------------------------------------------------------------------
sub hash_from_password { T::K304::Unloadable->connect({ dsn => $DSN, user => $USER, password => $_[0] }) }
{
  # control: this never leaked -- Carp shows a reference by its address
  my %info  = (dsn => $DSN, user => $USER, password => $AS_ARG);
  my $trace = trace_of { T::K304::Unloadable->connect(\%info) };
  no_secret($trace, 'the hash form');
  like $trace, qr/^\tDBIO::Schema::connect\("T::K304::Unloadable", $HASH\) called at /m,
    'the hash form: connect() shows the hash by its address';
  is_deeply \%info, { dsn => $DSN, user => $USER, password => $AS_ARG },
    'the hash form: looking for the password leaves the hash as it was';

  # ... and the caller's frame is masked from it all the same
  $trace = trace_of { hash_from_password($AS_ARG) };
  no_secret($trace, 'the hash form, the caller holding the password');
  like $trace, qr/^\tmain::hash_from_password\("\*\*\*"\) called at /m,
    'the hash form, the caller holding the password: masked as the same value';

  # ... and when the caller has Carp spell references out
  local $Carp::RefArgFormatter = sub {
    my $ref = shift;
    return overload::StrVal($ref) unless ref $ref eq 'HASH';
    return '{ ' . join(', ', map { "$_ => '$ref->{$_}'" } sort keys %$ref) . ' }';
  };
  $trace = trace_of { T::K304::Unloadable->connect({ dsn => $DSN, user => $USER, password => $AS_ARG }) };
  no_secret($trace, 'the hash form, references spelled out by $Carp::RefArgFormatter');
  like $trace, qr/\{ dsn => '\Q$DSN\E', password =\*\*\*, user => '\Q$USER\E' \}/,
    'the hash form, references spelled out: the key, the DSN and the user name stand';
}

# ---------------------------------------------------------------------------
# 6. After the connect.
# ---------------------------------------------------------------------------
sub fail_later       { $_[0]->storage->throw_exception('k304 fails after the connect') }
sub connect_and_fail { my $schema = T::K304::Connected->connect(@_); $schema->stacktrace(1); fail_later($schema) }
{
  my $schema = T::K304::Connected->connect(@DBI);
  isa_ok $schema->storage, 'DBIO::Test::Storage', 'a connected schema: its storage';
  $schema->stacktrace(1);

  my $trace = trace_of { fail_later($schema, 'k304-plain-argument', 42) };
  no_secret($trace, 'after the connect');
  like $trace, qr/k304 fails after the connect at /, 'after the connect: the exception of the storage call';
  like $trace, qr/^\tmain::fail_later\(T::K304::Connected=$HASH, "k304-plain-argument", 42\) called at $FILE line \d+$/m,
    'after the connect: the frame of the caller with its arguments';
  unlike $trace, qr/\*\*\*/, 'after the connect: nothing to mask, nothing masked';

  # the connect frames are gone, the frame that called connect() is not
  $trace = trace_of { connect_and_fail(@DBI) };
  no_secret($trace, 'after the connect, in the frame that connected');
  like $trace, qr/^\tmain::connect_and_fail\("\Q$DSN\E", "\Q$USER\E", "\*\*\*"\) called at /m,
    'after the connect, in the frame that connected: the password it still holds is masked';
}

# ---------------------------------------------------------------------------
# 7. The other places that write a trace.
# ---------------------------------------------------------------------------

# -- DBIO::Exception->throw with a stack trace, no schema anywhere -------------
# What DBIO::Util's own checks throw with ('with_stacktrace').
sub throws_with_trace  { DBIO::Exception->throw('k304 thrown without a schema', 1) }
sub holds_connect_info { throws_with_trace() }
{
  my $trace = trace_of { holds_connect_info(@DBI) };
  no_secret($trace, 'DBIO::Exception->throw with a stack trace');
  like $trace, qr/^\tmain::holds_connect_info\("\Q$DSN\E", "\Q$USER\E", "\*\*\*"\) called at $FILE line \d+$/m,
    'DBIO::Exception->throw with a stack trace: the frame holding the connect info, the password masked';
}

# -- DBIO::Carp: no callsite outside the skipped namespaces -------------------
# carp() names the first callsite outside the namespaces it skips. When every
# frame is inside them the whole stack is the callsite -- with the arguments.
{
  package DBIO::K304Probe::Carping;
  use base 'DBIO::Base';
  use DBIO::Carp;
  sub connection {
    my $self = shift;
    carp 'k304 warns while connecting';
    return $self->next::method(@_);
  }

  package DBIO::K304Probe::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('+DBIO::K304Probe::Carping');
  __PACKAGE__->storage_type('+DBIO::Test::Storage');
}
{
  my @warned;
  {
    package DBIO::K304Probe;    # a namespace DBIO::Carp skips, and no frame of main:: above it
    local $SIG{__WARN__} = sub { push @warned, @_ };
    DBIO::K304Probe::Schema->connect(@DBI);
  }

  is scalar @warned, 1, 'DBIO::Carp without a callsite: one warning' or diag explain \@warned;
  like $warned[0], qr/k304 warns while connecting/, 'DBIO::Carp without a callsite: the warning of the component';
  no_secret($warned[0], 'DBIO::Carp without a callsite');
  like $warned[0], qr/^\tDBIO::K304Probe::Carping::connection\(DBIO::K304Probe::Schema=$HASH, "\Q$DSN\E", "\Q$USER\E", "\*\*\*"\) called at /m,
    'DBIO::Carp without a callsite: connection() with the password masked';
}

# -- emit_loud_diag -----------------------------------------------------------
{
  package T::K304::Loud;
  use base 'DBIO::Base';
  our %DIAG;
  sub connection {
    my $self = shift;
    DBIO::Util::emit_loud_diag(%DIAG);
    return $self->next::method(@_);
  }

  package T::K304::LoudSchema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('+T::K304::Loud');
  __PACKAGE__->storage_type('+DBIO::Test::Storage');
}
for my $confess (0, 1) {
  my $how = $confess ? 'emit_loud_diag, confessing' : 'emit_loud_diag';
  local %T::K304::Loud::DIAG = (msg => "k304 loud diagnostic $confess", confess => $confess);

  my $printed = '';
  my $died = do {
    open my $capture, '>', \$printed or die "cannot capture STDERR: $!";
    local *STDERR = $capture;
    trace_of { T::K304::LoudSchema->connect(@DBI) };
  };

  like $printed, qr/k304 loud diagnostic $confess/, "$how: the diagnostic is printed";
  no_secret($printed, "$how, what it prints");
  like $printed, qr/^\tDBIO::Schema::connect\("T::K304::LoudSchema", "\Q$DSN\E", "\Q$USER\E", "\*\*\*"\) called at $FILE line \d+$/m,
    "$how, what it prints: connect() with the password masked";

  if ($confess) {
    no_secret($died, "$how, what it dies with");
    like $died, qr/^\tDBIO::Schema::connect\("T::K304::LoudSchema", "\Q$DSN\E", "\Q$USER\E", "\*\*\*"\) called at $FILE line \d+$/m,
      "$how, what it dies with: connect() with the password masked";
  }
  else {
    is $died, undef, "$how: does not die";
  }
}

# -- a scope guard that dies ---------------------------------------------------
{
  package T::K304::Guarded;
  use base 'DBIO::Base';
  sub connection {
    my $self = shift;
    { my $guard = DBIO::Util::scope_guard { die "k304 guard dies\n" }; }
    return $self->next::method(@_);
  }

  package T::K304::GuardedSchema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('+T::K304::Guarded');
  __PACKAGE__->storage_type('+DBIO::Test::Storage');
}
{
  my @warned;
  {
    local $SIG{__WARN__} = sub { push @warned, @_ };
    T::K304::GuardedSchema->connect(@DBI);
  }

  is scalar @warned, 1, 'a scope guard that dies: one warning' or diag explain \@warned;
  like $warned[0], qr/Execution of scope guard .* resulted in the non-trappable exception:\s+k304 guard dies/,
    'a scope guard that dies: the warning about it';
  no_secret($warned[0], 'a scope guard that dies');
  like $warned[0], qr/^\tT::K304::Guarded::connection\(T::K304::GuardedSchema=$HASH, "\Q$DSN\E", "\Q$USER\E", "\*\*\*"\) called at /m,
    'a scope guard that dies: connection() with the password masked';
}

# -- the exception_action panic -----------------------------------------------
# A handler that leaves throw_exception by a jump: DBIO can only say so, and
# says it with the stack the handler cut off -- to STDERR, past any handler.
{
  package T::K304::Jumping;
  use base 'DBIO::Schema';
  __PACKAGE__->storage_type('+T::K304::NoSuchStorage');
  __PACKAGE__->exception_action(sub { no warnings 'exiting'; last K304_JUMPED });
}
{
  my $printed = '';
  {
    open my $capture, '>', \$printed or die "cannot capture STDERR: $!";
    local *STDERR = $capture;
    K304_JUMPED: { T::K304::Jumping->connect(@DBI) }
  }

  like $printed, qr/DBIO INTERNAL PANIC/, 'the exception_action panic: printed';
  no_secret($printed, 'the exception_action panic');
  like $printed, qr/^\tDBIO::Schema::connect\("T::K304::Jumping", "\Q$DSN\E", "\Q$USER\E", "\*\*\*"\) called at $FILE line \d+$/m,
    'the exception_action panic: connect() with the password masked';
}

# ---------------------------------------------------------------------------
# 8. What is left alone.
# ---------------------------------------------------------------------------

# -- only arguments -----------------------------------------------------------
# The password is replaced wherever an ARGUMENT repeats it, as k297 does in a
# message; the names of the frames, the files and the message are no arguments.
{
  my $trace = trace_of { T::K304::Unloadable->connect($DSN, $USER, 'Schema') };
  like $trace, qr/^\tDBIO::Schema::connect\("T::K304::Unloadable", "\Q$DSN\E", "\Q$USER\E", "\*\*\*"\) called at $FILE line \d+$/m,
    'a password that is part of a frame name: the argument is masked, the frame name stands';
  like $trace, qr/^\tDBIO::Schema::connection\(.* called at \S*Schema\.pm line \d+$/m,
    'a password that is part of a file name: the file name stands';
}

# -- a password that is not told apart -----------------------------------------
# k297 masks the password wherever the text repeats it, however short it is and
# whatever else has the same value. The same here: rather too much than a leak.
{
  my $trace = trace_of { T::K304::Unloadable->connect($DSN, 'k304-secret-same', 'k304-secret-same') };
  no_secret($trace, 'a password that is the user name too');
  like $trace, qr/^\tDBIO::Schema::connect\("T::K304::Unloadable", "\Q$DSN\E", "\*\*\*", "\*\*\*"\) called at /m,
    'a password that is the user name too: both are masked';

  $trace = trace_of { T::K304::Unloadable->connect($DSN, $USER, 'p') };
  like $trace, qr/^\tDBIO::Schema::connect\("T::K304::Unloadable", "dbi:K304:dbname=a\*\*\*\*\*\*;host=db\.exam\*\*\*le", "\Q$USER\E", "\*\*\*"\) called at $FILE line \d+$/m,
    'a password of one character: masked wherever an argument repeats it, the frame stands';
}

# -- an empty password, none at all --------------------------------------------
for my $none ([ 'an empty password', '', '""' ], [ 'no password', undef, 'undef' ]) {
  my ($what, $password, $shown) = @$none;
  my $trace = trace_of { T::K304::Unloadable->connect($DSN, $USER, $password) };
  like $trace, qr/^\tDBIO::Schema::connect\("T::K304::Unloadable", "\Q$DSN\E", "\Q$USER\E", $shown\) called at /m,
    "$what: the arguments as they were";
  unlike $trace, qr/\*\*\*/, "$what: nothing masked";
}

# -- without a stack trace ------------------------------------------------------
{
  my $message = trace_of { T::K304::Quiet->connect(@DBI) };
  like $message,
    qr/\A\S.*Unable to load storage class T::K304::NoSuchStorage: .*Can't locate T\/K304\/NoSuchStorage\.pm .* at $FILE line \d+\n\z/s,
    'without a stack trace: the message with the callsite, as before';
  unlike $message, qr/\bcalled at\b|\*\*\*/, 'without a stack trace: no frames, nothing masked';
  unlike $message, $SECRET, 'without a stack trace: no password';
}

# -- DBIO installs nothing in Carp ----------------------------------------------
# A trace DBIO did not write is Carp's own business, before and after.
sub carp_itself  { carps_for_real(@_) }
sub carps_for_real { Carp::longmess('k304 carps itself') }
{
  my $format_arg = \&Carp::format_arg;
  my $trace = trace_of { T::K304::Unloadable->connect(@DBI) };
  no_secret($trace, 'a trace of DBIO');

  is \&Carp::format_arg, $format_arg, 'after a trace of DBIO: Carp formats arguments with what it did before';
  like carp_itself('k304-not-a-dbio-trace', @DBI),
    qr/^\tmain::carp_itself\("k304-not-a-dbio-trace", "\Q$DSN\E", "\Q$USER\E", "\Q$AS_ARG\E"\) called at /m,
    'a trace DBIO did not write: untouched';
}

done_testing;
