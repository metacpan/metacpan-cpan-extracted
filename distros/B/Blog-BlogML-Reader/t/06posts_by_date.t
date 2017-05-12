#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 10;
use blib;
use Blog::BlogML::Reader;

my $reader = new Blog::BlogML::Reader('t/example.xml', after=>"2006-04-12T00:00:00");
my $posts = $reader->posts();

is(@$posts, 3, q(Found three post created after given date.));
my $post = shift @$posts;
ok($post->{id} eq '120', q(First found post has the expected id.));
$post = shift @$posts;
ok($post->{id} eq '121', q(Second found post has the expected id.));

$reader = new Blog::BlogML::Reader('t/example.xml',
	after  => "2006-04-01T00:00:00",
	before => "2006-05-01T00:00:00",
);
$posts = $reader->posts();
is(@$posts, 2, q(Found two post created in given date range.));
my $fpost = shift @$posts;
is($fpost->{id}, '121', q(First found post in date range has the expected id.));
my $lpost = pop @$posts;
is($lpost->{id}, '122', q(Last found post in date range has the expected id.));

$reader = new Blog::BlogML::Reader('t/example.xml', before => "2006-01-01T00:00:00");
$posts = $reader->posts();
is(@$posts, 1, q(Found one post created before given date.));
$fpost = shift @$posts;
is($fpost->{id}, '93', q(Found post before date has the expected id.));

$reader = new Blog::BlogML::Reader('t/example.xml', before => "1136116800"); #2006-01-01T12:00:00
$posts = $reader->posts();
is(@$posts, 2, q(Found two posts created before given numeric date.));
$fpost = shift @$posts;
is($fpost->{id}, '115', q(Found post before date has the expected id.));
