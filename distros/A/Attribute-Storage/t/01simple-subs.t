#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use Attribute::Storage qw( get_subattr get_subattrs );

my $warnings = 0;
BEGIN {
   $SIG{__WARN__} = sub {
      local $SIG{__WARN__};
      warn $_[0];
      $warnings++;
   };
}

sub Title :ATTR(CODE)
{
   my $package = shift;
   my ( $title ) = @_;

   return "" unless defined $title;
   return $title;
}

sub myfunc :Title('The title of myfunc')
{
}

sub emptytitle :Title
{
}

sub anotherfunc
{
}

is( get_subattr( \&myfunc, "Title" ), "The title of myfunc", 'get_subattr Title on \&myfunc' );

is( get_subattr( "myfunc", "Title" ), "The title of myfunc", 'get_subattr Title on "myfunc"' );

is( get_subattr( \&myfunc, "Another" ), undef, 'get_subattr Another' );

is( get_subattr( \&anotherfunc, "Title" ), undef, 'get_subattr Title on \&another' );

is( get_subattrs( \&myfunc ),
   { Title => "The title of myfunc" },
   'get_subattrs' );

my $coderef;

$coderef = sub :Title('Dynamic code') { 1 };
is( get_subattr( $coderef, "Title" ), "Dynamic code", 'get_subattr Title on anon CODE' );

# We have to put  my $dummy = ...  or else the Perl compiler gets confused.
# Reported to perl-p5p@
$coderef = eval "my \$dummy = sub :Title('eval code') { 2 }" or die $@;
is( get_subattr( $coderef, "Title" ), "eval code", 'get_subattr Title on anon CODE from eval' );

$coderef = sub { 1 };
attributes->import( main => $coderef, "Title('attributes import')" );
is( get_subattr( $coderef, "Title" ), "attributes import", 'get_subattr Title on anon CODE from attributes->import application' );

{
   package OtherPackage;

   $coderef = sub { 2 };
   attributes->import( main => $coderef, "Title('import in other package')" );
}

is( get_subattr( $coderef, "Title" ), "import in other package", 'get_subattr Title on anon CODE ref in another package using attributes->import' );

is( $warnings, 0, 'No warnings were produced' );
done_testing;
