#!perl 

use strict;
use warnings;

use Test::More tests => 10;
use lib qw( lib ../lib ../../lib  ); #Just in case we are testing it in-place

use Algorithm::MasterMind qw(partitions);
use Algorithm::MasterMind::Test;

use Algorithm::Combinatorics qw(variations_with_repetition);

diag( "This could take a while \n" );

my $length= 3;
my @alphabet = qw( A B );

my $mastermind = new Algorithm::MasterMind::Test( {alphabet => \@alphabet,
						   length => $length} );

my @responses = $mastermind->all_responses();
is ( $#responses, 8, "Responses" );
my @combinations = $mastermind->all_combinations;
is ( $combinations[$#combinations], $alphabet[$#alphabet]x$length, "Combinations generated"),

my $partitions = partitions( @combinations ) ;
is( $partitions->{'AAA'}{'0b-0w'}, 1, "Partions computed" );

$length= 4;
@alphabet = qw( A B C D );

$mastermind = new Algorithm::MasterMind::Test( {alphabet => \@alphabet,
						   length => $length} );

@responses = $mastermind->all_responses();
is ( $#responses, 13, "Responses" );
@combinations = $mastermind->all_combinations;
is ( $combinations[$#combinations], $alphabet[$#alphabet]x$length, "Combinations generated"),

$partitions = partitions( @combinations ) ;

is( keys %$partitions, @combinations, "Number of partitions" );
my $engine = variations_with_repetition( \@alphabet, $length);
my $first_combo = join("",@{$engine->next()});

my $number_of_combos= 0;
for my $p ( keys %{$partitions->{$first_combo}} ) {
  $number_of_combos += $partitions->{$first_combo}{$p}
}
is ( $number_of_combos, $#combinations, "Number of combinations" );

#Test responses
for my $length ( 5..7 ) {
  $mastermind = new Algorithm::MasterMind::Test( { alphabet => \@alphabet,
						   length => $length } );

  my @responses = $mastermind->all_responses();
  is( $responses[$#responses-1], ($length-1)."B-0W", "Responses $length" );
}
