use strict;
use warnings;

use Test::More;

use Convert::Base32 qw( encode_base32 decode_base32 );

my @tests = (
    [ "\x3a\x27\x0f\x93"     => 'hitq7ey'  ],
    [ "\x3a\x27\x0f\x93\x2a" => 'hitq7ezk' ],
);

{
    my @syms = ( 'a'..'z', '2'..'7' );
    my $e;
    my $d;
    for (0..$#syms) {
	my $sym = $syms[$_];
	$e .= "aaaaaaa$sym";
	$d .= pack('C5', 0,0,0,0,$_);
    }
    push @tests, [ $d, $e ];
}

{
    my $d = join '', map chr, 0..255;
    my $e = join '', qw(
	aaaqeayeaudaocajbifqydiob4ibceqtcqkrmfyy
	denbwha5dypsaijcemsckjrhfausukzmfuxc6mbr
	giztinjwg44dsor3hq6t4p2aifbegrcfizduqskk
	jnge2tspkbiveu2ukvlfowczljnvyxk6l5qgcytd
	mrswmz3infvgw3dnnzxxa4lson2hk5txpb4xu634
	pv7h7aebqkbyjbmgq6eitculrsgy5d4qsgjjhfev
	s2lzrgm2tooj3hu7ucq2fi5euwtkpkfjvkv2zlno
	v6yldmvtws23nn5yxg5lxpf5x274bqocypcmlrwh
	zde4vs6mzxhm7ugr2lj5jvow27mntww33to55x7a
	4hrohzhf43t6r2pk5pwo33xp6dy7f47u6x3pp6hz
	7l57z7p674
    );
    push @tests, [ $d, $e ];
}

plan tests => 3 * @tests;

sub hexify {
    my $s = $_[0];
    $s =~ s/(.)/ sprintf '%02X ', ord($1) /seg;
    chop $s;
    return $s;
}

for (@tests) {
    my $d = $_->[0];
    my $e = lc($_->[1]);
    my $E = uc($_->[1]);

    is        encode_base32($d),         $e,  "encode ".hexify($d);
    is hexify(decode_base32($e)), hexify($d), "decode $e";
    is hexify(decode_base32($E)), hexify($d), "decode $E";
}
