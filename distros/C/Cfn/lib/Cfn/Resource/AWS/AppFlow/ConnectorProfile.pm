# AWS::AppFlow::ConnectorProfile generated from spec 21.0.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::AppFlow::ConnectorProfile',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::AppFlow::ConnectorProfile->new( %$_ ) };

package Cfn::Resource::AWS::AppFlow::ConnectorProfile {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::AppFlow::ConnectorProfile', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [ 'ConnectorProfileArn','CredentialsArn' ]
  }
  sub supported_regions {
    [ 'ap-northeast-1','ap-northeast-2','ap-south-1','ap-southeast-1','ap-southeast-2','ca-central-1','eu-central-1','eu-west-1','eu-west-2','eu-west-3','sa-east-1','us-east-1','us-east-2','us-west-1','us-west-2' ]
  }
}



subtype 'Cfn::Resource::Properties::AWS::AppFlow::ConnectorProfile::ConnectorOAuthRequest',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppFlow::ConnectorProfile::ConnectorOAuthRequest',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppFlow::ConnectorProfile::ConnectorOAuthRequest->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppFlow::ConnectorProfile::ConnectorOAuthRequest {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AuthCode => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RedirectUri => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppFlow::ConnectorProfile::ZendeskConnectorProfileProperties',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppFlow::ConnectorProfile::ZendeskConnectorProfileProperties',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppFlow::ConnectorProfile::ZendeskConnectorProfileProperties->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppFlow::ConnectorProfile::ZendeskConnectorProfileProperties {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has InstanceUrl => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppFlow::ConnectorProfile::ZendeskConnectorProfileCredentials',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppFlow::ConnectorProfile::ZendeskConnectorProfileCredentials',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppFlow::ConnectorProfile::ZendeskConnectorProfileCredentials->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppFlow::ConnectorProfile::ZendeskConnectorProfileCredentials {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AccessToken => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ClientId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ClientSecret => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ConnectorOAuthRequest => (isa => 'Cfn::Resource::Properties::AWS::AppFlow::ConnectorProfile::ConnectorOAuthRequest', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppFlow::ConnectorProfile::VeevaConnectorProfileProperties',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppFlow::ConnectorProfile::VeevaConnectorProfileProperties',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppFlow::ConnectorProfile::VeevaConnectorProfileProperties->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppFlow::ConnectorProfile::VeevaConnectorProfileProperties {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has InstanceUrl => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppFlow::ConnectorProfile::VeevaConnectorProfileCredentials',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppFlow::ConnectorProfile::VeevaConnectorProfileCredentials',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppFlow::ConnectorProfile::VeevaConnectorProfileCredentials->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppFlow::ConnectorProfile::VeevaConnectorProfileCredentials {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Password => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Username => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppFlow::ConnectorProfile::TrendmicroConnectorProfileCredentials',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppFlow::ConnectorProfile::TrendmicroConnectorProfileCredentials',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppFlow::ConnectorProfile::TrendmicroConnectorProfileCredentials->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppFlow::ConnectorProfile::TrendmicroConnectorProfileCredentials {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ApiSecretKey => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppFlow::ConnectorProfile::SnowflakeConnectorProfileProperties',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppFlow::ConnectorProfile::SnowflakeConnectorProfileProperties',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppFlow::ConnectorProfile::SnowflakeConnectorProfileProperties->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppFlow::ConnectorProfile::SnowflakeConnectorProfileProperties {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AccountName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has BucketName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has BucketPrefix => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has PrivateLinkServiceName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Region => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Stage => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Warehouse => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppFlow::ConnectorProfile::SnowflakeConnectorProfileCredentials',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppFlow::ConnectorProfile::SnowflakeConnectorProfileCredentials',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppFlow::ConnectorProfile::SnowflakeConnectorProfileCredentials->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppFlow::ConnectorProfile::SnowflakeConnectorProfileCredentials {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Password => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Username => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppFlow::ConnectorProfile::SlackConnectorProfileProperties',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppFlow::ConnectorProfile::SlackConnectorProfileProperties',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppFlow::ConnectorProfile::SlackConnectorProfileProperties->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppFlow::ConnectorProfile::SlackConnectorProfileProperties {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has InstanceUrl => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppFlow::ConnectorProfile::SlackConnectorProfileCredentials',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppFlow::ConnectorProfile::SlackConnectorProfileCredentials',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppFlow::ConnectorProfile::SlackConnectorProfileCredentials->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppFlow::ConnectorProfile::SlackConnectorProfileCredentials {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AccessToken => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ClientId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ClientSecret => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ConnectorOAuthRequest => (isa => 'Cfn::Resource::Properties::AWS::AppFlow::ConnectorProfile::ConnectorOAuthRequest', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppFlow::ConnectorProfile::SingularConnectorProfileCredentials',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppFlow::ConnectorProfile::SingularConnectorProfileCredentials',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppFlow::ConnectorProfile::SingularConnectorProfileCredentials->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppFlow::ConnectorProfile::SingularConnectorProfileCredentials {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ApiKey => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppFlow::ConnectorProfile::ServiceNowConnectorProfileProperties',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppFlow::ConnectorProfile::ServiceNowConnectorProfileProperties',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppFlow::ConnectorProfile::ServiceNowConnectorProfileProperties->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppFlow::ConnectorProfile::ServiceNowConnectorProfileProperties {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has InstanceUrl => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppFlow::ConnectorProfile::ServiceNowConnectorProfileCredentials',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppFlow::ConnectorProfile::ServiceNowConnectorProfileCredentials',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppFlow::ConnectorProfile::ServiceNowConnectorProfileCredentials->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppFlow::ConnectorProfile::ServiceNowConnectorProfileCredentials {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Password => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Username => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppFlow::ConnectorProfile::SalesforceConnectorProfileProperties',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppFlow::ConnectorProfile::SalesforceConnectorProfileProperties',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppFlow::ConnectorProfile::SalesforceConnectorProfileProperties->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppFlow::ConnectorProfile::SalesforceConnectorProfileProperties {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has InstanceUrl => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has isSandboxEnvironment => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppFlow::ConnectorProfile::SalesforceConnectorProfileCredentials',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppFlow::ConnectorProfile::SalesforceConnectorProfileCredentials',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppFlow::ConnectorProfile::SalesforceConnectorProfileCredentials->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppFlow::ConnectorProfile::SalesforceConnectorProfileCredentials {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AccessToken => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ClientCredentialsArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ConnectorOAuthRequest => (isa => 'Cfn::Resource::Properties::AWS::AppFlow::ConnectorProfile::ConnectorOAuthRequest', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RefreshToken => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppFlow::ConnectorProfile::RedshiftConnectorProfileProperties',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppFlow::ConnectorProfile::RedshiftConnectorProfileProperties',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppFlow::ConnectorProfile::RedshiftConnectorProfileProperties->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppFlow::ConnectorProfile::RedshiftConnectorProfileProperties {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has BucketName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has BucketPrefix => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DatabaseUrl => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RoleArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppFlow::ConnectorProfile::RedshiftConnectorProfileCredentials',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppFlow::ConnectorProfile::RedshiftConnectorProfileCredentials',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppFlow::ConnectorProfile::RedshiftConnectorProfileCredentials->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppFlow::ConnectorProfile::RedshiftConnectorProfileCredentials {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Password => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Username => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppFlow::ConnectorProfile::MarketoConnectorProfileProperties',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppFlow::ConnectorProfile::MarketoConnectorProfileProperties',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppFlow::ConnectorProfile::MarketoConnectorProfileProperties->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppFlow::ConnectorProfile::MarketoConnectorProfileProperties {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has InstanceUrl => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppFlow::ConnectorProfile::MarketoConnectorProfileCredentials',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppFlow::ConnectorProfile::MarketoConnectorProfileCredentials',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppFlow::ConnectorProfile::MarketoConnectorProfileCredentials->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppFlow::ConnectorProfile::MarketoConnectorProfileCredentials {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AccessToken => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ClientId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ClientSecret => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ConnectorOAuthRequest => (isa => 'Cfn::Resource::Properties::AWS::AppFlow::ConnectorProfile::ConnectorOAuthRequest', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppFlow::ConnectorProfile::InforNexusConnectorProfileProperties',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppFlow::ConnectorProfile::InforNexusConnectorProfileProperties',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppFlow::ConnectorProfile::InforNexusConnectorProfileProperties->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppFlow::ConnectorProfile::InforNexusConnectorProfileProperties {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has InstanceUrl => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppFlow::ConnectorProfile::InforNexusConnectorProfileCredentials',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppFlow::ConnectorProfile::InforNexusConnectorProfileCredentials',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppFlow::ConnectorProfile::InforNexusConnectorProfileCredentials->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppFlow::ConnectorProfile::InforNexusConnectorProfileCredentials {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AccessKeyId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Datakey => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SecretAccessKey => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has UserId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppFlow::ConnectorProfile::GoogleAnalyticsConnectorProfileCredentials',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppFlow::ConnectorProfile::GoogleAnalyticsConnectorProfileCredentials',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppFlow::ConnectorProfile::GoogleAnalyticsConnectorProfileCredentials->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppFlow::ConnectorProfile::GoogleAnalyticsConnectorProfileCredentials {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AccessToken => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ClientId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ClientSecret => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ConnectorOAuthRequest => (isa => 'Cfn::Resource::Properties::AWS::AppFlow::ConnectorProfile::ConnectorOAuthRequest', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RefreshToken => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppFlow::ConnectorProfile::DynatraceConnectorProfileProperties',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppFlow::ConnectorProfile::DynatraceConnectorProfileProperties',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppFlow::ConnectorProfile::DynatraceConnectorProfileProperties->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppFlow::ConnectorProfile::DynatraceConnectorProfileProperties {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has InstanceUrl => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppFlow::ConnectorProfile::DynatraceConnectorProfileCredentials',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppFlow::ConnectorProfile::DynatraceConnectorProfileCredentials',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppFlow::ConnectorProfile::DynatraceConnectorProfileCredentials->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppFlow::ConnectorProfile::DynatraceConnectorProfileCredentials {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ApiToken => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppFlow::ConnectorProfile::DatadogConnectorProfileProperties',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppFlow::ConnectorProfile::DatadogConnectorProfileProperties',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppFlow::ConnectorProfile::DatadogConnectorProfileProperties->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppFlow::ConnectorProfile::DatadogConnectorProfileProperties {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has InstanceUrl => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppFlow::ConnectorProfile::DatadogConnectorProfileCredentials',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppFlow::ConnectorProfile::DatadogConnectorProfileCredentials',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppFlow::ConnectorProfile::DatadogConnectorProfileCredentials->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppFlow::ConnectorProfile::DatadogConnectorProfileCredentials {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ApiKey => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ApplicationKey => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppFlow::ConnectorProfile::AmplitudeConnectorProfileCredentials',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppFlow::ConnectorProfile::AmplitudeConnectorProfileCredentials',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppFlow::ConnectorProfile::AmplitudeConnectorProfileCredentials->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppFlow::ConnectorProfile::AmplitudeConnectorProfileCredentials {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ApiKey => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SecretKey => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppFlow::ConnectorProfile::ConnectorProfileProperties',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppFlow::ConnectorProfile::ConnectorProfileProperties',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppFlow::ConnectorProfile::ConnectorProfileProperties->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppFlow::ConnectorProfile::ConnectorProfileProperties {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Datadog => (isa => 'Cfn::Resource::Properties::AWS::AppFlow::ConnectorProfile::DatadogConnectorProfileProperties', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Dynatrace => (isa => 'Cfn::Resource::Properties::AWS::AppFlow::ConnectorProfile::DynatraceConnectorProfileProperties', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has InforNexus => (isa => 'Cfn::Resource::Properties::AWS::AppFlow::ConnectorProfile::InforNexusConnectorProfileProperties', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Marketo => (isa => 'Cfn::Resource::Properties::AWS::AppFlow::ConnectorProfile::MarketoConnectorProfileProperties', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Redshift => (isa => 'Cfn::Resource::Properties::AWS::AppFlow::ConnectorProfile::RedshiftConnectorProfileProperties', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Salesforce => (isa => 'Cfn::Resource::Properties::AWS::AppFlow::ConnectorProfile::SalesforceConnectorProfileProperties', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ServiceNow => (isa => 'Cfn::Resource::Properties::AWS::AppFlow::ConnectorProfile::ServiceNowConnectorProfileProperties', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Slack => (isa => 'Cfn::Resource::Properties::AWS::AppFlow::ConnectorProfile::SlackConnectorProfileProperties', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Snowflake => (isa => 'Cfn::Resource::Properties::AWS::AppFlow::ConnectorProfile::SnowflakeConnectorProfileProperties', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Veeva => (isa => 'Cfn::Resource::Properties::AWS::AppFlow::ConnectorProfile::VeevaConnectorProfileProperties', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Zendesk => (isa => 'Cfn::Resource::Properties::AWS::AppFlow::ConnectorProfile::ZendeskConnectorProfileProperties', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppFlow::ConnectorProfile::ConnectorProfileCredentials',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppFlow::ConnectorProfile::ConnectorProfileCredentials',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppFlow::ConnectorProfile::ConnectorProfileCredentials->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppFlow::ConnectorProfile::ConnectorProfileCredentials {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Amplitude => (isa => 'Cfn::Resource::Properties::AWS::AppFlow::ConnectorProfile::AmplitudeConnectorProfileCredentials', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Datadog => (isa => 'Cfn::Resource::Properties::AWS::AppFlow::ConnectorProfile::DatadogConnectorProfileCredentials', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Dynatrace => (isa => 'Cfn::Resource::Properties::AWS::AppFlow::ConnectorProfile::DynatraceConnectorProfileCredentials', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has GoogleAnalytics => (isa => 'Cfn::Resource::Properties::AWS::AppFlow::ConnectorProfile::GoogleAnalyticsConnectorProfileCredentials', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has InforNexus => (isa => 'Cfn::Resource::Properties::AWS::AppFlow::ConnectorProfile::InforNexusConnectorProfileCredentials', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Marketo => (isa => 'Cfn::Resource::Properties::AWS::AppFlow::ConnectorProfile::MarketoConnectorProfileCredentials', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Redshift => (isa => 'Cfn::Resource::Properties::AWS::AppFlow::ConnectorProfile::RedshiftConnectorProfileCredentials', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Salesforce => (isa => 'Cfn::Resource::Properties::AWS::AppFlow::ConnectorProfile::SalesforceConnectorProfileCredentials', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ServiceNow => (isa => 'Cfn::Resource::Properties::AWS::AppFlow::ConnectorProfile::ServiceNowConnectorProfileCredentials', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Singular => (isa => 'Cfn::Resource::Properties::AWS::AppFlow::ConnectorProfile::SingularConnectorProfileCredentials', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Slack => (isa => 'Cfn::Resource::Properties::AWS::AppFlow::ConnectorProfile::SlackConnectorProfileCredentials', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Snowflake => (isa => 'Cfn::Resource::Properties::AWS::AppFlow::ConnectorProfile::SnowflakeConnectorProfileCredentials', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Trendmicro => (isa => 'Cfn::Resource::Properties::AWS::AppFlow::ConnectorProfile::TrendmicroConnectorProfileCredentials', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Veeva => (isa => 'Cfn::Resource::Properties::AWS::AppFlow::ConnectorProfile::VeevaConnectorProfileCredentials', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Zendesk => (isa => 'Cfn::Resource::Properties::AWS::AppFlow::ConnectorProfile::ZendeskConnectorProfileCredentials', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppFlow::ConnectorProfile::ConnectorProfileConfig',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppFlow::ConnectorProfile::ConnectorProfileConfig',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppFlow::ConnectorProfile::ConnectorProfileConfig->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppFlow::ConnectorProfile::ConnectorProfileConfig {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ConnectorProfileCredentials => (isa => 'Cfn::Resource::Properties::AWS::AppFlow::ConnectorProfile::ConnectorProfileCredentials', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ConnectorProfileProperties => (isa => 'Cfn::Resource::Properties::AWS::AppFlow::ConnectorProfile::ConnectorProfileProperties', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::AppFlow::ConnectorProfile {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has ConnectionMode => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ConnectorProfileConfig => (isa => 'Cfn::Resource::Properties::AWS::AppFlow::ConnectorProfile::ConnectorProfileConfig', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ConnectorProfileName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has ConnectorType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has KMSArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::AppFlow::ConnectorProfile - Cfn resource for AWS::AppFlow::ConnectorProfile

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::AppFlow::ConnectorProfile.

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
