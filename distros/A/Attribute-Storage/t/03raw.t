#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Attribute::Storage qw( get_subattr );

sub Title :ATTR(CODE,RAWDATA)
{
   my $package = shift;
   my ( $text ) = @_;

   return $text;
}

# This title text would be a perl syntax error if it were not RAWDATA
sub myfunc :Title(Here is my raw text)
{
}

is( get_subattr( \&myfunc, "Title" ), "Here is my raw text", 'get_subattr Title on \&myfunc' );

done_testing;
