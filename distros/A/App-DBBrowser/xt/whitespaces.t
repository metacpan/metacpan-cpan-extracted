use 5.016;
use strict;
use warnings;


use Test::Whitespaces {

    dirs => [
        'bin',
        'lib',
        't',
        'xt',
    ],

    files => [
        'README',
        'Makefile.PL',
        'Changes',
    ],

};
