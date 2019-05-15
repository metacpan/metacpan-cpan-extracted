#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;
use Cfn;

use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::DummyProps',
  from 'HashRef',
   via { Cfn::Resource::Properties::DummyProps->new( %$_ ) };

package Cfn::Resource::Properties::DummyProps {
  use Moose;
  extends 'Cfn::Resource::Properties';
  has Prop1 => (is => 'ro', isa => 'Cfn::Value', coerce => 1);
}

package Cfn::Resource::Type1 {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (is => 'ro', isa => 'Cfn::Resource::Properties::DummyProps', coerce => 1);
}

throws_ok(sub {
  Cfn::Resource::Type1->new(
    Type => 'XXX'
  );
}, qr/Invalid Cfn::Resource/, "Can't assign a conflicting type to a resource");

throws_ok(sub {
  Cfn::Resource::Type1->new(
    DeletionPolicy => 'InvalidOption'
  );
}, qr/InvalidOption is an invalid DeletionPolicy/, "Can't use an invalid DeletionPolicy");

throws_ok(sub {
  Cfn::Resource::Type1->new(
    UpdateReplacePolicy => 'InvalidOption'
  );
}, qr/InvalidOption is an invalid UpdateReplacePolicy/, "Can't use an invalid UpdateReplacePolicy");

throws_ok(sub {
  Cfn::Resource::Type1->new(
    UpdatePolicy => 'Not a hashref'
  );
}, qr/not isa Cfn::Resource::UpdatePolicy/, "Can't use an invalid UpdatePolicy");

{
  my $o = Cfn::Resource::Type1->new(
    DeletionPolicy => 'Retain',
    CreationPolicy => {
      AutoScalingCreationPolicy => {
        MinSuccessfulInstancesPercent => 50
      },
    },
    UpdateReplacePolicy => {
      AutoScalingRollingUpdate => { MaxBatchSize => 5 },
    },
    UpdateReplacePolicy => 'Retain',
    Metadata => {
      m1 => 'v1',
    }
  );

  is_deeply($o->as_hashref, {
    'UpdateReplacePolicy' => 'Retain',
    'DeletionPolicy' => 'Retain',
    'CreationPolicy' => {
      AutoScalingCreationPolicy => {
        MinSuccessfulInstancesPercent => 50
      },
    },
    'Metadata' => {
      'm1' => 'v1'
    },
    'Type' => 'Type1'
  });
}

done_testing;
