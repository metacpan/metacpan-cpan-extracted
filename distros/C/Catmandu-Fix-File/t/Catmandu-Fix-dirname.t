#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Exception;
use Cwd qw();
use File::Basename qw();

use_ok('Catmandu::Fix::dirname');

my $path = Cwd::realpath( __FILE__ );
my $dirname = File::Basename::dirname( $path );

my $fixer;

lives_ok(sub {
    $fixer = Catmandu::Fix::dirname->new('path');
},"fixer created");

is_deeply($fixer->fix({ path => $path }),{ path => $dirname },"test ok");

done_testing 3;
