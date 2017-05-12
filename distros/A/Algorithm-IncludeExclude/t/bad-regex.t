#!/usr/bin/perl
# bad-regex.t 
# Copyright (c) 2007 Jonathan Rockway <jrockway@cpan.org>
use Test::More tests => 14;
use Test::Exception;
use Algorithm::IncludeExclude;

my $ie = Algorithm::IncludeExclude->new;
dies_ok { $ie->exclude(qr/foo/, 'bar') };
dies_ok { $ie->exclude(qr/foo/, qr/foo/, 'bar') };
dies_ok { $ie->exclude('bar', qr/foo/, 'baz') };
dies_ok { $ie->exclude('bar', qr/foo/, qr/bar/) };
dies_ok { $ie->include(qr/foo/, 'bar') };
dies_ok { $ie->include(qr/foo/, qr/foo/, 'bar') };
dies_ok { $ie->include('bar', qr/foo/, 'baz') };
dies_ok { $ie->include('bar', qr/foo/, qr/bar/) };

lives_ok{ $ie->include(qr/foo|bar/) };
lives_ok{ $ie->include('string') };
lives_ok{ $ie->include('string', qr/regex/) };
lives_ok{ $ie->exclude(qr/foo|bar/) };
lives_ok{ $ie->exclude('string') };
lives_ok{ $ie->exclude('string', qr/regex/) };
