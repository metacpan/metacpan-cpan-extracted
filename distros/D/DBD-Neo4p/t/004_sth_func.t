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
  $connected = REST::Neo4p->connect($TEST_SERVER,$user,$pass);
};

SKIP : {
  skip 'no connection to neo4j', $num_live_tests unless $connected;
  ok $dbh = DBI->connect($dsn,$user,$pass);
  REST::Neo4p->set_handle($dbh->{neo_Handle});
  $t = Neo4p::Test->new($TEST_SERVER,$user,$pass);
  ok $t->create_sample, 'create sample graph';
  my $idx = ${$t->nix};
  my $q =<<OUTPUT;
   START x = node:$idx(name='I')
   MATCH path =(x)-[r]-(friend)
   RETURN friend, TYPE(r) 
   ORDER BY r.hash
OUTPUT
  my $q2 = <<INPUT;
   START x = node:$idx(name={Name})
   CREATE UNIQUE (x)-[:pally]->(y {name:'Fred'})
INPUT
  
  ok my $sth = $dbh->prepare($q), 'prepare statment';
  ok $sth->execute, "execute statement";
  is_deeply $sth->{NAME}, [qw/friend TYPE(r)/], 'NAME';
  is_deeply $sth->{NAME_lc}, [qw/friend type(r)/],'NAME_lc';
  is_deeply $sth->{NAME_uc}, [qw/FRIEND TYPE(R)/],'NAME_uc';
  is_deeply $sth->{NAME_hash}, { friend => 0, qw/TYPE(r)/ => 1 }, 'NAME_hash';
  is_deeply $sth->{NAME_lc_hash}, { friend => 0, qw/type(r)/ => 1 }, 'NAME_lc_hash';
  is_deeply $sth->{NAME_uc_hash}, { 
FRIEND => 0, qw/TYPE(R)/ => 1 }, 'NAME_uc_hash';
  ok my $row = $sth->fetchrow_hashref, 'fetchrow_hashref';
  is $row->{friend}->{name}, 'you', 'fetched row as hash 1';
  is $row->{'TYPE(r)'}, 'best', 'fetched row as hash 2';
  ok my $rows = $sth->fetchall_arrayref, 'fetchall_arrayref';
  is ref $rows, 'ARRAY', 'is arrayref';
  cmp_ok scalar @$rows, ">=", 2, 'got >= 2 rows';
  ok $sth->execute, "execute statement (2)";
  # fetchall_hashref - is weird, because the value of a cell generally is
  # a hash (a node or relationship in the db)
  ok $rows = $sth->fetchall_hashref('friend'), 'fetchall_hashref';
  is ref $rows, 'HASH', 'is hashref';
  ok $sth->execute, "execute statement (3)";
  ok $rows = $sth->fetchall_hashref(['friend','TYPE(r)']);
  is ref $rows, 'HASH', 'is hashref';
  $dbh->{neo_ResponseAsObjects} = 1;
  ok $sth->execute, "execute statement (4) - responses as objects";
  ok $rows =  $sth->fetchall_hashref(['friend','TYPE(r)']);
  1;
}

END {
  $dbh && $dbh->disconnect;
}
