# AWS::KinesisFirehose::DeliveryStream generated from spec 3.4.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream->new( %$_ ) };

package Cfn::Resource::AWS::KinesisFirehose::DeliveryStream {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [ 'Arn' ]
  }
  sub supported_regions {
    [ 'ap-northeast-1','ap-northeast-2','ap-northeast-3','ap-south-1','ap-southeast-1','ap-southeast-2','ca-central-1','eu-central-1','eu-north-1','eu-west-1','eu-west-2','eu-west-3','sa-east-1','us-east-1','us-east-2','us-west-1','us-west-2' ]
  }
}



subtype 'Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::ParquetSerDe',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::ParquetSerDe',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::ParquetSerDeValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::ParquetSerDeValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has BlockSizeBytes => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Compression => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has EnableDictionaryCompression => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has MaxPaddingBytes => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has PageSizeBytes => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has WriterVersion => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::OrcSerDe',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::OrcSerDe',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::OrcSerDeValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::OrcSerDeValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has BlockSizeBytes => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has BloomFilterColumns => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has BloomFilterFalsePositiveProbability => (isa => 'Cfn::Value::Double', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Compression => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DictionaryKeyThreshold => (isa => 'Cfn::Value::Double', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has EnablePadding => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has FormatVersion => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has PaddingTolerance => (isa => 'Cfn::Value::Double', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RowIndexStride => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has StripeSizeBytes => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::OpenXJsonSerDe',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::OpenXJsonSerDe',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::OpenXJsonSerDeValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::OpenXJsonSerDeValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has CaseInsensitive => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ColumnToJsonKeyMappings => (isa => 'Cfn::Value::Hash|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ConvertDotsInJsonKeysToUnderscores => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::HiveJsonSerDe',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::HiveJsonSerDe',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::HiveJsonSerDeValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::HiveJsonSerDeValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has TimestampFormats => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::Serializer',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::Serializer',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::SerializerValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::SerializerValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has OrcSerDe => (isa => 'Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::OrcSerDe', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ParquetSerDe => (isa => 'Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::ParquetSerDe', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
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

subtype 'Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::Deserializer',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::Deserializer',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::DeserializerValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::DeserializerValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has HiveJsonSerDe => (isa => 'Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::HiveJsonSerDe', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has OpenXJsonSerDe => (isa => 'Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::OpenXJsonSerDe', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::SchemaConfiguration',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::SchemaConfiguration',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::SchemaConfigurationValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::SchemaConfigurationValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has CatalogId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DatabaseName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Region => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RoleARN => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TableName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has VersionId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
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

subtype 'Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::OutputFormatConfiguration',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::OutputFormatConfiguration',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::OutputFormatConfigurationValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::OutputFormatConfigurationValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Serializer => (isa => 'Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::Serializer', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::InputFormatConfiguration',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::InputFormatConfiguration',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::InputFormatConfigurationValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::InputFormatConfigurationValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Deserializer => (isa => 'Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::Deserializer', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
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
  has ErrorOutputPrefix => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
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

subtype 'Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::DataFormatConversionConfiguration',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::DataFormatConversionConfiguration',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::DataFormatConversionConfigurationValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::DataFormatConversionConfigurationValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Enabled => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has InputFormatConfiguration => (isa => 'Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::InputFormatConfiguration', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has OutputFormatConfiguration => (isa => 'Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::OutputFormatConfiguration', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SchemaConfiguration => (isa => 'Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::SchemaConfiguration', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
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
  has DataFormatConversionConfiguration => (isa => 'Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::DataFormatConversionConfiguration', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has EncryptionConfiguration => (isa => 'Cfn::Resource::Properties::AWS::KinesisFirehose::DeliveryStream::EncryptionConfiguration', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ErrorOutputPrefix => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Prefix => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
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
