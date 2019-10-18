# AWS::Greengrass::ResourceDefinitionVersion generated from spec 6.3.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::Greengrass::ResourceDefinitionVersion',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::Greengrass::ResourceDefinitionVersion->new( %$_ ) };

package Cfn::Resource::AWS::Greengrass::ResourceDefinitionVersion {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::Greengrass::ResourceDefinitionVersion', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [  ]
  }
  sub supported_regions {
    [ 'ap-northeast-1','ap-northeast-2','ap-south-1','ap-southeast-1','ap-southeast-2','cn-north-1','eu-central-1','eu-west-1','eu-west-2','us-east-1','us-east-2','us-gov-west-1','us-west-2' ]
  }
}



subtype 'Cfn::Resource::Properties::AWS::Greengrass::ResourceDefinitionVersion::GroupOwnerSetting',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Greengrass::ResourceDefinitionVersion::GroupOwnerSetting',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::Greengrass::ResourceDefinitionVersion::GroupOwnerSettingValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::Greengrass::ResourceDefinitionVersion::GroupOwnerSettingValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AutoAddGroupOwner => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has GroupOwner => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

subtype 'Cfn::Resource::Properties::AWS::Greengrass::ResourceDefinitionVersion::SecretsManagerSecretResourceData',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Greengrass::ResourceDefinitionVersion::SecretsManagerSecretResourceData',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::Greengrass::ResourceDefinitionVersion::SecretsManagerSecretResourceDataValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::Greengrass::ResourceDefinitionVersion::SecretsManagerSecretResourceDataValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AdditionalStagingLabelsToDownload => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has ARN => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

subtype 'Cfn::Resource::Properties::AWS::Greengrass::ResourceDefinitionVersion::SageMakerMachineLearningModelResourceData',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Greengrass::ResourceDefinitionVersion::SageMakerMachineLearningModelResourceData',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::Greengrass::ResourceDefinitionVersion::SageMakerMachineLearningModelResourceDataValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::Greengrass::ResourceDefinitionVersion::SageMakerMachineLearningModelResourceDataValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has DestinationPath => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has SageMakerJobArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

subtype 'Cfn::Resource::Properties::AWS::Greengrass::ResourceDefinitionVersion::S3MachineLearningModelResourceData',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Greengrass::ResourceDefinitionVersion::S3MachineLearningModelResourceData',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::Greengrass::ResourceDefinitionVersion::S3MachineLearningModelResourceDataValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::Greengrass::ResourceDefinitionVersion::S3MachineLearningModelResourceDataValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has DestinationPath => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has S3Uri => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

subtype 'Cfn::Resource::Properties::AWS::Greengrass::ResourceDefinitionVersion::LocalVolumeResourceData',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Greengrass::ResourceDefinitionVersion::LocalVolumeResourceData',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::Greengrass::ResourceDefinitionVersion::LocalVolumeResourceDataValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::Greengrass::ResourceDefinitionVersion::LocalVolumeResourceDataValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has DestinationPath => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has GroupOwnerSetting => (isa => 'Cfn::Resource::Properties::AWS::Greengrass::ResourceDefinitionVersion::GroupOwnerSetting', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has SourcePath => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

subtype 'Cfn::Resource::Properties::AWS::Greengrass::ResourceDefinitionVersion::LocalDeviceResourceData',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Greengrass::ResourceDefinitionVersion::LocalDeviceResourceData',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::Greengrass::ResourceDefinitionVersion::LocalDeviceResourceDataValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::Greengrass::ResourceDefinitionVersion::LocalDeviceResourceDataValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has GroupOwnerSetting => (isa => 'Cfn::Resource::Properties::AWS::Greengrass::ResourceDefinitionVersion::GroupOwnerSetting', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has SourcePath => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

subtype 'Cfn::Resource::Properties::AWS::Greengrass::ResourceDefinitionVersion::ResourceDataContainer',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Greengrass::ResourceDefinitionVersion::ResourceDataContainer',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::Greengrass::ResourceDefinitionVersion::ResourceDataContainerValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::Greengrass::ResourceDefinitionVersion::ResourceDataContainerValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has LocalDeviceResourceData => (isa => 'Cfn::Resource::Properties::AWS::Greengrass::ResourceDefinitionVersion::LocalDeviceResourceData', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has LocalVolumeResourceData => (isa => 'Cfn::Resource::Properties::AWS::Greengrass::ResourceDefinitionVersion::LocalVolumeResourceData', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has S3MachineLearningModelResourceData => (isa => 'Cfn::Resource::Properties::AWS::Greengrass::ResourceDefinitionVersion::S3MachineLearningModelResourceData', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has SageMakerMachineLearningModelResourceData => (isa => 'Cfn::Resource::Properties::AWS::Greengrass::ResourceDefinitionVersion::SageMakerMachineLearningModelResourceData', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has SecretsManagerSecretResourceData => (isa => 'Cfn::Resource::Properties::AWS::Greengrass::ResourceDefinitionVersion::SecretsManagerSecretResourceData', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::Greengrass::ResourceDefinitionVersion::ResourceInstance',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::Greengrass::ResourceDefinitionVersion::ResourceInstance',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::Greengrass::ResourceDefinitionVersion::ResourceInstance')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::Greengrass::ResourceDefinitionVersion::ResourceInstance',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Greengrass::ResourceDefinitionVersion::ResourceInstance',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::Greengrass::ResourceDefinitionVersion::ResourceInstanceValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::Greengrass::ResourceDefinitionVersion::ResourceInstanceValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Id => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has ResourceDataContainer => (isa => 'Cfn::Resource::Properties::AWS::Greengrass::ResourceDefinitionVersion::ResourceDataContainer', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

package Cfn::Resource::Properties::AWS::Greengrass::ResourceDefinitionVersion {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has ResourceDefinitionId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Resources => (isa => 'ArrayOfCfn::Resource::Properties::AWS::Greengrass::ResourceDefinitionVersion::ResourceInstance', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

1;
