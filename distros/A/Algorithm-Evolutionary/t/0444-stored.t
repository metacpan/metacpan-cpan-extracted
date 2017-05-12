#-*-CPerl-*-

#########################
use strict;
use warnings;

use Test::More tests => 2;

use lib qw( lib ../lib ../../lib ); #Just in case we are testing it in-place

use Algorithm::Evolutionary::Individual::BitString;
use Algorithm::Evolutionary::Op::Bitflip;
use Algorithm::Evolutionary::Op::Crossover;
use Algorithm::Evolutionary::Op::Storing;


#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

my $bs = Algorithm::Evolutionary::Individual::BitString->new(10);

my $bf = new Algorithm::Evolutionary::Op::Bitflip;
my $cs = new Algorithm::Evolutionary::Op::Crossover;

my %population;
$population{ $bs->as_string() } = $bs; #Creates hash

my $storing_bf = new Algorithm::Evolutionary::Op::Storing $bf, \%population;

ok( ref $storing_bf, "Algorithm::Evolutionary::Op::Storing" );

my $result = $storing_bf->apply( $bs );
is( $result->as_string() ne $bs->as_string(), 1, "Results OK" );
  
=head1 Copyright
  
  This file is released under the GPL. See the LICENSE file included in this distribution,
  or go to http://www.fsf.org/licenses/gpl.txt

  CVS Info: $Date: 2009/07/24 08:46:59 $ 
  $Header: /media/Backup/Repos/opeal/opeal/Algorithm-Evolutionary/t/0444-stored.t,v 3.0 2009/07/24 08:46:59 jmerelo Exp $ 
  $Author: jmerelo $ 
  $Revision: 3.0 $
  $Name $

=cut
