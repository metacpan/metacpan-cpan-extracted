#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Exception;
use File::Spec qw();
use File::Basename qw();

use_ok('Catmandu::Fix::human_byte_size');

my $path = File::Spec->catfile( File::Basename::dirname( __FILE__ ), "data", "hello.txt" );
my $fixer;

lives_ok(sub {
    $fixer = Catmandu::Fix::human_byte_size->new('path');
},"fixer created");

is_deeply($fixer->fix({ path => -s $path }),{ path => "12 bytes" },"test ok");

done_testing 3;
