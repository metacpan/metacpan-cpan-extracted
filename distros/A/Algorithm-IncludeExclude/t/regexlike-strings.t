#!/usr/bin/perl
# regexlike-strings.t 
# Copyright (c) 2007 Jonathan Rockway <jrockway@cpan.org>

use Test::More tests => 3;
use Algorithm::IncludeExclude;

my $ie = Algorithm::IncludeExclude->new;

$ie->include('(?-xism:^foobar$)');   # string (?-xism:foobar)
$ie->exclude(qr/^foobar$/);            # regex

is $ie->evaluate('afoobar'), undef,    'no match';
is $ie->evaluate('foobar'), 0,         'matches regex';         
is $ie->evaluate('(?-xism:^foobar$)'), 1, 'matches string';
