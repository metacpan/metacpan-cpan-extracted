#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 3;
use blib;
use Blog::BlogML::Reader;

my $reader = new Blog::BlogML::Reader('t/example.xml', cat=>'100');
my $posts = $reader->posts();

is(@$posts, 2, q(Found two posts with the given cat.));
ok((grep{''.$_->{id} eq '121'}@$posts), q(Found expected post in results.));
ok((grep{''.$_->{id} eq '93'}@$posts), q(Found expected post in results.));
