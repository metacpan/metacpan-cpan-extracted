# AWS::KinesisFirehose::DeliveryStream generated from spec 2.3.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream->new( %$_ ) };

package Cfn::Resource::AWS::KinesisFirehose::DeliveryStream {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream', is => 'rw', coerce => 1);
  sub _build_attributes {
    [ 'Arn' ]
  }
}


subtype 'ArrayOfCfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::ProcessorParameter',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::ProcessorParameter',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       die 'Only accepts functions'; 
     }
   },
  from 'ArrayRef',
   via {
     Cfn::Value::Array->new(Value => [
       map { 
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::ProcessorParameter')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::ProcessorParameter',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::ProcessorParameter',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::ProcessorParameterValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::ProcessorParameterValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ParameterName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ParameterValue => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::KMSEncryptionConfig',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::KMSEncryptionConfig',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::KMSEncryptionConfigValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::KMSEncryptionConfigValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AWSKMSKeyARN => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::Processor',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::Processor',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       die 'Only accepts functions'; 
     }
   },
  from 'ArrayRef',
   via {
     Cfn::Value::Array->new(Value => [
       map { 
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::Processor')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::Processor',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::Processor',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::ProcessorValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::ProcessorValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Parameters => (isa => 'ArrayOfCfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::ProcessorParameter', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Type => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::EncryptionConfiguration',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::EncryptionConfiguration',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::EncryptionConfigurationValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::EncryptionConfigurationValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has KMSEncryptionConfig => (isa => 'Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::KMSEncryptionConfig', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has NoEncryptionConfig => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::CloudWatchLoggingOptions',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::CloudWatchLoggingOptions',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::CloudWatchLoggingOptionsValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::CloudWatchLoggingOptionsValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Enabled => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has LogGroupName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has LogStreamName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::BufferingHints',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::BufferingHints',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::BufferingHintsValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::BufferingHintsValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has IntervalInSeconds => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SizeInMBs => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::SplunkRetryOptions',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::SplunkRetryOptions',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::SplunkRetryOptionsValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::SplunkRetryOptionsValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has DurationInSeconds => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::S3DestinationConfiguration',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::S3DestinationConfiguration',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::S3DestinationConfigurationValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::S3DestinationConfigurationValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has BucketARN => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has BufferingHints => (isa => 'Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::BufferingHints', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has CloudWatchLoggingOptions => (isa => 'Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::CloudWatchLoggingOptions', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has CompressionFormat => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has EncryptionConfiguration => (isa => 'Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::EncryptionConfiguration', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Prefix => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RoleARN => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::ProcessingConfiguration',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::ProcessingConfiguration',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::ProcessingConfigurationValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::ProcessingConfigurationValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Enabled => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Processors => (isa => 'ArrayOfCfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::Processor', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::ElasticsearchRetryOptions',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::ElasticsearchRetryOptions',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::ElasticsearchRetryOptionsValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::ElasticsearchRetryOptionsValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has DurationInSeconds => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::ElasticsearchBufferingHints',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::ElasticsearchBufferingHints',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::ElasticsearchBufferingHintsValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::ElasticsearchBufferingHintsValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has IntervalInSeconds => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SizeInMBs => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::CopyCommand',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::CopyCommand',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::CopyCommandValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::CopyCommandValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has CopyOptions => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DataTableColumns => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DataTableName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::SplunkDestinationConfiguration',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::SplunkDestinationConfiguration',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::SplunkDestinationConfigurationValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::SplunkDestinationConfigurationValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has CloudWatchLoggingOptions => (isa => 'Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::CloudWatchLoggingOptions', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has HECAcknowledgmentTimeoutInSeconds => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has HECEndpoint => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has HECEndpointType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has HECToken => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ProcessingConfiguration => (isa => 'Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::ProcessingConfiguration', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RetryOptions => (isa => 'Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::SplunkRetryOptions', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has S3BackupMode => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has S3Configuration => (isa => 'Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::S3DestinationConfiguration', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::RedshiftDestinationConfiguration',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::RedshiftDestinationConfiguration',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::RedshiftDestinationConfigurationValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::RedshiftDestinationConfigurationValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has CloudWatchLoggingOptions => (isa => 'Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::CloudWatchLoggingOptions', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ClusterJDBCURL => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has CopyCommand => (isa => 'Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::CopyCommand', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Password => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ProcessingConfiguration => (isa => 'Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::ProcessingConfiguration', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RoleARN => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has S3Configuration => (isa => 'Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::S3DestinationConfiguration', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Username => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::KinesisStreamSourceConfiguration',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::KinesisStreamSourceConfiguration',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::KinesisStreamSourceConfigurationValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::KinesisStreamSourceConfigurationValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has KinesisStreamARN => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RoleARN => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::ExtendedS3DestinationConfiguration',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::ExtendedS3DestinationConfiguration',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::ExtendedS3DestinationConfigurationValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::ExtendedS3DestinationConfigurationValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has BucketARN => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has BufferingHints => (isa => 'Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::BufferingHints', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has CloudWatchLoggingOptions => (isa => 'Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::CloudWatchLoggingOptions', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has CompressionFormat => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has EncryptionConfiguration => (isa => 'Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::EncryptionConfiguration', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Prefix => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ProcessingConfiguration => (isa => 'Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::ProcessingConfiguration', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RoleARN => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has S3BackupConfiguration => (isa => 'Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::S3DestinationConfiguration', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has S3BackupMode => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::ElasticsearchDestinationConfiguration',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::ElasticsearchDestinationConfiguration',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::ElasticsearchDestinationConfigurationValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::ElasticsearchDestinationConfigurationValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has BufferingHints => (isa => 'Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::ElasticsearchBufferingHints', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has CloudWatchLoggingOptions => (isa => 'Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::CloudWatchLoggingOptions', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DomainARN => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has IndexName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has IndexRotationPeriod => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ProcessingConfiguration => (isa => 'Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::ProcessingConfiguration', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RetryOptions => (isa => 'Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::ElasticsearchRetryOptions', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RoleARN => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has S3BackupMode => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has S3Configuration => (isa => 'Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::S3DestinationConfiguration', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TypeName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has DeliveryStreamName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has DeliveryStreamType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has ElasticsearchDestinationConfiguration => (isa => 'Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::ElasticsearchDestinationConfiguration', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ExtendedS3DestinationConfiguration => (isa => 'Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::ExtendedS3DestinationConfiguration', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has KinesisStreamSourceConfiguration => (isa => 'Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::KinesisStreamSourceConfiguration', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RedshiftDestinationConfiguration => (isa => 'Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::RedshiftDestinationConfiguration', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has S3DestinationConfiguration => (isa => 'Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::S3DestinationConfiguration', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SplunkDestinationConfiguration => (isa => 'Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::SplunkDestinationConfiguration', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
