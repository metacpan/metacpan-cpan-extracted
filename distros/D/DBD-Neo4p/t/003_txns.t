use Test::More tests => 24;
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
my $num_live_tests = 24;
my ($t,$dbh);
my $dsn = "dbi:Neo4p:db=$TEST_SERVER";
my $connected;
eval {
  if (REST::Neo4p->agent->isa('LWP::UserAgent')) {
    REST::Neo4p->agent->ssl_opts(verify_hostname => 0);
  }
  $connected = REST::Neo4p->connect($TEST_SERVER, $user, $pass);
};
SKIP : {
  skip 'no connection to neo4j', $num_live_tests unless $connected;
  ok $dbh = DBI->connect($dsn,$user,$pass);
  REST::Neo4p->set_handle($dbh->{neo_Handle});
  skip 'Need server v2.0 to test transactions', $num_live_tests-1 unless REST::Neo4p->_check_version(2,0,0,2);
  $t = Neo4p::Test->new($TEST_SERVER,$user, $pass);
  ok $t->create_sample, 'create sample graph';
  my $idx = ${$t->nix};
  my $q =<<CYPHER;
   START x = node:$idx(name='he')
   MATCH (x)-[:pally]->(u)
   DELETE u
CYPHER
  my $w =<<CYPHER2;
   START x = node:$idx(name='he')
   CREATE UNIQUE (x)-[r:pally]->(u)
   RETURN u, r
CYPHER2
  my $v =<<CYPHER3;
   START x = node:$idx(name='he')
   MATCH (x)-[r:pally]->(u)
   SET u.name = 'Screlb'
   SET u.uuid = '925bd263_e369_4fc0_8e33_ea50d616358b'
   RETURN u
CYPHER3
  my $find =<<FIND;
   START x = node:$idx(name='he')
   MATCH (x)-[:pally]->(u)
   RETURN u
FIND
  ok $dbh->{AutoCommit}, "AutoCommit defaults to set";
  $dbh->{AutoCommit} = 0;
  ok !$dbh->begin_work, "try to begin_work";
  like $DBI::errstr, qr/begin_work not effective/, "AutoCommit cleared, begin_work not effective";
  ok my $sthq = $dbh->prepare($q), 'prepare query 1';
  ok my $sthw = $dbh->prepare($w), 'prepare query 2';
  ok my $sthv = $dbh->prepare($v), 'prepare query 3';
  ok my $sthf = $dbh->prepare($find), 'prepare find query';
  ok $sthq->execute, 'execute';
  ok $dbh->commit, 'commit successful';
  ok $sthw->execute, 'execute query 2 (new txn)';
  ok $sthv->execute, 'execute query 3 (new txn)';
  ok $dbh->rollback, 'rollback';
  ok $dbh->{AutoCommit} = 1, 'set AutoCommit';
  ok $sthf->execute, 'look for "created" node...';
  ok !$sthf->fetch, "but can't find it";
  ok $dbh->begin_work, 'begin_work (in AutoCommit)';
  ok $sthw->execute, 'execute query 2 (new txn)';
  ok $sthv->execute, 'execute query 3 (new txn)';
  ok $dbh->commit, 'now commit';
  ok $sthf->execute, 'look for created node';
  #PROBLEM HERE vvv
  ok my $row = $sthf->fetch, 'found it';
  is $row->[0]->{name}, 'Screlb', 'node created and property set';
  my ($r) = grep { $_->type eq 'pally'} ($t->nix->find_entries(name => 'he'))[0]->get_outgoing_relationships();
  $t->nix->add_entry($r->end_node, name => 'Screlb') if $r;
  $t->rix->add_entry($r, hash => '123') if $r;
  
}

END {
  $t && $t->delete_sample;
  $dbh && $dbh->disconnect;
}
