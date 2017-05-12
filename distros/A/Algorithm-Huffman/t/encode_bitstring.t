#!/usr/bin/perl

use Algorithm::Huffman;
use String::Random qw/random_string/;
use Test::More tests => 5 * 20 + 2;
use List::Util qw/max/;
use Data::Dumper;
use Test::Exception;

use constant MAX_COUNT            =>  1_000;
use constant MAX_SUBSTRING_LENGTH =>     10;
use constant HUFFMAN_ELEMENTS     =>  5_000;
use constant LONG_STRING_LENGTH   => 10_000;

sub myrand($) {
    return int( rand( int rand shift() ) + 1 );
}

# Create a random counting
my %counting = map {   random_string('c' x myrand MAX_SUBSTRING_LENGTH) 
                    => myrand(MAX_COUNT)
                   }
                   (1 .. HUFFMAN_ELEMENTS);
$counting{$_} = myrand(MAX_COUNT) for ('a' .. 'z');
my $huff = Algorithm::Huffman->new(\%counting);
my $encode_hash = $huff->encode_hash;

my $max_length = max map length, keys %counting;

for (1 .. 20) {
    my $s = random_string('c' x LONG_STRING_LENGTH);
    my $c = "";
    my $index = 0;
    while ($index < LONG_STRING_LENGTH) {
        for my $l (reverse (1 .. $max_length)) {
            if (my $bitcode = $encode_hash->{substr($s, $index, $l)}) {
                $c .= $bitcode;
                $index += $l;
                last;
            }
        }
    }
    my $encoded_with_huffman = $huff->encode_bitstring($s);
    is $encoded_with_huffman, $c, "Coded huffman string of '$s'"
    or diag Dumper($huff);
    
    my $encoded_with_huffman_bitvector = $huff->encode($s);
    is $encoded_with_huffman_bitvector,
       pack("b*", $encoded_with_huffman), 
       "->encode('$s') checked with pack";
    
    cmp_ok length($encoded_with_huffman)/8, "<=", LONG_STRING_LENGTH, 
       "Encoding produced a compression lower than only the compression of 26 characters";
    
    is $huff->decode_bitstring($encoded_with_huffman),
       $s,
       "Decoding of encoding bitstring should be the same as the orig";
       
    is $huff->decode($encoded_with_huffman_bitvector),
       $s,
       "Decoding of encoding (packed) bitvector should be the same as the orig";
}

my $string    = random_string('c' x LONG_STRING_LENGTH);

UNKNOWN_CHAR_IN_BITSTRING_SHOULD_PRODUCE_AN_EXCEPTION: {
    my $bitstring = $huff->encode_bitstring($string);
    substr($bitstring,length($string)/2,1) = "a";
    throws_ok {$huff->decode_bitstring($bitstring)} 
              qr/unknown/i, 
              "Unknown character (an a instead 0/1) into the bitstring";
}

BITSTRING_TOO_SHORT: {
    my $bitstring = $huff->encode_bitstring($string);
    $bitstring = substr($bitstring,0,length($bitstring-1));
    dies_ok {$huff->decode_bitstring($bitstring)}
            "Removed the last bit of the bitstring -> should die";
}
