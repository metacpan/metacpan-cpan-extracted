#!/usr/bin/env perl
use warnings;
use strict;
use Test::More tests => 8;

package Test01;
use parent 'Class::Accessor::Complex';
__PACKAGE__->mk_new->mk_integer_accessors(qw(an_integer reset));

# Gen an integer accessor called 'reset' because mk_integer_accessors() also
# generates reset_* and *_reset, so check there are no 'redefined' warnings.
package main;
can_ok(
    'Test01', qw(
      an_integer an_integer_reset an_integer_inc an_integer_dec
      reset reset_reset reset_inc reset_dec
      )
);
my $test01 = Test01->new;
is($test01->an_integer, 0, 'integer default value');
$test01->an_integer('blah');
is($test01->an_integer, 'blah', 'read set non-integer value');
$test01->an_integer(7);
is($test01->an_integer, 7, 'read set integer value');
$test01->an_integer_inc;
$test01->inc_an_integer;
is($test01->an_integer, 9, 'incremented integer');
$test01->an_integer_dec;
$test01->dec_an_integer;
is($test01->an_integer, 7, 'decremented integer');
$test01->an_integer_reset;
is($test01->an_integer, 0, 'reset integer');
$test01->reset_an_integer;
is($test01->an_integer, 0, 'reset integer again');
