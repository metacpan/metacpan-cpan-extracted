# AWS::StepFunctions::StateMachine generated from spec 1.11.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::StepFunctions::StateMachine',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::StepFunctions::StateMachine->new( %$_ ) };

package Cfn::Resource::AWS::StepFunctions::StateMachine {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::StepFunctions::StateMachine', is => 'rw', coerce => 1);
  sub _build_attributes {
    [ 'Name' ]
  }
}



package Cfn::Resource::Properties::AWS::StepFunctions::StateMachine {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has DefinitionString => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RoleArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has StateMachineName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

1;
