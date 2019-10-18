# AWS::Greengrass::ResourceDefinition generated from spec 6.3.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::Greengrass::ResourceDefinition',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::Greengrass::ResourceDefinition->new( %$_ ) };

package Cfn::Resource::AWS::Greengrass::ResourceDefinition {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::Greengrass::ResourceDefinition', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [ 'Arn','Id','LatestVersionArn','Name' ]
  }
  sub supported_regions {
    [ 'ap-northeast-1','ap-northeast-2','ap-south-1','ap-southeast-1','ap-southeast-2','cn-north-1','eu-central-1','eu-west-1','eu-west-2','us-east-1','us-east-2','us-gov-west-1','us-west-2' ]
  }
}



subtype 'Cfn::Resource::Properties::AWS::Greengrass::ResourceDefinition::GroupOwnerSetting',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Greengrass::ResourceDefinition::GroupOwnerSetting',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::Greengrass::ResourceDefinition::GroupOwnerSettingValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::Greengrass::ResourceDefinition::GroupOwnerSettingValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AutoAddGroupOwner => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has GroupOwner => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

subtype 'Cfn::Resource::Properties::AWS::Greengrass::ResourceDefinition::SecretsManagerSecretResourceData',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Greengrass::ResourceDefinition::SecretsManagerSecretResourceData',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::Greengrass::ResourceDefinition::SecretsManagerSecretResourceDataValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::Greengrass::ResourceDefinition::SecretsManagerSecretResourceDataValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AdditionalStagingLabelsToDownload => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has ARN => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

subtype 'Cfn::Resource::Properties::AWS::Greengrass::ResourceDefinition::SageMakerMachineLearningModelResourceData',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Greengrass::ResourceDefinition::SageMakerMachineLearningModelResourceData',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::Greengrass::ResourceDefinition::SageMakerMachineLearningModelResourceDataValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::Greengrass::ResourceDefinition::SageMakerMachineLearningModelResourceDataValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has DestinationPath => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has SageMakerJobArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

subtype 'Cfn::Resource::Properties::AWS::Greengrass::ResourceDefinition::S3MachineLearningModelResourceData',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Greengrass::ResourceDefinition::S3MachineLearningModelResourceData',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::Greengrass::ResourceDefinition::S3MachineLearningModelResourceDataValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::Greengrass::ResourceDefinition::S3MachineLearningModelResourceDataValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has DestinationPath => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has S3Uri => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

subtype 'Cfn::Resource::Properties::AWS::Greengrass::ResourceDefinition::LocalVolumeResourceData',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Greengrass::ResourceDefinition::LocalVolumeResourceData',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::Greengrass::ResourceDefinition::LocalVolumeResourceDataValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::Greengrass::ResourceDefinition::LocalVolumeResourceDataValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has DestinationPath => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has GroupOwnerSetting => (isa => 'Cfn::Resource::Properties::AWS::Greengrass::ResourceDefinition::GroupOwnerSetting', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has SourcePath => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

subtype 'Cfn::Resource::Properties::AWS::Greengrass::ResourceDefinition::LocalDeviceResourceData',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Greengrass::ResourceDefinition::LocalDeviceResourceData',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::Greengrass::ResourceDefinition::LocalDeviceResourceDataValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::Greengrass::ResourceDefinition::LocalDeviceResourceDataValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has GroupOwnerSetting => (isa => 'Cfn::Resource::Properties::AWS::Greengrass::ResourceDefinition::GroupOwnerSetting', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has SourcePath => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

subtype 'Cfn::Resource::Properties::AWS::Greengrass::ResourceDefinition::ResourceDataContainer',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Greengrass::ResourceDefinition::ResourceDataContainer',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::Greengrass::ResourceDefinition::ResourceDataContainerValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::Greengrass::ResourceDefinition::ResourceDataContainerValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has LocalDeviceResourceData => (isa => 'Cfn::Resource::Properties::AWS::Greengrass::ResourceDefinition::LocalDeviceResourceData', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has LocalVolumeResourceData => (isa => 'Cfn::Resource::Properties::AWS::Greengrass::ResourceDefinition::LocalVolumeResourceData', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has S3MachineLearningModelResourceData => (isa => 'Cfn::Resource::Properties::AWS::Greengrass::ResourceDefinition::S3MachineLearningModelResourceData', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has SageMakerMachineLearningModelResourceData => (isa => 'Cfn::Resource::Properties::AWS::Greengrass::ResourceDefinition::SageMakerMachineLearningModelResourceData', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has SecretsManagerSecretResourceData => (isa => 'Cfn::Resource::Properties::AWS::Greengrass::ResourceDefinition::SecretsManagerSecretResourceData', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::Greengrass::ResourceDefinition::ResourceInstance',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::Greengrass::ResourceDefinition::ResourceInstance',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::Greengrass::ResourceDefinition::ResourceInstance')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::Greengrass::ResourceDefinition::ResourceInstance',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Greengrass::ResourceDefinition::ResourceInstance',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::Greengrass::ResourceDefinition::ResourceInstanceValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::Greengrass::ResourceDefinition::ResourceInstanceValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Id => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has ResourceDataContainer => (isa => 'Cfn::Resource::Properties::AWS::Greengrass::ResourceDefinition::ResourceDataContainer', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

subtype 'Cfn::Resource::Properties::AWS::Greengrass::ResourceDefinition::ResourceDefinitionVersion',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Greengrass::ResourceDefinition::ResourceDefinitionVersion',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::Greengrass::ResourceDefinition::ResourceDefinitionVersionValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::Greengrass::ResourceDefinition::ResourceDefinitionVersionValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Resources => (isa => 'ArrayOfCfn::Resource::Properties::AWS::Greengrass::ResourceDefinition::ResourceInstance', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

package Cfn::Resource::Properties::AWS::Greengrass::ResourceDefinition {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has InitialVersion => (isa => 'Cfn::Resource::Properties::AWS::Greengrass::ResourceDefinition::ResourceDefinitionVersion', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Tags => (isa => 'Cfn::Value::Json|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
