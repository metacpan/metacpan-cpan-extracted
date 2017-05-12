#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Exception;
use Cwd qw();

use_ok('Catmandu::Fix::basename');

my $path = Cwd::realpath( __FILE__ );

my $fixer;

lives_ok(sub {
    $fixer = Catmandu::Fix::basename->new('path');
},"fixer created");

is_deeply($fixer->fix({ path => $path }),{ path => "Catmandu-Fix-basename.t" },"test ok");

done_testing 3;
