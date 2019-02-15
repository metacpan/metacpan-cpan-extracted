# AWS::Lambda::Version generated from spec 1.11.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::Lambda::Version',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::Lambda::Version->new( %$_ ) };

package Cfn::Resource::AWS::Lambda::Version {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::Lambda::Version', is => 'rw', coerce => 1);
  sub _build_attributes {
    [ 'Version' ]
  }
}



package Cfn::Resource::Properties::AWS::Lambda::Version {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has CodeSha256 => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Description => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has FunctionName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

1;
