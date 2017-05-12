use strict;
use warnings;

use Test::More;
use Test::Exception;

use Convert::Base32 qw( encode_base32 decode_base32 );

my @tests = (
    [ ''       =>  0            ],

    [ a        => 'bad len'     ],

    [ ae       =>  1            ],
    [ ac       => 'bad padding' ],
    [ ab       => 'bad padding' ],

    [ aaa      => 'bad len'     ],

    [ aaaq     =>  2            ],
    [ aaai     => 'bad padding' ],
    [ aaae     => 'bad padding' ],
    [ aaac     => 'bad padding' ],
    [ aaab     => 'bad padding' ],

    [ aaaac    =>  3            ],
    [ aaaab    => 'bad padding' ],

    [ aaaaaa   => 'bad len'     ],

    [ aaaaaai  =>  4            ],
    [ aaaaaae  => 'bad padding' ],
    [ aaaaaac  => 'bad padding' ],
    [ aaaaaab  => 'bad padding' ],
);

plan tests => 2*@tests + 2*512;

for (@tests) {
    my ($e, $dlen) = @$_;
    if ($dlen =~ /^[0-9]+\z/) {
        lives_and { is length(decode_base32($e)), $dlen } "$e (ok)";
    } else {
        dies_ok { decode_base32($e) } "$e ($dlen)";
    }
}

for (@tests) {
    my ($e, $dlen) = @$_;
    $e = "aaaaaaaa$e";
    if ($dlen =~ /^[0-9]+\z/) {
	lives_and { is length(decode_base32($e)), 5+$dlen } "$e (ok)";
    } else {
	dies_ok { decode_base32($e) } "$e ($dlen)";
    }
}


my %syms = map { $_ => 1 } ( 'a'..'z', 'A'..'Z', '2'..'7' );

for my $o (0..511) {
    my $c = chr($o);

    if ( ( $o >= ord('a') && $o <= ord('z') )
    ||   ( $o >= ord('A') && $o <= ord('Z') )
    ||   ( $o >= ord('2') && $o <= ord('7') ) ) {
	lives_ok { decode_base32("aaaaaaa$c") } sprintf('decode U+%04X (ok)', $o);
    } else {
	dies_ok { decode_base32("aaaaaaa$c") } sprintf('decode U+%04X (bad)', $o)
    }

    if ($o < 256) {
	lives_ok { encode_base32($c) } sprintf('encode U+%04X (ok)', $o);
    } else {
	dies_ok { encode_base32($c) } sprintf('encode U+%04X (bad)', $o);
    }
}
