#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

# This "test" never fails, but prints a benchmark comparison between
# Data::Checks and Types::Standard performing the same :Checked attribute
# assertions on an object field.

BEGIN {
   eval { require Object::Pad::FieldAttr::Checked;
          Object::Pad::FieldAttr::Checked->VERSION( '0.10' ) } or
      plan skip_all => "Object::Pad::FieldAttr::Checked >= 0.10 is not available";

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

use Object::Pad;
use Object::Pad::FieldAttr::Checked;
use Data::Checks;
use Types::Standard;

class TestClass_DC {
   field $x :param :Checked(Data::Checks::Defined);
}

class TestClass_TS {
   field $x :param :Checked(Types::Standard::Defined);
}

my $COUNT = 10_000;

my $elapsed_DC = 0;
my $elapsed_TS = 0;

# To reduce the influence of bursts of timing noise, interleave many small runs
# of each type.

foreach ( 1 .. 20 ) {
   my $overhead = measure {};

   $elapsed_DC += -$overhead + measure {
      TestClass_DC->new( x => 123 ) for 1 .. $COUNT;
   };
   $elapsed_TS += -$overhead + measure {
      TestClass_TS->new( x => 123 ) for 1 .. $COUNT;
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

done_testing;
