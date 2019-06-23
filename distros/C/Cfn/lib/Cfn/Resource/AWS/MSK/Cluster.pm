# AWS::MSK::Cluster generated from spec 3.4.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::MSK::Cluster',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::MSK::Cluster->new( %$_ ) };

package Cfn::Resource::AWS::MSK::Cluster {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::MSK::Cluster', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [  ]
  }
  sub supported_regions {
    [ 'ap-northeast-1','ap-southeast-1','ap-southeast-2','eu-central-1','eu-west-1','eu-west-2','eu-west-3','us-east-1','us-east-2','us-west-2' ]
  }
}



subtype 'Cfn::Resource::Properties::AWS::MSK::Cluster::EBSStorageInfo',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MSK::Cluster::EBSStorageInfo',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::MSK::Cluster::EBSStorageInfoValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::MSK::Cluster::EBSStorageInfoValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has VolumeSize => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

subtype 'Cfn::Resource::Properties::AWS::MSK::Cluster::Tls',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MSK::Cluster::Tls',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::MSK::Cluster::TlsValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::MSK::Cluster::TlsValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has CertificateAuthorityArnList => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

subtype 'Cfn::Resource::Properties::AWS::MSK::Cluster::StorageInfo',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MSK::Cluster::StorageInfo',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::MSK::Cluster::StorageInfoValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::MSK::Cluster::StorageInfoValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has EBSStorageInfo => (isa => 'Cfn::Resource::Properties::AWS::MSK::Cluster::EBSStorageInfo', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

subtype 'Cfn::Resource::Properties::AWS::MSK::Cluster::EncryptionInTransit',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MSK::Cluster::EncryptionInTransit',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::MSK::Cluster::EncryptionInTransitValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::MSK::Cluster::EncryptionInTransitValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ClientBroker => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has InCluster => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

subtype 'Cfn::Resource::Properties::AWS::MSK::Cluster::EncryptionAtRest',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MSK::Cluster::EncryptionAtRest',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::MSK::Cluster::EncryptionAtRestValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::MSK::Cluster::EncryptionAtRestValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has DataVolumeKMSKeyId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

subtype 'Cfn::Resource::Properties::AWS::MSK::Cluster::EncryptionInfo',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MSK::Cluster::EncryptionInfo',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::MSK::Cluster::EncryptionInfoValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::MSK::Cluster::EncryptionInfoValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has EncryptionAtRest => (isa => 'Cfn::Resource::Properties::AWS::MSK::Cluster::EncryptionAtRest', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has EncryptionInTransit => (isa => 'Cfn::Resource::Properties::AWS::MSK::Cluster::EncryptionInTransit', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

subtype 'Cfn::Resource::Properties::AWS::MSK::Cluster::ConfigurationInfo',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MSK::Cluster::ConfigurationInfo',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::MSK::Cluster::ConfigurationInfoValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::MSK::Cluster::ConfigurationInfoValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Arn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Revision => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

subtype 'Cfn::Resource::Properties::AWS::MSK::Cluster::ClientAuthentication',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MSK::Cluster::ClientAuthentication',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::MSK::Cluster::ClientAuthenticationValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::MSK::Cluster::ClientAuthenticationValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Tls => (isa => 'Cfn::Resource::Properties::AWS::MSK::Cluster::Tls', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

subtype 'Cfn::Resource::Properties::AWS::MSK::Cluster::BrokerNodeGroupInfo',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MSK::Cluster::BrokerNodeGroupInfo',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::MSK::Cluster::BrokerNodeGroupInfoValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::MSK::Cluster::BrokerNodeGroupInfoValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has BrokerAZDistribution => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has ClientSubnets => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has InstanceType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has SecurityGroups => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has StorageInfo => (isa => 'Cfn::Resource::Properties::AWS::MSK::Cluster::StorageInfo', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

package Cfn::Resource::Properties::AWS::MSK::Cluster {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has BrokerNodeGroupInfo => (isa => 'Cfn::Resource::Properties::AWS::MSK::Cluster::BrokerNodeGroupInfo', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has ClientAuthentication => (isa => 'Cfn::Resource::Properties::AWS::MSK::Cluster::ClientAuthentication', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has ClusterName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has ConfigurationInfo => (isa => 'Cfn::Resource::Properties::AWS::MSK::Cluster::ConfigurationInfo', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has EncryptionInfo => (isa => 'Cfn::Resource::Properties::AWS::MSK::Cluster::EncryptionInfo', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has EnhancedMonitoring => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has KafkaVersion => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has NumberOfBrokerNodes => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Tags => (isa => 'Cfn::Value::Json|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

1;
