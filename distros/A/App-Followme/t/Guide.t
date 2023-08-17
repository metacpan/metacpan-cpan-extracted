#!/usr/bin/env perl
use strict;

use Test::More tests => 3;

use File::Path qw(rmtree);
use File::Spec::Functions qw(catdir catfile rel2abs splitdir);

#----------------------------------------------------------------------
# Load package

my @path = splitdir(rel2abs($0));
pop(@path);
pop(@path);

my $lib = catdir(@path, 'lib');
unshift(@INC, $lib);

$lib = catdir(@path, 't');
unshift(@INC, $lib);

require App::Followme::Guide;

my $test_dir = catdir(@path, 'test');

rmtree($test_dir, 0, 1) if -e $test_dir;
mkdir($test_dir) unless -e $test_dir;
 

#----------------------------------------------------------------------
# Create object

my $obj = App::Followme::Guide->new();
isa_ok($obj, "App::Followme::Guide"); # test 1
can_ok($obj, qw(new print)); # test 2

#----------------------------------------------------------------------
# Print the guide

my $page = $obj->print();
my @lines = split(/\n/, $page);
ok(@lines > 100, "print guide"); # test 3
 