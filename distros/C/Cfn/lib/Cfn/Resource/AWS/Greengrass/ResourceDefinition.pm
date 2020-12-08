# AWS::Greengrass::ResourceDefinition generated from spec 18.4.0
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



subtype 'Cfn::Resource::Properties::AWS::Greengrass::ResourceDefinition::ResourceDownloadOwnerSetting',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Greengrass::ResourceDefinition::ResourceDownloadOwnerSetting',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Greengrass::ResourceDefinition::ResourceDownloadOwnerSetting->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Greengrass::ResourceDefinition::ResourceDownloadOwnerSetting {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has GroupOwner => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has GroupPermission => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

subtype 'Cfn::Resource::Properties::AWS::Greengrass::ResourceDefinition::GroupOwnerSetting',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Greengrass::ResourceDefinition::GroupOwnerSetting',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Greengrass::ResourceDefinition::GroupOwnerSetting->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Greengrass::ResourceDefinition::GroupOwnerSetting {
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
       return Cfn::Resource::Properties::Object::AWS::Greengrass::ResourceDefinition::SecretsManagerSecretResourceData->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Greengrass::ResourceDefinition::SecretsManagerSecretResourceData {
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
       return Cfn::Resource::Properties::Object::AWS::Greengrass::ResourceDefinition::SageMakerMachineLearningModelResourceData->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Greengrass::ResourceDefinition::SageMakerMachineLearningModelResourceData {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has DestinationPath => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has OwnerSetting => (isa => 'Cfn::Resource::Properties::AWS::Greengrass::ResourceDefinition::ResourceDownloadOwnerSetting', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
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
       return Cfn::Resource::Properties::Object::AWS::Greengrass::ResourceDefinition::S3MachineLearningModelResourceData->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Greengrass::ResourceDefinition::S3MachineLearningModelResourceData {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has DestinationPath => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has OwnerSetting => (isa => 'Cfn::Resource::Properties::AWS::Greengrass::ResourceDefinition::ResourceDownloadOwnerSetting', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
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
       return Cfn::Resource::Properties::Object::AWS::Greengrass::ResourceDefinition::LocalVolumeResourceData->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Greengrass::ResourceDefinition::LocalVolumeResourceData {
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
       return Cfn::Resource::Properties::Object::AWS::Greengrass::ResourceDefinition::LocalDeviceResourceData->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Greengrass::ResourceDefinition::LocalDeviceResourceData {
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
       return Cfn::Resource::Properties::Object::AWS::Greengrass::ResourceDefinition::ResourceDataContainer->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Greengrass::ResourceDefinition::ResourceDataContainer {
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
       return Cfn::Resource::Properties::Object::AWS::Greengrass::ResourceDefinition::ResourceInstance->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Greengrass::ResourceDefinition::ResourceInstance {
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
       return Cfn::Resource::Properties::Object::AWS::Greengrass::ResourceDefinition::ResourceDefinitionVersion->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Greengrass::ResourceDefinition::ResourceDefinitionVersion {
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
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::Greengrass::ResourceDefinition - Cfn resource for AWS::Greengrass::ResourceDefinition

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::Greengrass::ResourceDefinition.

See L<Cfn> for more information on how to use it.

=head1 AUTHOR

    Jose Luis Martinez
    CAPSiDE
    jlmartinez@capside.com

=head1 COPYRIGHT and LICENSE

Copyright (c) 2013 by CAPSiDE
This code is distributed under the Apache 2 License. The full text of the 
license can be found in the LICENSE file included with this module.

=cut
