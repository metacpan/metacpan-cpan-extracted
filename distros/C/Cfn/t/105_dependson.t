#!/usr/bin/env perl

use strict;
use warnings;
use Cfn;
use Data::Dumper;
use Test::More;

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

$o->addResource(R1 => 'Type1', { }, { DependsOn => [ 'R2', 'R3' ] });
$o->addResource(R2 => 'Type1', { });
$o->addResource(R3 => 'Type1', { Prop1 => { Ref => 'R2' } });
$o->addResource(R4 => 'Type1', { ArrayProp => [ { Ref => 'R3' }, { Ref => 'R4' } ] });
$o->addResource(R5 => 'Type1', { Prop3 => { 'Fn::Join' => [ ' ', [ 'hello ', { Ref => 'R3' } ] ] } });
$o->addResource(R6 => 'Type1', { Prop1 => { 'Fn::GetAtt' => [ 'R2', 'Prop1' ] } });
$o->addResource(R7 => 'Type1', { Prop1 => { Ref => 'R1' } }, { DependsOn => [ 'R2', 'R3' ] });
$o->addResource(R8 => 'Type1', { Prop1 => { Ref => 'R2' } }, { DependsOn => [ 'R2', 'R3' ] });
$o->addResource(R9 => 'Type1', { Prop1 => { Ref => 'R2' }, Prop2 => { Ref => 'R2' } });
$o->addResource(R10 => 'Type1', { Prop1 => { Ref => 'R2' }, Prop2 => { 'Fn::GetAtt' => [ 'R2', 'Attribute' ] } });
$o->addResource(R11 => 'Type1', { Prop1 => { Ref => 'R2' }, Prop2 => { Ref => 'R2' }, ArrayProp => [ { Ref => 'R2' } ] });
$o->addResource(R12 => 'Type1', { }, { DependsOn => 'R1' });


my $tests = [
  { resource => 'R1',  deps => [ 'R2', 'R3' ], desc => 'Explicit DependsOn'},
  { resource => 'R2',  deps => [  ], desc => 'No deps' },
  { resource => 'R3',  deps => [ 'R2' ], desc => 'Deps in a property with a Ref' },
  { resource => 'R4',  deps => [ 'R3', 'R4' ], desc => 'Deps in an Array property' },
  { resource => 'R5',  deps => [ 'R3' ], desc => 'Ref in a function gets detected' },
  { resource => 'R6',  deps => [ 'R2' ], desc => 'GetAtt also reports deps' },
  { resource => 'R7',  deps => [ 'R1', 'R2', 'R3' ], desc => 'Mix between implicit and explicit' },
  { resource => 'R8',  deps => [ 'R2', 'R3' ], desc => 'Explicit and implicit repeated should not duplicate' },
  { resource => 'R9',  deps => [ 'R2' ], desc => 'Repeated dep only counted once' },
  { resource => 'R10', deps => [ 'R2' ], desc => 'Dep via Ref and GetAtt only counted once' },
  { resource => 'R11', deps => [ 'R2' ], desc => 'Repeated ref in props and array props' },
  { resource => 'R12', deps => [ 'R1' ], desc => 'A non-arrayref DependsOn works' },
];

foreach my $test (@$tests) {
  my @deps;
  @deps = @{ $o->Resource( $test->{ resource} )->dependencies };
  my $desc = $test->{ desc } || '';
  @deps = sort @deps;
  my $num_deps = scalar(@deps);
  is_deeply(\@deps, $test->{deps}, "Got $num_deps deps from $test->{ resource }: $desc") or diag(Dumper(\@deps));
}

done_testing;
