use lib qw(../lib ../t/lib lib);
use Test::More;
use Test::Exception;
use DBI;
use DBD::Neo4p;
use strict;
use warnings;

my $build;
my ($user, $pass);
eval {
  $build = Module::Build->current;
  $user = $build->notes('user');
  $pass = $build->notes('pass');
  $ENV{REST_NEO4P_AGENT_MODULE} = $build->notes('backend');
};
my $TEST_SERVER = $build ? $build->notes('test_server') : 'http://127.0.0.1:7474';

my $num_live_tests = 8;
my $connected;
eval {
  $connected = REST::Neo4p->connect($TEST_SERVER, $user, $pass);
};

SKIP : {
  no warnings qw/uninitialized/;
  skip 'no connection to neo4j', $num_live_tests unless $connected;
  my ($dbh1,$dbh2,$dbh3,$dbh4);
  
  lives_ok { $dbh1 = DBI->connect("dbi:Neo4p:db=http://127.0.0.1:7474;user=$user;pass=$pass") };
  ok $dbh1, 'got handle (1)';
  ok $dbh1 && $dbh1->ping, 'connected (1)';
  lives_ok { $dbh2 = DBI->connect("dbi:Neo4p:host=127.0.0.1;port=7474;user=$user;pass=$pass") };
  ok $dbh2, 'got handle (2)';
  ok $dbh2 && $dbh2->ping, 'connected (2)';
  lives_ok { $dbh3 = DBI->connect("dbi:Neo4p:db=http://127.0.0.1:7474",$user,$pass) };
  ok $dbh3, 'got handle (3)';
  ok $dbh3 && $dbh3->ping, 'connected (3)';
  
}
done_testing;
