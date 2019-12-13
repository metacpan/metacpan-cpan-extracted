# AWS::AppSync::Resolver generated from spec 9.1.0
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
    [ 'ap-northeast-1','ap-northeast-2','ap-south-1','ap-southeast-1','ap-southeast-2','eu-central-1','eu-west-1','us-east-1','us-east-2','us-west-2' ]
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
       return Cfn::Resource::Properties::AWS::AppSync::Resolver::LambdaConflictHandlerConfigValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::AppSync::Resolver::LambdaConflictHandlerConfigValue {
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
       return Cfn::Resource::Properties::AWS::AppSync::Resolver::SyncConfigValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::AppSync::Resolver::SyncConfigValue {
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
       return Cfn::Resource::Properties::AWS::AppSync::Resolver::PipelineConfigValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::AppSync::Resolver::PipelineConfigValue {
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
       return Cfn::Resource::Properties::AWS::AppSync::Resolver::CachingConfigValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::AppSync::Resolver::CachingConfigValue {
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
