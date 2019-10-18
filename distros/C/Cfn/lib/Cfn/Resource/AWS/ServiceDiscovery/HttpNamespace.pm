# AWS::ServiceDiscovery::HttpNamespace generated from spec 6.3.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::ServiceDiscovery::HttpNamespace',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::ServiceDiscovery::HttpNamespace->new( %$_ ) };

package Cfn::Resource::AWS::ServiceDiscovery::HttpNamespace {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::ServiceDiscovery::HttpNamespace', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [ 'Arn','Id' ]
  }
  sub supported_regions {
    [ 'ap-east-1','ap-northeast-2','ap-south-1','ap-southeast-1','ap-southeast-2','ca-central-1','eu-central-1','eu-north-1','eu-west-1','eu-west-2','me-south-1','us-east-1','us-east-2','us-west-1','us-west-2' ]
  }
}



package Cfn::Resource::Properties::AWS::ServiceDiscovery::HttpNamespace {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has Description => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

1;
