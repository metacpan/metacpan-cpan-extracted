#!/usr/bin/perl
use strict; use warnings;

use lib qw(lib);
use Blog::BlogML::Reader;
use Date::Format;

# parse all posts in the month of April
my $reader = new Blog::BlogML::Reader('t/example.xml',
  after  => "2006-04-01T00:00:00",
  before => "2006-05-01T00:00:00",
);

my $posts = $reader->posts();
my $meta  = $reader->meta();
my $cats  = $reader->cats();

print "<h1>", $meta->{title}, "</h1>";
print $meta->{author};

foreach my $post (@$posts) {
  print "<h2>", $post->{title}, "</h2>";

  # post dates are returned in Unix time, so format as desired
  print "posted:", time2str("%o of %B %Y", $post->{time});

  print " categories:",
  join(", ",  map{$cats->{$_}{title}} @{$post->{cats}});

  print " link:", $post->{url};

  print $post->{content}, "<hr />";
}