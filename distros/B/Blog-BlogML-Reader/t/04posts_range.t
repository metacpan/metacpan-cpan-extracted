#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 8;
use blib;
use Blog::BlogML::Reader;

my $reader = new Blog::BlogML::Reader('t/example.xml', from=>3, to=>5);
my $posts = $reader->posts();

is(@$posts, 3, q(Found three posts in that range.));
my $post = shift @$posts;
is($post->{id}, '122', q(First found post has the expected id.));
$post = pop @$posts;
is($post->{id}, '93', q(Last found post has the expected id.));

$reader = new Blog::BlogML::Reader('t/example.xml', to=>2);
$posts = $reader->posts();

is(@$posts, 2, q(Found two posts in that range.));
$post = shift @$posts;
is($post->{id}, '120', q(First found post has the expected id.));
$post = shift @$posts;
is($post->{id}, '121', q(Second found post has the expected id.));

$reader = new Blog::BlogML::Reader('t/example.xml', to=>4);
$posts = $reader->posts();

is(@$posts, 4, q(Found four posts in that range.));
$post = pop @$posts;
is($post->{id}, '115', q(Last found post has the expected id.));