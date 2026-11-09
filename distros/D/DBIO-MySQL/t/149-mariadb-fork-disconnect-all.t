use strict;
use warnings;
use Test::More;
use POSIX ();
use lib 't/lib';

# DBD::MariaDB 1.24: DBI's END in an exiting forked child runs disconnect_all,
# which closes every connection the child inherited -- AutoInactiveDestroy
# notwithstanding -- or dies in a DBI "active kids" panic (child exit 22).
# COM_QUIT goes down the socket the parent shares, so the parent's session
# ends. DBIO::MySQL::MariaDBForkGuard wraps DBD::MariaDB::dr::disconnect_all
# so that it does nothing in a process other than the one that installed the
# guard (karr k56, this dist's ADR 0009).
#
# Offline: a MySQL wire-protocol stub (t/lib/MySQLProtocolStub.pm) hangs up on
# a session as soon as anybody sends COM_QUIT on it, which is what lets the
# parent see that the child closed its connection. No server, no database.

BEGIN {
  eval { require DBD::MariaDB; 1 }
    or plan skip_all => 'DBD::MariaDB is not installed';
}

use DBI ();
use MySQLProtocolStub;
use DBIO::MySQL::MariaDBForkGuard;

my $stub = MySQLProtocolStub->new;

sub raw_connect {
  return DBI->connect($stub->dsn('MariaDB'), 'u', 'p',
    { RaiseError => 1, PrintError => 0, AutoInactiveDestroy => 1 });
}

# Run $in_child in a forked child over $dbh; the child's exit status and
# whether the parent's handle still works afterwards.
sub after_child {
  my ($dbh, $in_child) = @_;
  my $pid = fork;
  die "fork: $!" unless defined $pid;
  if (!$pid) {
    $in_child->($dbh);
    POSIX::_exit(99);
  }
  waitpid $pid, 0;
  my $status = $? >> 8;
  return ($status, scalar eval { $dbh->do('DO 1'); 1 });
}

ok( DBIO::MySQL::MariaDBForkGuard->install, 'the guard installs' );

subtest 'a child that exits leaves the parent\'s connection alone' => sub {
  my $dbh = raw_connect();
  my ($status, $alive) = after_child($dbh, sub { exit 0 });
  is $status, 0, 'the child exits normally: no DBI "active kids" panic (22)';
  ok $alive, 'the parent\'s connection is alive';
};

subtest 'a child that still holds the handle in a global when it exits' => sub {
  my $dbh = raw_connect();
  our $KEEP;
  my ($status, $alive) = after_child($dbh, sub { $KEEP = $_[0]; exit 0 });
  is $status, 0, 'the child exits normally';
  ok $alive, 'the parent\'s connection is alive';
};

subtest 'a child that calls DBI->disconnect_all' => sub {
  my $dbh = raw_connect();
  my ($status, $alive) = after_child($dbh, sub { DBI->disconnect_all; POSIX::_exit(0) });
  is $status, 0, 'the child exits';
  ok $alive, 'the parent\'s connection is alive: the call is the inherited connections\', not the child\'s';
};

subtest 'a child that merely drops its handle is untouched, as before' => sub {
  my $dbh = raw_connect();
  my ($status, $alive) = after_child($dbh, sub { undef $_[0]; POSIX::_exit(0) });
  ok $alive, 'the parent\'s connection is alive (AutoInactiveDestroy)';
};

subtest 'the process that installed the guard still closes its connections' => sub {
  my $dbh = raw_connect();
  ok $dbh->{Active}, 'connected';
  DBI->disconnect_all;
  ok !$dbh->{Active}, 'disconnect_all in the installing process closed it';
};

subtest 'install is idempotent' => sub {
  my $first = \&DBD::MariaDB::dr::disconnect_all;
  ok( DBIO::MySQL::MariaDBForkGuard->install, 'installs again' );
  is \&DBD::MariaDB::dr::disconnect_all, $first, '... without wrapping the wrapper';
  my $dbh = raw_connect();
  my ($status, $alive) = after_child($dbh, sub { exit 0 });
  ok $alive, 'still guarded';
};

done_testing;
