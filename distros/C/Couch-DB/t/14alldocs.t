#!/usr/bin/env perl
# Check methods related to allDocs()

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

_result remove           => $db->remove;   # cleanup crash
_result create           => $db->create;

foreach my $docnr (1..30)
{	my $r = $db->doc("doc$docnr")->create({nr => $docnr});
	$r or die $r->response->to_string;
}

#### simplest

my $all1 = _result allDocs1  => $db->allDocs;
ok $all1, "Get all docs";    # can this ever page?

# always sorted on id: 1, 10, 11, 12, 13, ..., 2, 20, ...
my $row1_5 = $all1->row(5);
isa_ok $row1_5, 'Couch::DB::Row';
is $row1_5->values->{id}, 'doc13', '... 5th row';

#### include_docs

my $all2   = _result allDocs2 => $db->allDocs({include_docs => 1}, all => 1);
my $doc2_4 = $all2->pageDoc(4);
isa_ok $doc2_4, 'Couch::DB::Document';

#warn Dumper $doc2_4->latest;
is $doc2_4->latest->{nr}, 12, '... right document';  # 1, 10, 11, 12,

my $docs2 = $all2->page;
#warn "DOC[2]1", Dumper $docs2->[0];
cmp_ok scalar @$docs2, '==', 30;

_result removed          => $db->remove;

done_testing;
