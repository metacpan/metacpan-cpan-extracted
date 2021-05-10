# AWS::SageMaker::UserProfile generated from spec 34.0.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::SageMaker::UserProfile',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::SageMaker::UserProfile->new( %$_ ) };

package Cfn::Resource::AWS::SageMaker::UserProfile {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::SageMaker::UserProfile', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [ 'UserProfileArn' ]
  }
  sub supported_regions {
    [ 'af-south-1','ap-east-1','ap-northeast-1','ap-northeast-2','ap-south-1','ap-southeast-1','ap-southeast-2','ca-central-1','cn-north-1','cn-northwest-1','eu-central-1','eu-north-1','eu-south-1','eu-west-1','eu-west-2','eu-west-3','me-south-1','sa-east-1','us-east-1','us-east-2','us-west-1','us-west-2' ]
  }
}



subtype 'Cfn::Resource::Properties::AWS::SageMaker::UserProfile::ResourceSpec',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::SageMaker::UserProfile::ResourceSpec',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::SageMaker::UserProfile::ResourceSpec->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::SageMaker::UserProfile::ResourceSpec {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has InstanceType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SageMakerImageArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SageMakerImageVersionArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::SageMaker::UserProfile::CustomImage',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::SageMaker::UserProfile::CustomImage',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::SageMaker::UserProfile::CustomImage')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::SageMaker::UserProfile::CustomImage',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::SageMaker::UserProfile::CustomImage',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::SageMaker::UserProfile::CustomImage->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::SageMaker::UserProfile::CustomImage {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AppImageConfigName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ImageName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ImageVersionNumber => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::SageMaker::UserProfile::SharingSettings',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::SageMaker::UserProfile::SharingSettings',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::SageMaker::UserProfile::SharingSettings->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::SageMaker::UserProfile::SharingSettings {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has NotebookOutputOption => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has S3KmsKeyId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has S3OutputPath => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::SageMaker::UserProfile::KernelGatewayAppSettings',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::SageMaker::UserProfile::KernelGatewayAppSettings',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::SageMaker::UserProfile::KernelGatewayAppSettings->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::SageMaker::UserProfile::KernelGatewayAppSettings {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has CustomImages => (isa => 'ArrayOfCfn::Resource::Properties::AWS::SageMaker::UserProfile::CustomImage', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DefaultResourceSpec => (isa => 'Cfn::Resource::Properties::AWS::SageMaker::UserProfile::ResourceSpec', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::SageMaker::UserProfile::JupyterServerAppSettings',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::SageMaker::UserProfile::JupyterServerAppSettings',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::SageMaker::UserProfile::JupyterServerAppSettings->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::SageMaker::UserProfile::JupyterServerAppSettings {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has DefaultResourceSpec => (isa => 'Cfn::Resource::Properties::AWS::SageMaker::UserProfile::ResourceSpec', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::SageMaker::UserProfile::UserSettings',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::SageMaker::UserProfile::UserSettings',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::SageMaker::UserProfile::UserSettings->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::SageMaker::UserProfile::UserSettings {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ExecutionRole => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has JupyterServerAppSettings => (isa => 'Cfn::Resource::Properties::AWS::SageMaker::UserProfile::JupyterServerAppSettings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has KernelGatewayAppSettings => (isa => 'Cfn::Resource::Properties::AWS::SageMaker::UserProfile::KernelGatewayAppSettings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SecurityGroups => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SharingSettings => (isa => 'Cfn::Resource::Properties::AWS::SageMaker::UserProfile::SharingSettings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::SageMaker::UserProfile {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has DomainId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has SingleSignOnUserIdentifier => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has SingleSignOnUserValue => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Tags => (isa => 'ArrayOfCfn::Resource::Properties::TagType', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has UserProfileName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has UserSettings => (isa => 'Cfn::Resource::Properties::AWS::SageMaker::UserProfile::UserSettings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::SageMaker::UserProfile - Cfn resource for AWS::SageMaker::UserProfile

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::SageMaker::UserProfile.

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
