#-*-CPerl-*-

use Test::More;
BEGIN { plan 'no_plan' };

use lib qw( lib ../lib ../../lib  ); #Just in case we are testing it in-place

use Algorithm::Evolutionary::Experiment;
use Algorithm::Evolutionary::Op::Easy;

#########################
my $onemax = sub { 
  my $indi = shift;
  my $total = 0;
  my $len = $indi->length();
  my $i;
  while ($i < $len ) {
	$total += substr($indi->{'_str'}, $i, 1);
	$i++;
  }
  return $total;
};

my $ez = new Algorithm::Evolutionary::Op::Easy $onemax;
my $popSize = 20;
my $indiType = 'BitString';
my $indiSize = 64;

my $e = new Algorithm::Evolutionary::Experiment $popSize, $indiType, $indiSize, $ez;
isa_ok ( $e, 'Algorithm::Evolutionary::Experiment' ); # test 1

=head1 Copyright
  
  This file is released under the GPL. See the LICENSE file included in this distribution,
  or go to http://www.fsf.org/licenses/gpl.txt

=cut
