# ABSTRACT: DBIO builds its stack traces itself, and masks connect secrets while it does
use strict;
use warnings;

BEGIN { $ENV{DBIO_TRACE} = 0 }

use Test::More;

use Carp ();
use DBIO::Carp ();
use DBIO::Util ();
use DBIO::Base;
use DBIO::Exception;
use DBIO::Schema;
use DBIO::Test::Storage;

# OFFLINE (karr k311, maintainer's decision (b)). Until k311 the core made Carp
# mask the connect secrets of a trace by replacing Carp::format_arg -- a
# function Carp does not document -- for as long as Carp wrote. Now the core
# builds the trace itself, from caller(), and never touches a symbol of Carp:
#
#   DBIO::Util::masked_longmess / masked_confess / masked_cluck
#
# What this file claims:
#   1. Parity. For input without a secret the three functions write what
#      Carp::longmess / confess / cluck write: the same message, the same
#      frames, the same arguments (numbers, escapes, cuts, undef, references,
#      more than $Carp::MaxArgNums, eval frames), and they obey the same
#      documented variables ($Carp::CarpLevel, %Carp::Internal,
#      %Carp::CarpInternal, $Carp::MaxArgLen, ...). That equality is what lets
#      mask_connect_secrets read the traces Carp writes of its own accord.
#   2. A trace DBIO writes never names a connect password -- not even with
#      $Carp::Verbose on, which Carp's own traces obey and these do not.
#   3. The build is independent of Carp::format_arg: a replacement of it is not
#      called, and its text is not in a trace of the core.
#   4. The three functions are exportable.
#
# No database, no real password: the secrets are marker strings.

my $SECRET = qr/k311-secret/;
my $PASSWORD = 'k311-secret-as-argument';
my $USER   = 'k311-user';
my $DSN    = 'dbi:K311:dbname=app;host=db.example';
my @DBI    = ($DSN, $USER, $PASSWORD);
my $FILE   = quotemeta __FILE__;
my $HASH   = qr/HASH\(0x[0-9a-f]+\)/;

# ---------------------------------------------------------------------------
# 1. Parity with Carp
# ---------------------------------------------------------------------------

# Both are called from this one line, so that a trace has the same frames and
# the same lines either way.
sub W {
  my ($kind, $which, @msg) = @_;
  if ($kind eq 'longmess') {
    return $which eq 'real' ? Carp::longmess(@msg) : DBIO::Util::masked_longmess(@msg);
  }
  if ($kind eq 'confess') {
    eval { $which eq 'real' ? Carp::confess(@msg) : DBIO::Util::masked_confess(@msg) };
    return $@;
  }
  my $warned;
  local $SIG{__WARN__} = sub { $warned .= shift };
  $which eq 'real' ? Carp::cluck(@msg) : DBIO::Util::masked_cluck(@msg);
  return $warned;
}

# $body gets the function to call, once for Carp and once for DBIO, from the
# same code and the same line.
sub same_as_carp {
  my ($name, $body, @kinds) = @_;
  for my $kind (@kinds ? @kinds : qw(longmess confess cluck)) {
    my ($carp, $dbio) = map {
      my $which = $_;
      my $f = sub { W($kind, $which, @_) };
      $body->($f);
    } qw(real mine);

    # what differs by nature: the addresses, the name W is called with, the
    # number of an eval
    s/0x[0-9a-f]+/0xADDR/g, s/"(?:real|mine)"/"WHICH"/g, s/\(eval \d+\)/(eval N)/g
      for grep { defined } $carp, $dbio;

    ok defined $carp && length $carp, "$kind, $name: Carp wrote a trace" or next;
    is $dbio, $carp, "$kind, $name: the trace is the one Carp writes";
  }
}

my $object = bless {}, 'Some::Class';
{
  package Some::Class;
  sub method { $_[1]->('from a method') }
}

same_as_carp 'one frame' => sub { $_[0]->('msg') };

same_as_carp 'nested frames with numbers' => sub {
  my $f = shift;
  my $inner = sub { $_[0]->('msg') };
  my $outer = sub { $inner->(@_) };
  $outer->($f, 1, 2.5, -3, 1e5, '007', ' 1', 'a');
};

same_as_carp 'strings with escapes' => sub {
  my $f = shift;
  my $c = sub { $_[0]->('msg') };
  $c->($f, "a\"b\\c\$d\@e", "tab\there", "uni\x{263a}", "caf\xe9", undef, '', "new\nline");
};

same_as_carp 'long strings' => sub {
  my $f = shift;
  my $c = sub { $_[0]->('msg') };
  $c->($f, 'y' x 200, 'z' x 64, 'w' x 65, 'v' x 66);
};

same_as_carp 'references' => sub {
  my $f = shift;
  my $c = sub { $_[0]->('msg') };
  $c->($f, [1], { a => 1 }, $object, \'x', sub { 1 }, qr/ab"c/);
};

same_as_carp 'more arguments than $Carp::MaxArgNums' => sub {
  my $f = shift;
  my $c = sub { $_[0]->('msg') };
  $c->($f, 1 .. 20);
};

same_as_carp 'eval frames' => sub {
  my $f = shift;
  my $c = sub { eval { $_[0]->('msg') } // $@ };
  my $r = eval { $c->($f, 'e') };
  $r;
};

same_as_carp 'string eval' => sub {
  my $f = shift;
  my $r = eval q{ sub { $_[0]->('msg') }->($f, 'q') };
  $r;
};

same_as_carp 'a method call' => sub {
  my $f = shift;
  $object->method($f);
};

same_as_carp 'a frame without arguments' => sub {
  my $f = shift;
  my $c = sub { $f->('msg') };
  &$c;
};

same_as_carp 'a message in several parts' => sub {
  my $f = shift;
  my $c = sub { $_[0]->('a', 'b', 3) };
  $c->($f);
};

{
  local $Carp::MaxEvalLen = 10;
  same_as_carp 'a string eval cut at $Carp::MaxEvalLen' => sub {
    my $f = shift;
    my $r = eval q{ sub { $_[0]->('msg') }->($f, 'q'); };
    $r;
  };
}

{
  local $Carp::MaxArgLen = 10;
  local $Carp::MaxArgNums = 3;
  same_as_carp 'short $Carp::MaxArgLen and $Carp::MaxArgNums' => sub {
    my $f = shift;
    my $c = sub { $_[0]->('msg') };
    $c->($f, 'abcdefghijklmnop', 2, 3, 4, 5);
  };
}

{
  local $Carp::MaxArgLen = 0;
  local $Carp::MaxArgNums = 0;
  same_as_carp 'no limits' => sub {
    my $f = shift;
    my $c = sub { $_[0]->('msg') };
    $c->($f, 'a' x 100, 1 .. 12);
  };
}

{
  local $Carp::RefArgFormatter = sub { 'REF<' . ref($_[0]) . '>' };
  same_as_carp '$Carp::RefArgFormatter' => sub {
    my $f = shift;
    my $c = sub { $_[0]->('msg') };
    $c->($f, [1], $object);
  };
}

for my $level (1, 2) {
  local $Carp::CarpLevel = $level;
  same_as_carp "\$Carp::CarpLevel = $level" => sub {
    my $f = shift;
    my $inner = sub { $_[0]->('msg') };
    my $outer = sub { $inner->(@_) };
    $outer->($f, 'c');
  };
}

# Past the bottom of the stack Carp's confess and cluck show their own frame;
# the DBIO functions have no frame of Carp to show and stay at the call.
{
  local $Carp::CarpLevel = 20;
  same_as_carp '$Carp::CarpLevel past the stack' => sub {
    my $f = shift;
    my $c = sub { $_[0]->('msg') };
    $c->($f, 'c');
  }, 'longmess';
}

{
  package T::K311::Marked;
  sub outer { inner(@_) }
  sub inner { $_[0]->('msg') }
}
{
  local $Carp::Internal{'T::K311::Marked'} = 1;
  same_as_carp 'from a package marked %Carp::Internal' => sub { T::K311::Marked::outer(@_, 'i') };
}
{
  local $Carp::CarpInternal{'T::K311::Marked'} = 1;
  same_as_carp 'from a package marked %Carp::CarpInternal' => sub { T::K311::Marked::outer(@_, 'i') };
}

{
  open my $fh, '<', $0 or die "cannot read $0: $!";
  my $line = <$fh>;
  same_as_carp 'the last read handle: line' => sub {
    my $f = shift;
    my $c = sub { $_[0]->('msg') };
    $c->($f, 'h');
  };

  local $/ = \5;
  $line = <$fh>;
  same_as_carp 'the last read handle: chunk' => sub {
    my $f = shift;
    my $c = sub { $_[0]->('msg') };
    $c->($f, 'h');
  };
}

# a reference is no message
for my $kind (qw(longmess confess)) {
  my $ref = [ 'k311' ];
  my $back = $kind eq 'longmess'
    ? DBIO::Util::masked_longmess($ref)
    : do { eval { DBIO::Util::masked_confess($ref) }; $@ };
  is $back, $ref, "$kind: a reference as the message comes back as it is";
}

# $Carp::Verbose is Carp's own: a longmess is long anyway
{
  my ($with, $without) = map { local $Carp::Verbose = $_; DBIO::Util::masked_longmess('k311') } 1, 0;
  is $with, $without, '$Carp::Verbose changes nothing in a trace DBIO builds';
}

# ---------------------------------------------------------------------------
# 2. A trace DBIO writes never names the password, $Carp::Verbose or not
# ---------------------------------------------------------------------------
{
  package T::K311::Unloadable;
  use base 'DBIO::Schema';
  __PACKAGE__->storage_type('+T::K311::NoSuchStorage');
  __PACKAGE__->stacktrace(1);

  package T::K311::Loud;
  use base 'DBIO::Base';
  our %DIAG;
  sub connection {
    my $self = shift;
    DBIO::Util::emit_loud_diag(%DIAG);
    return $self->next::method(@_);
  }

  package T::K311::LoudSchema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('+T::K311::Loud');
  __PACKAGE__->storage_type('+DBIO::Test::Storage');

  package T::K311::Guarded;
  use base 'DBIO::Base';
  sub connection {
    my $self = shift;
    { my $guard = DBIO::Util::scope_guard { die "k311 guard dies\n" }; }
    return $self->next::method(@_);
  }

  package T::K311::GuardedSchema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('+T::K311::Guarded');
  __PACKAGE__->storage_type('+DBIO::Test::Storage');

  package T::K311::Jumping;
  use base 'DBIO::Schema';
  __PACKAGE__->storage_type('+T::K311::NoSuchStorage');
  __PACKAGE__->exception_action(sub { no warnings 'exiting'; last K311_JUMPED });

  package DBIO::StackProbe::Carping;
  use base 'DBIO::Base';
  use DBIO::Carp;
  sub connection {
    my $self = shift;
    carp 'k311 warns while connecting';
    return $self->next::method(@_);
  }

  package DBIO::StackProbe::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('+DBIO::StackProbe::Carping');
  __PACKAGE__->storage_type('+DBIO::Test::Storage');
}

sub throws_with_trace  { DBIO::Exception->throw('k311 thrown without a schema', 1) }
sub holds_connect_info { throws_with_trace() }

sub trace_of (&) {
  my $code = shift;
  my $lived = eval { $code->(); 1 };
  return $lived ? undef : "$@";
}

# every site of the core that writes a trace, as a closure that returns it
my %SITES = (
  'a stacktrace(1) exception' => sub {
    trace_of { T::K311::Unloadable->connect(@DBI) };
  },
  'DBIO::Exception->throw with a stack trace' => sub {
    trace_of { holds_connect_info(@DBI) };
  },
  'emit_loud_diag' => sub {
    local %T::K311::Loud::DIAG = (msg => 'k311 loud diagnostic', confess => 0, emit_dups => 1);
    my $printed = '';
    {
      open my $capture, '>', \$printed or die "cannot capture STDERR: $!";
      local *STDERR = $capture;
      T::K311::LoudSchema->connect(@DBI);
    }
    $printed;
  },
  'emit_loud_diag, confessing' => sub {
    local %T::K311::Loud::DIAG = (msg => 'k311 loud confess', confess => 1);
    my $printed = '';
    my $died = do {
      open my $capture, '>', \$printed or die "cannot capture STDERR: $!";
      local *STDERR = $capture;
      trace_of { T::K311::LoudSchema->connect(@DBI) };
    };
    $died . $printed;
  },
  'a scope guard that dies' => sub {
    my @warned;
    {
      local $SIG{__WARN__} = sub { push @warned, @_ };
      T::K311::GuardedSchema->connect(@DBI);
    }
    join '', @warned;
  },
  'the exception_action panic' => sub {
    my $printed = '';
    {
      open my $capture, '>', \$printed or die "cannot capture STDERR: $!";
      local *STDERR = $capture;
      K311_JUMPED: { T::K311::Jumping->connect(@DBI) }
    }
    $printed;
  },
  'DBIO::Carp with the whole stack as callsite' => sub {
    my @warned;
    {
      package DBIO::StackProbe;
      local $SIG{__WARN__} = sub { push @warned, @_ };
      DBIO::StackProbe::Schema->connect(@DBI);
    }
    join '', @warned;
  },
);

for my $verbose (0, 1) {
  for my $site (sort keys %SITES) {
    my $what = "$site, \$Carp::Verbose = $verbose";
    local $Carp::Verbose = $verbose;
    # The sites are called from a DBIO package: a carp names the place of the
    # caller outside DBIO, and only where there is none does it write the whole
    # stack. A call from main would be that place.
    my $trace = do { package DBIO::StackProbe; $SITES{$site}->() };

    ok defined $trace && $trace =~ /\bcalled at\b/, "$what: there is a stack trace" or diag $trace;
    unlike $trace, $SECRET, "$what: ... without the password";
    like $trace, qr/\Q$DSN\E", "\Q$USER\E", "\*\*\*"/, "$what: the connect info stands, the password masked";
  }
}

# the functions themselves, from a frame that holds the connect info
{
  sub holder { deeper(@_) }
  sub deeper { DBIO::Util::masked_longmess('k311 by hand') }
  my $trace = holder(@DBI);
  like $trace, qr/\Ak311 by hand at $FILE line \d+\.\n/, 'masked_longmess: the message and the place';
  like $trace, qr/^\tmain::holder\("\Q$DSN\E", "\Q$USER\E", "\*\*\*"\) called at $FILE line \d+$/m,
    'masked_longmess: a frame holding connect info has the password masked';

  sub confesser { DBIO::Util::masked_confess('k311 confesses') }
  my $died = trace_of { confesser(@DBI) };
  like $died, qr/\Ak311 confesses at $FILE line \d+\.\n\tmain::confesser\("\Q$DSN\E", "\Q$USER\E", "\*\*\*"\) called at /,
    'masked_confess: dies with the trace, its own frame the first, the password masked';

  sub clucker { DBIO::Util::masked_cluck('k311 clucks') }
  my @warned;
  {
    local $SIG{__WARN__} = sub { push @warned, @_ };
    clucker(@DBI);
  }
  is scalar @warned, 1, 'masked_cluck: warns once';
  like $warned[0], qr/\Ak311 clucks at $FILE line \d+\.\n\tmain::clucker\("\Q$DSN\E", "\Q$USER\E", "\*\*\*"\) called at /,
    'masked_cluck: the warning has the trace, the password masked';

  sub sql_holder { sql_deeper(@_) }
  sub sql_deeper { DBIO::Util::masked_longmess('k311 sql') }
  like sql_holder('SELECT 1 FROM t WHERE password = ?', @DBI),
    qr/^\tmain::sql_holder\("SELECT 1 FROM t WHERE password = \*\*\*", "\Q$DSN\E", "\Q$USER\E", "\*\*\*"\)/m,
    'an SQL statement among the arguments reads "password = ***" (documented)';
}

# ---------------------------------------------------------------------------
# 3. The build does not go through Carp::format_arg
# ---------------------------------------------------------------------------
{
  no warnings 'redefine';
  my $called = 0;
  local *Carp::format_arg = sub { $called++; 'CARP-FORMAT-ARG-USED' };

  for my $site (sort keys %SITES) {
    my $trace = $SITES{$site}->();
    ok defined $trace && length $trace, "$site: a trace is written";
    unlike $trace, qr/CARP-FORMAT-ARG-USED/, "$site: Carp::format_arg did not write it";
  }

  my $by_hand = holder(@DBI);
  unlike $by_hand, qr/CARP-FORMAT-ARG-USED/, 'masked_longmess: Carp::format_arg did not write it';
  like $by_hand, qr/main::holder\("\Q$DSN\E"/, 'masked_longmess: the arguments are formatted by DBIO';
  is $called, 0, 'the core never called Carp::format_arg';
}

# ---------------------------------------------------------------------------
# 4. Exportable
# ---------------------------------------------------------------------------
{
  package T::K311::Importer;
  use DBIO::Util qw(masked_longmess masked_confess masked_cluck);
}
for my $name (qw(masked_longmess masked_confess masked_cluck)) {
  ok( T::K311::Importer->can($name), "$name is exportable" );
  is \&{"T::K311::Importer::$name"}, \&{"DBIO::Util::$name"}, "$name is the function of DBIO::Util";
}

done_testing;
