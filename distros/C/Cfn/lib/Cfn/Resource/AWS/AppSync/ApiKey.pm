# AWS::AppSync::ApiKey generated from spec 2.25.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::AppSync::ApiKey',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::AppSync::ApiKey->new( %$_ ) };

package Cfn::Resource::AWS::AppSync::ApiKey {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::AppSync::ApiKey', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [ 'ApiKey','Arn' ]
  }
  sub supported_regions {
    [ 'ap-northeast-1','ap-southeast-2','eu-west-1','us-east-1','us-east-2','us-west-2' ]
  }
}



package Cfn::Resource::Properties::AWS::AppSync::ApiKey {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has ApiId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Description => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Expires => (isa => 'Cfn::Value::Double', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
