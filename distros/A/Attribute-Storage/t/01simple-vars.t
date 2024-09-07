#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use Attribute::Storage qw( get_varattr get_varattrs );

my $warnings = 0;
BEGIN {
   $SIG{__WARN__} = sub {
      local $SIG{__WARN__};
      warn $_[0];
      $warnings++;
   };
}

sub Title :ATTR(SCALAR,ARRAY,HASH)
{
   my $package = shift;
   my ( $title ) = @_;

   return "" unless defined $title;
   return $title;
}

my $lexvar :Title('The title of my lexical scalar');
my @lexvar :Title('The title of my lexical array');
my %lexvar :Title('The title of my lexical hash');

is( get_varattr( \$lexvar, "Title" ), "The title of my lexical scalar",
   'get_varattr Title on \$lexvar' );
is( get_varattr( \@lexvar, "Title" ), "The title of my lexical array",
   'get_varattr Title on \$lexvar' );
is( get_varattr( \%lexvar, "Title" ), "The title of my lexical hash",
   'get_varattr Title on \$lexvar' );

is( get_varattrs( \$lexvar ),
   { Title => "The title of my lexical scalar" },
   'get_varattrs on \$lexvar' );

our $pkgvar :Title('The title of a package var');

is( get_varattr( \$pkgvar, "Title" ), "The title of a package var",
   'get_varattr Title on \$pkgvar' );

is( $warnings, 0, 'No warnings were produced' );
done_testing;
