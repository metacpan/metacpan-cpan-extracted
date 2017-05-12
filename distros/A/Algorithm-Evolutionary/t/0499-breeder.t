#-*-CPerl-*-

#########################
use strict;
use warnings;

use Test;
BEGIN { plan tests => 5 };
use lib qw( lib ../lib ../../lib ); #Just in case we are testing it in-place

use Algorithm::Evolutionary qw( Individual::BitString 
				Fitness::ONEMAX;
				Op::Mutation Op::Crossover
				Op::Tournament_Selection
				Op::Breeder );

use Algorithm::Evolutionary::Utils qw(average);

#########################

my @pop;
my $number_of_bits = 20;
my $population_size = 20;
my $replacement_rate = 0.5;
my $onemax = new Algorithm::Evolutionary::Fitness::ONEMAX;
for ( 1..$population_size ) {
  my $indi = new Algorithm::Evolutionary::Individual::BitString $number_of_bits ; #Creates random individual
  $indi->evaluate( $onemax );
  push( @pop, $indi );
}

my $m =  new Algorithm::Evolutionary::Op::Mutation 0.5;
my $c = new Algorithm::Evolutionary::Op::Crossover; #Classical 2-point crossover

my $selector =  new Algorithm::Evolutionary::Op::Tournament_Selection 2;

my $generation = 
  new Algorithm::Evolutionary::Op::Breeder( [$m, $c] );
ok( ref $generation eq "Algorithm::Evolutionary::Op::Breeder", 1);
my $new_pop = $generation->apply( \@pop );
ok( scalar( @$new_pop) == scalar( @pop ), 1 ); #At least size is the same

map( $_->evaluate( $onemax ), @$new_pop );
$new_pop = $generation->apply( $new_pop, @$new_pop/10 );
ok( scalar( @$new_pop) == scalar( @pop )/10, 1 ); #At least size is the same

$selector =  new Algorithm::Evolutionary::Op::Tournament_Selection 5;

$generation = 
  new Algorithm::Evolutionary::Op::Breeder( [$m, $c], $selector );
ok( ref $generation eq "Algorithm::Evolutionary::Op::Breeder", 1);
$new_pop = $generation->apply( \@pop );
ok( scalar( @$new_pop) == scalar( @pop ), 1 ); #At least size is the same

=head1 Copyright
  
  This file is released under the GPL. See the LICENSE file included in this distribution,
  or go to http://www.fsf.org/licenses/gpl.txt

  CVS Info: $Date: 2010/12/16 18:57:41 $ 
  $Header: /media/Backup/Repos/opeal/opeal/Algorithm-Evolutionary/t/0499-breeder.t,v 1.3 2010/12/16 18:57:41 jmerelo Exp $ 
  $Author: jmerelo $ 
  $Revision: 1.3 $
  $Name $

=cut
