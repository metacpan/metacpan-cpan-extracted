#!/usr/bin/perl -w

#use lib '../blib/lib', '../blib/arch';

##  BitVectorDemo.pl

use strict;
use Algorithm::BitVector 1.24;

# Construct an EMPTY bitvector (a bitvector of size 0):
print "\nConstructing an EMPTY bitvector (a bitvector of size 0):\n";
my $bv1 = Algorithm::BitVector->new( size => 0 );
print "$bv1\n";                                   # no output

# Construct a bitvector of size 2:
print "\nConstructing a bitvector of size 2:\n";
my $bv2 = Algorithm::BitVector->new( size => 2 );
print "$bv2\n";                                   # 00

# Joining two bitvectors:
print "\nConcatenating two previously constructed bitvectors:\n";
my $result = $bv1 + $bv2;
print "$result\n";                                # 00

# The following works because Perl implicitly first stringyfies each
# argument before invoking the `.' operator
$result = $bv1 . $bv2;
print "$result\n";                                # 00

# Construct a bitvector with a list of bits:    
print "\nConstructing a bitvector from a list of bits:\n";
my $bv = Algorithm::BitVector->new( bitlist => [1, 1, 0, 1] );
print "$bv\n";                                    # 1101

# Construct a bitvector from an integer
$bv = Algorithm::BitVector->new( intVal => 5678 );
print "\nbitvector constructed from integer 5678:\n";
print "$bv\n";                                    # 1011000101110
print "\nbitvector constructed from integer 0:\n";
$bv = Algorithm::BitVector->new( intVal => 0 );
print "$bv\n";                                    # 0
print "\nbitvector constructed from integer 2:\n";
$bv = Algorithm::BitVector->new( intVal => 2 );
print "$bv\n";                                    # 10
print "\nbitvector constructed from integer 3:\n";
$bv = Algorithm::BitVector->new( intVal => 3 );
print "$bv\n";                                    # 11
print "\nbitvector constructed from integer 123456:\n";
$bv = Algorithm::BitVector->new( intVal => 123456 );
print "$bv\n";                                    # 11110001001000000
print "\nInt value of the previous bitvector as computed by int_value():\n";
print int($bv) . "\n";                            # 123456

# Construct a bitvector from a very large integer:
use Math::BigInt;
my $x = Math::BigInt->new('12345678901234567890123456789012345678901234567890');
$bv = Algorithm::BitVector->new( intVal => $x );
print "\nHere is a bitvector constructed from a very large integer:\n";
print "$bv\n";
printf "The integer value of the above bitvector shown as a string is:  %s\n", $bv->int_value();
print "Size of the bitvector: " . $bv->length() . "\n";

# Construct a bitvector of a specified length from a large integer:
$bv =Algorithm::BitVector->new(intVal => Math::BigInt->new("89485765"), size => 32);
print "\nHere is a bitvector of a specified size constructed from a large integer:\n";
my $len= $bv->length();
print "$bv\n";
print "size of bitvec: $len\n";
printf "The integer value of the above bitvector shown as a string is:  %s\n", $bv->int_value();
print "Size of the bitvector: " . $bv->length() . "\n";

# Construct a bitvector directly from a bit string:
$bv = Algorithm::BitVector->new( bitstring => '00110011' );
print "\nBitvector constructed directly from a bit string:\n";
print "$bv\n";                                    # 00110011
$bv = Algorithm::BitVector->new( bitstring => '');
print "\nBitvector constructed directly from an empty bit string:\n";
print "$bv\n";                                    # nothing
print "\nInteger value of the previous bitvector:\n";
print int($bv) . "\n";                            # 0

# Construct a bitvector directly from an ASCII text string:
print "\nConstructing a bitvector from the textstring 'hello':\n";
my $bv3 = Algorithm::BitVector->new( textstring => "hello" );
print "$bv3\n";              # 0110100001100101011011000110110001101111
#my $mytext = $bv3->get_text_from_bitvector();
my $mytext = $bv3->get_bitvector_in_ascii();
print "Text recovered from the previous bitvector:\n";
print "$mytext\n";                                         # hello
print "\nConstructing a bitvector from the textstring 'hello\\njello':\n";
$bv3 = Algorithm::BitVector->new( textstring => "hello\njello" );
print "$bv3\n";            
  # 0110100001100101011011000110110001101111000010100110101001100101011011000110110001101111
#$mytext = $bv3->get_text_from_bitvector();
$mytext = $bv3->get_bitvector_in_ascii();
print "Text recovered from the previous bitvector:\n";
print "$mytext\n";                                         # hello
                                                           # jello

# Construct a bitvector directly from a hex string:
print "\nConstructing a bitvector from the hexstring '68656c6c6f':\n";
my $bv4 = Algorithm::BitVector->new( hexstring => "68656c6c6f" );
print "$bv4\n";             # 0110100001100101011011000110110001101111
#my $myhexstring = $bv4->get_hex_string_from_bitvector();
my $myhexstring = $bv4->get_bitvector_in_hex();
print "Hex string recovered from the previous bitvector: \n";
print "$myhexstring\n";                                    # 68656c6c6f

# Test get_bit() based array-like indexing for a bitvector:
$bv = Algorithm::BitVector->new( bitstring => '10111' );
print "\nPrints out bits individually from bitstring 10111:\n";
print $bv->get_bit(0), $bv->get_bit(1), $bv->get_bit(2), $bv->get_bit(3), $bv->get_bit(4), "\n";      # 10111
print "\nSame as above but using negative array indexing:\n";
print $bv->get_bit(-1), $bv->get_bit(-2), $bv->get_bit(-3), $bv->get_bit(-4), $bv->get_bit(-5), "\n";

# Test setting bit values with positive and negative accessors:
$bv = Algorithm::BitVector->new( bitstring => '1111' );
print "\nBitstring for 1111:\n";
print "$bv\n";                                    # 1111
print "\nReset individual bits of above vector:\n";
$bv->set_bit(0,0); $bv->set_bit(1,0); $bv->set_bit(2,0); $bv->set_bit(3,0); 
print "$bv\n";                                    # 0000
print "\nDo the same as above with negative indices:\n";
$bv->set_bit(-1,1); $bv->set_bit(-2,1); $bv->set_bit(-4,1);
print "$bv\n";                                    # 1011

# Check spaceship overloading for numeric comparison operators:
print "\nCheck equality and inequality ops:\n";
$bv1 = Algorithm::BitVector->new( bitstring => '00110011' );
$bv2 = Algorithm::BitVector->new( bitlist => [0,0,1,1,0,0,1,1] );
$bv1 == $bv2 ? print "1\n" : print "0\n";              # 1
$bv1 != $bv2 ? print "1\n" : print "0\n";              # 0
$bv1 < $bv2  ? print "1\n" : print "0\n";              # 0
$bv1 <= $bv2 ? print "1\n" : print "0\n";              # 1
$bv3 = Algorithm::BitVector->new( intVal => 5678 );
print $bv3->int_value(), "\n";                          # 5678
print "$bv3\n";                                        # 1011000101110
$bv1 == $bv3 ? print "1\n" : print "0\n";              # 0
$bv3 > $bv1  ? print "1\n" : print "0\n";              # 1
$bv3 >= $bv1 ? print "1\n" : print "0\n";              # 1

# Check overloading of bitwise logical operators:
print "\nExperiments with bitwise logical operations:\n";
$bv = $bv1 | $bv2;
print "$bv\n";                                         # 00110011
$bv = $bv1 | $bv3;
print "$bv\n";                                         # 1011000111111
$bv = $bv1 & $bv2;
print "$bv\n";                                         # 00110011
$bv = $bv1 + $bv2;
print "$bv\n";                                         # 0011001100110011
$bv4 = Algorithm::BitVector->new( size => 3 );
print "$bv4\n";                                        # 000
my $bv5 = $bv + $bv4;
print "$bv5\n";                                        # 0011001100110011000
my $bv6 = ~$bv5;     
print "$bv6\n";                                        # 1100110011001100111
my $bv7 = $bv5 & $bv6;
print "$bv7\n";                                        # 0000000000000000000
$bv7 = $bv5 | $bv6;
print "$bv7\n";                                        # 1111111111111111111

# Experiment with logical operations on bitvectors of different sizes:
print "\nTry logical operations on bitvectors of different sizes:\n";
$bv = Algorithm::BitVector->new(intVal=>6) ^ Algorithm::BitVector->new(intVal=>13);
print "$bv\n";                                         # 1011
$bv = Algorithm::BitVector->new(intVal=>6) & Algorithm::BitVector->new(intVal=>13);
print "$bv\n";                                         # 0100
$bv = Algorithm::BitVector->new(intVal=>6) | Algorithm::BitVector->new(intVal=>13);
print "$bv\n";                                         # 1111
$bv = Algorithm::BitVector->new(intVal=>1) ^ Algorithm::BitVector->new(intVal=>13);
print "$bv\n";                                         # 1100
$bv = Algorithm::BitVector->new(intVal=>1) & Algorithm::BitVector->new(intVal=>13);
print "$bv\n";                                         # 0001
$bv = Algorithm::BitVector->new(intVal=>1) | Algorithm::BitVector->new(intVal=>13);
print "$bv\n";                                         # 1101

# Experiments with set_bit() and length():\n";
print "\nExperiments with set_bit() and length():\n";
$bv7->set_bit(7,0);
print "$bv7\n";                                        # 1111111011111111111
print length($bv7) . "\n";                             # 19
my $bv8 = ($bv5 & $bv6) ^ $bv7;
print "$bv8\n";                                        # 1111111011111111111

# Constructing a bitvector from the contents of a disk file:
print "\nConstruct a bitvector from what is in the file testinput1.txt:\n";
$bv = Algorithm::BitVector->new( filename => 'testinput.txt' );
#print "$bv\n";                                         # nothing to show
$bv1 = $bv->read_bits_from_file(64);
print "\nPrint out the first 64 bits read from the file:\n";
print "$bv1\n";               
          # 0100000100100000011010000111010101101110011001110111001001111001
print "\nRead the next 64 bits from the same file:\n";
$bv2 = $bv->read_bits_from_file(64);
print "$bv2\n";               
          # 0010000001100010011100100110111101110111011011100010000001100110
print "\nTake xor of the previous two bitvectors:\n";
$bv3 = $bv1 ^ $bv2;
print "$bv3\n";                
          # 0110000101000010000110100001101000011001000010010101001000011111

# Dividing an even-sized bitvector into two bitvectors:
print "\nExperiment with dividing an even-sized vector into two:\n";
($bv4,$bv5) = $bv3->divide_into_two();
print "$bv4\n";                           # 01100001010000100001101000011010
print "$bv5\n";                           # 00011001000010010101001000011111

# Permute a bitvector:
print "\nWe will use this bitvector for experiments with permute()\n";
$bv1 = Algorithm::BitVector->new( bitlist => [1, 0, 0, 1, 1, 0, 1] );
print "$bv1\n";                                        # 1001101
$bv2 = $bv1->permute( [6, 2, 0, 1] );
print "Permuted and contracted form of the previous bitvector:\n";
print "$bv2\n";                                        # 1010

# Write an internally generated bitvector to a disk file:
print "\nExperiment with writing an internally generated bitvector out to a disk file:\n";
$bv1 = Algorithm::BitVector->new( bitstring => '00001010' ); 
open my $FILEOUT, ">test.txt";
$bv1->write_to_file( $FILEOUT );
close $FILEOUT;
$bv2 = Algorithm::BitVector->new( filename => 'test.txt' );
$bv3 = $bv2->read_bits_from_file( 32 );
print "\nDisplay bitvectors written out to file and read back from the file and their respective lengths:\n";
print "$bv1      $bv3\n";                                      #   00001010      00001010
print length($bv1) . "             " . length($bv3) . "\n";    #   8             8

# Experiment with reading a file from beginning to end and constructing 64-bit bit
# vectors as you go along:
print "\nExperiments with reading a file from the beginning to end:\n";
$bv = Algorithm::BitVector->new( filename => 'testinput.txt' );
print "Here are all the bits read from the file:\n";
while ($bv->{more_to_read}) {
    my $bv_read = $bv->read_bits_from_file( 64 );
    print "$bv_read\n";
}
print "\n";
                  # 0100000100100000011010000111010101101110011001110111001001111001
                  # 0010000001100010011100100110111101110111011011100010000001100110
                  # 0110111101111000001000000110101001110101011011010111000001100101
                  # 0110010000100000011011110111011001100101011100100010000001100001
                  # 0010000001101100011000010111101001111001001000000111011101101001
                  # 0110110001100100001000000110010001101111011001110010111000001010
                  # 0000101001100001011000010110000101100001011000010110000101100001
                  # 0110000101100001011000010110000101100001000010100000101001101010
                  # 0110101001101010011010100110101001101010011010100110101001101010
                  # 0110101001101010011010100110101001101010011010100110101001101010
                  # 0000101000001010

print "\nExperiment with closing a file object and start extracting bitvectors from the file from the beginning again:\n";
$bv->close_file_handle();
$bv = Algorithm::BitVector->new( filename => 'testinput.txt' );
$bv1 = $bv->read_bits_from_file(64);
print "Here are all the first 64 bits read from the file again after the file object was closed and opened again:\n";
print "$bv1\n";      # 0100000100100000011010000111010101101110011001110111001001111001
open $FILEOUT, ">testinput5.txt";
$bv1->write_to_file( $FILEOUT );
close $FILEOUT; 

# Experiments in 64-bit permutation and unpermutation:
print "\nExperiment in 64-bit permutation and unpermutation of the previous 64-bit bitvector:\n";
print "The permutation array was generated separately by the Fisher-Yates shuffle algorithm:\n";
$bv2 = $bv1->permute( [22, 47, 33, 36, 18, 6, 32, 29, 54, 62, 4,
                        9, 42, 39, 45, 59, 8, 50, 35, 20, 25, 49,
                       15, 61, 55, 60, 0, 14, 38, 40, 23, 17, 41,
                       10, 57, 12, 30, 3, 52, 11, 26, 43, 21, 13,
                       58, 37, 48, 28, 1, 63, 2, 31, 53, 56, 44, 24,
                       51, 19, 7, 5, 34, 27, 16, 46] );
print "Permuted bitvector:\n";
print "$bv2\n";      # 0111100110001011010111000100100111100000100011001101000010101101
$bv3 = $bv2->unpermute( [22, 47, 33, 36, 18, 6, 32, 29, 54, 62, 4,
                          9, 42, 39, 45, 59, 8, 50, 35, 20, 25, 49,
                         15, 61, 55, 60, 0, 14, 38, 40, 23, 17, 41,
                         10, 57, 12, 30, 3, 52, 11, 26, 43, 21, 13,
                         58, 37, 48, 28, 1, 63, 2, 31, 53, 56, 44, 24,
                         51, 19, 7, 5, 34, 27, 16, 46] );    
print "Result obtained by unpurmuting the permuted bitvector:\n";
print "$bv3\n";      # 0100000100100000011010000111010101101110011001110111001001111001

# Experiments with circular shifts to the left and to the right:
print "\nTry circular shifts to the left and to the right for the following bitvector:\n";
print "$bv3\n";      # 0100000100100000011010000111010101101110011001110111001001111001
print "Circular shift to the left by 7 positions:\n";
$bv3 = $bv3 << 7;
print "$bv3\n";      # 1001000000110100001110101011011100110011101110010011110010100000
print "\nCircular shift to the right by 7 positions:\n";
$bv3 = $bv3 >> 7;
print "$bv3\n";      # 0100000100100000011010000111010101101110011001110111001001111001
print "Test length on the above bitvector:   ";
print length($bv3) . "\n";                      # 64

print "\nExperiments with chained invocations of circular shifts:\n";
$bv = Algorithm::BitVector->new( bitlist => [1, 1, 1, 0, 0, 1] );
print "$bv\n";                                    # 111001
$bv = $bv >> 1;
print "$bv\n";                                    # 111100
$bv = $bv >> 1 >> 1;
print "$bv\n";                                    # 001111
$bv = Algorithm::BitVector->new( bitlist => [1, 1, 1, 0, 0, 1] );
print "$bv\n";                                    # 111001
$bv = $bv << 1;
print "$bv\n";                                    # 110011
$bv = $bv << 1 << 1;
print "$bv\n";                                    # 001111

# Experiment with extracting a slice of a bitvector:
print "\nTest forming a [5..21] slice of the above bitvector:\n";
# The following call will return bits indexed from 5 through 21 from the $bv3 
# bitvector:
my $arr = $bv3->get_bit([5..21]);
print "@$arr\n";                         # 0 0 1 0 0 1 0 0 0 0 0 0 1 1 0 1 0

# Experiment with the overloading of the iterator `<>':
print "\nTest the iterator:\n";
while (<$bv4>) {
    print "$_ ";
}          # 0 1 1 0 0 0 0 1 0 1 0 0 0 0 1 0 0 0 0 1 1 0 1 0 0 0 0 1 1 0 1 0
print "\n";

# Experiments with padding a bitvector with zeros:
print "\nDemonstrate padding a bitvector from left:\n";
$bv = Algorithm::BitVector->new( bitstring => '101010' );
$bv->pad_from_left( 4 );
print "$bv\n";                           # 000010101
print "\nDemonstrate padding a bitvector from right:\n";
$bv->pad_from_right( 4 );
print "$bv\n";                           # 00001010100000

# Experiments with the size modifier when int value is used for constructing a bitvector:
print "\nTest the size modifier when a bitvector is initialized with the intVal method:\n";
$bv = Algorithm::BitVector->new( intVal => 45, size => 16 );
print "$bv\n";                           # 0000000000101101
$bv = Algorithm::BitVector->new( intVal => 0, size => 8 );
print "$bv\n";                           # 00000000
$bv = Algorithm::BitVector->new( intVal => 1, size => 8 );    
print "$bv\n";                           # 00000001

# Experiments with resetting a bitvector to either all 1's or all 0's:
print "\nTesting reset method:\n";
$bv1->reset(1);             
print "$bv1\n";     
                  # 1111111111111111111111111111111111111111111111111111111111111111

# Experiments in counting the number of bits set:
print "\nTesting count_bit():\n";
$bv = Algorithm::BitVector->new( intVal => 45, size => 16 );
my $y = $bv->count_bits();
print "$y\n";                                  # 4
$bv = Algorithm::BitVector->new( bitstring => '100111' );
print $bv->count_bits() . "\n";                 # 4
$bv = Algorithm::BitVector->new( bitstring => '00111000' );
print $bv->count_bits() . "\n";                 # 3
$bv = Algorithm::BitVector->new( bitstring => '001' );
print $bv->count_bits() . "\n";                 # 1
$bv = Algorithm::BitVector->new( bitstring => '00000000000000' );
print $bv->count_bits() . "\n";                 # 0

# Experiment with the fast algorithm for counts the set bits in large but sparse bitvectors:
print "\nTesting count_bits_sparse() on a vector of TWO MILLION bits (be patient):\n";
$bv = Algorithm::BitVector->new( size => 2000000 );
$bv->set_bit(345234, 1);
$bv->set_bit(233, 1);
$bv->set_bit(243, 1);
$bv->set_bit(18, 1);
$bv->set_bit(785, 1);
print "The number of bits set: " . $bv->count_bits_sparse() . "\n";  # 5

# Experiments with resetting the internals of a bitvector:
print "\nTest set_value() method:\n";
$bv = Algorithm::BitVector->new( intVal => 7, size => 16 );
print "$bv\n";                             # 0000000000000111
$bv->set_value( intVal => 45 );
print "$bv\n";                             # 101101

# Experiment with Jaccard similarity and distance and with Hamming distance:
print "\nTesting Jaccard similarity and distance and Hamming distance:\n";
$bv1 = Algorithm::BitVector->new( bitstring => '11111111' );
$bv2 = Algorithm::BitVector->new( bitstring => '00101011' );
print "Jaccard similarity: " . $bv1->jaccard_similarity( $bv2 ) . "\n"; # 0.5
print "Jaccard distance: " . $bv1->jaccard_distance( $bv2 ) . "\n";     # 0.5
print "Hamming distance: " . $bv1->hamming_distance( $bv2 ) . "\n";     # 4

# Experiments in finding the position of the next set bit after a given position:
print "\nTesting next_set_bit():\n";
$bv = Algorithm::BitVector->new( bitstring => '00000000000001' );
print $bv->next_set_bit(5) . "\n";                             # 13
$bv = Algorithm::BitVector->new( bitstring => '000000000000001' );
print $bv->next_set_bit(5) . "\n";                             # 14
$bv = Algorithm::BitVector->new( bitstring => '0000000000000001' );
print $bv->next_set_bit(5) . "\n";                             # 15
$bv = Algorithm::BitVector->new( bitstring => '00000000000000001' );
print $bv->next_set_bit(5) . "\n";                             # 16

# The rank of a bit is the number of bits set prior to that bit:
print "\nTesting rank_of_bit_set_at_index():\n";
$bv = Algorithm::BitVector->new( bitstring => '01010101011100' );
print $bv->rank_of_bit_set_at_index( 10 ) . "\n";                 # 6

# Experiment with determining whether the int value of a bitvector is a power 2:
print "\nTesting is_power_of_2():\n";
$bv = Algorithm::BitVector->new( bitstring => '10000000001110' );
print "int value: " . int($bv) . "\n";                       # 826
print $bv->is_power_of_2() . "\n";                            # 0
print "\nTesting is_power_of_2_sparse():\n";             
print $bv->is_power_of_2_sparse() . "\n";                      # 0

# Experiment with reversing a bitvector:
print "\nTesting reverse():\n";
$bv = Algorithm::BitVector->new( bitstring => '0001100000000000001' );
print "original bv: $bv\n";                      # 0001100000000000001
print "reversed bv: " . $bv->reverse() . "\n";   # 1000000000000011000

# Calculate the GCD of two bitvectors using Euclid's algorithm on the integers values:
print "\nTesting Greatest Common Divisor (gcd):\n";
$bv1 = Algorithm::BitVector->new( bitstring => '01100110' );
print "first arg bv: $bv1 of int value: " . int($bv1) . "\n";    #102
$bv2 = Algorithm::BitVector->new( bitstring => '011010' ); 
print "second arg bv: $bv2 of int value: "  . int($bv2) . "\n";  # 26
$bv = $bv1->gcd( $bv2 );
print "gcd bitvec is: $bv of int value: " . int($bv) . "\n";     # 2

# Calculate the multiplicative inverse of a bitvector with respect to a modulus vector:
print "\nTesting multiplicative_inverse:\n";
my $bv_modulus = Algorithm::BitVector->new( intVal => 32 );
print "modulus is bitvec: $bv_modulus of int value: " . int($bv_modulus) . "\n";
$bv = Algorithm::BitVector->new( intVal => 17 );
print "bv: $bv of int value: " . int($bv) . "\n";
$result = $bv->multiplicative_inverse( $bv_modulus );
if ($result) {
    print "MI bitvec is: $result of int value: " . int($result) . "\n";     # 17
} else {
    print "No multiplicative inverse in this case\n";
}

# Experiments with non-circular shifts to the left and to the right:
print "\nExperiments with regular and chained invocations of NON-circular shifts:\n";
$bv = Algorithm::BitVector->new( bitlist => [1,1, 1, 0, 0, 1] );
print "$bv\n";                                       # 111001
$bv->shift_right(1);
print "$bv\n";                                       # 011100
$bv->shift_right(1);
print "$bv\n";                                       # 001110
$bv->shift_right(1)->shift_right(1); 
print "$bv\n";                                       # 000011
$bv->shift_right(1);
print "$bv\n";                                       # 000001
$bv = Algorithm::BitVector->new( bitlist => [1,1, 1, 0, 0, 1] );
print "$bv\n";                                       # 111001
$bv->shift_left(1);
print "$bv\n";                                       # 110010
$bv->shift_left(1);
print "$bv\n";                                       # 100100
$bv->shift_left(1)->shift_left(1);
print "$bv\n";                                       # 010000
$bv->shift_left(1);
print "$bv\n";                                       # 100000

# Experiment with the calculation of multiplication in a Galois Field GF(2);
print "\nTest multiplication in GF(2):\n";
$a = Algorithm::BitVector->new( bitstring => '0110001' );
$b = Algorithm::BitVector->new( bitstring => '0110' );
my $c = $a->gf_multiply($b);
print "Product of a = $a with b = $b is $c\n";
                             # Product of a = 0110001 with b = 0110 is 00010100110

# Experiment with dividing one vector by another in GF(2^n):
print "\nTest division in GF(2^n):\n";
my $mod = Algorithm::BitVector->new( bitstring => '100011011' );   # AES modulus
my $n = 8;
$a = Algorithm::BitVector->new( bitstring => '11100010110001' );
my ($quotient, $remainder) = $a->gf_divide_by_modulus($mod, $n);
print "Dividing a= $a  by mod= $mod in GF(2^8) returns the quotient $quotient and the remainder $remainder\n";
          #Dividing a=11100010110001 by mod=100011011 in GF(2^8) returns the quotient 00000000111010 and the remainder 10001111

# Experiment in modular multiplication of bit patterns in GF(2^n):
print "\nTest modular multiplication in GF(2^n):\n";
my $modulus = Algorithm::BitVector->new( bitstring => '100011011' );     # AES modulus
$n = 8;
$a = Algorithm::BitVector->new( bitstring => '0110001' );
$b = Algorithm::BitVector->new( bitstring => '0110' );
$c = $a->gf_multiply_modular($b, $modulus, $n);
print "Modular product of a = $a   b = $b  in GF(2^8) is $c\n";
                        # Modular product of a = 0110001   b = 0110  in GF(2^8) is 10100110

# Experiment with finding the multiplicative inverse in GF(2^8) for modulus polynomial = x^8 + x^4 + x^3 + x + 1:
print "\nTest multiplicative inverses in GF(2^3) with modulus polynomial = x^8 + x^4 + x^3 + x + 1:\n";
print "Find multiplicative inverse of a single bit array\n";
$modulus = Algorithm::BitVector->new( bitstring => '100011011' );     # AES modulus
$n = 8;
$a = Algorithm::BitVector->new( bitstring => '00110011' );
my $mi = $a->gf_MI($modulus, $n);
print "Multiplicative inverse of $a in GF(2^8) is $mi\n";

# Experiments with finding ALL multiplicative inverses in a small Galois Field:
print "\nIn the display produced by following statements, you will see " .
      "\nthree rows. The first row shows the binary code words, the " .
      "\nsecond the multiplicative inverses, and the third the product " .
      "\nof a binary word with its multiplicative inverse modulo the " .
      "\nprime polynomial:\n";
$mod = Algorithm::BitVector->new( bitstring => '1011' );
$n = 3;
my @bitarrays = map Algorithm::BitVector->new(intVal=>$_, size=>$n), 1 .. 2**3 -1;
my @mi_list = map $_->gf_MI($mod,$n), @bitarrays;
print "bit arrays in GF(2^3)  : @bitarrays\n";
print "multiplicative inverses: @mi_list\n";
my @products;
foreach my $i (0..@bitarrays-1) {
    push @products, $bitarrays[$i]->gf_multiply_modular($mi_list[$i], $mod, $n);
}
print "bit_array * multi_inv:   @products\n";

# Experiments with finding ALL multiplicative inverses in a rather large Galois Field:

#UNCOMMENT THE FOLLOWING LINES FOR
#DISPLAYING ALL OF THE MULTIPLICATIVE 
#INVERSES IN GF(2^8) WITH THE AES MODULUS:
print "\nMultiplicative inverses in GF(2^8) with modulus polynomial x^8 + x^4 + x^3 + x + 1:\n";
print "\n(This may take a few seconds)\n";
$mod = Algorithm::BitVector->new( bitstring => '100011011' );
$n = 8;
@bitarrays = map Algorithm::BitVector->new(intVal=>$_, size=>$n), 1 .. 2**8 -1;
@mi_list = map $_->gf_MI($mod,$n), @bitarrays;
print "multiplicative inverses: @mi_list\n";
@products = ();
foreach my $i (0..@bitarrays-1) {
    push @products, $bitarrays[$i]->gf_multiply_modular($mi_list[$i], $mod, $n);
}
print "\nShown below is the product of each binary code word in GF(2^3) and its multiplicative inverse:\n\n";
print "@products\n";

# Experiments with finding runs of 1's and 0's in a bit pattern:
print "\nExperimenting with runs():\n";
$bv = Algorithm::BitVector->new( bitlist => [1, 0, 0, 1] );
my @bvruns = $bv->runs();
print "For bitvector: $bv";
print "       the runs are: @bvruns\n";
$bv = Algorithm::BitVector->new( bitlist => [1, 0] );
@bvruns = $bv->runs();
print "For bitvector: $bv";
print "       the runs are: @bvruns\n";
$bv = Algorithm::BitVector->new( bitlist => [0, 1] );
@bvruns = $bv->runs();
print "For bitvector: $bv";
print "       the runs are: @bvruns\n";
$bv = Algorithm::BitVector->new( bitlist => [0, 0, 0, 1] );
@bvruns = $bv->runs();
print "For bitvector: $bv";
print "       the runs are: @bvruns\n";
$bv = Algorithm::BitVector->new( bitlist => [0, 1, 1, 0] );
@bvruns = $bv->runs();
print "For bitvector: $bv";
print "       the runs are: @bvruns\n";

# Experiments with primality testing of small integers:
print "\nRun the small-integer primality test on a a bunch of known primes:\n";
my @primes = (179, 233, 283, 353, 419, 467, 547, 607, 661, 739, 811, 877, 
              947, 1019, 1087, 1153, 1229, 1297, 1381, 1453, 1523, 1597, 
              1663, 1741, 1823, 1901, 7001, 7109, 7211, 7307, 7417, 7507,
              7573, 7649, 7727, 7841);
foreach my $p (@primes) {
    my $bv = Algorithm::BitVector->new( intVal => $p );
    my $check = $bv->test_for_primality();
    print "The primality test for $p: $check\n";
}

# Experiments with random bit generation for a bitvector:
print "\nGenerate 16-bit wide candidates for primality testing:\n";
foreach my $i (0..10) {
    $bv = Algorithm::BitVector->new( intVal => 0 );
    $bv = $bv->gen_random_bits(16);
    print "\n$bv\n";
    my $check = $bv->test_for_primality();
    print "The primality test for " . int($bv) . ": $check\n";
}

