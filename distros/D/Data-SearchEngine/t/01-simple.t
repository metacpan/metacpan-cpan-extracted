use strict;
use Test::More;

use lib 't/lib';

use Data::SearchEngine;
use Data::SearchEngine::Query;
use SearchEngineWee;

my @data = (
    {
        id => '1',
        name => 'One Fish',
        description => 'A fish numbered one'
    },
    {
        id => '2',
        name => 'Two Fish',
        description => 'A fish numbered two'
    },
    {
        id => '3',
        name => 'Red Fish',
        description => 'A fish colored red '
    },
    {
        id => '4',
        name => 'Blue Fish',
        description => 'A fish colored blue'
    },
);

my $searcher = SearchEngineWee->new;
foreach my $prod (@data) {
    $searcher->add($prod);
}

{
    my $query = Data::SearchEngine::Query->new(query => 'Fish');
    my $results = $searcher->search($query);
    cmp_ok($results->query->query, 'eq', 'Fish', 'query');
    cmp_ok($results->pager->total_entries, '==', 4, '4 items in results');
    cmp_ok($results->get(0)->score, '==', 2, 'score is 2');
}

{
    my $query = Data::SearchEngine::Query->new(query => 'fish blue');
    my $results = $searcher->search($query);
    cmp_ok($results->query->query, 'eq', 'fish blue', 'query');
    cmp_ok($results->pager->total_entries, '==', 4, '4 items in results');

    my $first = $results->get(0);
    cmp_ok($first->score, '==', 4, 'high score is 4');
    cmp_ok($first->id, '==', 4, 'correct id');
    cmp_ok($first->get_value('name'), 'eq', 'Blue Fish', 'get value name');
    cmp_ok($first->get_value('description'), 'eq', 'A fish colored blue', 'get value description');
    cmp_ok($results->get(1)->score, '==', 2, 'second score is 2');
}

done_testing;