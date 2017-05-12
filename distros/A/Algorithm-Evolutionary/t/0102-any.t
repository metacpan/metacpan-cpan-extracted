#-*-cperl-*-

use Test::More;
use warnings;
use strict;

use lib qw( lib ../lib ../../lib  ); #Just in case we are testing it in-place

BEGIN { plan tests => 3;
    use_ok('Algorithm::Evolutionary::Individual::Any');
};

#Object methods
my @array = qw (1 2 3);
push @array, ['5','6'];
my $indi = new Algorithm::Evolutionary::Individual::Any 'Object::Array', \@array;
isa_ok( $indi, "Algorithm::Evolutionary::Individual::Any" );

my $fitness = 0.01;
$indi->Fitness( $fitness );
is( $indi->Fitness(), $fitness, 'Fitness' );


=head1 Copyright
  
  This file is released under the GPL. See the LICENSE file included in this distribution,
  or go to http://www.fsf.org/licenses/gpl.txt

  CVS Info: $Date: 2009/07/24 08:46:59 $ 
  $Header: /media/Backup/Repos/opeal/opeal/Algorithm-Evolutionary/t/0102-any.t,v 3.0 2009/07/24 08:46:59 jmerelo Exp $ 
  $Author: jmerelo $ 
  $Revision: 3.0 $
  $Name $

=cut
