#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use Attribute::Storage qw( get_subattr );

sub Number :ATTR(CODE)
{
   my $package = shift;
   my ( @values ) = @_;

   my $total;
   $total += $_ for @values;

   return $total;
}

sub myfunc :Number(1,2,3,4,5)
{
}

is( get_subattr( \&myfunc, "Number" ), 15, 'get_subattr Number on \&myfunc' );

done_testing;
