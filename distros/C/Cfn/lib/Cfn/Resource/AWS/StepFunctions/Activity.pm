# AWS::StepFunctions::Activity generated from spec 1.11.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::StepFunctions::Activity',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::StepFunctions::Activity->new( %$_ ) };

package Cfn::Resource::AWS::StepFunctions::Activity {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::StepFunctions::Activity', is => 'rw', coerce => 1);
  sub _build_attributes {
    [ 'Name' ]
  }
}



package Cfn::Resource::Properties::AWS::StepFunctions::Activity {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

1;
