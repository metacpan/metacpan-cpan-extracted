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

my $db = $couch->db('test');
_result create           => $db->create;

####### $db->doc('testdoc')

my $t1 = $db->doc('testdoc1');
ok defined $t1, "Created testdoc1 in test";
isa_ok $t1, 'Couch::DB::Document';

is $t1->id, 'testdoc1', '... id';
is $t1->db, $db, '... db';
is $t1->couch, $couch, '... couch';

_result t1_create        => $t1->create({tic => 1, tac => 2});
$trace && warn Dumper [ $t1->revisions ];

_result t1_update        => $t1->update({tic => 3, toe => 4});
$trace && warn Dumper [ $t1->revisions ];

_result t1_att1_save     => $t1->attSave(att1 => 'unsorted bytes');

my $t2 = $db->doc('testdoc1');
isa_ok $t2, 'Couch::DB::Document';
my $r2 = _result t2_get => $t2->get({
	attachments => 1,
	att_encoding_info => 1,
	conflicts => 1,
	deleted_conflicts => 1,
	latest => 1,
	local_seq => 1,
	meta => 1,
	revs => 1,
	revs_info => 1,
});

$trace && warn "INFO=", Dumper $t2->_info;
$trace && warn "LATEST=", Dumper $t2->latest;
$trace && warn "CONFLICTS=", Dumper $t2->conflicts;
$trace && warn "DEL CONFLICTS=", Dumper $t2->deletedConflicts;
$trace && warn "UPDATE SEQ=", Dumper $t2->updateSequence;
$trace && warn "REV INFO=", Dumper $t2->revisionsInfo;

$trace && warn $r2->request->to_string;
$trace && warn $r2->response->to_string;
$trace && warn "ATTNAMES=", join '#', $t2->attachments;
$trace && warn "ATT2=", $t2->attachment('att1');


my $a2  = _result t2_att1_load => $t2->attLoad('att1');
$trace && warn $a2->request->to_string;
$trace && warn $a2->response->to_string;

my $t3 = $db->doc('testdoc1');
my $r3 = _result t3_get => $t3->get;
$trace && warn "ATT3a=", $t3->attachment('att1') // 'expected empty';
_result t3_load => $t3->attLoad('att1');
$trace && warn "ATT3b=", $t3->attachment('att1');
$trace && warn "ATT3c=", Dumper $t3->attInfo('att1');
$trace && warn "ATT3d=", join '#', $t3->attachments;

my $f1 = _result f1_find => $db->find;
my $f1a = $f1->values->{docs};
$trace && warn "FOUND ".  @$f1a . " documents";
$trace && warn "FOUND @$f1a documents";
$trace && warn "CONTENT=", Dumper $f1a->[0]->latest;

####### Cleanup
_result removed          => $db->remove;


done_testing;
