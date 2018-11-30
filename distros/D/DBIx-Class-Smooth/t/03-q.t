use 5.20.0;
use strict;
use warnings;
use Test::More;
use if $ENV{'AUTHOR_TESTING'}, 'Test::Warnings';

use DBIx::Class::Smooth::Q;
use experimental qw/postderef/;

my $tests = [
    {
        test => q{ Q(name => 'bob') },
        result => [-and => [name => 'bob']],
    },
    {
        test => q{ Q(name => 'bob') | Q(name => 'alice')},
        result => [-or => [name => 'bob', name => 'alice']],
    },
    {
        test => q{ (Q(name => 'Bob') | Q(name => 'Rob')) & Q(name => { -like => '%o%' }) },
        result => [
            -and => [
                -or => [
                    name => 'Bob',
                    name => 'Rob',
                ],
                name => {
                    -like => '%o%',
                }
            ]
        ]
    },
    {
        test => q{ (Q(name => 'Bob') | Q(name => 'Rob') | Q(name => 'Alice') | Q(name => 'Foo')) & Q(name => { -not_like => '%o%' }) },
        result => [
            -and => [
                -or => [
                    -or => [
                        name => 'Bob',
                        name => 'Rob',
                        name => 'Alice',
                    ],
                    name => 'Foo',
                ],
                name => {
                    -not_like => '%o%',
                }
            ]
        ]
    },
    {
        test => q{ (Q(name => 'Bob') | Q(name => 'Rob') | Q(name => 'Alice') | Q(name => 'Foo')) & Q(name => { -not_like => '%o%' }) & Q(name => { -like => '%e' }) & Q(last_name => 'Bar') },
        result => [
            -and => [
                -or => [
                    -or => [
                        name => 'Bob',
                        name => 'Rob',
                        name => 'Alice',
                    ],
                    name => 'Foo',
                ],
                name => { -not_like => '%o%' },
                name => { -like => '%e' },
                last_name => 'Bar',
            ]
        ]

    },
    {
        test => q{ Q(name => { -not_like => '%o%' }) & Q(name => { -like => '%e' }) & Q(last_name => 'Bar') & (Q(name => 'Bob') | Q(name => 'Rob') | Q(name => 'Alice') | Q(name => 'Foo')) },
        result => [
            -and => [
                name => { -not_like => '%o%' },
                name => { -like => '%e' },
                last_name => 'Bar',
                -or => [
                    -or => [
                        name => 'Bob',
                        name => 'Rob',
                        name => 'Alice',
                    ],
                    name => 'Foo',
                ],
            ]
        ]
    },
    {
        test => q{ Q(name => { -not_like => '%o%' }) & Q(Q(Q(name => 'a') & Q(name => { -like => '%e' })) | Q(last_name => 'Foo')) & Q(last_name => 'Bar') & Q(Q(name => 'Bob') | Q(name => 'Rob') | Q(name => 'Alice') | Q(name => 'Foo')) },
        result => [
            -and => [
                name => { -not_like => "%o%" },
                -or => [
                    -and => [
                        name => "a",
                        name => { -like => "%e" }
                    ],
                    last_name => "Foo",
                ],
                last_name => "Bar",
                -or => [
                    -or => [
                        name => "Bob",
                        name => "Rob",
                        name => "Alice",
                    ],
                    name => "Foo",
                ]
            ]
        ]
    },
];

for my $test (@{ $tests }) {
    next if !length $test->{'test'};
    my $got = eval($test->{'test'})->value;
    is_deeply $got, $test->{'result'}, $test->{'test'} or diag explain $got;
}

done_testing;
