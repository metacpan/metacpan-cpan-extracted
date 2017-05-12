#-*-cperl-*-
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 3;

use warnings;
use strict;

use lib qw( ../../lib ../lib lib ); #Just in case we are testing it in-place

use Algorithm::Evolutionary::Individual::BitString;
use Algorithm::Evolutionary::Utils qw(random_bitstring decode_string);

use_ok( "Algorithm::Evolutionary::Fitness::Any", "using Fitness::Any OK" );

my $string = random_bitstring(64);
sub squares {
  my $chrom = shift;
  my @values = decode_string( $chrom, 32, -1, 1 );
  return $values[0] * $values[1];
}

my $resultado = squares( $string );

my $any_eval = new Algorithm::Evolutionary::Fitness::Any \&squares;

isa_ok( $any_eval,  "Algorithm::Evolutionary::Fitness::Any" );

my $chrom = Algorithm::Evolutionary::Individual::BitString->fromString( $string );
ok( $any_eval->apply( $chrom ) == $resultado, "Seems to work" );

