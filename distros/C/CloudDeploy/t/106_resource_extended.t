#!/usr/bin/env perl

use Test::More;
use CCfn;

#
# This test is designed to verify that the shortcut "resource" assigns extra information (the
# fourth parameter) correctly to resources
#

package Params {
  use Moose;
  with 'MooseX::Getopt';

}

package TestClass {
  use Moose;
  extends 'CCfn';
  use CCfnX::Shortcuts;

  has params => (is => 'ro', isa => 'Params', default => sub { Params->new_with_options });

  resource User => 'AWS::IAM::User', {
    Path => '/',
  }, {
    Metadata => { 'is' => 'Metadata' },
    DeletionPolicy => 'Retain',
  };
}

my $obj = TestClass->new;

cmp_ok($obj->Resource('User')->Properties->Path->as_hashref, 'eq', '/', 'Path is accessible');
is_deeply($obj->Resource('User')->Metadata->as_hashref, { is => 'Metadata' }, 'Metadata is correct');
cmp_ok($obj->Resource('User')->DeletionPolicy, 'eq', 'Retain', 'DeletionPolicy is correct');

done_testing; 
