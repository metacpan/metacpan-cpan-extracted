# AWS::IAM::AccessKey generated from spec 1.11.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::IAM::AccessKey',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::IAM::AccessKey->new( %$_ ) };

package Cfn::Resource::AWS::IAM::AccessKey {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::IAM::AccessKey', is => 'rw', coerce => 1);
  sub _build_attributes {
    [ 'SecretAccessKey' ]
  }
}



package Cfn::Resource::Properties::AWS::IAM::AccessKey {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has Serial => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Status => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has UserName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

1;
