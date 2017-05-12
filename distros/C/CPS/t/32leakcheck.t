#!/usr/bin/perl -w

use strict;

use Test::More;

use CPS qw( kwhile );

if( $] < 5.008 ) {
   plan skip_all => "weaken() doesn't work before 5.8";
}
else {
   plan tests => 3;
}

my $destroycount = 0;

my $poke;

{
   my $obj = DestroyCounter->new( \$destroycount );
   my $callcount = 0;

   kwhile(
      sub {
         my ( $knext, $klast ) = @_;

         $callcount++;

         # Just so this closure references the variable
         $obj = $obj;

         return $klast->() if $callcount == 3;

         $poke = $knext;
      },
      sub {
      }
   );
}

is( $destroycount, 0, 'Initially undestroyed' );

$poke->();

is( $destroycount, 0, 'Undestroyed after first poke' );

$poke->();
undef $poke;

is( $destroycount, 1, 'Destroyed after second poke' );

package DestroyCounter;

sub new
{
   my $class = shift;
   my ( $varref ) = @_;
   bless [ $varref ], $class;
}

sub DESTROY
{
   my $self = shift;
   ${ $self->[0] }++;
}
