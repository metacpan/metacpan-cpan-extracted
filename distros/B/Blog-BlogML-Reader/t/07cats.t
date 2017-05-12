#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 5;
use blib;
use Blog::BlogML::Reader;

can_ok('Blog::BlogML::Reader', 'cats');
my $reader = new Blog::BlogML::Reader('t/example.xml');
my $cats = $reader->cats();

is(keys %$cats, 5, q(Found five cats.));
ok($cats->{100}{title} =~ /Pets/, q(Found cat has expected title.));

my $cat_parent = $cats->{201}{parent};
is($cat_parent, 200, q(Found cat has expected parent ref.));
like($cats->{$cat_parent}{title}, qr/Reptiles/, q(Parent cat has expected title.));