use strict;
use warnings;

use Test::More 0.88; # for done_testing
use Test::Differences;
use Bencode 'bencode';

sub enc_ok {
	my ( $frozen, $thawed ) = @_;
	local $Test::Builder::Level = $Test::Builder::Level + 1;
	eq_or_diff bencode( $thawed ), $frozen, "encode $frozen";
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

done_testing;
