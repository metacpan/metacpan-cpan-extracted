# AWS::CodeDeploy::DeploymentConfig generated from spec 5.3.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::CodeDeploy::DeploymentConfig',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::CodeDeploy::DeploymentConfig->new( %$_ ) };

package Cfn::Resource::AWS::CodeDeploy::DeploymentConfig {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::CodeDeploy::DeploymentConfig', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [  ]
  }
  sub supported_regions {
    [ 'ap-east-1','ap-northeast-1','ap-northeast-2','ap-northeast-3','ap-south-1','ap-southeast-1','ap-southeast-2','ca-central-1','cn-north-1','cn-northwest-1','eu-central-1','eu-north-1','eu-west-1','eu-west-2','eu-west-3','me-south-1','sa-east-1','us-east-1','us-east-2','us-gov-east-1','us-gov-west-1','us-west-1','us-west-2' ]
  }
}



subtype 'Cfn::Resource::Properties::AWS::CodeDeploy::DeploymentConfig::MinimumHealthyHosts',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::CodeDeploy::DeploymentConfig::MinimumHealthyHosts',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::CodeDeploy::DeploymentConfig::MinimumHealthyHostsValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::CodeDeploy::DeploymentConfig::MinimumHealthyHostsValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Type => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Value => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::CodeDeploy::DeploymentConfig {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has DeploymentConfigName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has MinimumHealthyHosts => (isa => 'Cfn::Resource::Properties::AWS::CodeDeploy::DeploymentConfig::MinimumHealthyHosts', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

1;
