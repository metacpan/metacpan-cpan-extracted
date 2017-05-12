#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

my @input;
my $output;
{
   package Test_perlsh;
   use base qw( App::perlsh );

   sub read { shift @input }
   sub print { shift; $output .= join "", @_ }
}

{
   @input = ( "1" );
   $output = "";

   Test_perlsh->run;

   is( $output, "'1'\n\n\n", 'Output from "1"' );
}

done_testing;
