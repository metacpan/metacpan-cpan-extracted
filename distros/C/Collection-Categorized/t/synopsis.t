#!/usr/bin/env perl
# Copyright (c) 2007 Jonathan Rockway <jrockway@cpan.org>

use strict;
use warnings;
use Test::More tests => 4;
use Collection::Categorized;

# create a collection where elements are categorized by
# the class they are in
my $cc = Collection::Categorized->new( sub { ref $_ } );

my $foo  = bless {} => 'Foo';
my $bar  = bless {} => 'Bar';
my $bar2 = bless {} => 'Bar';
my @bazs = map { bless {} => 'Baz' } 1..10;

# add some data
$foo->{awesomeness} = 42;
$cc->add($foo); # $foo isa Foo
$cc->add($bar, $bar2); # $bars are Bars
$cc->add(@bazs); # @bazs are Bazs

# see what we have
my @c = $cc->categories; # (Foo, Bar, Baz) 
is_deeply [sort @c], [sort qw/Foo Bar Baz/], 'foo bar baz categories';

# get the data by category  
my @foos = $cc->get('Foo'); # ($foo)
my @bars = $cc->get('Bar'); # ($bar, $bar2)
my @HOOO = $cc->get('HOOO'); # undef

# grep the data
$cc->edit(sub { grep { defined $_->{awesomeness} } @_ });
is_deeply [$cc->get('Foo')], [@foos], 'got one foo';
is_deeply [$cc->get('Bar')], [], 'no bars';
is_deeply [$cc->get('HOOO')], [], "no HOOOs (too bad this isn't CPAN)";
