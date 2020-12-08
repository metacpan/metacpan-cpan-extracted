# AWS::AppSync::DataSource generated from spec 20.1.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::AppSync::DataSource',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::AppSync::DataSource->new( %$_ ) };

package Cfn::Resource::AWS::AppSync::DataSource {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::AppSync::DataSource', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [ 'DataSourceArn','Name' ]
  }
  sub supported_regions {
    [ 'ap-east-1','ap-northeast-1','ap-northeast-2','ap-south-1','ap-southeast-1','ap-southeast-2','cn-north-1','cn-northwest-1','eu-central-1','eu-west-1','me-south-1','us-east-1','us-east-2','us-west-2' ]
  }
}



subtype 'Cfn::Resource::Properties::AWS::AppSync::DataSource::AwsIamConfig',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppSync::DataSource::AwsIamConfig',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppSync::DataSource::AwsIamConfig->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppSync::DataSource::AwsIamConfig {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has SigningRegion => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SigningServiceName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppSync::DataSource::RdsHttpEndpointConfig',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppSync::DataSource::RdsHttpEndpointConfig',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppSync::DataSource::RdsHttpEndpointConfig->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppSync::DataSource::RdsHttpEndpointConfig {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AwsRegion => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has AwsSecretStoreArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DatabaseName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DbClusterIdentifier => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Schema => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppSync::DataSource::DeltaSyncConfig',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppSync::DataSource::DeltaSyncConfig',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppSync::DataSource::DeltaSyncConfig->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppSync::DataSource::DeltaSyncConfig {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has BaseTableTTL => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DeltaSyncTableName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DeltaSyncTableTTL => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppSync::DataSource::AuthorizationConfig',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppSync::DataSource::AuthorizationConfig',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppSync::DataSource::AuthorizationConfig->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppSync::DataSource::AuthorizationConfig {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AuthorizationType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has AwsIamConfig => (isa => 'Cfn::Resource::Properties::AWS::AppSync::DataSource::AwsIamConfig', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppSync::DataSource::RelationalDatabaseConfig',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppSync::DataSource::RelationalDatabaseConfig',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppSync::DataSource::RelationalDatabaseConfig->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppSync::DataSource::RelationalDatabaseConfig {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has RdsHttpEndpointConfig => (isa => 'Cfn::Resource::Properties::AWS::AppSync::DataSource::RdsHttpEndpointConfig', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RelationalDatabaseSourceType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppSync::DataSource::LambdaConfig',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppSync::DataSource::LambdaConfig',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppSync::DataSource::LambdaConfig->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppSync::DataSource::LambdaConfig {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has LambdaFunctionArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppSync::DataSource::HttpConfig',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppSync::DataSource::HttpConfig',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppSync::DataSource::HttpConfig->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppSync::DataSource::HttpConfig {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AuthorizationConfig => (isa => 'Cfn::Resource::Properties::AWS::AppSync::DataSource::AuthorizationConfig', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Endpoint => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppSync::DataSource::ElasticsearchConfig',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppSync::DataSource::ElasticsearchConfig',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppSync::DataSource::ElasticsearchConfig->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppSync::DataSource::ElasticsearchConfig {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AwsRegion => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Endpoint => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppSync::DataSource::DynamoDBConfig',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppSync::DataSource::DynamoDBConfig',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppSync::DataSource::DynamoDBConfig->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppSync::DataSource::DynamoDBConfig {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AwsRegion => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DeltaSyncConfig => (isa => 'Cfn::Resource::Properties::AWS::AppSync::DataSource::DeltaSyncConfig', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TableName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has UseCallerCredentials => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Versioned => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::AppSync::DataSource {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has ApiId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Description => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DynamoDBConfig => (isa => 'Cfn::Resource::Properties::AWS::AppSync::DataSource::DynamoDBConfig', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ElasticsearchConfig => (isa => 'Cfn::Resource::Properties::AWS::AppSync::DataSource::ElasticsearchConfig', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has HttpConfig => (isa => 'Cfn::Resource::Properties::AWS::AppSync::DataSource::HttpConfig', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has LambdaConfig => (isa => 'Cfn::Resource::Properties::AWS::AppSync::DataSource::LambdaConfig', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has RelationalDatabaseConfig => (isa => 'Cfn::Resource::Properties::AWS::AppSync::DataSource::RelationalDatabaseConfig', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ServiceRoleArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Type => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::AppSync::DataSource - Cfn resource for AWS::AppSync::DataSource

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::AppSync::DataSource.

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
