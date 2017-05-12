#!/usr/bin/env perl
use warnings;
use strict;
use Test::More tests => 8;

package Test01;
use parent 'Class::Accessor::Complex';
__PACKAGE__->mk_new->mk_concat_accessors('plain', [ output => '---' ]);

package main;
can_ok(
    'Test01', qw(
      output output_clear clear_output
      )
);
my $test01 = Test01->new;
is($test01->output, undef, 'concat default value');
$test01->output('blah');
is($test01->output, 'blah', 'added "blah"');
$test01->output(7);
is($test01->output, 'blah---7', 'added 7');
$test01->clear_output;
is($test01->output, undef, 'after clear');
$test01->plain('blah');
is($test01->plain, 'blah', 'empty join string: added "blah"');
$test01->plain(7);
is($test01->plain, 'blah7', 'empty join string: added 7');
$test01->clear_plain;
is($test01->plain, undef, 'empty join string: after clear');
