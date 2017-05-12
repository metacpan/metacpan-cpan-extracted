#-*-CPerl-*-

#########################
use strict;
use warnings;

use Test;
BEGIN { plan tests => 4 };
use lib qw( lib ../lib ../../lib ); #Just in case we are testing it in-place

use Algorithm::Evolutionary qw( Individual::BitString 
				Fitness::ONEMAX;
				Op::Mutation Op::Crossover
				Op::Tournament_Selection );

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

ok( ref $selector eq "Algorithm::Evolutionary::Op::Tournament_Selection", 1);
my @new_pop = $selector->apply( \@pop );
ok( scalar( @new_pop) == scalar( @pop ), 1 ); #At least size is the same

@new_pop = $selector->apply( \@pop, @pop/10 );
ok( scalar( @new_pop) == scalar( @pop )/10, 1 ); #At least size is the same

$selector =  new Algorithm::Evolutionary::Op::Tournament_Selection 10;
@new_pop = $selector->apply( \@pop );
ok( scalar( @new_pop) == scalar( @pop ), 1 ); #At least size is the same

=head1 Copyright
  
  This file is released under the GPL. See the LICENSE file included in this distribution,
  or go to http://www.fsf.org/licenses/gpl.txt

  CVS Info: $Date: 2010/12/20 16:01:39 $ 
  $Header: /media/Backup/Repos/opeal/opeal/Algorithm-Evolutionary/t/0407-tournament.t,v 1.1 2010/12/20 16:01:39 jmerelo Exp $ 
  $Author: jmerelo $ 
  $Revision: 1.1 $
  $Name $

=cut
