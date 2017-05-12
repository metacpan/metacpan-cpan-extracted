use strict;
use warnings;
use Test::More;

use File::Spec;
use File::Basename;
BEGIN {
    @ARGV = File::Spec->catfile(dirname(__FILE__), 'data', '01.json')
}

use ARGV::JSON;

is_deeply [ @ARGV::JSON::Data ], [
    {
        'bar' => {
            'baz' => undef
        },
        'foo' => [
            1,
            2,
            3
        ]
    },
    [
        'x',
        'y',
        'z'
    ],
    {}
];

is_deeply scalar <>, {
    foo => [1,2,3],
    bar => { baz => undef },
};

is_deeply [ <> ], [
    [ 'x', 'y', 'z' ],
    {},
];

is scalar <>, undef;

done_testing;
