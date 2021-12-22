#!perl -T
use 5.012;
use strict;
use warnings;
use Test::More tests => 1;


BEGIN {
    my $module = 'Bio::RNA::BarMap';
    use_ok($module) || BAIL_OUT "Module $module could not be loaded.";
}

diag( "Testing Bio::RNA::BarMap $Bio::RNA::BarMap::VERSION, Perl $], $^X" );

