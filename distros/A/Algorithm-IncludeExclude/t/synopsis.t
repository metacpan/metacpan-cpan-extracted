#!/usr/bin/perl
# synopsis.t 
# Copyright (c) 2007 Jonathan Rockway <jrockway@cpan.org>

# always a good idea to see if the example in the docs works
use Test::More tests => 4;
use Algorithm::IncludeExclude;

my $ie = Algorithm::IncludeExclude->new;

# setup rules
$ie->include();                      # default to include
$ie->exclude('foo');
$ie->exclude('bar');
$ie->include(qw/foo baz/);

# evaluate candidates
is($ie->evaluate(qw/foo bar/), 0);
is($ie->evaluate(qw/quux foo bar/), 1);
is($ie->evaluate(qw/foo baz quux/), 1);
is($ie->evaluate(qw/bar baz/), 0);
