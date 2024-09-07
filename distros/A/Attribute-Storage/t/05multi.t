#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use Attribute::Storage qw( get_subattr );

sub One :ATTR(CODE)
{
   my $package = shift;
   1;
}

sub Many :ATTR(CODE,MULTI)
{
   my $package = shift;
   my ( $oldvalue ) = @_;
   return ++$oldvalue;
}

# We have to put  my $dummy = ...  or else the Perl compiler gets confused.
# Reported to perl-p5p@
eval "my \$dummy = sub :One :One { 'XXX' }";
like( $@, qr/^Already have the One attribute /, 'Applying :One multiple times dies' );

my $coderef = eval "my \$dummy = sub :Many :Many :Many { 'XXX' }";
ok( !$@, 'Applying :Many succeeds' );
is( get_subattr( $coderef, "Many" ), 3, 'Value of Many is 3' );

done_testing;
