use Test::More;
use Test::Exception;
use Module::Build;
use lib 't/lib';
use lib '../lib';
use lib '../t/lib';
use strict;
use warnings;
use REST::Neo4p;
use Neo4p::Test;
use DBI;

my $build;
my ($user,$pass);
eval {
  $build = Module::Build->current;
  $user = $build->notes('user');
  $pass = $build->notes('pass');
  $ENV{REST_NEO4P_AGENT_MODULE} = $build->notes('backend');
};
my $TEST_SERVER = $build ? $build->notes('test_server') : 'http://127.0.0.1:7474';
my $num_live_tests = 1;
my ($t, $dbh);
my $dsn = "dbi:Neo4p:db=$TEST_SERVER";
my $connected;
eval {
  if (REST::Neo4p->agent->isa('LWP::UserAgent')) {
    REST::Neo4p->agent->ssl_opts(verify_hostname => 0);
  }
  $connected = REST::Neo4p->connect($TEST_SERVER, $user,$pass);
};

SKIP : {
  skip 'no connection to neo4j', $num_live_tests unless $connected;
  ok $dbh = DBI->connect($dsn,$user,$pass);
  $t = Neo4p::Test->new($TEST_SERVER,$user,$pass);
  ok $t->create_sample, 'create sample graph';
  my $idx = ${$t->nix};
  my $q =<<CYPHER;
   START x = node:$idx(name= { startName })
   MATCH path =(x)-[r]-(friend)
   WHERE friend.name = { name }
   RETURN TYPE(r)
CYPHER
  ok my $sth = $dbh->prepare($q), 'prepare synopsis query';
  # startName => 'I', name => 'you'
  ok $sth->execute("I", "you"), 'execute with params';
  is_deeply $sth->{neo_param_names}, [qw/startName name/], 'param_names attribute ok';
  is_deeply $sth->{NAME}, [qw/TYPE(r)/], 'NAME attribute correct';
  my @types;
  while (my $row = $sth->fetch) {
    push @types, $row->[0];
  }
  is_deeply [sort @types], [qw/best best bosom/], 
    'got types of friend from query fetch (param binding in execute worked)';
  ok $sth->bind_param(1,'he'), 'bind_param() 1';
  ok $sth->bind_param(2,'she'), 'bind_param() 2';
  ok $sth->execute(), 'execute with separate bind_param() call';
  ok my $row = $sth->fetch, 'got row';
  is $row->[0], 'umm', 'got correct type of friend (param binding with bind_param worked)';
  # bind_param_array and execute_array
  ok $sth->bind_param_array(1, ['he', 'it']);
  ok $sth->bind_param_array(2, ['she']);
  my @status;
  my $tuples = $sth->execute_array( { ArrayTupleStatus => \@status } );
  is $tuples, 2, 'execute_array executed successfully';
}

done_testing;

END {
  $dbh && $dbh->disconnect;
}
