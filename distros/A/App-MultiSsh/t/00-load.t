#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use Test::Warnings;
use File::Spec;

BEGIN {
    use_ok( 'App::MultiSsh' );
}

diag my $perl = File::Spec->rel2abs($^X);
ok !(system $perl, qw{ -Ilib -c bin/mssh}), "bin/mssh compiles";

diag( "Testing App::MultiSsh $App::MultiSsh::VERSION, Perl $], $^X" );
done_testing();
