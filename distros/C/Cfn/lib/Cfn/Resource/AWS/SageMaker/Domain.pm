# AWS::SageMaker::Domain generated from spec 34.0.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::SageMaker::Domain',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::SageMaker::Domain->new( %$_ ) };

package Cfn::Resource::AWS::SageMaker::Domain {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::SageMaker::Domain', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [ 'DomainArn','DomainId','HomeEfsFileSystemId','SingleSignOnManagedApplicationInstanceId','Url' ]
  }
  sub supported_regions {
    [ 'af-south-1','ap-east-1','ap-northeast-1','ap-northeast-2','ap-south-1','ap-southeast-1','ap-southeast-2','ca-central-1','cn-north-1','cn-northwest-1','eu-central-1','eu-north-1','eu-south-1','eu-west-1','eu-west-2','eu-west-3','me-south-1','sa-east-1','us-east-1','us-east-2','us-west-1','us-west-2' ]
  }
}



subtype 'Cfn::Resource::Properties::AWS::SageMaker::Domain::ResourceSpec',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::SageMaker::Domain::ResourceSpec',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::SageMaker::Domain::ResourceSpec->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::SageMaker::Domain::ResourceSpec {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has InstanceType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SageMakerImageArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SageMakerImageVersionArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::SageMaker::Domain::CustomImage',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::SageMaker::Domain::CustomImage',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::SageMaker::Domain::CustomImage')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::SageMaker::Domain::CustomImage',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::SageMaker::Domain::CustomImage',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::SageMaker::Domain::CustomImage->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::SageMaker::Domain::CustomImage {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AppImageConfigName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ImageName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ImageVersionNumber => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::SageMaker::Domain::SharingSettings',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::SageMaker::Domain::SharingSettings',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::SageMaker::Domain::SharingSettings->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::SageMaker::Domain::SharingSettings {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has NotebookOutputOption => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has S3KmsKeyId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has S3OutputPath => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::SageMaker::Domain::KernelGatewayAppSettings',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::SageMaker::Domain::KernelGatewayAppSettings',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::SageMaker::Domain::KernelGatewayAppSettings->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::SageMaker::Domain::KernelGatewayAppSettings {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has CustomImages => (isa => 'ArrayOfCfn::Resource::Properties::AWS::SageMaker::Domain::CustomImage', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DefaultResourceSpec => (isa => 'Cfn::Resource::Properties::AWS::SageMaker::Domain::ResourceSpec', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::SageMaker::Domain::JupyterServerAppSettings',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::SageMaker::Domain::JupyterServerAppSettings',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::SageMaker::Domain::JupyterServerAppSettings->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::SageMaker::Domain::JupyterServerAppSettings {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has DefaultResourceSpec => (isa => 'Cfn::Resource::Properties::AWS::SageMaker::Domain::ResourceSpec', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::SageMaker::Domain::UserSettings',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::SageMaker::Domain::UserSettings',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::SageMaker::Domain::UserSettings->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::SageMaker::Domain::UserSettings {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ExecutionRole => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has JupyterServerAppSettings => (isa => 'Cfn::Resource::Properties::AWS::SageMaker::Domain::JupyterServerAppSettings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has KernelGatewayAppSettings => (isa => 'Cfn::Resource::Properties::AWS::SageMaker::Domain::KernelGatewayAppSettings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SecurityGroups => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SharingSettings => (isa => 'Cfn::Resource::Properties::AWS::SageMaker::Domain::SharingSettings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::SageMaker::Domain {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has AppNetworkAccessType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has AuthMode => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has DefaultUserSettings => (isa => 'Cfn::Resource::Properties::AWS::SageMaker::Domain::UserSettings', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DomainName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has KmsKeyId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has SubnetIds => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Tags => (isa => 'ArrayOfCfn::Resource::Properties::TagType', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has VpcId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::SageMaker::Domain - Cfn resource for AWS::SageMaker::Domain

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::SageMaker::Domain.

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
