#!perl

use strict;
use warnings;

use Test::More;
use CSAF::Util::List;

my $collection = CSAF::Util::List->new(1, 2);

subtest 'size' => sub {
    is($collection->size, 2, 'Test size #1');
    $collection->add(3);
    is($collection->size, 3, 'Size #2');
};

is($collection->first, 1, 'Test first');
is($collection->last,  3, 'Test last');

subtest 'join' => sub {
    is($collection->join,      '123',   'Test join #1');
    is($collection->join(','), '1,2,3', 'Test join #2');
};

subtest 'to_array' => sub {
    isa_ok($collection->to_array, 'ARRAY', 'Test to_array #1');
    isa_ok(\@{$collection},       'ARRAY', 'Test to_array #2');
};

subtest 'each' => sub {

    is_deeply [$collection->each], [1, 2, 3], 'Test each #1';

    my @test = ();
    $collection->each(sub { push @test, $_[0] });

    is_deeply \@test, [1, 2, 3], 'Test each #2';

};

done_testing();
