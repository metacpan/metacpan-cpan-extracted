#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use Attribute::Storage qw( find_vars_with_attr );

{
   package Testing;

   use Attribute::Storage;

   sub Title :ATTR(SCALAR)
   {
      my $package = shift;
      my ( $title ) = @_;
      return $title;
   }

   our $ONE :Title("One") = 1;

   our $TWO :Title("Two") = 2;

   our $THREE :Title("Three") = 3;
}

my %vars = find_vars_with_attr "Testing", "Title";

is( $vars{'$ONE'}, \$Testing::ONE, 'find_vars_with_attr finds $ONE' );
is( $vars{'$TWO'}, \$Testing::TWO, 'find_vars_with_attr finds $TWO' );
is( $vars{'$THREE'}, \$Testing::THREE, 'find_vars_with_attr finds $THREE' );

# matching
{
   my %vars = find_vars_with_attr "Testing", "Title", matching => sub { length == 4 };

   ok(  defined $vars{'$ONE'},   'find_vars_with_attr matching CODE finds $ONE' );
   ok( !defined $vars{'$THREE'}, 'find_vars_with_attr matching CODE does not find $THREE' );

   %vars = find_vars_with_attr "Testing", "Title", matching => qr/^\$...$/;

   ok(  defined $vars{'$ONE'},   'find_vars_with_attr matching Regexp finds $ONE' );
   ok( !defined $vars{'$THREE'}, 'find_vars_with_attr matching Regexp does not find $THREE' );
}

# filter
{
   my %vars = find_vars_with_attr "Testing", "Title", filter => sub {
      my ( $varref ) = @_;
      return $$varref % 2;
   };

   ok(  defined $vars{'$ONE'}, 'find_vars_with_attr filter finds $ONE' );
   ok( !defined $vars{'$TWO'}, 'find_vars_with_attr filter does not find $TWO' );
}

done_testing;
