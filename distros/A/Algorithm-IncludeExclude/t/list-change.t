#!/usr/bin/perl
# list-change.t 
# Copyright (c) 2007 Jonathan Rockway <jrockway@cpan.org>
use Test::More tests => 13;
use Algorithm::IncludeExclude;

my $ie = Algorithm::IncludeExclude->new;

is($ie->evaluate(), undef);
is($ie->evaluate(qw/foo bar baz quux qux quuuux la la la/), undef);

$ie->include();
is($ie->evaluate(), 1);
is($ie->evaluate(qw/foo bar baz quux qux quuuux la la la/), 1);

$ie->exclude('foo');
is($ie->evaluate(), 1);
is($ie->evaluate(qw/foo bar baz quux/), 0);
is($ie->evaluate(qw/made up name/), 1);

$ie->include('foo');
is($ie->evaluate(), 1);
is($ie->evaluate(qw/foo bar baz quux/), 1);
is($ie->evaluate(qw/made up name/), 1);

$ie->exclude();
is($ie->evaluate(), 0);
is($ie->evaluate(qw/foo bar baz quux/), 1);
is($ie->evaluate(qw/made up name/), 0);
