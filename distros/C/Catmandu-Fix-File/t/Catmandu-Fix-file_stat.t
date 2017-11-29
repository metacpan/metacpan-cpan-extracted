#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Exception;
use File::Spec qw();
use File::Basename qw();

use_ok('Catmandu::Fix::file_stat');

my $path = File::Spec->catfile( File::Basename::dirname( __FILE__ ), "data", "hello.txt" );
my $fixer;

lives_ok(sub {
    $fixer = Catmandu::Fix::file_stat->new('path');
},"fixer created");

isa_ok( $fixer->fix({ path => $path })->{path}, "HASH" );

done_testing 3;
