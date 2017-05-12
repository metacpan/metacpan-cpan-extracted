#!/usr/bin/perl

use warnings;
use strict;

use Test::More 'no_plan';

BEGIN {
  eval {require Class::Accessor::Classy};
  ok(!$@);
}

# TODO require some kind of import('USE_NOTES') or something?

my $p = 'Class::Accessor::Classy';
is($p->annotate('foo', 'thing', 'stuff'), 'stuff');
my %notes = $p->get_notes;
is_deeply(\%notes, {foo => {thing => 'stuff'}}, 'notes');

# vi:ts=2:sw=2:et:sta
