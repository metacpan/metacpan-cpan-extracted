#!/usr/bin/perl
BEGIN {
   unless ($ENV{PERL_ANYEVENT_DBI_TESTS}) {
      print "1..0 # SKIP env var PERL_ANYEVENT_DBI_TESTS not set\n"; exit;
   }
   eval {
      require DBIx::MyServer;
      require DBIx::MyServer::DBI;
   };
   if ($@) {
      print "1..0 # SKIP these tests require DBIx::MyServer\n"; exit;
   }
}

no warnings;
use List::Util     qw(sum);
use Cwd            qw(abs_path);
use File::Basename qw(dirname);

use AnyEvent::DBI;

my $topdir = dirname abs_path $0;

# fork off a child to be a mysql server
my $server_pid = fork;
unless ($server_pid) {
   exec "$^X $topdir/fake-mysql --config $topdir/myserver.conf";
   die 'exec failed';
}

# the parent is the test script
eval {
   require Test::More;
   #d#import Test::More tests => 34;
   import Test::More tests => 33;
};
if ($@) {
   print 'ok 1 # skip this test requires Test::More'."\n";
   exit 0;
}

# wait for server
sleep 1;
my $cv  = AnyEvent->condvar;
my $dbh = new AnyEvent::DBI(
   "dbi:mysql:database=database;host=127.0.0.1;port=23306",'','',
   PrintError => 0,
   timeout    => 2,
   on_error   => sub { },
   on_connect => sub {
      if (!$_[1]) {
         $cv->send($@);
      } else {
         $cv->send();
      }
   },
);
my $connect_error = $cv->recv();
is($connect_error,undef,'on_connect() called without error, fake mysql server is connected');

# issue a query
$cv = AnyEvent->condvar;
$dbh->exec (
   "select a,b,c from rows14 where num=?", 10, sub {
      my ($dbh,$rows, $metadata) = @_;
      if (! $dbh) {
         $cv->send($@);
      }
      else {
         $cv->send(undef,$rows);
      }
   }
);
my ($error, $rows) = $cv->recv();
#print "@$_\n" for @$rows;
is($error,undef,'query returns no errors');
is(scalar @$rows,14,'query found 14 rows');
is(scalar @{$$rows[0]},3,'first row has 3 data');

# issue a query that returns an error
$cv = AnyEvent->condvar;
$dbh->exec (
   "select a,b,c from nosuchtable", sub {
      my ($dbh, $rows, $metadata) = @_;
      if (!$rows) {
         $cv->send($@);
      } else {
         $cv->send(undef,$rows);
      }
   }
);
($error, $rows) = $cv->recv();
is($error,qq{Table 'database.nosuchtable' doesn't exist},"SELECT on non-existant table returns NONFATAL error");

# good query after bad
$cv = AnyEvent->condvar;
$dbh->exec (
   "select a,b,c from rows14 where num=?", 10, sub {
      my ($dbh,$rows, $metadata) = @_;
      if (!$rows) {
         $cv->send($@);
      } else {
         $cv->send(undef,$rows);
      }
   }
);
($error, $rows) = $cv->recv();
#print "@$_\n" for @$rows;
is($error,undef,'good query after bad returns no errors');
is(scalar @$rows,14,'query found 14 rows');
is(scalar @{$$rows[0]},3,'first row has 3 data');

############################################################################
# enque a series of alternating good/bad queries
$cv = AnyEvent->condvar;
my @results = ();
my $num_qry = 0;
my $qrydone = sub {
   my ($dbh,$rows,$metadata) = @_;
   my $err = undef;
   if (!$rows) {
      $err = $@;
   }
   push @results , [$err,$rows];
   if (scalar @results == $num_qry) {
      $cv->send();
   }
};

$dbh->exec ("select a,b,c from nosuchtable1", $qrydone); $num_qry++;
$dbh->exec ("select a,b,c from rows1"       , $qrydone); $num_qry++;
$dbh->exec ("select a,b,c from nosuchtable2", $qrydone); $num_qry++;
$dbh->exec ("select a,b,c from rows2"       , $qrydone); $num_qry++;
$dbh->exec ("select a,b,c from nosuchtable3", $qrydone); $num_qry++;
$dbh->exec ("select a,b,c from rows3"       , $qrydone); $num_qry++;
$dbh->exec ("select a,b,c from nosuchtable4", $qrydone); $num_qry++;
$dbh->exec ("select a,b,c from rows4"       , $qrydone); $num_qry++;

$cv->recv();
for my $r (0..$num_qry-1) {
   my $offset = int($r / 2 )+1;
   if ($r % 2) {
      ok(! defined $results[$r]->[0],'Multi Query Queue: No error on good queries');
      is(scalar @{$results[$r]->[1]},$offset,'Multi Query Queue: Good query got right number of rows');
   } else {
      is(
         $results[$r]->[0],
         qq{Table 'database.nosuchtable$offset' doesn't exist},'Multi Query Queue: Bad query gets correct error'
      );
   }
}

############################################################################

# try to connect to a closed port
# NOTE tcp port 9 is 'discard', hopefully not running
$cv = AnyEvent->condvar;
my $dbh2 = new AnyEvent::DBI(
   "dbi:mysql:database=test;host=127.0.0.1;port=9",'','',
   PrintError => 0,
   timeout    => 3,
   on_error   => sub { },
   on_connect => sub {
      if (!$_[1]) {
         $cv->send($@);
      }
      else {
         $cv->send();
      }
   },
);
$connect_error = $cv->recv();
like($connect_error,qr{can't connect}i,'mysql connect to localhost:9 refused');

# try to connect to a firewalled port
$cv = AnyEvent->condvar;
$dbh2 = new AnyEvent::DBI(
   "dbi:mysql:database=test;host=www.google.com;port=23306",'','',
   timeout    => 3,
   on_error   => sub { },
   on_connect => sub {
      if (!$_[1]) {
         $cv->send($@);
      }
      else {
         $cv->send();
      }
   },
);
$connect_error = $cv->recv();
is($connect_error,'timeout','mysql connect to google port 23306 times out');
undef $dbh2;

# issue a query which times out
$cv = AnyEvent->condvar;
$dbh->exec (
   "select a,b,c from delay10 where num=?", 10, sub {
      my ($dbh,$rows, $metadata) = @_;
      if (! $rows) {
         $cv->send($@);
      }
      else {
         $cv->send(undef,$rows);
      }
   }
);
($error,$rows) = $cv->recv();
is($error,'timeout','timeout fires during long-running query');

# issue a query after a fatal timeout error
$cv = AnyEvent->condvar;
my $start = AnyEvent->now;
my $run   = 10;
my $ran   = 0;
my $fin   = 0;
my $errs  = [];
while ($ran++ < $run) {
   $dbh->exec (
      "select d,e,f,g from rows5 where num=?", 10, sub {
         my ($dbh,$rows, $metadata) = @_;
         if (!$rows) {
            push @$errs, $@;
         }
         if (++$fin == $run) {
            $cv->send();
         }
      }
   );
}
$cv->recv();
ok(AnyEvent->now -$start < 0.0001,'invalid db handle returns from multiple queries immediately');
is (scalar @$errs, 10, 'invalid db handle returned error for all enqueued queries');
is($errs->[0],'no database connection','invalid db handle returns correct error');
undef $dbh;

# check for server process leakage
eval {
   require Proc::Exists;
   import Proc::Exists qw(pexists);
};
my $has_pe = ! $@;
SKIP: {
   skip ( 'This test requires Proc::Exists',4)  unless $has_pe;
   # connect three handles
   $cv  = AnyEvent->condvar;
   my @handles;
   my @handle_errors;
   my $connected =0;
   for (0..2) {
      my $dbh3 = new AnyEvent::DBI(
         "dbi:mysql:database=database;host=127.0.0.1;port=23306",'','',
         PrintError => 0,
         timeout    => 2,
         on_error   => sub { },
         on_connect => sub {
            if (!$_[1]) {
               push @handle_errors, $@;
            }
            if (++$connected == 3) {
               $cv->send();
            }
         },
      );
      push @handles, $dbh3;
   }
   $cv->recv();
   is(scalar @handles,3,'created three handles');
   is(scalar @handle_errors,0,'no errors during handle creation');
   my @pids = map {$_->_server_pid} @handles;
   ok( defined pexists(@pids, {all=>1}),'Found three slave processes');
   undef @handles;

   $cv = AnyEvent->condvar;
   my $cleanup = AnyEvent->timer(after=>0.5,cb=>sub {$cv->send()});
   $cv->recv();
   ok(!defined pexists(@pids, {any=>1}),'All slave processes exited');
}

# connect to the server again
$cv  = AnyEvent->condvar;
$dbh = new AnyEvent::DBI(
   "dbi:mysql:database=database;host=127.0.0.1;port=23306",'','',
   PrintError => 0,
   timeout    => 2,
   on_error   => sub { },
   on_connect => sub {
      if (!$_[1]) {
         $cv->send($@);
      } else {
         $cv->send();
      }
   },
);
$connect_error = $cv->recv();
is($connect_error,undef,'on_connect() called without error, fake mysql server is re-connected');

# End the server and reap it
$cv  = AnyEvent->condvar;
my $server_process_watcher = AnyEvent->child(
   pid => $server_pid,
   cb  => sub {
      $cv->send(@_);
   }
);
kill 2, $server_pid; # 2 is SIGINT, usually
my ($dead_pid,$dead_status)=$cv->recv();
is ($dead_pid,$server_pid,'MySQL Server processess exited');
is ($dead_status,2,'Server exited on our signal');

if (0) {
   # does not seem tor eliably kill all children
sleep 2;

# try to make another query with a down MYSQL server
# issue a query
$cv = AnyEvent->condvar;
$dbh->exec (
   "select x from rows1 where num=?", 10, sub {
      my ($dbh, $rows, $metadata) = @_;
      if (!$rows) {
         $cv->send($@);
      } else {
         $cv->send(undef,$rows);
      }
   }
);

($error, $rows) = $cv->recv();
is($error,'timeout','mysql query to dead server times out');
undef $dbh;
}

END {
   if ($server_pid) {
      # shut down the fake_mysql server
      delete $SIG{CLD};
      kill 15, $server_pid;
      waitpid $server_pid,0;
   }
   exit 0;
}

