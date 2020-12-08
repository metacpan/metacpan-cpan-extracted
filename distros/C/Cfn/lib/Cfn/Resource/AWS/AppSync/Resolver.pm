# AWS::AppSync::Resolver generated from spec 20.1.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::AppSync::Resolver',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::AppSync::Resolver->new( %$_ ) };

package Cfn::Resource::AWS::AppSync::Resolver {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::AppSync::Resolver', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [ 'FieldName','ResolverArn','TypeName' ]
  }
  sub supported_regions {
    [ 'ap-east-1','ap-northeast-1','ap-northeast-2','ap-south-1','ap-southeast-1','ap-southeast-2','cn-north-1','cn-northwest-1','eu-central-1','eu-west-1','me-south-1','us-east-1','us-east-2','us-west-2' ]
  }
}



subtype 'Cfn::Resource::Properties::AWS::AppSync::Resolver::LambdaConflictHandlerConfig',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppSync::Resolver::LambdaConflictHandlerConfig',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppSync::Resolver::LambdaConflictHandlerConfig->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppSync::Resolver::LambdaConflictHandlerConfig {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has LambdaConflictHandlerArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppSync::Resolver::SyncConfig',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppSync::Resolver::SyncConfig',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppSync::Resolver::SyncConfig->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppSync::Resolver::SyncConfig {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ConflictDetection => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ConflictHandler => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has LambdaConflictHandlerConfig => (isa => 'Cfn::Resource::Properties::AWS::AppSync::Resolver::LambdaConflictHandlerConfig', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppSync::Resolver::PipelineConfig',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppSync::Resolver::PipelineConfig',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppSync::Resolver::PipelineConfig->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppSync::Resolver::PipelineConfig {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Functions => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppSync::Resolver::CachingConfig',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppSync::Resolver::CachingConfig',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppSync::Resolver::CachingConfig->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppSync::Resolver::CachingConfig {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has CachingKeys => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Ttl => (isa => 'Cfn::Value::Double', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::AppSync::Resolver {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has ApiId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has CachingConfig => (isa => 'Cfn::Resource::Properties::AWS::AppSync::Resolver::CachingConfig', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DataSourceName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has FieldName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Kind => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has PipelineConfig => (isa => 'Cfn::Resource::Properties::AWS::AppSync::Resolver::PipelineConfig', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RequestMappingTemplate => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RequestMappingTemplateS3Location => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ResponseMappingTemplate => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ResponseMappingTemplateS3Location => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SyncConfig => (isa => 'Cfn::Resource::Properties::AWS::AppSync::Resolver::SyncConfig', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TypeName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::AppSync::Resolver - Cfn resource for AWS::AppSync::Resolver

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::AppSync::Resolver.

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
