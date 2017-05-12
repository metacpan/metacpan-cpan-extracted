#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 6;
use blib;
use Blog::BlogML::Reader;

can_ok('Blog::BlogML::Reader', 'meta');
my $reader = new Blog::BlogML::Reader('t/example.xml');
my $meta = $reader->meta();

like($meta->{title}, qr'Animal News', q(Found expected title.));
like($meta->{subtitle}, qr'The wild side of the news.', q(Found expected subtitle.));
is($meta->{author}, 'Tex McNabbit', q(Found expected author.));
is($meta->{email}, 'tex@wcs.org', q(Found expected email.));
is($meta->{url}, 'http://blog.wcs.org/', q(Found expected url.));

