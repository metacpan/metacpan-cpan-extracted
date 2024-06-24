#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

# This "test" never fails, but prints a benchmark comparison between
# Data::Checks and Types::Standard performing the same :Checked attribute
# assertions on a function. It also compares against a manually-written check
# for interest.

BEGIN {
   eval { require Signature::Attribute::Checked } or
      plan skip_all => "Signature::Attribute::Checked is not available";

   eval { require Types::Standard } or
      plan skip_all => "Types::Standard is not available";
}

use Time::HiRes qw( gettimeofday tv_interval );
sub measure(&)
{
   my ( $code ) = @_;
   my $start = [ gettimeofday ];
   $code->();
   return tv_interval $start;
}

use Sublike::Extended;
use Signature::Attribute::Checked;
use Data::Checks;
use Types::Standard;

use experimental qw( signatures );

extended sub func_DC ( $x :Checked(Data::Checks::Defined) ) { return $x; }

extended sub func_TS ( $x :Checked(Types::Standard::Defined) ) { return $x; }

sub func_manual ( $x ) {
   defined $x or die "Require defined value for \$x";
   return $x;
}

my $COUNT = 50_000;

my $elapsed_DC    = 0;
my $elapsed_TS    = 0;
my $elapsed_manual= 0;

# To reduce the influence of bursts of timing noise, interleave many small runs
# of each type.

foreach ( 1 .. 20 ) {
   my $overhead = measure {};

   $elapsed_DC += -$overhead + measure {
      func_DC( 123 ) for 1 .. $COUNT;
   };
   $elapsed_TS += -$overhead + measure {
      func_TS( 123 ) for 1 .. $COUNT;
   };
   $elapsed_manual += -$overhead + measure {
      func_manual( 123 ) for 1 .. $COUNT;
   };
}

pass( "Benchmarked" );

if( $elapsed_DC > $elapsed_TS ) {
   diag( sprintf "Types::Standard took %.3fsec, ** this was SLOWER at %.3fsec **",
      $elapsed_TS, $elapsed_DC );
}
else {
   my $speedup = ( $elapsed_TS - $elapsed_DC ) / $elapsed_TS;
   diag( sprintf "Types::Standard took %.3fsec, this was %d%% faster at %.3fsec",
      $elapsed_TS, $speedup * 100, $elapsed_DC );
}

my $speedup = ( $elapsed_manual - $elapsed_DC ) / $elapsed_manual;
if( $elapsed_DC > $elapsed_manual ) {
   diag( sprintf "manual took %.3fsec, this was %d%% slower at %.3fsec",
      $elapsed_manual, -$speedup * 100, $elapsed_DC );
}
else {
   diag( sprintf "manual took %.3fsec, this was %d%% faster at %.3fsec",
      $elapsed_manual, $speedup * 100, $elapsed_DC );
}

done_testing;
