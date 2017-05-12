use strict;
use Test::More tests => 15;
use Test::Exception;

use lib 't';
use PgLinkTestUtil;
use DBIx::PgLink::Adapter::Pg;

my $db = DBIx::PgLink::Adapter::Pg->new();

$db->install_roles('Reconnect');

can_ok( $db, 'reconnect');

ok( 
  $db->connect($Test->{TEST}->{dsn}, $Test->{TEST}->{user}, $Test->{TEST}->{password}, {}),
  'adapter connected'
);

diag <<EOF;

##################################################################  
#  This test will kill PostgreSQL backend process several times, #
#  simulating network failure.                                   #
##################################################################

EOF

my $sth = $db->prepare("SELECT pg_backend_pid()");

my $max = 5;
for my $counter (1..$max) {
  ok($sth->execute, "execute statement");
  my $pid = $sth->fetchrow_array;
  ok($pid, "fetch pid");
  diag "try #$counter of $max: pg_backend_pid=$pid\n";
  if ($counter % 2 == 0) {
    diag "killing $pid ";
    my $rc = system("pg_ctl kill TERM $pid");
    is($rc, 0, "backend process killed");
  } else {
    sleep 1;
  }
  diag "ping=", $db->ping, "\n";
}

lives_ok {
  $db->do('SELECT 1');
} 'live connection';
