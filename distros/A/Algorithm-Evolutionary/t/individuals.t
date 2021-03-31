#-*-cperl-*-

use Test::More;
use warnings;
use strict;
use YAML qw(Load);

local $YAML::LoadBlessed = 1;

BEGIN { plan 'no_plan' };
use lib qw( lib ../lib ../../lib  ); #Just in case we are testing it in-place

my $size = 16;
#Use: module name, args to ctor.
my $primitives = { sum => [2, -1, 1],
		   multiply => [2, -1, 1],
		   substract => [2, -1, 1],
		   divide => [2, -1, 1],
		   x => [0, -10, 10],
		   y => [0, -10, 10] };

my %modulesToTest = ( String => [['a'..'z'],$size ],
		      BitString => [$size],
		      Vector => [$size],
		      Bit_Vector => [{length =>  $size }],
		      Tree => [$primitives, $size/4 ] );

####################################################################
#Subroutine that tests and creates an op. Takes as argument
#the name of the op and a ref-to-array with the arguments to new
####################################################################

sub createAndTest ($$;$) {
  my $module = shift || die "No module name";
  my $newArgs = shift || die "No args";

  my $class = "Algorithm::Evolutionary::Individual::$module";
  #require module
  eval " require  $class" || die "Can't load module $class: $@";
  my $nct = new $class @$newArgs;
  print "Testing $module\n";
  isa_ok( $nct, $class );
  if ( $module ne 'Tree' ) {
    is( $nct->size(), $size, "Size" );
  } else {
    is( $nct->size(), 1, "Size" );
  }

  for (my $i = 0; $i < $nct->size(); $i ++ ) {
    is( defined( $nct->Atom($i)), 1, "Atom($i)");
  }

  my $yaml = $nct->as_yaml();
  my $fromyaml = Load($yaml);
  ok( $yaml, $fromyaml->as_yaml());
  return $nct;
}

###########################################################################

use_ok( 'Algorithm::Evolutionary::Individual::Base' );
my @ops= Algorithm::Evolutionary::Individual::Base->my_operators();
ok( $ops[0], 'None');

my %indis;
for ( keys %modulesToTest ) {
  my $indi = createAndTest( $_, $modulesToTest{$_});
  $indis{ ref $_ } = $indi;
}

  
=head1 Copyright
  
  This file is released under the GPL. See the LICENSE file included in this distribution,
  or go to http://www.fsf.org/licenses/gpl.txt

  CVS Info: $Date: 2009/07/24 08:46:59 $ 
  $Header: /media/Backup/Repos/opeal/opeal/Algorithm-Evolutionary/t/individuals.t,v 3.0 2009/07/24 08:46:59 jmerelo Exp $ 
  $Author: jmerelo $ 
  $Revision: 3.0 $
  $Name $

=cut
