# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 3 };
use lib qw( lib ../lib ../../lib  ); #Just in case we are testing it in-place

use Algorithm::Evolutionary::Op::GenerationalTerm;
use Algorithm::Evolutionary::Individual::String;

#########################

my $gens = 1;
my $nct = new Algorithm::Evolutionary::Op::GenerationalTerm $gens; 
ok( ref $nct, "Algorithm::Evolutionary::Op::GenerationalTerm" );

my $indi= new Algorithm::Evolutionary::Individual::String [0,1], 2;
ok( $nct->apply([$indi]), 1 ); #Runs once, possible
ok( $nct->apply([$indi]), '' ); #Runs twice, returns fail

=head1 Copyright
  
  This file is released under the GPL. See the LICENSE file included in this distribution,
  or go to http://www.fsf.org/licenses/gpl.txt

  CVS Info: $Date: 2009/07/24 08:46:59 $ 
  $Header: /media/Backup/Repos/opeal/opeal/Algorithm-Evolutionary/t/GenerationalTerm.t,v 3.0 2009/07/24 08:46:59 jmerelo Exp $ 
  $Author: jmerelo $ 
  $Revision: 3.0 $
  $Name $

=cut
