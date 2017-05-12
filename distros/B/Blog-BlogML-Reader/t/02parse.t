#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 3;
use blib;
use Blog::BlogML::Reader;

my $reader;
eval { $reader = new Blog::BlogML::Reader('t/example.xml'); };
is($@, '', q(new Blog::BlogML::Reader('t/example.xml') runs.));
isa_ok($reader, 'Blog::BlogML::Reader');
is(@{$reader->{blog}{posts}}, 5, q(Found all five posts.));
