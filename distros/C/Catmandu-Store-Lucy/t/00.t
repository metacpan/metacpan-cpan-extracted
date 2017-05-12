#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Temp ();

my $pkg;
BEGIN {
    $pkg = 'Catmandu::Store::Lucy';
    use_ok $pkg;
}

require_ok $pkg;

my $index_path = File::Temp->newdir;

note "Index path is $index_path";

my $store = $pkg->new(path => $index_path);

isa_ok $store, $pkg;

is $store->path, $index_path;

my $bag = $store->bag;

isa_ok $bag, "${pkg}::Bag";

is_deeply $bag->_flatten_data({
    foo => 'foo',
    bar => [['bar']],
    baz => {baz=>[{'boz' => 'boz'},'baz']},
    fob => 'fob',
    foz => ['faz', 'foz'],
}), {
    'foo' => 'foo',
    'bar' => 'bar',
    'baz.baz.boz' => 'boz',
    'baz.baz' => 'baz',
    'fob' => 'fob',
    'foz' => 'foz',
};

my $data = $bag->add({lang => 'Perl'});
$bag->add({lang => 'Ruby'});
$bag->add({lang => 'Perl'});

is $bag->count, 0;

$bag->commit;

is $bag->count, 3;

is_deeply $bag->get($data->{_id}), $data;
is $bag->get('?'), undef;

my $hits = $bag->search;

isa_ok $hits, 'Catmandu::Hits';

is $hits->total, 3;

$hits = $bag->search(query => 'ruby');

is $hits->total, 1;

$bag->delete($data->{_id});
$bag->commit;

is $bag->count, 2;

$bag->delete_by_query(query => 'ruby');
$bag->commit;

is $bag->count, 1;

$bag->delete_all;
$bag->commit;

is $bag->count, 0;

done_testing;
