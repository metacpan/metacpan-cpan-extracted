# AWS::AppSync::FunctionConfiguration generated from spec 20.1.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::AppSync::FunctionConfiguration',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::AppSync::FunctionConfiguration->new( %$_ ) };

package Cfn::Resource::AWS::AppSync::FunctionConfiguration {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::AppSync::FunctionConfiguration', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [ 'DataSourceName','FunctionArn','FunctionId','Name' ]
  }
  sub supported_regions {
    [ 'ap-east-1','ap-northeast-1','ap-northeast-2','ap-south-1','ap-southeast-1','ap-southeast-2','cn-north-1','cn-northwest-1','eu-central-1','eu-west-1','me-south-1','us-east-1','us-east-2','us-west-2' ]
  }
}



subtype 'Cfn::Resource::Properties::AWS::AppSync::FunctionConfiguration::LambdaConflictHandlerConfig',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppSync::FunctionConfiguration::LambdaConflictHandlerConfig',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppSync::FunctionConfiguration::LambdaConflictHandlerConfig->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppSync::FunctionConfiguration::LambdaConflictHandlerConfig {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has LambdaConflictHandlerArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppSync::FunctionConfiguration::SyncConfig',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppSync::FunctionConfiguration::SyncConfig',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppSync::FunctionConfiguration::SyncConfig->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppSync::FunctionConfiguration::SyncConfig {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ConflictDetection => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ConflictHandler => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has LambdaConflictHandlerConfig => (isa => 'Cfn::Resource::Properties::AWS::AppSync::FunctionConfiguration::LambdaConflictHandlerConfig', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::AppSync::FunctionConfiguration {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has ApiId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has DataSourceName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Description => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has FunctionVersion => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RequestMappingTemplate => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RequestMappingTemplateS3Location => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ResponseMappingTemplate => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ResponseMappingTemplateS3Location => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SyncConfig => (isa => 'Cfn::Resource::Properties::AWS::AppSync::FunctionConfiguration::SyncConfig', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::AppSync::FunctionConfiguration - Cfn resource for AWS::AppSync::FunctionConfiguration

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::AppSync::FunctionConfiguration.

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
