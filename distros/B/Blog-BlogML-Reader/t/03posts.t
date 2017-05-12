#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 4;
use blib;
use Blog::BlogML::Reader;

can_ok('Blog::BlogML::Reader', 'posts');
my $reader = new Blog::BlogML::Reader('t/example.xml');
my $posts = $reader->posts();
is(@$posts, 5, q(Found five approved posts.));

ok($posts->[0]{id} eq '120', q(First post has expected id.));
like($posts->[0]{title}, qr/Missing dog found/, q(First post has expected title.));