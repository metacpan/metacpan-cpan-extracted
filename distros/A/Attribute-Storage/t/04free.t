#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

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

is_deeply( get_subattr( "myfunc", "Value" ), [ "first generation" ], 'First generation of attribute' );

{
   no warnings 'redefine';
   *myfunc = sub :Value("second generation") {}
}

is_deeply( get_subattr( "myfunc", "Value" ), [ "second generation" ], 'Second generation of attribute' );
is_deeply( \@destroyed, [ "first generation" ], 'First generation got destroyed' );

done_testing;
