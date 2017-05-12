#!/perl

use strict;
use warnings;
use Test::More tests => 2;

use Data::Debug;

use_ok("Data::Debug");
require_ok("Data::Debug");

sub _data {
    return {
        array => [
            { paynum => 1 },
            { paynum => 2 }
        ],
        hi => 'bye',
        pkgnum => 42,
        hash => {
            what => 'how?',
            another_hash => {
                some_key => 'yeah',
                custnum  => 2
            },
            custnum => 1,
            rows => [
                { agent => 'voldemort' },
                { agent => 'smith' }
            ]
        }
    };
}
