#!/usr/bin/perl
use 5.016;
use strict;
use warnings;

use Test::More;

use File::Spec;

use App::newver::INI qw(read_ini);

my $TEST_INI = File::Spec->catfile(qw/t data test.ini/);

my $ini = read_ini($TEST_INI);

is_deeply(
    $ini,
    {
        Gray => {
            Color => 'Gray',
            Home => '???',
            Alignment => 'Neutral Evil',
        },
        LGM => {
            Color => 'Green',
            Home => 'Mars',
            Alignment => 'Neutral Good',
        },
        Reptillian => {
            Color => 'Green',
            Home => 'Earth',
            Alignment => 'Lawful Evil',
        },
    },
    "read_ini ok"
);

done_testing;
