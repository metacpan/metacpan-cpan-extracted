#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use Attribute::Storage qw( get_subattr );

my @destroyed;
sub FreeGuard::DESTROY { push @destroyed, $_[0]->[0] }

sub Value :ATTR(CODE)
{
   my $package = shift;
   my ( $value ) = @_;
   return bless [ $value ], "FreeGuard";
}

sub myfunc :Value("first generation")
{
}

is( get_subattr( "myfunc", "Value" ), [ "first generation" ], 'First generation of attribute' );

{
   no warnings 'redefine';
   *myfunc = sub :Value("second generation") {}
}

is( get_subattr( "myfunc", "Value" ), [ "second generation" ], 'Second generation of attribute' );
is( \@destroyed, [ "first generation" ], 'First generation got destroyed' );

done_testing;
