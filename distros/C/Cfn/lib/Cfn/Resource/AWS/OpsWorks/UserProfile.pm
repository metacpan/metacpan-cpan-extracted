# AWS::OpsWorks::UserProfile generated from spec 1.11.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::OpsWorks::UserProfile',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::OpsWorks::UserProfile->new( %$_ ) };

package Cfn::Resource::AWS::OpsWorks::UserProfile {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::OpsWorks::UserProfile', is => 'rw', coerce => 1);
  sub _build_attributes {
    [ 'SshUsername' ]
  }
}



package Cfn::Resource::Properties::AWS::OpsWorks::UserProfile {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has AllowSelfManagement => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has IamUserArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has SshPublicKey => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SshUsername => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
