#-*-CPerl-*-

use lib qw( lib ../lib ../../lib  ); #Just in case we are testing it in-place
use Test::More qw(no_plan);

eval "use Test::Output";
my $no_test_output=1 if $@;
use Algorithm::Evolutionary::Individual::String;


#########################
BEGIN {
  use_ok( 'Algorithm::Evolutionary::Op::Population_Output' );
}

my $pp = new Algorithm::Evolutionary::Op::Population_Output; 
ok( ref $pp, "Algorithm::Evolutionary::Op::Population_Output" );

if ( !$no_test_output ) {
  my @pop;
  for ( 1..10 ) {
    my $indi= new Algorithm::Evolutionary::Individual::String [0,1], 8;
    push @pop, $indi;
  }
  
  sub writer { $pp->apply( \@pop ) };
  
  stdout_like( \&writer, qr/[01]+/, 'Writing OK' ); #Should return 0
  
  $pp = new Algorithm::Evolutionary::Op::Population_Output sub { my $member = shift; 
								 print $member->as_yaml, "\n"; } ; 
  
  stdout_like( \&writer, qr/_length: 8/, 'Writing YAML OK' ); #Should return 0
  
}

=head1 Copyright
  
  This file is released under the GPL. See the LICENSE file included in this distribution,
  or go to http://www.fsf.org/licenses/gpl.txt

  CVS Info: $Date: 2009/07/25 10:16:49 $ 
  $Header: /media/Backup/Repos/opeal/opeal/Algorithm-Evolutionary/t/0502-pop_printer.t,v 3.2 2009/07/25 10:16:49 jmerelo Exp $ 
  $Author: jmerelo $ 
  $Revision: 3.2 $
  $Name $

=cut
