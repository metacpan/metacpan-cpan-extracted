# AWS::Greengrass::DeviceDefinition generated from spec 6.3.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::Greengrass::DeviceDefinition',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::Greengrass::DeviceDefinition->new( %$_ ) };

package Cfn::Resource::AWS::Greengrass::DeviceDefinition {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::Greengrass::DeviceDefinition', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [ 'Arn','Id','LatestVersionArn','Name' ]
  }
  sub supported_regions {
    [ 'ap-northeast-1','ap-northeast-2','ap-south-1','ap-southeast-1','ap-southeast-2','cn-north-1','eu-central-1','eu-west-1','eu-west-2','us-east-1','us-east-2','us-gov-west-1','us-west-2' ]
  }
}


subtype 'ArrayOfCfn::Resource::Properties::AWS::Greengrass::DeviceDefinition::Device',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::Greengrass::DeviceDefinition::Device',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::Greengrass::DeviceDefinition::Device')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::Greengrass::DeviceDefinition::Device',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Greengrass::DeviceDefinition::Device',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::Greengrass::DeviceDefinition::DeviceValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::Greengrass::DeviceDefinition::DeviceValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has CertificateArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Id => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has SyncShadow => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has ThingArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

subtype 'Cfn::Resource::Properties::AWS::Greengrass::DeviceDefinition::DeviceDefinitionVersion',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Greengrass::DeviceDefinition::DeviceDefinitionVersion',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::Greengrass::DeviceDefinition::DeviceDefinitionVersionValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::Greengrass::DeviceDefinition::DeviceDefinitionVersionValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Devices => (isa => 'ArrayOfCfn::Resource::Properties::AWS::Greengrass::DeviceDefinition::Device', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

package Cfn::Resource::Properties::AWS::Greengrass::DeviceDefinition {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has InitialVersion => (isa => 'Cfn::Resource::Properties::AWS::Greengrass::DeviceDefinition::DeviceDefinitionVersion', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Tags => (isa => 'Cfn::Value::Json|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
