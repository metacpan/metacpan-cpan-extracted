#-*-CPerl-*-

use Test::More 'no_plan';
use lib qw( lib ../lib ../../lib  ); #Just in case we are testing it in-place

use Algorithm::Evolutionary::Op::Convergence_Terminator;
use Algorithm::Evolutionary::Individual::String;
use Clone qw( clone );

#########################

my $nct = new Algorithm::Evolutionary::Op::Convergence_Terminator 0.5; 
ok( ref $nct, "Algorithm::Evolutionary::Op::Convergence_Terminator" );

my @pop;
my $pop_size=5;
for ( 1..$pop_size ) {
    my $indi= new Algorithm::Evolutionary::Individual::String [0,1], 8;
    push @pop, $indi;
}

is( $nct->apply(\@pop ), 0, 'Not yet' ); #Should return 0

for ( 1..$pop_size+1 ) { # Clones to ensure convergence
    my $indi = clone( $pop[0]);
    push @pop, $indi;
}

is( $nct->apply(\@pop ), 1, 'Now' ); #Should return 1
  
=head1 Copyright
  
  This file is released under the GPL. See the LICENSE file included in this distribution,
  or go to http://www.fsf.org/licenses/gpl.txt

=cut
