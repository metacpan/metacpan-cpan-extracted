#!/usr/bin/env perl
# Test the Couch::DB::Result paging

use Test::More;

use lib 'lib', 't';
use Couch::DB::Util qw(simplified);
use Test;

#$dump_answers = 1;
#$dump_values  = 1;
#$trace = 1;

my $couch = _framework;
ok defined $couch, 'Created the framework';

### fill the database with a few documents

my $db = $couch->db('test');
_result removed          => $db->remove;
_result create           => $db->create;

foreach my $docnr (01..70)
{	my $r = $db->doc("doc$docnr")->create({nr => $docnr});
	$r or die $r->response->to_string;
}

### check parameter parsing

my %p1 = $couch->_resultsPaging( +{ } );
ok keys %p1, 'Paging with default settings';

#warn Dumper \%p1;
is_deeply $p1{paging}, +{
	bookmarks => {},
	harvester => undef,
	harvested => [],
	page_size => 25,
	req_max   => 100,
	skip      => 0,
	start     => 0,
}, '... defaults';

my %p2 = $couch->_resultsPaging( +{
	limit      => 10,
	_page      => 5,
	_page_size => 35,
	_harvester => "MYCODE",
	_bookmark  => 'abc',
});
ok keys %p2, 'Paging with all settings';

#warn Dumper \%p2;
is_deeply $p2{paging}, +{
	bookmarks => { 140 => 'abc' },
	harvester => "MYCODE",
	harvested => [],
	page_size => 35,
	req_max => 10,
	skip => 0,
	start => 140,
}, '... all fresh';


### find, first page of data

my $query;   # undef = return all documents

my $f1 = _result find_page1 => $db->find($query);
my $this1 = $f1->_thisPage;
#warn Dumper $this1;
ok exists $this1->{bookmarks}{25}, '... caught bookmark';
cmp_ok @{$this1->{harvested}}, '==', 25, '... harvested';

ok ! $f1->pageIsPartial, '... full page';
ok ! $f1->isLastPage, '... not last page';
my $docs1 = $f1->page;
cmp_ok @$docs1, '==', 25, '... page';

ok $_->isa('Couch::DB::Document'), '... is doc '.$_->id 
	for @$docs1;

### find, second full page of data

my $f2 = _result find_page2 => $db->find($query, _succeed => $f1);
my $this2 = $f2->_thisPage;
#warn "THIS 2: ", Dumper $this2;
ok exists $this2->{bookmarks}{25}, '... remembered bookmark';
ok exists $this2->{bookmarks}{50}, '... caught new bookmark';
cmp_ok @{$this2->{harvested}}, '==', 25, '... harvested new';

ok ! $f2->pageIsPartial, '... full page';
ok ! $f2->isLastPage, '... not last page';
my $docs2 = $f2->page;
cmp_ok @$docs2, '==', 25, '... page';

ok $_->isa('Couch::DB::Document'), '... is doc '.$_->id 
	for @$docs2;

### find, third page of data, final and partial

my $f3 = _result find_page3 => $db->find($query, _succeed => $f2);
my $this3 = $f3->_thisPage;
#warn "THIS 3: ", Dumper $this3;
ok exists $this3->{bookmarks}{25}, '... remembered bookmark 1';
ok exists $this3->{bookmarks}{50}, '... remembered bookmark 2';
cmp_ok keys %{$this3->{bookmarks}}, '==', 3, '... new bookmark 3';

cmp_ok @{$this3->{harvested}}, '==', 20, '... harvested new';

ok $f3->pageIsPartial, '... partial page';
ok $f3->isLastPage, '... last page';
my $docs3 = $f3->page;
cmp_ok @$docs3, '==', 20, '... page';

ok $_->isa('Couch::DB::Document'), '... is doc '.$_->id 
	for @$docs3;

####### Cleanup
_result removed          => $db->remove;

done_testing;
