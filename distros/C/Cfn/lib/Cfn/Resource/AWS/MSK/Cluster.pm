# AWS::MSK::Cluster generated from spec 34.0.0
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
    [ 'ap-east-1','ap-northeast-1','ap-northeast-2','ap-south-1','ap-southeast-1','ap-southeast-2','ca-central-1','cn-north-1','cn-northwest-1','eu-central-1','eu-north-1','eu-west-1','eu-west-2','eu-west-3','me-south-1','sa-east-1','us-east-1','us-east-2','us-gov-east-1','us-gov-west-1','us-west-1','us-west-2' ]
  }
}



subtype 'Cfn::Resource::Properties::AWS::MSK::Cluster::Scram',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MSK::Cluster::Scram',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MSK::Cluster::Scram->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MSK::Cluster::Scram {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Enabled => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

subtype 'Cfn::Resource::Properties::AWS::MSK::Cluster::S3',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MSK::Cluster::S3',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MSK::Cluster::S3->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MSK::Cluster::S3 {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Bucket => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Enabled => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Prefix => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MSK::Cluster::NodeExporter',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MSK::Cluster::NodeExporter',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MSK::Cluster::NodeExporter->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MSK::Cluster::NodeExporter {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has EnabledInBroker => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MSK::Cluster::JmxExporter',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MSK::Cluster::JmxExporter',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MSK::Cluster::JmxExporter->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MSK::Cluster::JmxExporter {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has EnabledInBroker => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MSK::Cluster::Firehose',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MSK::Cluster::Firehose',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MSK::Cluster::Firehose->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MSK::Cluster::Firehose {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has DeliveryStream => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Enabled => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MSK::Cluster::EBSStorageInfo',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MSK::Cluster::EBSStorageInfo',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MSK::Cluster::EBSStorageInfo->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MSK::Cluster::EBSStorageInfo {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has VolumeSize => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

subtype 'Cfn::Resource::Properties::AWS::MSK::Cluster::CloudWatchLogs',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MSK::Cluster::CloudWatchLogs',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MSK::Cluster::CloudWatchLogs->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MSK::Cluster::CloudWatchLogs {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Enabled => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has LogGroup => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MSK::Cluster::Tls',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MSK::Cluster::Tls',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MSK::Cluster::Tls->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MSK::Cluster::Tls {
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
       return Cfn::Resource::Properties::Object::AWS::MSK::Cluster::StorageInfo->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MSK::Cluster::StorageInfo {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has EBSStorageInfo => (isa => 'Cfn::Resource::Properties::AWS::MSK::Cluster::EBSStorageInfo', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

subtype 'Cfn::Resource::Properties::AWS::MSK::Cluster::Sasl',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MSK::Cluster::Sasl',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MSK::Cluster::Sasl->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MSK::Cluster::Sasl {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Scram => (isa => 'Cfn::Resource::Properties::AWS::MSK::Cluster::Scram', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

subtype 'Cfn::Resource::Properties::AWS::MSK::Cluster::Prometheus',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MSK::Cluster::Prometheus',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MSK::Cluster::Prometheus->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MSK::Cluster::Prometheus {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has JmxExporter => (isa => 'Cfn::Resource::Properties::AWS::MSK::Cluster::JmxExporter', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has NodeExporter => (isa => 'Cfn::Resource::Properties::AWS::MSK::Cluster::NodeExporter', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MSK::Cluster::EncryptionInTransit',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MSK::Cluster::EncryptionInTransit',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MSK::Cluster::EncryptionInTransit->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MSK::Cluster::EncryptionInTransit {
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
       return Cfn::Resource::Properties::Object::AWS::MSK::Cluster::EncryptionAtRest->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MSK::Cluster::EncryptionAtRest {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has DataVolumeKMSKeyId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

subtype 'Cfn::Resource::Properties::AWS::MSK::Cluster::BrokerLogs',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MSK::Cluster::BrokerLogs',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MSK::Cluster::BrokerLogs->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MSK::Cluster::BrokerLogs {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has CloudWatchLogs => (isa => 'Cfn::Resource::Properties::AWS::MSK::Cluster::CloudWatchLogs', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Firehose => (isa => 'Cfn::Resource::Properties::AWS::MSK::Cluster::Firehose', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has S3 => (isa => 'Cfn::Resource::Properties::AWS::MSK::Cluster::S3', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MSK::Cluster::OpenMonitoring',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MSK::Cluster::OpenMonitoring',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MSK::Cluster::OpenMonitoring->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MSK::Cluster::OpenMonitoring {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Prometheus => (isa => 'Cfn::Resource::Properties::AWS::MSK::Cluster::Prometheus', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MSK::Cluster::LoggingInfo',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MSK::Cluster::LoggingInfo',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MSK::Cluster::LoggingInfo->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MSK::Cluster::LoggingInfo {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has BrokerLogs => (isa => 'Cfn::Resource::Properties::AWS::MSK::Cluster::BrokerLogs', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MSK::Cluster::EncryptionInfo',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MSK::Cluster::EncryptionInfo',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MSK::Cluster::EncryptionInfo->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MSK::Cluster::EncryptionInfo {
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
       return Cfn::Resource::Properties::Object::AWS::MSK::Cluster::ConfigurationInfo->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MSK::Cluster::ConfigurationInfo {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Arn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Revision => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MSK::Cluster::ClientAuthentication',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MSK::Cluster::ClientAuthentication',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MSK::Cluster::ClientAuthentication->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MSK::Cluster::ClientAuthentication {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Sasl => (isa => 'Cfn::Resource::Properties::AWS::MSK::Cluster::Sasl', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
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
       return Cfn::Resource::Properties::Object::AWS::MSK::Cluster::BrokerNodeGroupInfo->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MSK::Cluster::BrokerNodeGroupInfo {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has BrokerAZDistribution => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has ClientSubnets => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has InstanceType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SecurityGroups => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has StorageInfo => (isa => 'Cfn::Resource::Properties::AWS::MSK::Cluster::StorageInfo', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

package Cfn::Resource::Properties::AWS::MSK::Cluster {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has BrokerNodeGroupInfo => (isa => 'Cfn::Resource::Properties::AWS::MSK::Cluster::BrokerNodeGroupInfo', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ClientAuthentication => (isa => 'Cfn::Resource::Properties::AWS::MSK::Cluster::ClientAuthentication', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has ClusterName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has ConfigurationInfo => (isa => 'Cfn::Resource::Properties::AWS::MSK::Cluster::ConfigurationInfo', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has EncryptionInfo => (isa => 'Cfn::Resource::Properties::AWS::MSK::Cluster::EncryptionInfo', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has EnhancedMonitoring => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has KafkaVersion => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has LoggingInfo => (isa => 'Cfn::Resource::Properties::AWS::MSK::Cluster::LoggingInfo', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has NumberOfBrokerNodes => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has OpenMonitoring => (isa => 'Cfn::Resource::Properties::AWS::MSK::Cluster::OpenMonitoring', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Tags => (isa => 'Cfn::Value::Json|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::MSK::Cluster - Cfn resource for AWS::MSK::Cluster

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::MSK::Cluster.

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
