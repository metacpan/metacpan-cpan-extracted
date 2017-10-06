use strict;
use warnings;

use Test::More tests => 25;
use Bencode 'bencode';

sub enc_ok {
	my ( $frozen, $thawed ) = @_;
	local $Test::Builder::Level = $Test::Builder::Level + 1;
	is bencode( $thawed ), $frozen, "encode $frozen";
}

enc_ok 'i4e'                      => 4;
enc_ok 'i0e'                      => 0;
enc_ok 'i-10e'                    => -10;
enc_ok 'i12345678901234567890e'   => '12345678901234567890';
enc_ok '0:'                       => '';
enc_ok '3:abc'                    => 'abc';
enc_ok '10:1234567890'            => \'1234567890';
enc_ok 'le'                       => [];
enc_ok 'li1ei2ei3ee'              => [ 1, 2, 3 ];
enc_ok 'll5:Alice3:Bobeli2ei3eee' => [ [ 'Alice', 'Bob' ], [ 2, 3 ] ];
enc_ok 'de'                       => {};
enc_ok 'd3:agei25e4:eyes4:bluee'  => { 'age' => 25, 'eyes' => 'blue' };
enc_ok 'd8:spam.mp3d6:author5:Alice6:lengthi100000eee' => { 'spam.mp3' => { 'author' => 'Alice', 'length' => 100000 } };

is bencode( undef ),        '0:',  'undef in implicit default mode';
is bencode( undef, undef ), '0:',  'undef in explicit default mode';
is bencode( undef, 'str' ), '0:',  'undef in str mode';
is bencode( undef, 'num' ), 'i0e', 'undef in num mode';

{
	my $frozen = eval { bencode [[[undef]]], 'die' }; my $e = $@;
	is $frozen, undef, 'undef in die mode';
	is $e, sprintf( "unhandled data type at %s line %d.\n", __FILE__, __LINE__ - 2 ), '... fails for the right reason';
}

for my $mode ( qw( foo bar baz ) ) {
	my $frozen = eval { bencode 1, $mode }; my $e = $@;
	is $frozen, undef, qq'bad undef mode "$mode"';
	is $e, sprintf( qq'undef_mode argument must be "str", "num", "die" or undefined, not "%s" at %s line %d.\n', $mode, __FILE__, __LINE__ - 2 ), '... fails for the right reason';
}
