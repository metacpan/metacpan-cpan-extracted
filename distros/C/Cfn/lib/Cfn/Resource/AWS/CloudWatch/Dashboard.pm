# AWS::CloudWatch::Dashboard generated from spec 6.0.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::CloudWatch::Dashboard',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::CloudWatch::Dashboard->new( %$_ ) };

package Cfn::Resource::AWS::CloudWatch::Dashboard {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::CloudWatch::Dashboard', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [  ]
  }
  sub supported_regions {
    [ 'ap-east-1','ap-northeast-1','ap-northeast-2','ap-northeast-3','ap-south-1','ap-southeast-1','ap-southeast-2','ca-central-1','cn-north-1','cn-northwest-1','eu-central-1','eu-north-1','eu-west-1','eu-west-2','eu-west-3','me-south-1','sa-east-1','us-east-1','us-east-2','us-gov-east-1','us-gov-west-1','us-west-1','us-west-2' ]
  }
}



package Cfn::Resource::Properties::AWS::CloudWatch::Dashboard {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has DashboardBody => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DashboardName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

1;
