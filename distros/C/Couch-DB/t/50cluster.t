#!/usr/bin/env perl

use Test::More;
use HTTP::Status    qw(HTTP_OK);

use lib 'lib', 't';
use Couch::DB::Util qw(simplified);
use Test;

#$dump_answers = 1;
#$dump_values  = 1;
#$trace = 1;

my $couch = _framework;
ok defined $couch, 'Created the framework';

my $cluster = $couch->cluster;
ok defined $cluster, 'Create cluster access';
isa_ok $cluster, 'Couch::DB::Cluster', '...';

_result clusterState     => $cluster->clusterState;
#_result clusterSetup     => $cluster->clusterSetup;
_result reshardStatus    => $cluster->reshardStatus;
_result reshardStatus    => $cluster->reshardStatus(counts => 1);
#_result resharding      => $cluster->resharding(state => 'stopped');
_result reshardJobs      => $cluster->reshardJobs;
#_result reshardStart      => $cluster->reshardStart;
#_result reshardJob        => $cluster->reshardJob;
#_result reshardJobRemove  => $cluster->reshardJobRemove;
#_result reshardJobState   => $cluster->reshardJobState;
#_result reshardJobChange  => $cluster->reshardJobChange;

#### database related

my $db = $couch->db('test');
_result create_db => $db->create;

_result shardsForDB      => $cluster->shardsForDB($db);
_result syncShards       => $cluster->syncShards($db);

my $doc1 = $db->doc('testdoc1');
_result doc1_create      => $doc1->create({tic => 1, tac => 2});

_result shardsForDoc     => $cluster->shardsForDoc($doc1);

_result remove_db => $db->remove;



done_testing;
