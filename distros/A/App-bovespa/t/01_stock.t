#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use_ok( 'App::bovespa' );

my $ministock = App::bovespa->new();

is( ref $ministock, "App::bovespa", "Yes, it is" );

#
# All stocks should return a value that is digit dot digit
#

my $match = qr/\d{1,3}.\d{1,2}/;

#my $rent3 = $ministock->stock( "RENT3" );

#diag "This is rent3 $rent3 .";

ok ( $ministock->stock( "RENT3" ) =~ /$match/ , "It seems that works localiza" );
ok ( $ministock->stock( "PETR4" ) =~ /$match/ , "It seems that works Petrobras" );

done_testing;
