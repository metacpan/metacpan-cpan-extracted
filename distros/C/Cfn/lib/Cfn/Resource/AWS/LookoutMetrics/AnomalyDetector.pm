# AWS::LookoutMetrics::AnomalyDetector generated from spec 34.0.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::LookoutMetrics::AnomalyDetector',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::LookoutMetrics::AnomalyDetector->new( %$_ ) };

package Cfn::Resource::AWS::LookoutMetrics::AnomalyDetector {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::LookoutMetrics::AnomalyDetector', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [ 'Arn' ]
  }
  sub supported_regions {
    [ 'ap-northeast-1','ap-southeast-1','ap-southeast-2','eu-central-1','eu-north-1','eu-west-1','us-east-1','us-east-2','us-west-2' ]
  }
}



subtype 'Cfn::Resource::Properties::AWS::LookoutMetrics::AnomalyDetector::SubnetIdList',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::LookoutMetrics::AnomalyDetector::SubnetIdList',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::LookoutMetrics::AnomalyDetector::SubnetIdList->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::LookoutMetrics::AnomalyDetector::SubnetIdList {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has SubnetIdList => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::LookoutMetrics::AnomalyDetector::SecurityGroupIdList',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::LookoutMetrics::AnomalyDetector::SecurityGroupIdList',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::LookoutMetrics::AnomalyDetector::SecurityGroupIdList->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::LookoutMetrics::AnomalyDetector::SecurityGroupIdList {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has SecurityGroupIdList => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::LookoutMetrics::AnomalyDetector::JsonFormatDescriptor',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::LookoutMetrics::AnomalyDetector::JsonFormatDescriptor',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::LookoutMetrics::AnomalyDetector::JsonFormatDescriptor->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::LookoutMetrics::AnomalyDetector::JsonFormatDescriptor {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Charset => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has FileCompression => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::LookoutMetrics::AnomalyDetector::CsvFormatDescriptor',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::LookoutMetrics::AnomalyDetector::CsvFormatDescriptor',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::LookoutMetrics::AnomalyDetector::CsvFormatDescriptor->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::LookoutMetrics::AnomalyDetector::CsvFormatDescriptor {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Charset => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ContainsHeader => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Delimiter => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has FileCompression => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has HeaderList => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has QuoteSymbol => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::LookoutMetrics::AnomalyDetector::VpcConfiguration',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::LookoutMetrics::AnomalyDetector::VpcConfiguration',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::LookoutMetrics::AnomalyDetector::VpcConfiguration->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::LookoutMetrics::AnomalyDetector::VpcConfiguration {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has SecurityGroupIdList => (isa => 'Cfn::Resource::Properties::AWS::LookoutMetrics::AnomalyDetector::SecurityGroupIdList', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SubnetIdList => (isa => 'Cfn::Resource::Properties::AWS::LookoutMetrics::AnomalyDetector::SubnetIdList', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::LookoutMetrics::AnomalyDetector::FileFormatDescriptor',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::LookoutMetrics::AnomalyDetector::FileFormatDescriptor',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::LookoutMetrics::AnomalyDetector::FileFormatDescriptor->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::LookoutMetrics::AnomalyDetector::FileFormatDescriptor {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has CsvFormatDescriptor => (isa => 'Cfn::Resource::Properties::AWS::LookoutMetrics::AnomalyDetector::CsvFormatDescriptor', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has JsonFormatDescriptor => (isa => 'Cfn::Resource::Properties::AWS::LookoutMetrics::AnomalyDetector::JsonFormatDescriptor', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::LookoutMetrics::AnomalyDetector::S3SourceConfig',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::LookoutMetrics::AnomalyDetector::S3SourceConfig',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::LookoutMetrics::AnomalyDetector::S3SourceConfig->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::LookoutMetrics::AnomalyDetector::S3SourceConfig {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has FileFormatDescriptor => (isa => 'Cfn::Resource::Properties::AWS::LookoutMetrics::AnomalyDetector::FileFormatDescriptor', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has HistoricalDataPathList => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RoleArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TemplatedPathList => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::LookoutMetrics::AnomalyDetector::RedshiftSourceConfig',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::LookoutMetrics::AnomalyDetector::RedshiftSourceConfig',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::LookoutMetrics::AnomalyDetector::RedshiftSourceConfig->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::LookoutMetrics::AnomalyDetector::RedshiftSourceConfig {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ClusterIdentifier => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DatabaseHost => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DatabaseName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DatabasePort => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RoleArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SecretManagerArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TableName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has VpcConfiguration => (isa => 'Cfn::Resource::Properties::AWS::LookoutMetrics::AnomalyDetector::VpcConfiguration', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::LookoutMetrics::AnomalyDetector::RDSSourceConfig',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::LookoutMetrics::AnomalyDetector::RDSSourceConfig',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::LookoutMetrics::AnomalyDetector::RDSSourceConfig->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::LookoutMetrics::AnomalyDetector::RDSSourceConfig {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has DatabaseHost => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DatabaseName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DatabasePort => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DBInstanceIdentifier => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RoleArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SecretManagerArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TableName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has VpcConfiguration => (isa => 'Cfn::Resource::Properties::AWS::LookoutMetrics::AnomalyDetector::VpcConfiguration', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::LookoutMetrics::AnomalyDetector::CloudwatchConfig',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::LookoutMetrics::AnomalyDetector::CloudwatchConfig',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::LookoutMetrics::AnomalyDetector::CloudwatchConfig->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::LookoutMetrics::AnomalyDetector::CloudwatchConfig {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has RoleArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::LookoutMetrics::AnomalyDetector::AppFlowConfig',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::LookoutMetrics::AnomalyDetector::AppFlowConfig',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::LookoutMetrics::AnomalyDetector::AppFlowConfig->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::LookoutMetrics::AnomalyDetector::AppFlowConfig {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has FlowName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RoleArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::LookoutMetrics::AnomalyDetector::TimestampColumn',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::LookoutMetrics::AnomalyDetector::TimestampColumn',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::LookoutMetrics::AnomalyDetector::TimestampColumn->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::LookoutMetrics::AnomalyDetector::TimestampColumn {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ColumnFormat => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ColumnName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::LookoutMetrics::AnomalyDetector::MetricSource',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::LookoutMetrics::AnomalyDetector::MetricSource',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::LookoutMetrics::AnomalyDetector::MetricSource->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::LookoutMetrics::AnomalyDetector::MetricSource {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AppFlowConfig => (isa => 'Cfn::Resource::Properties::AWS::LookoutMetrics::AnomalyDetector::AppFlowConfig', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has CloudwatchConfig => (isa => 'Cfn::Resource::Properties::AWS::LookoutMetrics::AnomalyDetector::CloudwatchConfig', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RDSSourceConfig => (isa => 'Cfn::Resource::Properties::AWS::LookoutMetrics::AnomalyDetector::RDSSourceConfig', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RedshiftSourceConfig => (isa => 'Cfn::Resource::Properties::AWS::LookoutMetrics::AnomalyDetector::RedshiftSourceConfig', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has S3SourceConfig => (isa => 'Cfn::Resource::Properties::AWS::LookoutMetrics::AnomalyDetector::S3SourceConfig', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::LookoutMetrics::AnomalyDetector::Metric',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::LookoutMetrics::AnomalyDetector::Metric',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::LookoutMetrics::AnomalyDetector::Metric')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::LookoutMetrics::AnomalyDetector::Metric',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::LookoutMetrics::AnomalyDetector::Metric',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::LookoutMetrics::AnomalyDetector::Metric->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::LookoutMetrics::AnomalyDetector::Metric {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AggregationFunction => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has MetricName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Namespace => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::LookoutMetrics::AnomalyDetector::MetricSet',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::LookoutMetrics::AnomalyDetector::MetricSet',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::LookoutMetrics::AnomalyDetector::MetricSet')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::LookoutMetrics::AnomalyDetector::MetricSet',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::LookoutMetrics::AnomalyDetector::MetricSet',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::LookoutMetrics::AnomalyDetector::MetricSet->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::LookoutMetrics::AnomalyDetector::MetricSet {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has DimensionList => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has MetricList => (isa => 'ArrayOfCfn::Resource::Properties::AWS::LookoutMetrics::AnomalyDetector::Metric', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has MetricSetDescription => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has MetricSetFrequency => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has MetricSetName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has MetricSource => (isa => 'Cfn::Resource::Properties::AWS::LookoutMetrics::AnomalyDetector::MetricSource', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Offset => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TimestampColumn => (isa => 'Cfn::Resource::Properties::AWS::LookoutMetrics::AnomalyDetector::TimestampColumn', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Timezone => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::LookoutMetrics::AnomalyDetector {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has AnomalyDetectorConfig => (isa => 'Cfn::Value::Json|Cfn::DynamicValue', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has AnomalyDetectorDescription => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has AnomalyDetectorName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has KmsKeyArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has MetricSetList => (isa => 'ArrayOfCfn::Resource::Properties::AWS::LookoutMetrics::AnomalyDetector::MetricSet', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::LookoutMetrics::AnomalyDetector - Cfn resource for AWS::LookoutMetrics::AnomalyDetector

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::LookoutMetrics::AnomalyDetector.

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
