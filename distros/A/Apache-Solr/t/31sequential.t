#!/usr/bin/perl

use warnings;
use strict;

use lib 'lib';
use Test::More;

my $server;

use Data::Dumper;
$Data::Dumper::Indent = 1;
$Data::Dumper::Quotekeys = 0;

BEGIN {
    $server = $ENV{SOLR_TEST_SERVER}
        or plan skip_all => "no SOLR_TEST_SERVER provided";

	$server .= '/markov';
}

my $rows_per_page = 7;
my @create_ids = 'A'..'Z';

require_ok 'Apache::Solr';
require_ok 'Apache::Solr::Document';

my $solr   = Apache::Solr->new(server => $server);
ok defined $solr, 'Created client';

### reset the database
my $r0 = $solr->delete(id => \@create_ids);
ok $r0->success, 'Delete succeeded';
#warn Dumper $r0;

### Create some documents

my @docs1 = map Apache::Solr::Document->new(fields =>
  [ id      => $_
  , subject => "subject $_"
  , content => "<html>Document $_"
  , content_type => 'text/html'
  ]), @create_ids;

ok $solr->addDocument(\@docs1, commit => 1, overwrite => 1), 'Created docs';

### Find all documents

my $t2 = $solr->select({ sequential => 1 }, rows => $rows_per_page, q => 'text:Document');
#warn Dumper $t2->decoded;
ok $t2, 'Searched for all docs';
isa_ok $t2, 'Apache::Solr::Result', '...';

cmp_ok $t2->nrSelected, '==', scalar @create_ids, '... found all documents';

cmp_ok $t2->fullPageSize, '==', $rows_per_page, "... page has $rows_per_page rows";

my $pageset = $t2->{ASR_pages};   # internal table
cmp_ok scalar @$pageset, '==', 1, '... only first page loaded for size';

### Get first document

my $d2 = $t2->selected(0);
#warn Dumper $d2;
isa_ok $d2, 'Apache::Solr::Document', 'Inspect first answer';
is $d2->rank, 0, '... rank 0';
isa_ok $d2->field('subject'), 'HASH', '... has subject field';
is $d2->field('subject')->{content}, 'subject A', '... correct subject field';
is $d2->content('subject'), 'subject A', '... subject field content';
is $d2->_subject, 'subject A', '... subject field overload';
ok defined $pageset->[0], '... first page kept';

### Test page number

cmp_ok $t2->selectedPageNr(0), '==', 0, 'doc 0 on page 0';
cmp_ok $t2->selectedPageNr(1), '==', 0, '... doc 1 on page 0';

cmp_ok $t2->selectedPageNr(11), '==', 1, '... doc 11 on page 1';

my $last_page = int(@create_ids / $rows_per_page);
cmp_ok $t2->selectedPageNr(scalar @create_ids), '==', $last_page, "... last doc  on page $last_page";

cmp_ok scalar @$pageset, '==', 1, '... page-number calc does not trigger load';

### Second document, same page

my $d3 = $t2->selected(1);
ok defined $d3, 'Second doc on first page';
is $d3->rank, 1, '... rank 1';
is $d3->_subject, 'subject B', '... subject field';
#warn Dumper $d3;
cmp_ok scalar @$pageset, '==', 1, '... still the only loaded page';

### Second page

my $rank4 = $rows_per_page + 1;
my $d4 = $t2->selected($rank4);
ok defined $d4, 'Doc on second page';
is $d4->rank, $rank4, "... rank $rank4";
is $d4->_subject, 'subject '.$create_ids[$rank4], '... subject field';
cmp_ok scalar @$pageset, '==', 2, '... second page loaded page';
ok ! defined $pageset->[0], '... first page released';
ok   defined $pageset->[1], '... second page kept';

my $p4 = $t2->selectedPage(1);
is $pageset->[1]->endpoint, $p4->endpoint, '... selectedPage()';
cmp_ok $p4->fullPageSize, '==', $rows_per_page, '... pageset knows page size';

### nextSelected

my $d5 = $t2->nextSelected;
ok defined $d5, 'nextSelected document';
is $d5->rank, $rank4+1, "... rank ".($rank4+1);
is $d5->_subject, 'subject '.$create_ids[$rank4+1], '... subject field';

while(my $next = $t2->nextSelected)
{   is $next->_subject, 'subject '.$create_ids[$next->rank], '... rank '.$next->rank;
}

### Start a search without pagesize.

my $t5 = $solr->select(q => 'text:Document');
#warn Dumper $t5->decoded;
cmp_ok $t5->fullPageSize, '<', scalar @create_ids,
   'Auto-pagesize is '.$t5->fullPageSize;

### Cleanup

ok $solr->delete(id => \@create_ids)->success, 'Cleanup';

done_testing;
