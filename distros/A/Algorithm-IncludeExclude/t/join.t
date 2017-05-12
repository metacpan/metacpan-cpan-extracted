#!/usr/bin/perl
# join.t 
# Copyright (c) 2007 Jonathan Rockway <jrockway@cpan.org>
use Test::More tests => 2;
use Algorithm::IncludeExclude;

my $ie = Algorithm::IncludeExclude->new({join => '|XXX|'});

$ie->include('foo');
$ie->exclude(qr/foo\|XXX\|bar$/);

is $ie->evaluate('foo'), 1;
is $ie->evaluate('foo', 'bar'), 0;
