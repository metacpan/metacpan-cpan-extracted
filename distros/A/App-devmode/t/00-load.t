#!/usr/bin/perl

use strict;
use warnings;
use FindBin qw/$Bin/;
use File::Spec;

use Test::More tests => 2;

use_ok('App::devmode');
my $perl = File::Spec->rel2abs($^X);
ok( !(system $perl, "-I $Bin/../lib", '-c', "$Bin/../bin/devmode"), "bin/devmode compiles");

diag( "Testing App::devmode $App::devmode::VERSION, Perl $], $^X" );
done_testing();
