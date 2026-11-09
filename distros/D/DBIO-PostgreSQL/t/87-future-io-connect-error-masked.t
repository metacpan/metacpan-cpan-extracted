use strict;
use warnings;
use Test::More;

# OFFLINE test: a connection the future_io transport cannot open is reported
# without its password (karr k111; core k297 for the sync storage).
#
# WHY: the message about a connection that cannot be opened ends where nobody
# guards it -- a log, a bug report, the exception page of a web application.
# This transport opens its connections with a DBI->connect of its own
# (_pg_connect: every pool connection, and the dedicated listen connection),
# so core's masking of DBIO::Storage::DBI::_connect never sees them. And the
# password is in what comes back, from two writers:
#   * DBI. It dies with "DBI connect('<dsn>','<user>',...) failed: ..." under
#     the RaiseError this transport sets, and a DSN may carry password=...;
#   * libpq. It quotes what it could not read, and what it reads is the string
#     DBD::Pg makes of all of it: a postgresql:// URI whole, user:password@
#     included, and behind it the user='...' password='...' DBD::Pg appends --
#     the third argument of the connect, or the Password attribute, which DBI
#     takes in its place.
# Both reach the caller of a pooled statement, the Future of a listen and
# on_listen_error -- on every reconnect attempt again.
#
# What this file claims, for each of the two ways a connect fails here --
# DBI dies itself (the usual one), and DBI->connect answers false (a
# HandleError among the connect attributes that swallowed the error):
#   1. the password is not in the exception, wherever it was given: in the
#      DSN, as the third argument, as the Password attribute;
#   2. the rest is: whose message it is, the DSN without the secret, the user,
#      and libpq's reason. A message that says nothing would hide the password
#      as well;
#   3. that holds where the message arrives, not only where it is made: the
#      pool's Future, the listen Future, and on_listen_error on the first
#      attempt and on the reconnect after it;
#   4. the transport hands the masker the whole connect info, not only the
#      text: a password that stands in the message without a key in front of
#      it is masked too. Under Carp's verbose mode DBI's die is a stack trace,
#      and the frame of DBI->connect shows the third argument that way.
#
# WHAT RUNS FOR REAL in 1-3 and the first half of 4: everything -- this
# dist's _pg_connect, pool and listen seams, core's listen machinery,
# dbio-async's backoff timer, DBI, DBD::Pg and libpq. No server is reached: a
# connect goes to a unix socket directory that does not exist and fails in
# connect(2), or libpq refuses the string before it opens a socket.
# THE SUBSTITUTION, in the second half of 4 only: DBI->connect is a stand-in
# that fails the two ways with a message repeating the password bare. Nothing
# real shows a Password attribute that way, or either password in the error
# of a connect that answered false.

BEGIN {
  eval { require DBIO::PostgreSQL::Storage::Async; 1 }
    or plan skip_all =>
      'DBIO::Async not installed (recommends only) -- future_io transport unavailable';
}

use DBI;
use DBD::Pg;
use Future::IO;
use Time::HiRes ();

my $ASYNC = 'DBIO::PostgreSQL::Storage::Async';

# A unix socket directory that does not exist: the only place a connection of
# this file may be tried at.
my $DEAD = '/nonexistent/dbio-postgresql-k111';
plan skip_all => "$DEAD exists on this machine" if -e $DEAD;

# libpq reads its environment for what a connection string leaves out, so none
# of it is there.
delete @ENV{ grep { /^PG/ } keys %ENV };

alarm 60;

# Each secret in pieces: a message that kept half a password has not hidden it.
my %SECRET = (
  dsn    => [ 'dsn-s3cret-k111' ],
  quoted => [ 'quoted-s3cret', 'k111-behind-the-semicolon' ],
  arg    => [ 'arg-s3cret-k111' ],
  attr   => [ 'attr-s3cret-k111' ],
);

# libpq's reason, by what no locale translates: the socket it tried, or the
# string it could not read.
my $SOCKET_TRIED = qr{\Q$DEAD\E/\.s\.PGSQL\.\d+};
my $URI_REFUSED  = qr{"postgresql://app(?::\*\*\*)?\@\[::1/appdb};

my @CASES = (
  {
    label    => 'a password in the DSN',
    conninfo => { dsn => "dbi:Pg:host=$DEAD;dbname=appdb;password=$SECRET{dsn}[0]", user => 'app' },
    secrets  => [qw( dsn )],
    dsn_kept => qr/\Q'host=$DEAD;dbname=appdb;password=***'\E/,
    reason   => $SOCKET_TRIED,
  },
  {
    label    => q{a quoted password in the DSN, with a blank and a ';' in it},
    conninfo => {
      dsn  => "dbi:Pg:host=$DEAD;password='$SECRET{quoted}[0] ;$SECRET{quoted}[1]';dbname=appdb",
      user => 'app',
    },
    secrets  => [qw( quoted )],
    dsn_kept => qr/\Q'host=$DEAD;password=***;dbname=appdb'\E/,
    reason   => $SOCKET_TRIED,
  },
  {
    label    => 'a password in a URI libpq cannot read, and one as the third argument',
    conninfo => {
      dsn => "dbi:Pg:postgresql://app:$SECRET{dsn}[0]\@[::1/appdb", user => 'app',
      password => $SECRET{arg}[0],
    },
    secrets  => [qw( dsn arg )],
    dsn_kept => qr{\Q'postgresql://app:***\E\@\Q[::1/appdb'\E},
    reason   => qr/$URI_REFUSED user='app' password=\*\*\*"/,
  },
  {
    label    => 'a Password attribute, which DBI connects with in place of the third argument',
    conninfo => {
      dsn => 'dbi:Pg:postgresql://app@[::1/appdb', user => 'app',
      password => $SECRET{arg}[0], attrs => { Password => $SECRET{attr}[0] },
    },
    secrets  => [qw( arg attr )],
    dsn_kept => qr{\Q'postgresql://app\E\@\Q[::1/appdb'\E},
    reason   => qr/$URI_REFUSED user='app' password=\*\*\*"/,
  },
);

# The two ways a connect fails in _pg_connect. A HandleError that answers true
# has taken the error: DBI does not die then, DBI->connect answers false.
my @WAYS = (
  { name => 'DBI dies itself',           attrs => {},
    whose => qr/\ADBI connect\(/ },
  { name => 'DBI->connect answers false', attrs => { HandleError => sub { 1 } },
    whose => qr/\ADBD::Pg connect failed: / },
);

sub conninfo_for {
  my ($case, $way) = @_;
  my %conninfo = %{ $case->{conninfo} };
  $conninfo{attrs} = { %{ $conninfo{attrs} || {} }, %{ $way->{attrs} } };
  return \%conninfo;
}

# No piece of the secrets in play is in $text.
sub no_secret_in {
  my ($text, $case, $name) = @_;
  my @found = grep { index($text // '', $_) >= 0 } map { @{ $SECRET{$_} } } @{ $case->{secrets} };
  ok !@found, $name or diag "still in it: @found\nthe message: " . ($text // 'undef');
}

# ---------------------------------------------------------------------------
# 1 + 2. _pg_connect, the one DBI->connect of this transport.
# ---------------------------------------------------------------------------

for my $case (@CASES) {
  for my $way (@WAYS) {
    my $conn = eval { $ASYNC->_pg_connect(conninfo_for($case, $way)) };
    my $err  = $@;
    if ($conn) {
      $conn->{dbh}->disconnect;
      BAIL_OUT("a connection was opened for [$case->{label}] -- this file must never reach a server");
    }

    my $name = "$case->{label}, $way->{name}";
    like $err, $way->{whose}, "$name: the connect fails, in the words of who reported it";
    no_secret_in($err, $case, '... without the password');
    like $err, $case->{reason}, '... with libpq\'s reason';

    next unless $way->{name} eq 'DBI dies itself';
    like $err, $case->{dsn_kept}, '... with the DSN, its secret masked and nothing else';
    like $err, qr/,'app',\.\.\.\) failed: /, '... and with the user';
  }
}

# ---------------------------------------------------------------------------
# 3. Where the message arrives: the pool and the listen connection both open
#    through _pg_connect.
# ---------------------------------------------------------------------------

SKIP: for my $case (@CASES[ 0, 2 ]) {
  skip "Future::IO is bound to $Future::IO::IMPL; this part drives the built-in implementation", 1
    if defined $Future::IO::IMPL && $Future::IO::IMPL ne 'Future::IO::_DefaultImpl';

  my ($dsn, $user, $password) = @{ $case->{conninfo} }{qw( dsn user password )};
  my $s = $ASYNC->new(undef);
  $s->connect_info([ $dsn, $user, $password, { pool_size => 1 } ]);

  my @warned;
  local $SIG{__WARN__} = sub { push @warned, @_ };

  # the pool
  my $f = $s->pool->acquire;
  ok $f->is_failed, "$case->{label}: acquiring a pool connection fails";
  my ($pool_error) = $f->is_failed ? $f->failure : ();
  no_secret_in($pool_error, $case, '... without the password');
  like $pool_error, $case->{reason}, '... with libpq\'s reason';

  # the listen connection, and the reconnect after it
  my @heard;
  $s->on_listen_error(sub { push @heard, $_[1] });
  $s->listen_backoff_initial(0.01);
  $s->listen_backoff_max(0.01);

  my $listen = $s->listen(jobs => sub { });
  ok $listen->is_failed, 'listen fails';
  my ($listen_error) = $listen->is_failed ? $listen->failure : ();
  no_secret_in($listen_error, $case, '... without the password');
  like $listen_error, qr/\Aopening the listen connection failed: DBI connect\(/,
    '... in core\'s words and DBI\'s';
  like $listen_error, $case->{reason}, '... with libpq\'s reason';

  my $deadline = Time::HiRes::time() + 5;
  Future::IO->sleep(0.005)->get while @heard < 2 && Time::HiRes::time() < $deadline;
  $s->unlisten('jobs');

  cmp_ok scalar(@heard), '>=', 2, 'on_listen_error heard the first attempt and a reconnect';
  no_secret_in(join("\n", @heard), $case, '... none of them with the password');
  is scalar(grep { $_ =~ $case->{reason} } @heard), scalar(@heard),
    '... each with libpq\'s reason';

  no_secret_in(join('', @warned), $case, 'and nothing warned on the way carries the password');
}

# ---------------------------------------------------------------------------
# 4. The whole connect info goes to the masker: a password repeated bare.
# ---------------------------------------------------------------------------

{
  my $conninfo = {
    dsn => "dbi:Pg:host=$DEAD;dbname=appdb", user => 'app',
    password => $SECRET{arg}[0], attrs => { Password => $SECRET{attr}[0] },
  };
  my $case = { secrets => [qw( arg attr )] };
  my $told = "the driver could not log in as app with $SECRET{arg}[0] nor with $SECRET{attr}[0]";

  # For real: the trace Carp writes for DBI's die when it is asked for one.
  {
    local $Carp::Verbose = 1;
    my $conn = eval { $ASYNC->_pg_connect($conninfo) };
    my $err  = $@;
    if ($conn) {
      $conn->{dbh}->disconnect;
      BAIL_OUT('a connection was opened -- this file must never reach a server');
    }
    like $err, qr/^\s*DBI::connect\(.DBI., .\Qdbi:Pg:host=$DEAD;dbname=appdb\E., .app., /m,
      'DBI dies with a stack trace: the frame of DBI->connect is in it, with its arguments';
    no_secret_in($err, $case, '... without the password that is one of them');
    like $err, $SOCKET_TRIED, '... and with libpq\'s reason';
  }

  no warnings 'redefine';

  {
    local *DBI::connect = sub { die "$told\n" };
    my $conn = eval { $ASYNC->_pg_connect($conninfo) };
    my $err  = $@;
    ok !$conn, 'a DBD that dies repeating the password bare: the connect fails';
    no_secret_in($err, $case, '... without the password, as third argument or as Password attribute');
    is $err, "the driver could not log in as app with *** nor with ***\n",
      '... and with everything else it said';
  }

  {
    my $drh = DBI->install_driver('Pg');
    # set_err appends to an error the handle still holds: start from none.
    local *DBI::connect = sub { $drh->set_err(undef, undef); $drh->set_err(1, $told); return };
    my $conn = eval { $ASYNC->_pg_connect($conninfo) };
    my $err  = $@;
    ok !$conn, 'a DBD that answers false, its error repeating the password bare: the connect fails';
    no_secret_in($err, $case, '... without the password, as third argument or as Password attribute');
    is $err, "DBD::Pg connect failed: the driver could not log in as app with *** nor with ***\n",
      '... and with everything else it said';
  }
}

done_testing;
