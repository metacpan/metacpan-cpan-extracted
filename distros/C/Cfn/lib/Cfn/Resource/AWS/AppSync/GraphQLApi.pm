# AWS::AppSync::GraphQLApi generated from spec 4.1.0
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
    [ 'ap-northeast-1','ap-southeast-2','eu-central-1','eu-west-1','us-east-1','us-east-2','us-west-2' ]
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
       return Cfn::Resource::Properties::AWS::AppSync::GraphQLApi::OpenIDConnectConfigValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::AppSync::GraphQLApi::OpenIDConnectConfigValue {
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
       return Cfn::Resource::Properties::AWS::AppSync::GraphQLApi::CognitoUserPoolConfigValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::AppSync::GraphQLApi::CognitoUserPoolConfigValue {
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
       return Cfn::Resource::Properties::AWS::AppSync::GraphQLApi::UserPoolConfigValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::AppSync::GraphQLApi::UserPoolConfigValue {
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
       return Cfn::Resource::Properties::AWS::AppSync::GraphQLApi::TagsValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::AppSync::GraphQLApi::TagsValue {
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
       return Cfn::Resource::Properties::AWS::AppSync::GraphQLApi::LogConfigValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::AppSync::GraphQLApi::LogConfigValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has CloudWatchLogsRoleArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
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
       return Cfn::Resource::Properties::AWS::AppSync::GraphQLApi::AdditionalAuthenticationProvidersValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::AppSync::GraphQLApi::AdditionalAuthenticationProvidersValue {
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
       return Cfn::Resource::Properties::AWS::AppSync::GraphQLApi::AdditionalAuthenticationProviderValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::AppSync::GraphQLApi::AdditionalAuthenticationProviderValue {
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
}

1;
