#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Attribute::Storage qw( find_subs_with_attr );

{
   package Testing;

   use Attribute::Storage;

   sub Title :ATTR(CODE)
   {
      my $package = shift;
      my ( $title ) = @_;
      return $title;
   }

   sub one :Title("One") { 1 }

   sub two :Title("Two") { 2 }

   sub three :Title("Three") { 3 }

   package SubClass;

   use base qw( Testing );

   sub four :Title("Four") {}
}

my %subs = find_subs_with_attr "Testing", "Title";

is( $subs{one}, \&Testing::one, 'find_subs_with_attr finds sub one()' );
is( $subs{two}, \&Testing::two, 'find_subs_with_attr finds sub two()' );
is( $subs{three}, \&Testing::three, 'find_subs_with_attr finds sub three()' );

%subs = find_subs_with_attr( [qw( SubClass Testing )], "Title" );

is( $subs{one}, \&Testing::one, 'find_subs_with_attr on subclass finds parent subs' );

# matching
{
   my %subs = find_subs_with_attr "Testing", "Title", matching => sub { length == 3 };

   ok(  defined $subs{one},   'find_subs_with_attr matching CODE finds one' );
   ok( !defined $subs{three}, 'find_subs_with_attr matching CODE does not find three' );

   %subs = find_subs_with_attr "Testing", "Title", matching => qr/^...$/;

   ok(  defined $subs{one},   'find_subs_with_attr matching Regexp finds one' );
   ok( !defined $subs{three}, 'find_subs_with_attr matching Regexp does not find three' );
}

# filter
{
   my %subs = find_subs_with_attr "Testing", "Title", filter => sub {
      my ( $cv ) = @_;
      return $cv->() % 2;
   };

   ok(  defined $subs{one}, 'find_subs_with_attr filter finds one' );
   ok( !defined $subs{two}, 'find_subs_with_attr filter does not find two' );
}

done_testing;
