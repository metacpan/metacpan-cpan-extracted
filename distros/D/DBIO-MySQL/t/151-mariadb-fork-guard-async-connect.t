use strict;
use warnings;
use Test::More;
use POSIX ();
use lib 't/lib';

# The guard (t/149) is installed by the connect paths of this dist, so that no
# caller has to ask for it. This file: the future_io transport (t/150: the sync
# storage), and only when the connection is DBD::MariaDB's (karr k56, ADR 0009). Offline,
# against t/lib/MySQLProtocolStub.pm.

BEGIN {
  eval { require DBD::MariaDB; require DBD::mysql; 1 }
    or plan skip_all => 'DBD::MariaDB and DBD::mysql are needed to tell the drivers apart';
}

use DBI ();
use MySQLProtocolStub;
use DBIO::MySQL::Storage::Async;

my $stub = MySQLProtocolStub->new;
my $orig = \&DBD::MariaDB::dr::disconnect_all;

sub guarded { \&DBD::MariaDB::dr::disconnect_all != $orig }

sub exit_leaves_parent_alive {
  my ($dbh) = @_;
  my $pid = fork // die "fork: $!";
  exit 0 if !$pid;
  waitpid $pid, 0;
  return ( $? >> 8, scalar eval { $dbh->do('DO 1'); 1 } );
}

ok !guarded(), 'nothing is wrapped before a connection of this dist exists';

subtest 'future_io transport over DBD::MariaDB' => sub {
  my $storage = bless {}, 'DBIO::MySQL::Storage::Async';
  my $conn = $storage->_mysql_connect({ dsn => $stub->dsn('MariaDB'), user => 'u', password => 'p' });
  ok guarded(), 'the connect installed the guard';
  my ($status, $alive) = exit_leaves_parent_alive($conn->{dbh});
  is $status, 0, 'a forked child exits normally';
  ok $alive, '... and the parent\'s pool connection lives';
};


done_testing;
