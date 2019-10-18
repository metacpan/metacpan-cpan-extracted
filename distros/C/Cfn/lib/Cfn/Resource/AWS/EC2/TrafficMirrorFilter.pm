# AWS::EC2::TrafficMirrorFilter generated from spec 6.3.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::EC2::TrafficMirrorFilter',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::EC2::TrafficMirrorFilter->new( %$_ ) };

package Cfn::Resource::AWS::EC2::TrafficMirrorFilter {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::EC2::TrafficMirrorFilter', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [  ]
  }
  sub supported_regions {
    [ 'ap-northeast-1','ap-northeast-2','ap-south-1','ap-southeast-1','ca-central-1','eu-central-1','eu-north-1','eu-west-1','eu-west-2','eu-west-3','sa-east-1','us-east-1','us-east-2','us-gov-east-1','us-gov-west-1','us-west-1','us-west-2' ]
  }
}



package Cfn::Resource::Properties::AWS::EC2::TrafficMirrorFilter {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has Description => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has NetworkServices => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Tags => (isa => 'ArrayOfCfn::Resource::Properties::TagType', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

1;
