# AWS::Greengrass::Group generated from spec 6.3.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::Greengrass::Group',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::Greengrass::Group->new( %$_ ) };

package Cfn::Resource::AWS::Greengrass::Group {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::Greengrass::Group', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [ 'Arn','Id','LatestVersionArn','Name','RoleArn','RoleAttachedAt' ]
  }
  sub supported_regions {
    [ 'ap-northeast-1','ap-northeast-2','ap-south-1','ap-southeast-1','ap-southeast-2','cn-north-1','eu-central-1','eu-west-1','eu-west-2','us-east-1','us-east-2','us-gov-west-1','us-west-2' ]
  }
}



subtype 'Cfn::Resource::Properties::AWS::Greengrass::Group::GroupVersion',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Greengrass::Group::GroupVersion',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::Greengrass::Group::GroupVersionValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::Greengrass::Group::GroupVersionValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ConnectorDefinitionVersionArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has CoreDefinitionVersionArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has DeviceDefinitionVersionArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has FunctionDefinitionVersionArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has LoggerDefinitionVersionArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has ResourceDefinitionVersionArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has SubscriptionDefinitionVersionArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

package Cfn::Resource::Properties::AWS::Greengrass::Group {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has InitialVersion => (isa => 'Cfn::Resource::Properties::AWS::Greengrass::Group::GroupVersion', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RoleArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Tags => (isa => 'Cfn::Value::Json|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
