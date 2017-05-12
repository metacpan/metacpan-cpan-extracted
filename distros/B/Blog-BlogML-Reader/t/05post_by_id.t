#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 4;
use blib;
use Blog::BlogML::Reader;

my $reader = new Blog::BlogML::Reader('t/example.xml', post=>115);
my $posts = $reader->posts();

is(@$posts, 1, q(Found one post with given id.));
my $post = shift @$posts;
ok($post->{id} eq '115', q(Found post has the expected id.));
ok($post->{title} =~ /Killer Pythons/, q(Found post has expected title.));
ok($post->{content} =~ /slithery creatures/, q(Found post has expected content.));