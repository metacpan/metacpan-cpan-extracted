# AWS::ImageBuilder::ContainerRecipe generated from spec 34.0.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::ImageBuilder::ContainerRecipe',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::ImageBuilder::ContainerRecipe->new( %$_ ) };

package Cfn::Resource::AWS::ImageBuilder::ContainerRecipe {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::ImageBuilder::ContainerRecipe', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [ 'Arn','Name' ]
  }
  sub supported_regions {
    [ 'af-south-1','ap-east-1','ap-northeast-1','ap-northeast-2','ap-northeast-3','ap-south-1','ap-southeast-1','ap-southeast-2','ca-central-1','cn-north-1','cn-northwest-1','eu-central-1','eu-north-1','eu-south-1','eu-west-1','eu-west-2','eu-west-3','me-south-1','sa-east-1','us-east-1','us-east-2','us-gov-east-1','us-gov-west-1','us-west-1','us-west-2' ]
  }
}



subtype 'Cfn::Resource::Properties::AWS::ImageBuilder::ContainerRecipe::EbsInstanceBlockDeviceSpecification',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::ImageBuilder::ContainerRecipe::EbsInstanceBlockDeviceSpecification',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::ImageBuilder::ContainerRecipe::EbsInstanceBlockDeviceSpecification->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::ImageBuilder::ContainerRecipe::EbsInstanceBlockDeviceSpecification {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has DeleteOnTermination => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Encrypted => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Iops => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has KmsKeyId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has SnapshotId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has VolumeSize => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has VolumeType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::ImageBuilder::ContainerRecipe::InstanceBlockDeviceMapping',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::ImageBuilder::ContainerRecipe::InstanceBlockDeviceMapping',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::ImageBuilder::ContainerRecipe::InstanceBlockDeviceMapping')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::ImageBuilder::ContainerRecipe::InstanceBlockDeviceMapping',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::ImageBuilder::ContainerRecipe::InstanceBlockDeviceMapping',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::ImageBuilder::ContainerRecipe::InstanceBlockDeviceMapping->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::ImageBuilder::ContainerRecipe::InstanceBlockDeviceMapping {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has DeviceName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Ebs => (isa => 'Cfn::Resource::Properties::AWS::ImageBuilder::ContainerRecipe::EbsInstanceBlockDeviceSpecification', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has NoDevice => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has VirtualName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

subtype 'Cfn::Resource::Properties::AWS::ImageBuilder::ContainerRecipe::TargetContainerRepository',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::ImageBuilder::ContainerRecipe::TargetContainerRepository',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::ImageBuilder::ContainerRecipe::TargetContainerRepository->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::ImageBuilder::ContainerRecipe::TargetContainerRepository {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has RepositoryName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Service => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

subtype 'Cfn::Resource::Properties::AWS::ImageBuilder::ContainerRecipe::InstanceConfiguration',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::ImageBuilder::ContainerRecipe::InstanceConfiguration',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::ImageBuilder::ContainerRecipe::InstanceConfiguration->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::ImageBuilder::ContainerRecipe::InstanceConfiguration {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has BlockDeviceMappings => (isa => 'ArrayOfCfn::Resource::Properties::AWS::ImageBuilder::ContainerRecipe::InstanceBlockDeviceMapping', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Image => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::ImageBuilder::ContainerRecipe::ComponentConfiguration',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::ImageBuilder::ContainerRecipe::ComponentConfiguration',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::ImageBuilder::ContainerRecipe::ComponentConfiguration')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::ImageBuilder::ContainerRecipe::ComponentConfiguration',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::ImageBuilder::ContainerRecipe::ComponentConfiguration',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::ImageBuilder::ContainerRecipe::ComponentConfiguration->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::ImageBuilder::ContainerRecipe::ComponentConfiguration {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ComponentArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

package Cfn::Resource::Properties::AWS::ImageBuilder::ContainerRecipe {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has Components => (isa => 'ArrayOfCfn::Resource::Properties::AWS::ImageBuilder::ContainerRecipe::ComponentConfiguration', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has ContainerType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Description => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has DockerfileTemplateData => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DockerfileTemplateUri => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ImageOsVersionOverride => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has InstanceConfiguration => (isa => 'Cfn::Value::Json|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has KmsKeyId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has ParentImage => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has PlatformOverride => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Tags => (isa => 'Cfn::Value::Hash|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has TargetRepository => (isa => 'Cfn::Resource::Properties::AWS::ImageBuilder::ContainerRecipe::TargetContainerRepository', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Version => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has WorkingDirectory => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::ImageBuilder::ContainerRecipe - Cfn resource for AWS::ImageBuilder::ContainerRecipe

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::ImageBuilder::ContainerRecipe.

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
