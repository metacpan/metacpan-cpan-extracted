# AWS::EC2::VPCEndpointService generated from spec 6.3.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::EC2::VPCEndpointService',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::EC2::VPCEndpointService->new( %$_ ) };

package Cfn::Resource::AWS::EC2::VPCEndpointService {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::EC2::VPCEndpointService', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [  ]
  }
  sub supported_regions {
    [ 'ap-east-1','ap-northeast-3','cn-north-1','cn-northwest-1','eu-north-1','us-east-1' ]
  }
}



package Cfn::Resource::Properties::AWS::EC2::VPCEndpointService {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has AcceptanceRequired => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has NetworkLoadBalancerArns => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
