#!/usr/bin/env perl

use Test::More;

package TestClass {
  use Moose;
  extends 'CCfn';
  use CCfnX::CommonArgs;
  use CCfnX::Shortcuts;
  use CCfnX::InstanceArgs;

  has params => (is => 'ro', isa => 'CCfnX::CommonArgs', default => sub { CCfnX::InstanceArgs->new(
    instance_type => 'x1.xlarge',
    region => 'eu-west-1',
    account => 'devel-capside',
    name => 'NAME'
  ); } );

  metadata 'MyMDTest1', Ref('XXX');
  metadata 'MyMDTest2', 'String';
  metadata 'MyMDTest3', { a => 'hash' };
  metadata 'MyMDTest4', [ 1,2,3,4 ];
}

my $obj = TestClass->new;
my $struct = $obj->as_hashref;

is_deeply(
  $struct->{Metadata}->{ MyMDTest1 },
  { Ref => 'XXX' },
  'Got a Ref in MyMDTest1'
);

cmp_ok(
  $struct->{Metadata}->{ MyMDTest2 },
  'eq', 'String',
  'Got a string in MyMDTest2'
);

is_deeply(
  $struct->{Metadata}->{ MyMDTest3 },
  { a => 'hash' },
  'Got a hash in MyMDTest3'
);

is_deeply(
  $struct->{Metadata}->{ MyMDTest4 },
  [ 1,2,3,4 ],
  'Got an array in MyMDTest4'
);

done_testing;
