use strict;
use warnings;
use Test::More;
use Data::Dumper qw/Dumper/;

use Data::Context::BEM::Merge;

my $merger = Data::Context::BEM::Merge->new;;

merge();

done_testing();

sub merge {
    my $child = {
        content => [
            {},
            {
                block => "overridden",
                content => {
                    blcok => "arrayified",
                },
            },
        ],
        other => {
            some => "thing",
        },
    };
    my $parent = {
        block   => "page",
        content => [
            {
                block => "head",
            },
            {},
            {
                block => "foot",
            }
        ],
    };
    my $expected = {
        block   => "page",
        content => [
            {
                block => "head",
            },
            {
                block => "overridden",
                content => [
                    {
                        blcok => "arrayified",
                    },
                ],
            },
            {
                block => "foot",
            },
        ],
        other => {
            some => "thing",
        },
    };

    is_deeply $expected, $merger->merge($child, $parent), "Merge blocks correctly"
        or note Dumper $expected, $merger->merge($child, $parent);
}

