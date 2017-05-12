#!/usr/bin/perl
# synopsis2.t 
# Copyright (c) 2007 Jonathan Rockway <jrockway@cpan.org>
# always a good idea to see if the example in the docs works
use Test::More tests => 6;
use Algorithm::IncludeExclude;

my $ie = Algorithm::IncludeExclude->new;
$ie->exclude('admin');
$ie->exclude(qr/[.]protected$/);

is $ie->evaluate(qw/admin let me in/), 0;
is $ie->evaluate(qw/a path.protected/), 0;
is $ie->evaluate(qw/foo bar/), undef;

$ie->include(qw/foo bar/);
is $ie->evaluate(qw/foo bar/), 1;

$ie->include('admin', qr/[.]ok$/);
is $ie->evaluate(qw/admin super public records.ok/), 1;

$ie->exclude('XXX', 'YYY');
$ie->include(qr/YYY/);

is $ie->evaluate('XXX', 'YYY'), 1; # include, due to regex

