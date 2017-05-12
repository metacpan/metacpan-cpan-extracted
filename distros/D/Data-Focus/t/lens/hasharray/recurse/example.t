use strict;
use warnings FATAL => "all";
use Test::More;
use Data::Focus qw(focus);
use Data::Focus::Lens::HashArray::Recurse;

{
    note("-- SYNOPSIS");
    
    my $target = [
        {foo => 1, bar => 2},
        3,
        [4, 5, 6],
        [],
        {},
        {hoge => 7},
    ];
    
    my $lens = Data::Focus::Lens::HashArray::Recurse->new;
    
    my $result = focus($target)->over($lens, sub { $_[0] * 100 });
    
    is_deeply(
        $result,
        [
            {foo => 100, bar => 200},
            300,
            [400, 500, 600],
            [],
            {},
            {hoge => 700}
        ],
        "synopsis result OK"
    );
}

done_testing;
