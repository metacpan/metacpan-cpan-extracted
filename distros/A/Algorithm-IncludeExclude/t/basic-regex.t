#!/usr/bin/perl
# basic-regex.t 
# Copyright (c) 2007 Jonathan Rockway <jrockway@cpan.org>
use Test::More tests => 6;
use Algorithm::IncludeExclude;

my $ie = Algorithm::IncludeExclude->new;

$ie->include('foo');
$ie->exclude('foo', qr/[.]pl$/);

is($ie->evaluate(), undef);
is($ie->evaluate('foo'), 1);
is($ie->evaluate(qw/foo bar/), 1);
is($ie->evaluate(qw/foo bar baz/), 1);
is($ie->evaluate(qw/foo bar.pl/), 0);
is($ie->evaluate(qw/foo bar baz.pl/), 0);
