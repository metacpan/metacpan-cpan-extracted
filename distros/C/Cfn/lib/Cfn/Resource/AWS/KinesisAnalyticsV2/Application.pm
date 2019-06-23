# AWS::KinesisAnalyticsV2::Application generated from spec 3.2.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::Application',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::Application->new( %$_ ) };

package Cfn::Resource::AWS::KinesisAnalyticsV2::Application {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::Application', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [  ]
  }
  sub supported_regions {
    [ 'ap-northeast-1','ap-northeast-2','ap-southeast-1','ap-southeast-2','eu-central-1','eu-west-1','eu-west-2','us-east-1','us-east-2','us-west-2' ]
  }
}



subtype 'Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::Application::JSONMappingParameters',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::Application::JSONMappingParameters',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::Application::JSONMappingParametersValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::Application::JSONMappingParametersValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has RecordRowPath => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::Application::CSVMappingParameters',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::Application::CSVMappingParameters',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::Application::CSVMappingParametersValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::Application::CSVMappingParametersValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has RecordColumnDelimiter => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RecordRowDelimiter => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::Application::MappingParameters',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::Application::MappingParameters',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::Application::MappingParametersValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::Application::MappingParametersValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has CSVMappingParameters => (isa => 'Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::Application::CSVMappingParameters', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has JSONMappingParameters => (isa => 'Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::Application::JSONMappingParameters', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::Application::RecordFormat',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::Application::RecordFormat',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::Application::RecordFormatValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::Application::RecordFormatValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has MappingParameters => (isa => 'Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::Application::MappingParameters', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RecordFormatType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::KinesisAnalyticsV2::Application::RecordColumn',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::KinesisAnalyticsV2::Application::RecordColumn',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::Application::RecordColumn')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::Application::RecordColumn',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::Application::RecordColumn',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::Application::RecordColumnValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::Application::RecordColumnValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Mapping => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SqlType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::Application::InputLambdaProcessor',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::Application::InputLambdaProcessor',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::Application::InputLambdaProcessorValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::Application::InputLambdaProcessorValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ResourceARN => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::Application::S3ContentLocation',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::Application::S3ContentLocation',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::Application::S3ContentLocationValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::Application::S3ContentLocationValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has BucketARN => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has FileKey => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ObjectVersion => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::Application::KinesisStreamsInput',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::Application::KinesisStreamsInput',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::Application::KinesisStreamsInputValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::Application::KinesisStreamsInputValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ResourceARN => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::Application::KinesisFirehoseInput',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::Application::KinesisFirehoseInput',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::Application::KinesisFirehoseInputValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::Application::KinesisFirehoseInputValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ResourceARN => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::Application::InputSchema',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::Application::InputSchema',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::Application::InputSchemaValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::Application::InputSchemaValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has RecordColumns => (isa => 'ArrayOfCfn::Resource::Properties::AWS::KinesisAnalyticsV2::Application::RecordColumn', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RecordEncoding => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RecordFormat => (isa => 'Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::Application::RecordFormat', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::Application::InputProcessingConfiguration',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::Application::InputProcessingConfiguration',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::Application::InputProcessingConfigurationValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::Application::InputProcessingConfigurationValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has InputLambdaProcessor => (isa => 'Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::Application::InputLambdaProcessor', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::Application::InputParallelism',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::Application::InputParallelism',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::Application::InputParallelismValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::Application::InputParallelismValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Count => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::KinesisAnalyticsV2::Application::PropertyGroup',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::KinesisAnalyticsV2::Application::PropertyGroup',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::Application::PropertyGroup')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::Application::PropertyGroup',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::Application::PropertyGroup',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::Application::PropertyGroupValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::Application::PropertyGroupValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has PropertyGroupId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has PropertyMap => (isa => 'Cfn::Value::Json|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::Application::ParallelismConfiguration',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::Application::ParallelismConfiguration',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::Application::ParallelismConfigurationValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::Application::ParallelismConfigurationValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AutoScalingEnabled => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ConfigurationType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Parallelism => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ParallelismPerKPU => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::Application::MonitoringConfiguration',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::Application::MonitoringConfiguration',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::Application::MonitoringConfigurationValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::Application::MonitoringConfigurationValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ConfigurationType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has LogLevel => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has MetricsLevel => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::KinesisAnalyticsV2::Application::Input',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::KinesisAnalyticsV2::Application::Input',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::Application::Input')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::Application::Input',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::Application::Input',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::Application::InputValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::Application::InputValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has InputParallelism => (isa => 'Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::Application::InputParallelism', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has InputProcessingConfiguration => (isa => 'Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::Application::InputProcessingConfiguration', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has InputSchema => (isa => 'Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::Application::InputSchema', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has KinesisFirehoseInput => (isa => 'Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::Application::KinesisFirehoseInput', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has KinesisStreamsInput => (isa => 'Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::Application::KinesisStreamsInput', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has NamePrefix => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::Application::CodeContent',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::Application::CodeContent',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::Application::CodeContentValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::Application::CodeContentValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has S3ContentLocation => (isa => 'Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::Application::S3ContentLocation', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TextContent => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ZipFileContent => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::Application::CheckpointConfiguration',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::Application::CheckpointConfiguration',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::Application::CheckpointConfigurationValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::Application::CheckpointConfigurationValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has CheckpointingEnabled => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has CheckpointInterval => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ConfigurationType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has MinPauseBetweenCheckpoints => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::Application::SqlApplicationConfiguration',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::Application::SqlApplicationConfiguration',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::Application::SqlApplicationConfigurationValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::Application::SqlApplicationConfigurationValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Inputs => (isa => 'ArrayOfCfn::Resource::Properties::AWS::KinesisAnalyticsV2::Application::Input', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::Application::FlinkApplicationConfiguration',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::Application::FlinkApplicationConfiguration',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::Application::FlinkApplicationConfigurationValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::Application::FlinkApplicationConfigurationValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has CheckpointConfiguration => (isa => 'Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::Application::CheckpointConfiguration', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has MonitoringConfiguration => (isa => 'Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::Application::MonitoringConfiguration', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ParallelismConfiguration => (isa => 'Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::Application::ParallelismConfiguration', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::Application::EnvironmentProperties',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::Application::EnvironmentProperties',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::Application::EnvironmentPropertiesValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::Application::EnvironmentPropertiesValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has PropertyGroups => (isa => 'ArrayOfCfn::Resource::Properties::AWS::KinesisAnalyticsV2::Application::PropertyGroup', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::Application::ApplicationSnapshotConfiguration',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::Application::ApplicationSnapshotConfiguration',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::Application::ApplicationSnapshotConfigurationValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::Application::ApplicationSnapshotConfigurationValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has SnapshotsEnabled => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::Application::ApplicationCodeConfiguration',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::Application::ApplicationCodeConfiguration',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::Application::ApplicationCodeConfigurationValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::Application::ApplicationCodeConfigurationValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has CodeContent => (isa => 'Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::Application::CodeContent', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has CodeContentType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::Application::ApplicationConfiguration',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::Application::ApplicationConfiguration',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::Application::ApplicationConfigurationValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::Application::ApplicationConfigurationValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ApplicationCodeConfiguration => (isa => 'Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::Application::ApplicationCodeConfiguration', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ApplicationSnapshotConfiguration => (isa => 'Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::Application::ApplicationSnapshotConfiguration', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has EnvironmentProperties => (isa => 'Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::Application::EnvironmentProperties', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has FlinkApplicationConfiguration => (isa => 'Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::Application::FlinkApplicationConfiguration', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SqlApplicationConfiguration => (isa => 'Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::Application::SqlApplicationConfiguration', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::Application {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has ApplicationConfiguration => (isa => 'Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::Application::ApplicationConfiguration', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ApplicationDescription => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ApplicationName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has RuntimeEnvironment => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has ServiceExecutionRole => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
