#!/usr/bin/perl
# overlapping-regex.t 
# Copyright (c) 2007 Jonathan Rockway <jrockway@cpan.org>

use Test::More tests => 6;
use Algorithm::IncludeExclude;

my $ie = Algorithm::IncludeExclude->new;

$ie->exclude(qr/foo/);
$ie->include(qr/bar/);

is $ie->evaluate('foo'), 0;
is $ie->evaluate('bar'), 1;
is $ie->evaluate('foobar'), undef;
is $ie->evaluate(qw/foo bar/), undef;
is $ie->evaluate(qw/bar foo/), undef;
is $ie->evaluate(qw/foo XXX XXX bar/), undef;
