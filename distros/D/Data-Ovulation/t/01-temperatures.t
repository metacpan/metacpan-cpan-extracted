#!perl -T

use strict;
use warnings;

use Test::More tests => 4;

use Data::Ovulation;

my $temperatures = [ qw/
36.5 36.1 36.1 36.2 36.2 36.2 36.3 36.2 36.2 36.1 36.3 36.4 36.2 36.4 36.4
36.4 36.4 36.5 36.7 36.7 36.6 36.6 36.7 36.8 36.6 36.7 36.8 36.8 36.8 36.7 36.9
36.9 36.8 36.8 36.7 36.8 36.9/ ];

# Set/Get temperature values at once
my $ovul = Data::Ovulation->new;
$ovul->temperatures( $temperatures );
is_deeply( $ovul->temperatures, $temperatures, "->temperatures()" );

# Clear temperature values
$ovul->clear;
is( scalar @{ $ovul->temperatures }, 0, "Clear temperatures" );

# Set temperature values individually
$ovul->temperature( { day => $_ + 1, temp => $temperatures->[ $_ ] } ) for( 0..@$temperatures );
is_deeply( $ovul->temperatures, $temperatures, "->temperature()" );

# Number of temperature values
$ovul->clear;
$ovul->temperature( { day => $_, temp => 36 } ) for( qw/1 6 9 2 4 10 50 3 125 255/ );
is( $ovul->no_of_values, 10, "No of temperature values" );
