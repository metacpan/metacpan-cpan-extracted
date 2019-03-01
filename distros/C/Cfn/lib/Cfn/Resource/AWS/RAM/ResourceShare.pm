# AWS::RAM::ResourceShare generated from spec 2.24.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::RAM::ResourceShare',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::RAM::ResourceShare->new( %$_ ) };

package Cfn::Resource::AWS::RAM::ResourceShare {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::RAM::ResourceShare', is => 'rw', coerce => 1);
  sub _build_attributes {
    [ 'Arn' ]
  }
}



package Cfn::Resource::Properties::AWS::RAM::ResourceShare {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has AllowExternalPrincipals => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Principals => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ResourceArns => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Tags => (isa => 'ArrayOfCfn::Resource::Properties::TagType', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
