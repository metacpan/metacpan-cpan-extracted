#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use FindBin qw/$Bin/;
use File::Spec;

use_ok('App::cpanreports');

my $perl = File::Spec->rel2abs($^X);
ok( !(system $perl, '-c', "$Bin/../bin/cpan-reports"), "bin/cpan-reports compiles");

diag( "Testing App::cpanreports 0.004, Perl $], $^X" );
done_testing();
