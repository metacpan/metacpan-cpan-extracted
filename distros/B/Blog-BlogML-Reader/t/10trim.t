#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 4;
use blib;
use Blog::BlogML::Reader;

can_ok('Blog::BlogML::Reader', '_trim');
my $reader = new Blog::BlogML::Reader('t/example.xml');
my $meta = $reader->meta();

my $test_string = " 	zoo bar \n \t\t";
Blog::BlogML::Reader::_trim($test_string);
is($test_string, 'zoo bar', q(Leading and trailing whitespace trimmed.));
is($meta->{title}, 'Animal News', q(Whitespace in title is as expected.));
is($meta->{subtitle}, 'The wild side of the news.', q(Whitespace in subtitle is as expected.));