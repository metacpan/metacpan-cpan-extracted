use strict;
use warnings;
use Test::More;

use Config::INI::Reader::Multiline;

my @fail = (    # input, expected error, message
    [
        'bloop bap bang_eth',
        qr/Syntax error at line 1: 'bloop bap bang_eth'/i,
        'syntax error (no = sign)'
    ],
    [
        <<~ 'INI',
        [plop]
        glurpp = splatt \
        INI
        qr/Continuation on the last line: 'glurpp = splatt \\'/i,
        'no continuation on the last line (value)',
    ],
    [
        <<~ 'INI',
        [z_zwap]
        crash = zwapp

        [ker_plop] \
        INI
        qr/Continuation on the last line: '\[ker_plop\] \\'/i,
        'no continuation on the last line (section)',
    ],
    [
        <<~ 'INI',
        [z_zwap]
        crash = zwapp
           \
        INI
        qr/Continuation on the last line: ' \\'/i,
        'no continuation on the last line (empty line)',
    ],
);

for my $test (@fail) {
    my ( $input, $expected, $message ) = @$test;
    eval { Config::INI::Reader::Multiline->read_string($input); };
    like( $@, $expected, $message );
}

done_testing;
