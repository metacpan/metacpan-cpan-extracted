#-*-CPerl-*-

#########################
use strict;
use warnings;

use Test::More;
BEGIN { plan 'no_plan' };
use lib qw( lib ../lib ../../lib ); #Just in case we are testing it in-place

use Algorithm::Evolutionary qw( Individual::String Individual::BitString 
				Individual::Vector Individual::Tree 
				Fitness::ONEMAX);

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

#String
print "Testing Individual objects...String \n";
is( ref Algorithm::Evolutionary::Individual::String->new(['a'..'z'],10), "Algorithm::Evolutionary::Individual::String", "Good ref" );
is( ref Algorithm::Evolutionary::Individual::Base::create( 'String', { chars => ['a'..'e'], length => 10 }), "Algorithm::Evolutionary::Individual::String", "Good ref" );

#Bitstring - 3 & 4
print "BitString...\n";
my $bs = Algorithm::Evolutionary::Individual::BitString->new(100);
is( ref $bs, "Algorithm::Evolutionary::Individual::BitString", , "Good ref" );
is( ref Algorithm::Evolutionary::Individual::Base::create( 'BitString', { length => 10 }), "Algorithm::Evolutionary::Individual::BitString", "Good ref" );

#Vector - 5..7
print "Vector...\n";
is( ref Algorithm::Evolutionary::Individual::Vector->new(10), "Algorithm::Evolutionary::Individual::Vector", "Good ref" );
is( ref Algorithm::Evolutionary::Individual::Base::create( 'Vector', 
							   { length => 20,
							     rangestart => -5,
							     rangeend => 5 }), 
    "Algorithm::Evolutionary::Individual::Vector", "Good ref" );

my $primitives = { sum => [2, -1, 1],
		   multiply => [2, -1, 1],
		   substract => [2, -1, 1],
		   divide => [2, -1, 1],
		   x => [0, -10, 10],
		   y => [0, -10, 10] };

is( ref Algorithm::Evolutionary::Individual::Tree->new( $primitives, 3 ), "Algorithm::Evolutionary::Individual::Tree", "Good ref" );


my $fitness = sub {
  my $indi = shift;
  return unpack("N", pack("B32", substr("0" x 32 . $indi->{'_str'}, -32)));
};

is( $bs->evaluate( $fitness ) > 0, 1, "Evaluation correct");
my $fitness_obj = new Algorithm::Evolutionary::Fitness::ONEMAX;
is( $bs->evaluate( $fitness_obj ) > 0, 1,  "Evaluation object correct" );

my $bprime = new Algorithm::Evolutionary::Individual::String ['a'..'z'], 64;

print "Testing algorithms\n";

#test 33
use Algorithm::Evolutionary::Op::LinearFreezer;
use Algorithm::Evolutionary::Op::SimulatedAnnealing;

my $m  = new Algorithm::Evolutionary::Op::Bitflip; #Changes a single bit
my $initTemp = 2;
my $minTemp = 0.1;
my $freezer = new Algorithm::Evolutionary::Op::LinearFreezer( $initTemp );
my $numChanges = 7;
my $eval =  
  sub {
    my $indi = shift;
    my ( $x, $y ) = @{$indi->{_array}};
    my $sqrt = sqrt( $x*$x+$y*$y);
    return sin( $sqrt )/$sqrt;
  };
my $sa = new Algorithm::Evolutionary::Op::SimulatedAnnealing( $eval, $m, $freezer, $initTemp, $minTemp,  );
is( ref $sa, 'Algorithm::Evolutionary::Op::SimulatedAnnealing', "Good class" );

#test 34
my $c = new Algorithm::Evolutionary::Op::Crossover; #Classical 2-point crossover
my $replacementRate = 0.3;	#Replacement rate
use Algorithm::Evolutionary::Op::RouletteWheel;
my $popSize = 20;
my $selector = new Algorithm::Evolutionary::Op::RouletteWheel $popSize; #One of the possible selectors
use Algorithm::Evolutionary::Op::GeneralGeneration;
my $onemax = sub { 
  my $indi = shift;
  my $total = 0;
  my $len = $indi->size();
  my $i = 0;
  while ($i < $len ) {
    $total += substr($indi->{'_str'}, $i, 1);
    $i++;
  }
  return $total;
};
my @pop;
my $numBits = 20;
for ( 0..$popSize ) {
  my $indi = new Algorithm::Evolutionary::Individual::BitString $numBits ; #Creates random individual
  my $fitness = $onemax->( $indi );
  $indi->Fitness( $fitness );
  push( @pop, $indi );
}

#fitness
my $generation = 
  new Algorithm::Evolutionary::Op::GeneralGeneration( $onemax, $selector, [$m, $c], $replacementRate );
my @sortPop = sort { $b->Fitness() <=> $a->Fitness() } @pop;
my $bestIndi = $sortPop[0];
$generation->apply( \@sortPop );
is( $bestIndi->Fitness() <= $sortPop[0]->Fitness(), 1, "Fitness improvement" ); #fitness improves, but not always

# To be obsoleted
my $ggxml = $generation->asXML();
my $gprime =  Algorithm::Evolutionary::Op::Base->fromXML( $ggxml );
is( $gprime->{_eval}( $pop[0] ) eq $generation->{_eval}( $pop[0] ) , 1, "XML" ); #Code snippets will never be exactly the same.

#Test 33 & 34
use Algorithm::Evolutionary::Op::Easy;
my $ez = new Algorithm::Evolutionary::Op::Easy $onemax;
  
my $ezxml = $ez->asXML();
my $ezprime = Algorithm::Evolutionary::Op::Base->fromXML( $ezxml );
is( $ezprime->{_eval}( $pop[0] ) eq $ez->{_eval}( $pop[0] ) , 1, "Code snippets" ); #Code snippets will never be exactly the same.
my $oldBestFitness = $bestIndi->Fitness();
$ez->apply( \@sortPop );
is( $sortPop[0]->Fitness() >= $oldBestFitness, 1, "Fitness improving");
  
#Test 35 & 36
use Algorithm::Evolutionary::Op::GenerationalTerm;
my $g100 = new Algorithm::Evolutionary::Op::GenerationalTerm 10;
use Algorithm::Evolutionary::Op::FullAlgorithm;
my $f = new Algorithm::Evolutionary::Op::FullAlgorithm $generation, $g100;
  
my $fxml = $f->asXML();
my $txml = $f->{_terminator}->asXML();
my $fprime = Algorithm::Evolutionary::Op::Base->fromXML( $fxml );
is( $txml eq $fprime->{_terminator}->asXML() , 1, "from XML" ); 
$oldBestFitness = $bestIndi->Fitness();
for ( @sortPop ) {
  if ( !defined $_->Fitness() ) {
    my $fitness = $onemax->( $_ );
    $_->Fitness( $fitness );
  }
}
$f->apply( \@sortPop );
is( $sortPop[0]->Fitness() >= $oldBestFitness, 1, "Improving fitness");
  
=head1 Copyright
  
  This file is released under the GPL. See the LICENSE file included in this distribution,
  or go to http://www.fsf.org/licenses/gpl.txt

  CVS Info: $Date: 2010/09/24 08:39:07 $ 
  $Header: /media/Backup/Repos/opeal/opeal/Algorithm-Evolutionary/t/general.t,v 3.1 2010/09/24 08:39:07 jmerelo Exp $ 
  $Author: jmerelo $ 
  $Revision: 3.1 $
  $Name $

=cut
