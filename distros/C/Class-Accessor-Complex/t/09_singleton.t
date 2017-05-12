#!/usr/bin/env perl
use warnings;
use strict;
use Test::More tests => 6;

package Test01;
use parent 'Class::Accessor::Complex';
__PACKAGE__->mk_singleton->mk_scalar_accessors(qw(name));

package main;
can_ok(
    'Test01', qw(
      new name name_clear clear_name
      )
);
my $test01 = Test01->new(name => 'Shindou Hikaru');
is($test01->name, 'Shindou Hikaru', 'name of first object');
my $test02 = Test01->new;
is($test02->name, 'Shindou Hikaru', 'name of second object');
my $test03 = Test01->new(name => 'Touya Akira');
is($test03->name, 'Shindou Hikaru', 'field initialized only during first time');
$test02->name('Touya Akira');
is($test01->name, 'Touya Akira', "first object's name changed as well");
is($test03->name, 'Touya Akira', "third object's name changed as well");
