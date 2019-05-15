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
  has Prop2 => (is => 'ro', isa => 'Cfn::Value', coerce => 1);
  has Prop3 => (is => 'ro', isa => 'Cfn::Value', coerce => 1);
  has ArrayProp => (is => 'ro', isa => 'Cfn::Value::Array', coerce => 1);
}

package Cfn::Resource::Type1 {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (is => 'ro', isa => 'Cfn::Resource::Properties::DummyProps', coerce => 1);
}

my $o = Cfn->new;

$o->addResource(
  R1 => Cfn::Resource::Type1->new(
    Properties => { Prop1 => 'X' },
  )
);

$o->addResource(
  R2 => 'Type1',
  Prop1 => 'X',
);

$o->addResource(
  R3 => 'Type1',
  { Prop1 => 'X' }
);

$o->addResource(
  R4 => 'Type1',
  { Prop1 => 'X' },
  { DependsOn => [ 'R1' ] },
);

$o->addResource(
  R5 => 'Type1'
);

# Regression test: adding a WaitConditionHandle this way would blow up
$o->addResource(
  'WCH', 'AWS::CloudFormation::WaitConditionHandle',
);

my $struct = $o->as_hashref;

ok(defined($struct->{ Resources }->{ R1 }));
cmp_ok($struct->{ Resources }->{ R1 }->{ Properties }->{ Prop1 }, 'eq', 'X');

ok(defined($struct->{ Resources }->{ R2 }));
cmp_ok($struct->{ Resources }->{ R2 }->{ Properties }->{ Prop1 }, 'eq', 'X');

ok(defined($struct->{ Resources }->{ R3 }));
cmp_ok($struct->{ Resources }->{ R3 }->{ Properties }->{ Prop1 }, 'eq', 'X');

ok(defined($struct->{ Resources }->{ R4 }));
cmp_ok($struct->{ Resources }->{ R4 }->{ Properties }->{ Prop1 }, 'eq', 'X');
cmp_ok($struct->{ Resources }->{ R4 }->{ DependsOn }->[ 0 ], 'eq', 'R1');

ok(defined($struct->{ Resources }->{ R5 }));

ok(defined($struct->{ Resources }->{ WCH }));

done_testing;
