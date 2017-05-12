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

    plan tests => 42;
}

require_ok('Apache::Solr');
require_ok('Apache::Solr::Document');

my $format = $0 =~ m/xml/ ? 'xml' : 'json';
my $FORMAT = uc $format;

my $solr = Apache::Solr->new(format => $FORMAT, server => $server);
ok(defined $solr, "instantiated client in $format");

isa_ok($solr, 'Apache::Solr::'.$FORMAT);

my $result = eval { $solr->commit };
ok(!$@, 'try commit:'.$@);

isa_ok($result, 'Apache::Solr::Result');
is($result->endpoint, "$result");

$result->showTimings(\*STDERR);
ok($result->success, 'successful');

# reset the database
my $r0 = $solr->delete(id => [1,2,3]);
ok($r0->success, 'delete succeeded');
#warn Dumper $r0;

### test $solr->addDocument()
my $d1a = Apache::Solr::Document->new
  ( fields => [ id => 1, subject => '1 2 3', content => "<html>tic tac"
              , content_type => 'text/html' ]
  );

my $d1b = Apache::Solr::Document->new
  ( fields => [ id => 2, content => "<body>tac too"
              , content_type => 'text/html' ]
  , boost  => '5'
  );

$solr->addDocument([$d1a, $d1b], commit => 1, overwrite => 1);

### test $solr->terms()

my $t1 = $solr->queryTerms(fl => 'id', limit => 20);
isa_ok($t1, 'Apache::Solr::Result');

my $r1 = $t1->terms('id');
#warn Dumper $r1;

ok(defined $r1, 'lookup search results for "id"');
isa_ok($r1, 'ARRAY');
cmp_ok(scalar @$r1, '==', 2, 'both documents have an id');
isa_ok($r1->[0], 'ARRAY', 'is array of arrays');
cmp_ok(scalar @{$r1->[0]}, '==', 2, 'each size 2');
cmp_ok(scalar @{$r1->[1]}, '==', 2, 'each size 2');

### test $solr->select with one result

my $t2 = $solr->select(q => 'text:tic', hl => {fl => 'content'});
#warn Dumper $t2->decoded;
isa_ok($t2, 'Apache::Solr::Result');
ok($t2, 'select was successful');
is($t2->endpoint, "$server/select?wt=$format&q=text%3Atic&hl=true&hl.fl=content");

cmp_ok($t2->nrSelected, '==', 1);

my $d2 = $t2->selected(0);
#warn Dumper $d2;
isa_ok($d2, 'Apache::Solr::Document', 'got 1 answer');
isa_ok($d2->field('subject'), 'HASH', 'subject');
is($d2->field('subject')->{content}, '1 2 3');
is($d2->content('subject'), '1 2 3');
is($d2->_subject, '1 2 3');

#ok($d2->{hl}, 'got 1 hightlights');

### test $solr->select with two results

my $t3 = $solr->select(q => 'text:tac', rows => 1, hl => {fl => 'content'});
#warn Dumper $t3->decoded;
ok($t3, 'select was successfull');
isa_ok($t3, 'Apache::Solr::Result');
is($t3->endpoint, "$server/select?wt=$format&q=text%3Atac&rows=1&hl=true&hl.fl=content");

cmp_ok($t3->nrSelected, '==', 2, '2 items selected');

cmp_ok($t3->selectedPageSize, '==', 1, 'page size 1');
cmp_ok($t3->selectedPageNr(0), '==', 0, 'item 0 on page 0');
cmp_ok($t3->selectedPageNr(1), '==', 1, 'item 1 on page 1');

my $d3a = $t3->selected(0);
is($d3a->rank, 0, 'rank 0');
#warn Dumper $d3a;
my %id3 = ($d3a->uniqueId => $d3a);
isa_ok($d3a, 'Apache::Solr::Document', 'got 1 doc answer');

my $d3b = $t3->selected(1, $solr);
is($d3b->rank, 1, 'rank 1');
#warn Dumper $d3b;
isa_ok($d3b, 'Apache::Solr::Document', 'got 2 answer');
$id3{$d3b->uniqueId} = $d3b;
cmp_ok(keys %id3, '==', 2, 'both documents found');
ok($id3{1}, 'found id=1');
ok($id3{2}, 'found id=2');

my $h3a = $t3->highlighted($id3{1});
isa_ok($h3a, 'Apache::Solr::Document', 'got 1 hl answer');
is($h3a->_content, '<html>tic <em>tac</em>', 'test hl content');

### upload document

#my $t4 = $solr->extractDocument( #overwrite => 1, commit => 1
#   extractOnly => 1, file => 't/a.pdf');
my $t4 = $solr->extractDocument(overwrite => 1, commit => 1,
   literal_id => 3, file => 't/a.pdf');
ok($t4, 'uploaded document 3, an pdf')


