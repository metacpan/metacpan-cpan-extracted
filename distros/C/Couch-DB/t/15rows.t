#!/usr/bin/env perl
# Test the Couch::DB::Result rows

use Test::More;

use lib 'lib', 't';
use Couch::DB::Util qw(simplified);
use Test;

use warnings;
use strict;

#$dump_answers = 1;
#$dump_values  = 1;
#$trace = 1;

my $couch = _framework;
ok defined $couch, 'Created the framework';

### fill the database with a few documents

my $db = $couch->db('test');
_result removed          => $db->remove;

_result create           => $db->create or die;

foreach my $docnr (1..70)
{	my $r = $db->doc("doc$docnr")->create({nr => $docnr});
	$r or die $r->response->to_string;
}

### find, first page of data

my $query;   # undef = return all documents

my $f1 = _result find_page1 => $db->find($query, limit => 25, stop => 'SMALLER');
ok ! $f1->inPagingMode, '... not paging';
is $f1->pageNumber, 1, '... page number 1';

my $docs1 = $f1->answer->{docs};
ok defined $docs1, '... contains docs';
cmp_ok scalar @$docs1, '==', 25, '... 25 docs';
is_deeply $f1->answer, $f1->values, '... no value decoding needed';

#warn Dumper $f1->answer;

# Actually, not 100% sure that we got 25 rows without the paging.
my $hits1 = 25;

my $rows1 = $f1->rowsRef;
is ref $rows1, 'ARRAY', '... got rowsRef';
cmp_ok scalar(@$rows1), '==', $hits1, "... rowsRef size $hits1";

my @rows1 = $f1->rows;
cmp_ok scalar(@rows1), '==', $hits1, '... rows size in list context';

cmp_ok scalar($f1->rows), '==', $hits1, '... rows in scalar context';

my $row1 = $rows1[3];
isa_ok $row1, 'Couch::DB::Row', '... single row';
is $row1, $f1->row(4), '... get row directly';
is $row1->rowNumberInResult, 4, '... rowNumberInResult';

my $this1 = $f1->_thisPage;
#warn Dumper $this1;
ok exists $this1->{bookmarks}{25}, '... caught bookmark';
cmp_ok @{$this1->{harvested}}, '==', 25, '... harvested';

ok ! $f1->pageIsPartial, '... full page';
ok ! $f1->isLastPage, '... not last page';

ok $_->isa('Couch::DB::Document'), '... is doc '.$_->id 
	for map $_->doc, @rows1;

my @docs1 = $f1->docs;
cmp_ok @docs1, '==', 25, '... docs size';
is_deeply \@docs1, [ map $_->doc, @rows1 ], '... docs = row docs';

### find, second full page of data

my $f2 = _result find_page2 => $db->find($query, succeed => $f1);
is $f2->pageNumber, 2, '... page number 2';
my $this2 = $f2->_thisPage;
#warn "THIS 2: ", Dumper $this2;
ok exists $this2->{bookmarks}{25}, '... remembered bookmark';
ok exists $this2->{bookmarks}{50}, '... caught new bookmark';
cmp_ok @{$this2->{harvested}}, '==', 25, '... harvested new';

ok ! $f2->pageIsPartial, '... full page';
ok ! $f2->isLastPage, '... not last page';
my $rows2 = $f2->rowsRef;
cmp_ok @$rows2, '==', 25, '... second set of rows';

ok $_->isa('Couch::DB::Document'), '... is doc '.$_->id
	for map $_->doc, @$rows2;

### find, third page of data, final and partial

my $f3 = _result find_page3 => $db->find($query, succeed => $f2);
is $f3->pageNumber, 3, '... page number 3';
my $this3 = $f3->_thisPage;
#warn "THIS 3: ", Dumper $this3->{bookmarks};
ok exists $this3->{bookmarks}{25}, '... remembered bookmark 1';
ok exists $this3->{bookmarks}{50}, '... remembered bookmark 2';
cmp_ok keys %{$this3->{bookmarks}}, '==', 3, '... bookmarks on page 3';

cmp_ok @{$this3->{harvested}}, '==', 20, '... harvested new';

ok ! $f3->pageIsPartial, '... not full but also not partial page';
ok $f3->isLastPage, '... last page';
my @rows3 = $f3->rows;
cmp_ok scalar @rows3, '==', 20, '... rows';

ok $_->isa('Couch::DB::Document'), '... is doc '.$_->id 
	for map $_->doc, @rows3;

### findExplain

_result find_explain => $db->findExplain($query);

####### Cleanup
_result removed      => $db->remove;

done_testing;
