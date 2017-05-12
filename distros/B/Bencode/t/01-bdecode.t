use strict;
use warnings;

use Test::More 0.88; # for done_testing
use Test::Differences;
use Bencode 'bdecode';

sub un {
	my ( $frozen ) = @_;
	local $, = ', ';
	return 'ARRAY' eq ref $frozen
		? ( "decode [@$frozen]", bdecode @$frozen )
		: ( "decode '$frozen'",  bdecode  $frozen );
}

sub decod_ok {
	my ( $frozen, $thawed ) = @_;
	my ( $testname, $result ) = un $frozen;
	local $Test::Builder::Level = $Test::Builder::Level + 1;
	eq_or_diff $result, $thawed, $testname;
}

sub error_ok {
	my ( $frozen, $error_rx, $kind_of_brokenness ) = @_;
	local $@;
	eval { un $frozen };
	local $Test::Builder::Level = $Test::Builder::Level + 1;
	like $@, $error_rx, "reject $kind_of_brokenness";
}

error_ok '0:0:'          => qr/\Atrailing garbage at 2\b/, 'data past end of first correct bencoded string';
error_ok 'i'             => qr/\Aunexpected end of data at 1\b/, 'aborted integer';
error_ok 'i0'            => qr/\Amalformed integer data at 1\b/, 'unterminated integer';
error_ok 'ie'            => qr/\Amalformed integer data at 1\b/, 'empty integer';
error_ok 'i341foo382e'   => qr/\Amalformed integer data at 1\b/, 'malformed integer';
decod_ok 'i4e'           => 4;
decod_ok 'i0e'           => 0;
decod_ok 'i123456789e'   => 123456789;
decod_ok 'i-10e'         => -10;
error_ok 'i-0e'          => qr/\Amalformed integer data at 1\b/, 'negative zero integer';
error_ok 'i123'          => qr/\Amalformed integer data at 1\b/, 'unterminated integer';
error_ok ''              => qr/\Aunexpected end of data at 0/, 'empty data';
error_ok '1:'            => qr/\Aunexpected end of string data starting at 2\b/, 'string longer than data';
error_ok 'i6easd'        => qr/\Atrailing garbage at 3\b/, 'integer with trailing garbage';
error_ok '35208734823ljdahflajhdf' => qr/\Agarbage at 0/, 'garbage looking vaguely like a string, with large count';
error_ok '2:abfdjslhfld' => qr/\Atrailing garbage at 4\b/, 'string with trailing garbage';
decod_ok '0:'            => '';
decod_ok '3:abc'         => 'abc';
decod_ok '10:1234567890' => '1234567890';
error_ok '02:xy'         => qr/\Amalformed string length at 0\b/, 'string with extra leading zero in count';
error_ok 'l'             => qr/\Aunexpected end of data at 1\b/, 'unclosed empty list';
decod_ok 'le'            => [];
error_ok 'leanfdldjfh'   => qr/\Atrailing garbage at 2\b/, 'empty list with trailing garbage';
decod_ok 'l0:0:0:e'      => [ '', '', '' ];
error_ok 'relwjhrlewjh'  => qr/\Agarbage at 0/, 'complete garbage';
decod_ok 'li1ei2ei3ee'   => [ 1, 2, 3 ];
decod_ok 'l3:asd2:xye'   => [ 'asd', 'xy' ];
decod_ok 'll5:Alice3:Bobeli2ei3eee' => [ [ 'Alice', 'Bob' ], [ 2, 3 ] ];
error_ok 'd'             => qr/\Aunexpected end of data at 1\b/, 'unclosed empty dict';
error_ok 'defoobar'      => qr/\Atrailing garbage at 2\b/, 'empty dict with trailing garbage';
decod_ok 'de'            => {};
decod_ok 'd3:agei25e4:eyes4:bluee' => { 'age' => 25, 'eyes' => 'blue' };
decod_ok 'd8:spam.mp3d6:author5:Alice6:lengthi100000eee' => { 'spam.mp3' => { 'author' => 'Alice', 'length' => '100000' } };
error_ok 'd3:fooe'       => qr/\Adict key is missing value at 7\b/, 'dict with odd number of elements';
error_ok 'di1e0:e'       => qr/\Adict key is not a string at 1/, 'dict with integer key';
error_ok 'd1:b0:1:a0:e'  => qr/\Adict key not in sort order at 9/, 'missorted keys';
error_ok 'd1:a0:1:a0:e'  => qr/\Aduplicate dict key at 9/, 'duplicate keys';
error_ok 'i03e'          => qr/\Amalformed integer data at 1/, 'integer with leading zero';
error_ok 'l01:ae'        => qr/\Amalformed string length at 1/, 'list with string with leading zero in count';
error_ok '9999:x'        => qr/\Aunexpected end of string data starting at 5/, 'string shorter than count';
error_ok 'l0:'           => qr/\Aunexpected end of data at 3/, 'unclosed list with content';
error_ok 'd0:0:'         => qr/\Aunexpected end of data at 5/, 'unclosed dict with content';
error_ok 'd0:'           => qr/\Aunexpected end of data at 3/, 'unclosed dict with odd number of elements';
error_ok '00:'           => qr/\Amalformed string length at 0/, 'zero-length string with extra leading zero in count';
error_ok 'l-3:e'         => qr/\Amalformed string length at 1/, 'list with negative-length string';
error_ok 'i-03e'         => qr/\Amalformed integer data at 1/, 'negative integer with leading zero';
decod_ok "2:\x0A\x0D"    => "\x0A\x0D";

decod_ok ['d1:a0:e', 0, 1]        => { a => '' }, # Accept single dict when max_depth is 1
error_ok ['d1:a0:e', 0, 0]        => qr/\Anesting depth exceeded at 1/, 'single dict when max_depth is 0';
decod_ok ['d1:ad1:a0:ee', 0, 2]   => { a => { a => '' } }, # Accept a nested dict when max_depth is 2
error_ok ['d1:ad1:a0:ee', 0, 1]   => qr/\Anesting depth exceeded at 5/, 'nested dict when max_depth is 1';
decod_ok ['l0:e', 0, 1]           => [ '' ], # Accept single list when max_depth is 1
error_ok ['l0:e', 0, 0]           => qr/\Anesting depth exceeded at 1/, 'single list when max_depth is 0';
decod_ok ['ll0:ee', 0, 2]         => [ [ '' ] ], # Accept a nested list when max_depth is 2
error_ok ['ll0:ee', 0, 1]         => qr/\Anesting depth exceeded at 2/, 'nested list when max_depth is 1';
decod_ok ['d1:al0:ee', 0, 2]      => { a => [ '' ] }, # Accept dict containing list when max_depth is 2
error_ok ['d1:al0:ee', 0, 1]      => qr/\Anesting depth exceeded at 5/, 'list in dict when max_depth is 1';
decod_ok ['ld1:a0:ee', 0, 2]      => [ { 'a'  => '' } ], # Accept list containing dict when max_depth is 2
error_ok ['ld1:a0:ee', 0, 1]      => qr/\Anesting depth exceeded at 2/, 'dict in list when max_depth is 1';
decod_ok ['d1:a0:1:bl0:ee', 0, 2] => { a => '', b => [ '' ] }, # Accept dict containing list when max_depth is 2
error_ok ['d1:a0:1:bl0:ee', 0, 1] => qr/\Anesting depth exceeded at 10/, 'list in dict when max_depth is 1';

eq_or_diff(
	bdecode( 'd1:b0:1:a0:e', 1 ),
	{ a => '', b => '', },
	'accept missorted keys when decoding leniently',
);

done_testing;
