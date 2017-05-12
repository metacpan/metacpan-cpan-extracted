#-*-cperl-*-

use warnings;
use strict;

use lib qw( ../../lib ../lib lib ); #Just in case we are testing it in-place

use Test::More qw( no_plan );

BEGIN { 
  use_ok( 'Algorithm::Evolutionary::Op::Uniform_Crossover_Diff' );
};

use Algorithm::Evolutionary::Individual::String;

my $number_of_chars = 32;

my $q = new Algorithm::Evolutionary::Op::Uniform_Crossover_Diff $number_of_chars/2;
isa_ok( $q, 'Algorithm::Evolutionary::Op::Uniform_Crossover_Diff' );

my $result;
my $str = "A"x$number_of_chars;
my $str_2 = "b"x$number_of_chars;
my $indi = Algorithm::Evolutionary::Individual::String->fromString( $str );
my $indi_2 = Algorithm::Evolutionary::Individual::String->fromString( $str_2 );
my @pop;
for ( 1..100 ) { 
  $str = $indi->{'_str'};
  $str_2 = $indi_2->{'_str'};
  my $result = $q->apply( $indi, $indi_2 );
  isnt( $indi->{'_str'}, $result->{'_str'}, $result->{'_str'}." differs from ". $str);
  isnt( $indi_2->{'_str'}, $result->{'_str'}, $result->{'_str'}." differs from ". $str_2);
  push( @pop, $result );
}

$q = new Algorithm::Evolutionary::Op::Uniform_Crossover_Diff  $number_of_chars/4;
for ( my $i =0; $i <= $#pop; $i+= 2 ) { 
  next if  $pop[$i]->{'_str'} eq $pop[$i+1]->{'_str'};
  my $result = $q->apply( $pop[$i], $pop[$i+1] );
  isnt( $pop[$i]->{'_str'}, $result->{'_str'}, $result->{'_str'}." differs from ". $pop[$i]->{'_str'});

}


=head1 Copyright
  
  This file is released under the GPL. See the LICENSE file included in this distribution,
  or go to http://www.fsf.org/licenses/gpl.txt

  CVS Info: $Date: 2010/12/20 16:56:46 $ 
  $Header: /media/Backup/Repos/opeal/opeal/Algorithm-Evolutionary/t/04067-uxover-diff.t,v 1.2 2010/12/20 16:56:46 jmerelo Exp $ 
  $Author: jmerelo $ 
  $Revision: 1.2 $
  $Name $

=cut
