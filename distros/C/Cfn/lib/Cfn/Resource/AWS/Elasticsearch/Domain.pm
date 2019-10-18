# AWS::Elasticsearch::Domain generated from spec 6.0.0
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
    [ 'ap-east-1','ap-northeast-1','ap-northeast-2','ap-northeast-3','ap-south-1','ap-southeast-1','ap-southeast-2','ca-central-1','cn-north-1','cn-northwest-1','eu-central-1','eu-north-1','eu-west-1','eu-west-2','eu-west-3','me-south-1','sa-east-1','us-east-1','us-east-2','us-gov-east-1','us-gov-west-1','us-west-1','us-west-2' ]
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
       return Cfn::Resource::Properties::AWS::Elasticsearch::Domain::ZoneAwarenessConfigValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::Elasticsearch::Domain::ZoneAwarenessConfigValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AvailabilityZoneCount => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::Elasticsearch::Domain::VPCOptions',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Elasticsearch::Domain::VPCOptions',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::Elasticsearch::Domain::VPCOptionsValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::Elasticsearch::Domain::VPCOptionsValue {
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
       return Cfn::Resource::Properties::AWS::Elasticsearch::Domain::SnapshotOptionsValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::Elasticsearch::Domain::SnapshotOptionsValue {
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
       return Cfn::Resource::Properties::AWS::Elasticsearch::Domain::NodeToNodeEncryptionOptionsValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::Elasticsearch::Domain::NodeToNodeEncryptionOptionsValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Enabled => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

subtype 'Cfn::Resource::Properties::AWS::Elasticsearch::Domain::EncryptionAtRestOptions',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Elasticsearch::Domain::EncryptionAtRestOptions',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::Elasticsearch::Domain::EncryptionAtRestOptionsValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::Elasticsearch::Domain::EncryptionAtRestOptionsValue {
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
       return Cfn::Resource::Properties::AWS::Elasticsearch::Domain::ElasticsearchClusterConfigValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::Elasticsearch::Domain::ElasticsearchClusterConfigValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has DedicatedMasterCount => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DedicatedMasterEnabled => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DedicatedMasterType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has InstanceCount => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has InstanceType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
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
       return Cfn::Resource::Properties::AWS::Elasticsearch::Domain::EBSOptionsValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::Elasticsearch::Domain::EBSOptionsValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has EBSEnabled => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Iops => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has VolumeSize => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has VolumeType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::Elasticsearch::Domain {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has AccessPolicies => (isa => 'Cfn::Value::Json|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has AdvancedOptions => (isa => 'Cfn::Value::Hash|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DomainName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has EBSOptions => (isa => 'Cfn::Resource::Properties::AWS::Elasticsearch::Domain::EBSOptions', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ElasticsearchClusterConfig => (isa => 'Cfn::Resource::Properties::AWS::Elasticsearch::Domain::ElasticsearchClusterConfig', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ElasticsearchVersion => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has EncryptionAtRestOptions => (isa => 'Cfn::Resource::Properties::AWS::Elasticsearch::Domain::EncryptionAtRestOptions', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has NodeToNodeEncryptionOptions => (isa => 'Cfn::Resource::Properties::AWS::Elasticsearch::Domain::NodeToNodeEncryptionOptions', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has SnapshotOptions => (isa => 'Cfn::Resource::Properties::AWS::Elasticsearch::Domain::SnapshotOptions', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Tags => (isa => 'ArrayOfCfn::Resource::Properties::TagType', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has VPCOptions => (isa => 'Cfn::Resource::Properties::AWS::Elasticsearch::Domain::VPCOptions', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
