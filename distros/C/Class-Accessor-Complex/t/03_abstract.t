#!/usr/bin/env perl
use warnings;
use strict;
use Test::More tests => 2;

package Test01;
use parent 'Class::Accessor::Complex';
__PACKAGE__->mk_new->mk_abstract_accessors(qw(not_there));

package Test02;
our @ISA = ('Test01');
sub not_there { 'is_there' }

package main;
my $test01 = Test01->new;

# Don't use try/catch, as Error::Hierarchy may not be installed, see
# mk_abstract_accessors().
eval { $test01->not_there };
like(
    $@,
    qr/called abstract method \[Test01::not_there\]/,
    'abstract method error message'
);
my $test02 = Test02->new;
eval { $test02->not_there };
is($@, '', 'not_there implemented in subclass');
