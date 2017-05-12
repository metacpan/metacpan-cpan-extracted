#!/usr/bin/perl
# basic-list.t 
# Copyright (c) 2007 Jonathan Rockway <jrockway@cpan.org>
use Test::More tests => 11;
use Algorithm::IncludeExclude;

my $ie = Algorithm::IncludeExclude->new;

$ie->exclude('foo');
$ie->exclude('bar');
$ie->include(qw/foo baz/);

is($ie->evaluate('foo'), 0);
is($ie->evaluate('bar'), 0);
is($ie->evaluate(qw/foo baz/), 1);
is($ie->evaluate(qw/foo baz bar/), 1);
is($ie->evaluate(qw/foo bar baz/), 0);
is($ie->evaluate(qw/bar baz/), 0);
is($ie->evaluate('quux'), undef);
is($ie->evaluate('fooo'), undef);
is($ie->evaluate(qw/x foo baz/), undef);
is($ie->evaluate(qw/foo foo baz/), 0);
is($ie->evaluate(), undef);
