# AWS::Greengrass::ConnectorDefinitionVersion generated from spec 6.3.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::Greengrass::ConnectorDefinitionVersion',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::Greengrass::ConnectorDefinitionVersion->new( %$_ ) };

package Cfn::Resource::AWS::Greengrass::ConnectorDefinitionVersion {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::Greengrass::ConnectorDefinitionVersion', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [  ]
  }
  sub supported_regions {
    [ 'ap-northeast-1','ap-northeast-2','ap-south-1','ap-southeast-1','ap-southeast-2','cn-north-1','eu-central-1','eu-west-1','eu-west-2','us-east-1','us-east-2','us-gov-west-1','us-west-2' ]
  }
}


subtype 'ArrayOfCfn::Resource::Properties::AWS::Greengrass::ConnectorDefinitionVersion::Connector',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::Greengrass::ConnectorDefinitionVersion::Connector',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       die 'Only accepts functions'; 
     }
   },
  from 'ArrayRef',
   via {
     Cfn::Value::Array->new(Value => [
       map { 
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::Greengrass::ConnectorDefinitionVersion::Connector')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::Greengrass::ConnectorDefinitionVersion::Connector',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Greengrass::ConnectorDefinitionVersion::Connector',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::Greengrass::ConnectorDefinitionVersion::ConnectorValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::Greengrass::ConnectorDefinitionVersion::ConnectorValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ConnectorArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Id => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Parameters => (isa => 'Cfn::Value::Json|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

package Cfn::Resource::Properties::AWS::Greengrass::ConnectorDefinitionVersion {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has ConnectorDefinitionId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Connectors => (isa => 'ArrayOfCfn::Resource::Properties::AWS::Greengrass::ConnectorDefinitionVersion::Connector', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

1;
