use strict;
use warnings;

use Test::More;
use if $ENV{'AUTHOR_TESTING'}, 'Test::Warnings';
BEGIN {
    use_ok 'Badge::Depot';
}

use lib 't/corpus/lib';
use Badge::Depot::Plugin::Afakebadge;
use Badge::Depot::Plugin::Afakebadgewithoutimage;

my $tests = [
    {
        name => 'Correct usage (link, no alt)',
        class => 'Afakebadge',
        args => { username => 'fakeuser', repo => 'fakerepo' },
        is => [
            {
                method => 'link_url',
                expected => 'https://travis-ci.org/fakeuser/fakerepo',
                name => 'Correct link url',
            },
            {
                method => 'image_url',
                expected => 'https://travis-ci.org/fakeuser/fakerepo.svg?branch=master',
                name => 'Correct image url',
            },
            {
                method => 'to_html',
                expected => '<a href="https://travis-ci.org/fakeuser/fakerepo"><img src="https://travis-ci.org/fakeuser/fakerepo.svg?branch=master" /></a>',
                name => 'Correct html',
            },
            {
                method => 'to_markdown',
                expected => '[![](https://travis-ci.org/fakeuser/fakerepo.svg?branch=master)](https://travis-ci.org/fakeuser/fakerepo)',
                name => 'Correct markdown',
            }
        ],
    },
    {
        name => 'Correct usage (link, alt)',
        class => 'Afakebadge',
        args => { username => 'fakeuser', repo => 'fakerepo', alt_text => 'Fake alt text' },
        is => [
            {
                method => 'link_url',
                expected => 'https://travis-ci.org/fakeuser/fakerepo',
                name => 'Correct link url',
            },
            {
                method => 'image_url',
                expected => 'https://travis-ci.org/fakeuser/fakerepo.svg?branch=master',
                name => 'Correct image url',
            },
            {
                method => 'to_html',
                expected => '<a href="https://travis-ci.org/fakeuser/fakerepo"><img src="https://travis-ci.org/fakeuser/fakerepo.svg?branch=master" alt="Fake alt text" /></a>',
                name => 'Correct html',
            },
            {
                method => 'to_markdown',
                expected => '[![Fake alt text](https://travis-ci.org/fakeuser/fakerepo.svg?branch=master)](https://travis-ci.org/fakeuser/fakerepo)',
                name => 'Correct markdown',
            }
        ],
    },
    {
        name => 'Correct usage (no link, no alt)',
        class => 'Afakebadge',
        args => { username => 'fakeuser', repo => 'fakerepo', dont_link => 1 },
        is => [
            {
                method => 'link_url',
                expected => undef,
                name => 'Correct link url',
            },
            {
                method => 'image_url',
                expected => 'https://travis-ci.org/fakeuser/fakerepo.svg?branch=master',
                name => 'Correct image url',
            },
            {
                method => 'to_html',
                expected => '<img src="https://travis-ci.org/fakeuser/fakerepo.svg?branch=master" />',
                name => 'Correct html',
            },
            {
                method => 'to_markdown',
                expected => '![](https://travis-ci.org/fakeuser/fakerepo.svg?branch=master)',
                name => 'Correct markdown',
            }
        ],
    },
    {
        name => 'Correct usage (no link, alt)',
        class => 'Afakebadge',
        args => { username => 'fakeuser', repo => 'fakerepo', alt_text => 'Fake alt text', dont_link => 1 },
        is => [
            {
                method => 'link_url',
                expected => undef,
                name => 'Correct link url',
            },
            {
                method => 'image_url',
                expected => 'https://travis-ci.org/fakeuser/fakerepo.svg?branch=master',
                name => 'Correct image url',
            },
            {
                method => 'to_html',
                expected => '<img src="https://travis-ci.org/fakeuser/fakerepo.svg?branch=master" alt="Fake alt text" />',
                name => 'Correct html',
            },
            {
                method => 'to_markdown',
                expected => '![Fake alt text](https://travis-ci.org/fakeuser/fakerepo.svg?branch=master)',
                name => 'Correct markdown',
            }
        ],
    },
    {
        name => 'Without image',
        class => 'Afakebadgewithoutimage',
        args => { username => 'fakeuser' },
        is => [
            {
                method => 'to_html',
                expected => '',
                name => 'Correct html (no output)',
            },
            {
                method => 'to_markdown',
                expected => '',
                name => 'Correct markdown (no output)',
            }
        ],
    },
];

foreach my $test (@$tests) {
    subtest $test->{'name'} => sub {
        my $package = sprintf 'Badge::Depot::Plugin::%s', $test->{'class'};
        my $badge = $package->new(%{ $test->{'args'}});

        foreach my $is (@{ $test->{'is'} }) {
            my $method = $is->{'method'};
            is $badge->$method, $is->{'expected'}, $is->{'name'};
        }

        done_testing;
    };
}

done_testing;
