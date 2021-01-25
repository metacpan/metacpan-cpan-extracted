#!/usr/bin/perl -w


use strict;
use warnings;
use Test::More tests => 7;

BEGIN { use_ok("DBIx::SearchBuilder::Handle"); }
BEGIN { use_ok("DBIx::SearchBuilder::Handle::mysql"); }

my $h = DBIx::SearchBuilder::Handle::mysql->new();

is ($h->QuoteName('foo'), '`foo`', 'QuoteName works as expected');
is ($h->DequoteName('`foo`'), 'foo', 'DequoteName works as expected');
is ($h->DequoteName('`foo'), '`foo', 'DequoteName works as expected');
is ($h->DequoteName('foo`'), 'foo`', 'DequoteName works as expected');
is ($h->DequoteName('"foo"'), '"foo"', 'DequoteName works as expected');
