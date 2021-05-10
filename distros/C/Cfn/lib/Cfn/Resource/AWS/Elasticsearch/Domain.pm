# AWS::Elasticsearch::Domain generated from spec 22.0.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::Elasticsearch::Domain',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::Elasticsearch::Domain->new( %$_ ) };

package Cfn::Resource::AWS::Elasticsearch::Domain {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::Elasticsearch::Domain', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [ 'Arn','DomainArn','DomainEndpoint' ]
  }
  sub supported_regions {
    [ 'af-south-1','ap-east-1','ap-northeast-1','ap-northeast-2','ap-northeast-3','ap-south-1','ap-southeast-1','ap-southeast-2','ca-central-1','cn-north-1','cn-northwest-1','eu-central-1','eu-north-1','eu-south-1','eu-west-1','eu-west-2','eu-west-3','me-south-1','sa-east-1','us-east-1','us-east-2','us-gov-east-1','us-gov-west-1','us-west-1','us-west-2' ]
  }
}



subtype 'Cfn::Resource::Properties::AWS::Elasticsearch::Domain::ZoneAwarenessConfig',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Elasticsearch::Domain::ZoneAwarenessConfig',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Elasticsearch::Domain::ZoneAwarenessConfig->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Elasticsearch::Domain::ZoneAwarenessConfig {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AvailabilityZoneCount => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::Elasticsearch::Domain::MasterUserOptions',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Elasticsearch::Domain::MasterUserOptions',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Elasticsearch::Domain::MasterUserOptions->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Elasticsearch::Domain::MasterUserOptions {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has MasterUserARN => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has MasterUserName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has MasterUserPassword => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::Elasticsearch::Domain::VPCOptions',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Elasticsearch::Domain::VPCOptions',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Elasticsearch::Domain::VPCOptions->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Elasticsearch::Domain::VPCOptions {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has SecurityGroupIds => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SubnetIds => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::Elasticsearch::Domain::SnapshotOptions',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Elasticsearch::Domain::SnapshotOptions',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Elasticsearch::Domain::SnapshotOptions->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Elasticsearch::Domain::SnapshotOptions {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AutomatedSnapshotStartHour => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::Elasticsearch::Domain::NodeToNodeEncryptionOptions',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Elasticsearch::Domain::NodeToNodeEncryptionOptions',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Elasticsearch::Domain::NodeToNodeEncryptionOptions->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Elasticsearch::Domain::NodeToNodeEncryptionOptions {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Enabled => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

subtype 'MapOfCfn::Resource::Properties::AWS::Elasticsearch::Domain::LogPublishingOption',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Hash') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'MapOfCfn::Resource::Properties::AWS::Elasticsearch::Domain::LogPublishingOption',
  from 'HashRef',
   via {
     my $arg = $_;
     if (my $f = Cfn::TypeLibrary::try_function($arg)) {
       return $f
     } else {
       Cfn::Value::Hash->new(Value => {
         map { $_ => Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::Elasticsearch::Domain::LogPublishingOption')->coerce($arg->{$_}) } keys %$arg
       });
     }
   };

subtype 'Cfn::Resource::Properties::AWS::Elasticsearch::Domain::LogPublishingOption',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Elasticsearch::Domain::LogPublishingOption',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Elasticsearch::Domain::LogPublishingOption->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Elasticsearch::Domain::LogPublishingOption {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has CloudWatchLogsLogGroupArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Enabled => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::Elasticsearch::Domain::EncryptionAtRestOptions',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Elasticsearch::Domain::EncryptionAtRestOptions',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Elasticsearch::Domain::EncryptionAtRestOptions->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Elasticsearch::Domain::EncryptionAtRestOptions {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Enabled => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has KmsKeyId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

subtype 'Cfn::Resource::Properties::AWS::Elasticsearch::Domain::ElasticsearchClusterConfig',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Elasticsearch::Domain::ElasticsearchClusterConfig',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Elasticsearch::Domain::ElasticsearchClusterConfig->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Elasticsearch::Domain::ElasticsearchClusterConfig {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has DedicatedMasterCount => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DedicatedMasterEnabled => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DedicatedMasterType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has InstanceCount => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has InstanceType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has WarmCount => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has WarmEnabled => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has WarmType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ZoneAwarenessConfig => (isa => 'Cfn::Resource::Properties::AWS::Elasticsearch::Domain::ZoneAwarenessConfig', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ZoneAwarenessEnabled => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::Elasticsearch::Domain::EBSOptions',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Elasticsearch::Domain::EBSOptions',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Elasticsearch::Domain::EBSOptions->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Elasticsearch::Domain::EBSOptions {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has EBSEnabled => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Iops => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has VolumeSize => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has VolumeType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::Elasticsearch::Domain::DomainEndpointOptions',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Elasticsearch::Domain::DomainEndpointOptions',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Elasticsearch::Domain::DomainEndpointOptions->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Elasticsearch::Domain::DomainEndpointOptions {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has CustomEndpoint => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has CustomEndpointCertificateArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has CustomEndpointEnabled => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has EnforceHTTPS => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TLSSecurityPolicy => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::Elasticsearch::Domain::CognitoOptions',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Elasticsearch::Domain::CognitoOptions',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Elasticsearch::Domain::CognitoOptions->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Elasticsearch::Domain::CognitoOptions {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Enabled => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has IdentityPoolId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RoleArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has UserPoolId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::Elasticsearch::Domain::AdvancedSecurityOptionsInput',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Elasticsearch::Domain::AdvancedSecurityOptionsInput',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Elasticsearch::Domain::AdvancedSecurityOptionsInput->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Elasticsearch::Domain::AdvancedSecurityOptionsInput {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Enabled => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has InternalUserDatabaseEnabled => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has MasterUserOptions => (isa => 'Cfn::Resource::Properties::AWS::Elasticsearch::Domain::MasterUserOptions', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::Elasticsearch::Domain {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has AccessPolicies => (isa => 'Cfn::Value::Json|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has AdvancedOptions => (isa => 'Cfn::Value::Hash|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has AdvancedSecurityOptions => (isa => 'Cfn::Resource::Properties::AWS::Elasticsearch::Domain::AdvancedSecurityOptionsInput', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has CognitoOptions => (isa => 'Cfn::Resource::Properties::AWS::Elasticsearch::Domain::CognitoOptions', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DomainEndpointOptions => (isa => 'Cfn::Resource::Properties::AWS::Elasticsearch::Domain::DomainEndpointOptions', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DomainName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has EBSOptions => (isa => 'Cfn::Resource::Properties::AWS::Elasticsearch::Domain::EBSOptions', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ElasticsearchClusterConfig => (isa => 'Cfn::Resource::Properties::AWS::Elasticsearch::Domain::ElasticsearchClusterConfig', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ElasticsearchVersion => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Conditional');
  has EncryptionAtRestOptions => (isa => 'Cfn::Resource::Properties::AWS::Elasticsearch::Domain::EncryptionAtRestOptions', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has LogPublishingOptions => (isa => 'MapOfCfn::Resource::Properties::AWS::Elasticsearch::Domain::LogPublishingOption', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has NodeToNodeEncryptionOptions => (isa => 'Cfn::Resource::Properties::AWS::Elasticsearch::Domain::NodeToNodeEncryptionOptions', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has SnapshotOptions => (isa => 'Cfn::Resource::Properties::AWS::Elasticsearch::Domain::SnapshotOptions', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Tags => (isa => 'ArrayOfCfn::Resource::Properties::TagType', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has VPCOptions => (isa => 'Cfn::Resource::Properties::AWS::Elasticsearch::Domain::VPCOptions', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::Elasticsearch::Domain - Cfn resource for AWS::Elasticsearch::Domain

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::Elasticsearch::Domain.

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
