#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Attribute::Storage qw( get_subattr get_subattrs apply_subattrs );

sub Title :ATTR(CODE)
{
   my $package = shift;
   my ( $title ) = @_;

   return "" unless defined $title;
   return $title;
}

my $code = apply_subattrs
   Title => '"Here is my title"',
   sub { };

is( get_subattr( $code, "Title" ), "Here is my title", 'apply_subattrs can set Title on $code' );

done_testing;
