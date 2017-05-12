#!/usr/bin/perl

# t/03core.t
#  Some core functionality tests
#
# $Id: 03core.t 10346 2009-12-03 01:53:25Z FREQUENCY@cpan.org $

use strict;
use warnings;

use Test::More tests => 4;
use Test::NoWarnings; # 1 test

use Algorithm::Diff::Any;

# Incorrectly called methods
{
  eval { Algorithm::Diff::Any->new('a', 'b'); };
  ok($@, '->new called with string sequences');

  eval { Algorithm::Diff::Any->new([ 'a' ], 'b'); };
  ok($@, '->new called with one array, one string sequence');

  my $obj = Algorithm::Diff::Any->new(
    ['a', 'b', 'c'],
    ['a', 'b', 'd']
  );
  eval { $obj->new; };
  ok($@, '->new called as an object method');
}
