#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;

use lib "$FindBin::Bin/../lib";

use Test::More;

use App::Muter;

eval { require Test::NoWarnings; };

my @examples = (
    {
        chain  => 'hex',
        parsed => [
            {
                name   => 'hex',
                method => 'encode',
                args   => [],
            }
        ]
    }, {
        chain  => '-hex',
        parsed => [
            {
                name   => 'hex',
                method => 'decode',
                args   => [],
            }
        ]
    }, {
        chain   => 'hex',
        reverse => 1,
        parsed  => [
            {
                name   => 'hex',
                method => 'decode',
                args   => [],
            }
        ]
    }, {
        chain   => '-hex',
        reverse => 1,
        parsed  => [
            {
                name   => 'hex',
                method => 'encode',
                args   => [],
            }
        ]
    }, {
        chain  => '-hex:base64',
        parsed => [
            {
                name   => 'hex',
                method => 'decode',
                args   => [],
            }, {
                name   => 'base64',
                method => 'encode',
                args   => [],
            }
        ]
    }, {
        chain  => '-hex(upper):xml(html):hash(sha256)',
        parsed => [
            {
                name   => 'hex',
                method => 'decode',
                args   => ['upper'],
            }, {
                name   => 'xml',
                method => 'encode',
                args   => ['html'],
            }, {
                name   => 'hash',
                method => 'encode',
                args   => ['sha256'],
            }
        ]
    }, {
        chain  => '-hex(upper):xml(html):hash(sha256):vis(glob,space,tab)',
        parsed => [
            {
                name   => 'hex',
                method => 'decode',
                args   => ['upper'],
            }, {
                name   => 'xml',
                method => 'encode',
                args   => ['html'],
            }, {
                name   => 'hash',
                method => 'encode',
                args   => ['sha256'],
            }, {
                name   => 'vis',
                method => 'encode',
                args   => [qw/glob space tab/],
            }
        ]
    }, {
        chain   => '-hex(upper):xml(html):vis(glob,space,tab)',
        reverse => 1,
        parsed  => [
            {
                name   => 'vis',
                method => 'decode',
                args   => [qw/glob space tab/],
            }, {
                name   => 'xml',
                method => 'decode',
                args   => ['html'],
            }, {
                name   => 'hex',
                method => 'encode',
                args   => ['upper'],
            }
        ]
    },
);

foreach my $test (@examples) {
    is_deeply(
        $test->{parsed},
        [App::Muter::Chain->_parse_chain($test->{chain}, $test->{reverse})],
        "$test->{chain} parses properly"
    );
}

Test::NoWarnings::had_no_warnings() if $INC{'Test/NoWarnings.pm'};

done_testing();
