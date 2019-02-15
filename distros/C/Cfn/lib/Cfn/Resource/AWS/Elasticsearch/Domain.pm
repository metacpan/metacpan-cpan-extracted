# AWS::Elasticsearch::Domain generated from spec 2.20.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::Elasticsearch::Domain',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::Elasticsearch::Domain->new( %$_ ) };

package Cfn::Resource::AWS::Elasticsearch::Domain {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::Elasticsearch::Domain', is => 'rw', coerce => 1);
  sub _build_attributes {
    [ 'Arn','DomainArn','DomainEndpoint' ]
  }
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
  
  has SecurityGroupIds => (isa => 'Cfn::Value::Array|Cfn::Value::Function', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SubnetIds => (isa => 'Cfn::Value::Array|Cfn::Value::Function', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
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
  
  has AccessPolicies => (isa => 'Cfn::Value::Json', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has AdvancedOptions => (isa => 'Cfn::Value::Hash', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
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
