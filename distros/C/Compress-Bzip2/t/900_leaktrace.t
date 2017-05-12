#!perl -w

use strict;
use constant HAS_LEAKTRACE => eval{ require Test::LeakTrace };
use Test::More HAS_LEAKTRACE ? (tests => 2) : (skip_all => 'require Test::LeakTrace');
use Test::LeakTrace;

use Compress::Bzip2;
my $string = q/
Twas brillig and the slithy toves
did gire and gimble in the wabe
All mimsey were the borogroves
and the Momewrathes outgrabe
    / x 20;

leaks_cmp_ok{
  my $compress = memBzip( $string );
  my $uncompress = memBunzip( $compress );
} '<', 1;

do './t/lib.pl';

leaks_cmp_ok{
  my $INFILE = catfile( qw(bzlib-src sample0.bz2) );
  local $/ = undef;
  open( IN, "< $INFILE" ) or die "$INFILE: $!";
  binmode IN;
  my $sample0 = <IN>;
  close( IN );
  my $uncompress = memBunzip( $sample0 );
} '<', 1;
