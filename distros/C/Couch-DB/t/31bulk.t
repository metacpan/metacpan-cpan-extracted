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

##### $couch->db('test');

my $db = $couch->db('test');
ok defined $db, 'Create database "test"';
isa_ok $db, 'Couch::DB::Database', '...';
is $db->name, 'test', '... name';
is $db->couch, $couch, '... link back to couch';

_result create           => $db->create;

my @docs = map $db->doc("doc$_", content => { nr => $_ }), 1..70;

_result saveBulkAdd => $db->saveBulk(\@docs);
my $victim = $docs[1];
$trace && warn simplified added => $victim;   # rev added

_result saveBulkDel => $db->saveBulk([], delete => $victim);

$trace && warn Dumper $victim;   # delete flag set, rev added
ok $victim->isDeleted, '... deleted';

my $all1  = _result search => $db->allDocs({include_docs => 1}, all => 1);
my $docs1 = $all1->page;
#warn "DOC1", Dumper $docs1->[0];
cmp_ok scalar @$docs1, '==', 69, '... one deleted';

_result removed          => $db->remove;

done_testing;
