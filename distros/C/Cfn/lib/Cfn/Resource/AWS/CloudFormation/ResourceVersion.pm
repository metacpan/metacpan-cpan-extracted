# AWS::CloudFormation::ResourceVersion generated from spec 34.0.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::CloudFormation::ResourceVersion',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::CloudFormation::ResourceVersion->new( %$_ ) };

package Cfn::Resource::AWS::CloudFormation::ResourceVersion {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::CloudFormation::ResourceVersion', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [ 'Arn','IsDefaultVersion','ProvisioningType','TypeArn','VersionId','Visibility' ]
  }
  sub supported_regions {
    [ 'af-south-1','ap-east-1','ap-northeast-1','ap-northeast-2','ap-northeast-3','ap-south-1','ap-southeast-1','ap-southeast-2','ca-central-1','cn-north-1','cn-northwest-1','eu-central-1','eu-north-1','eu-south-1','eu-west-1','eu-west-2','eu-west-3','me-south-1','sa-east-1','us-east-1','us-east-2','us-west-1','us-west-2' ]
  }
}



subtype 'Cfn::Resource::Properties::AWS::CloudFormation::ResourceVersion::LoggingConfig',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::CloudFormation::ResourceVersion::LoggingConfig',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::CloudFormation::ResourceVersion::LoggingConfig->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::CloudFormation::ResourceVersion::LoggingConfig {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has LogGroupName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has LogRoleArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

package Cfn::Resource::Properties::AWS::CloudFormation::ResourceVersion {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has ExecutionRoleArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has LoggingConfig => (isa => 'Cfn::Resource::Properties::AWS::CloudFormation::ResourceVersion::LoggingConfig', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has SchemaHandlerPackage => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has TypeName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::CloudFormation::ResourceVersion - Cfn resource for AWS::CloudFormation::ResourceVersion

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::CloudFormation::ResourceVersion.

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
