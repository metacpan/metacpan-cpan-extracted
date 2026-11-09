use strict;
use warnings;
use Test::More;

# OFFLINE test: a connection the future_io transport cannot open is reported
# without its password (karr k76; core k297 for the sync storage).
#
# WHY: the message about a connection that cannot be opened ends where nobody
# guards it -- a log, a bug report, the exception page of a web application.
# This transport opens its connections with a DBI->connect of its own
# (_mysql_connect: every pool connection, and the dedicated listen connection),
# so core's masking of DBIO::Storage::DBI::_connect never sees them. DBI dies
# with "DBI connect('<dsn>','<user>',...) failed: ..." under the RaiseError this
# transport sets, and a DSN may carry password=... (hand-written, or an
# AccessBroker's answer). The password is the third argument of the connect
# or the Password attribute too, where a stack trace or a DBD's own message can
# repeat it. All of it reaches the caller of a pooled statement, the Future of
# a listen and on_listen_error -- on every reconnect attempt again.
#
# What this file claims, for DBD::mysql and DBD::MariaDB, and for each of the
# two ways a connect fails here -- DBI dies itself (the usual one), and
# DBI->connect answers false (a HandleError among the connect attributes that
# swallowed the error):
#   1. the password is not in the exception, wherever it was given;
#   2. the rest is: whose message it is, the DSN without the secret, the user,
#      and the DBD's reason. A message that says nothing would hide the
#      password as well;
#   3. that holds where the message arrives, not only where it is made: the
#      pool's Future, the listen Future, and on_listen_error on the first
#      attempt and on the reconnect after it;
#   4. the transport hands the masker the whole connect info, not only the
#      text: a password that stands in the message without a key in front of
#      it is masked too.
# A flavour whose DBD is not installed is skipped.
#
# WHAT RUNS FOR REAL in 1-3 and the first half of 4: this dist's
# _mysql_connect, pool and listen seams, core's listen machinery, dbio-async's
# backoff timer, DBI and the real DBD. No server is reached: a connect goes to
# a unix socket that does not exist and fails in connect(2).
# THE SUBSTITUTION, in the second half of 4 only: DBI->connect is a stand-in
# that fails the two ways with a message repeating the password bare, which
# nothing real shows for a Password attribute.

BEGIN {
  eval {
    require DBIO::MySQL::Storage::Async;
    require DBIO::MySQL::Storage::MariaDB::Async;
    1;
  } or plan skip_all =>
    'DBIO::Async not installed (recommends only) -- future_io transport unavailable';
  plan skip_all => 'the installed DBIO core predates DBIO::Util::mask_connect_secrets'
    unless DBIO::Util->can('mask_connect_secrets');
}

use DBI;
use Future::IO;
use Time::HiRes ();

my $ASYNC = 'DBIO::MySQL::Storage::Async';

# A unix socket that does not exist: the only place a connection of this file
# may be tried at.
my $DEAD = '/nonexistent/dbio-mysql-k76.sock';
plan skip_all => "$DEAD exists on this machine" if -e $DEAD;

delete @ENV{ grep { /^(?:MYSQL|MARIADB)_/ } keys %ENV };

alarm 60;

# Each secret in pieces: a message that kept half a password has not hidden it.
my %SECRET = (
  dsn  => [ 'dsn-s3cret-k76' ],
  arg  => [ 'arg-s3cret-k76' ],
  attr => [ 'attr-s3cret-k76' ],
);

# The DBD's reason, by what no locale translates: the socket it tried.
my $SOCKET_TRIED = qr{\Q$DEAD\E};

my @FLAVOURS = (
  { dbd => 'mysql',   socket => 'mysql_socket'   },
  { dbd => 'MariaDB', socket => 'mariadb_socket' },
);

sub cases_for {
  my ($f) = @_;
  my ($dbd, $sock) = @{$f}{qw( dbd socket )};
  return (
    {
      label    => "dbi:$dbd: a password in the DSN",
      conninfo => { dsn => "dbi:$dbd:database=appdb;$sock=$DEAD;password=$SECRET{dsn}[0]", user => 'app' },
      secrets  => [qw( dsn )],
      dsn_kept => qr/\Q'database=appdb;$sock=$DEAD;password=***'\E/,
    },
    {
      label    => "dbi:$dbd: a password in the DSN and one as the third argument",
      conninfo => {
        dsn => "dbi:$dbd:database=appdb;$sock=$DEAD;password=$SECRET{dsn}[0]", user => 'app',
        password => $SECRET{arg}[0],
      },
      secrets  => [qw( dsn arg )],
      dsn_kept => qr/\Q'database=appdb;$sock=$DEAD;password=***'\E/,
    },
    {
      label    => "dbi:$dbd: a Password attribute, which DBI connects with in place of the third argument",
      conninfo => {
        dsn => "dbi:$dbd:database=appdb;$sock=$DEAD", user => 'app',
        password => $SECRET{arg}[0], attrs => { Password => $SECRET{attr}[0] },
      },
      secrets  => [qw( arg attr )],
      dsn_kept => qr/\Q'database=appdb;$sock=$DEAD'\E/,
    },
  );
}

# The two ways a connect fails in _mysql_connect. A HandleError that answers
# true has taken the error: DBI does not die then, DBI->connect answers false.
my @WAYS = (
  { name => 'DBI dies itself',            attrs => {},
    whose => qr/\ADBI connect\(/ },
  { name => 'DBI->connect answers false', attrs => { HandleError => sub { 1 } },
    whose => qr/\ADBI connect failed: / },
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
# 1 + 2. _mysql_connect, the one DBI->connect of this transport.
# ---------------------------------------------------------------------------

for my $f (@FLAVOURS) {
  SKIP: {
    skip "DBD::$f->{dbd} is not installed", 24
      unless eval "require DBD::$f->{dbd}; 1";

    for my $case (cases_for($f)) {
      for my $way (@WAYS) {
        my $conn = eval { $ASYNC->_mysql_connect(conninfo_for($case, $way)) };
        my $err  = $@;
        if ($conn) {
          $conn->{dbh}->disconnect;
          BAIL_OUT("a connection was opened for [$case->{label}] -- this file must never reach a server");
        }

        my $name = "$case->{label}, $way->{name}";
        like $err, $way->{whose}, "$name: the connect fails, in the words of who reported it";
        no_secret_in($err, $case, '... without the password');
        like $err, $SOCKET_TRIED, '... with the DBD\'s reason';

        next unless $way->{name} eq 'DBI dies itself';
        like $err, $case->{dsn_kept}, '... with the DSN, its secret masked and nothing else';
        like $err, qr/,'app',\.\.\.\) failed: /, '... and with the user';
      }
    }
  }
}

# ---------------------------------------------------------------------------
# 3. Where the message arrives: the pool and the listen connection both open
#    through _mysql_connect.
# ---------------------------------------------------------------------------

for my $f (@FLAVOURS) {
  SKIP: {
    skip "DBD::$f->{dbd} is not installed", 11
      unless eval "require DBD::$f->{dbd}; 1";

    my $case = (cases_for($f))[1];

    skip "Future::IO is bound to $Future::IO::IMPL; this part drives the built-in implementation", 1
      if defined $Future::IO::IMPL && $Future::IO::IMPL ne 'Future::IO::_DefaultImpl';

    my ($dsn, $user, $password) = @{ $case->{conninfo} }{qw( dsn user password )};
    my $s = $ASYNC->new(undef);
    $s->connect_info([ $dsn, $user, $password, { pool_size => 1 } ]);

    my @warned;
    local $SIG{__WARN__} = sub { push @warned, @_ };

    # the pool
    my $f1 = $s->pool->acquire;
    ok $f1->is_failed, "$case->{label}: acquiring a pool connection fails";
    my ($pool_error) = $f1->is_failed ? $f1->failure : ();
    no_secret_in($pool_error, $case, '... without the password');
    like $pool_error, $SOCKET_TRIED, '... with the DBD\'s reason';

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
    like $listen_error, $SOCKET_TRIED, '... with the DBD\'s reason';

    my $deadline = Time::HiRes::time() + 5;
    Future::IO->sleep(0.005)->get while @heard < 2 && Time::HiRes::time() < $deadline;
    $s->unlisten('jobs');

    cmp_ok scalar(@heard), '>=', 2, 'on_listen_error heard the first attempt and a reconnect';
    no_secret_in(join("\n", @heard), $case, '... none of them with the password');
    is scalar(grep { $_ =~ $SOCKET_TRIED } @heard), scalar(@heard),
      '... each with the DBD\'s reason';

    no_secret_in(join('', @warned), $case, 'and nothing warned on the way carries the password');
  }
}

# ---------------------------------------------------------------------------
# 4. The whole connect info goes to the masker: a password repeated bare.
# ---------------------------------------------------------------------------

for my $f (@FLAVOURS) {
  SKIP: {
    skip "DBD::$f->{dbd} is not installed", 9
      unless eval "require DBD::$f->{dbd}; 1";

    my $dbd      = $f->{dbd};
    my $conninfo = {
      dsn => "dbi:$dbd:database=appdb;$f->{socket}=$DEAD", user => 'app',
      password => $SECRET{arg}[0], attrs => { Password => $SECRET{attr}[0] },
    };
    my $case = { secrets => [qw( arg attr )] };
    my $told = "the driver could not log in as app with $SECRET{arg}[0] nor with $SECRET{attr}[0]";

    # For real: the trace Carp writes for DBI's die when it is asked for one.
    {
      local $Carp::Verbose = 1;
      my $conn = eval { $ASYNC->_mysql_connect($conninfo) };
      my $err  = $@;
      if ($conn) {
        $conn->{dbh}->disconnect;
        BAIL_OUT('a connection was opened -- this file must never reach a server');
      }
      like $err, qr/^\s*DBI::connect\(.DBI., .\Qdbi:$dbd:database=appdb\E/m,
        "dbi:$dbd: DBI dies with a stack trace: the frame of DBI->connect is in it, with its arguments";
      no_secret_in($err, $case, '... without the password that is one of them');
      like $err, $SOCKET_TRIED, '... and with the DBD\'s reason';
    }

    no warnings 'redefine';

    {
      local *DBI::connect = sub { die "$told\n" };
      my $conn = eval { $ASYNC->_mysql_connect($conninfo) };
      my $err  = $@;
      ok !$conn, "dbi:$dbd: a DBD that dies repeating the password bare: the connect fails";
      no_secret_in($err, $case, '... without the password, as third argument or as Password attribute');
      is $err, "the driver could not log in as app with *** nor with ***\n",
        '... and with everything else it said';
    }

    {
      my $drh = DBI->install_driver($dbd);
      # set_err appends to an error the handle still holds: start from none.
      local *DBI::connect = sub { $drh->set_err(undef, undef); $drh->set_err(1, $told); return };
      my $conn = eval { $ASYNC->_mysql_connect($conninfo) };
      my $err  = $@;
      ok !$conn, "dbi:$dbd: a DBD that answers false, its error repeating the password bare: the connect fails";
      no_secret_in($err, $case, '... without the password, as third argument or as Password attribute');
      like $err, qr/\ADBI connect failed: the driver could not log in as app with \*\*\* nor with \*\*\* at /,
        '... and with everything else it said';
    }
  }
}

done_testing;
