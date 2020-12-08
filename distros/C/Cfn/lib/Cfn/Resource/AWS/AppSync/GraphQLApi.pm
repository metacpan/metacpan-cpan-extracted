# AWS::AppSync::GraphQLApi generated from spec 20.1.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::AppSync::GraphQLApi',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::AppSync::GraphQLApi->new( %$_ ) };

package Cfn::Resource::AWS::AppSync::GraphQLApi {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::AppSync::GraphQLApi', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [ 'ApiId','Arn','GraphQLUrl' ]
  }
  sub supported_regions {
    [ 'ap-east-1','ap-northeast-1','ap-northeast-2','ap-south-1','ap-southeast-1','ap-southeast-2','cn-north-1','cn-northwest-1','eu-central-1','eu-west-1','eu-west-2','me-south-1','us-east-1','us-east-2','us-west-2' ]
  }
}



subtype 'Cfn::Resource::Properties::AWS::AppSync::GraphQLApi::OpenIDConnectConfig',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppSync::GraphQLApi::OpenIDConnectConfig',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppSync::GraphQLApi::OpenIDConnectConfig->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppSync::GraphQLApi::OpenIDConnectConfig {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AuthTTL => (isa => 'Cfn::Value::Double', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ClientId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has IatTTL => (isa => 'Cfn::Value::Double', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Issuer => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppSync::GraphQLApi::CognitoUserPoolConfig',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppSync::GraphQLApi::CognitoUserPoolConfig',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppSync::GraphQLApi::CognitoUserPoolConfig->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppSync::GraphQLApi::CognitoUserPoolConfig {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AppIdClientRegex => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has AwsRegion => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has UserPoolId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppSync::GraphQLApi::UserPoolConfig',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppSync::GraphQLApi::UserPoolConfig',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppSync::GraphQLApi::UserPoolConfig->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppSync::GraphQLApi::UserPoolConfig {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AppIdClientRegex => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has AwsRegion => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DefaultAction => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has UserPoolId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppSync::GraphQLApi::Tags',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppSync::GraphQLApi::Tags',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppSync::GraphQLApi::Tags->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppSync::GraphQLApi::Tags {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
}

subtype 'Cfn::Resource::Properties::AWS::AppSync::GraphQLApi::LogConfig',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppSync::GraphQLApi::LogConfig',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppSync::GraphQLApi::LogConfig->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppSync::GraphQLApi::LogConfig {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has CloudWatchLogsRoleArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ExcludeVerboseContent => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has FieldLogLevel => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppSync::GraphQLApi::AdditionalAuthenticationProviders',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppSync::GraphQLApi::AdditionalAuthenticationProviders',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppSync::GraphQLApi::AdditionalAuthenticationProviders->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppSync::GraphQLApi::AdditionalAuthenticationProviders {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
}

subtype 'Cfn::Resource::Properties::AWS::AppSync::GraphQLApi::AdditionalAuthenticationProvider',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppSync::GraphQLApi::AdditionalAuthenticationProvider',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppSync::GraphQLApi::AdditionalAuthenticationProvider->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppSync::GraphQLApi::AdditionalAuthenticationProvider {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AuthenticationType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has OpenIDConnectConfig => (isa => 'Cfn::Resource::Properties::AWS::AppSync::GraphQLApi::OpenIDConnectConfig', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has UserPoolConfig => (isa => 'Cfn::Resource::Properties::AWS::AppSync::GraphQLApi::CognitoUserPoolConfig', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::AppSync::GraphQLApi {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has AdditionalAuthenticationProviders => (isa => 'Cfn::Resource::Properties::AWS::AppSync::GraphQLApi::AdditionalAuthenticationProviders', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has AuthenticationType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has LogConfig => (isa => 'Cfn::Resource::Properties::AWS::AppSync::GraphQLApi::LogConfig', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has OpenIDConnectConfig => (isa => 'Cfn::Resource::Properties::AWS::AppSync::GraphQLApi::OpenIDConnectConfig', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Tags => (isa => 'Cfn::Resource::Properties::AWS::AppSync::GraphQLApi::Tags', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has UserPoolConfig => (isa => 'Cfn::Resource::Properties::AWS::AppSync::GraphQLApi::UserPoolConfig', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has XrayEnabled => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::AppSync::GraphQLApi - Cfn resource for AWS::AppSync::GraphQLApi

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::AppSync::GraphQLApi.

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
