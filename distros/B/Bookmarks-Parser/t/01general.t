#!/usr/bin/perl

use lib 'lib';
use Test::More tests => 2;
use Data::Dumper;

use_ok('Bookmarks::Parser');

my $parser = Bookmarks::Parser->new();
isa_ok($parser, 'Bookmarks::Parser');
