# AWS::KinesisAnalytics::ApplicationReferenceDataSource generated from spec 3.2.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::KinesisAnalytics::ApplicationReferenceDataSource',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::KinesisAnalytics::ApplicationReferenceDataSource->new( %$_ ) };

package Cfn::Resource::AWS::KinesisAnalytics::ApplicationReferenceDataSource {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::KinesisAnalytics::ApplicationReferenceDataSource', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [  ]
  }
  sub supported_regions {
    [ 'ap-northeast-1','ap-northeast-2','ap-southeast-1','ap-southeast-2','eu-west-1','eu-west-2','us-east-1','us-east-2','us-west-2' ]
  }
}



subtype 'Cfn::Resource::Properties::AWS::KinesisAnalytics::ApplicationReferenceDataSource::JSONMappingParameters',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::KinesisAnalytics::ApplicationReferenceDataSource::JSONMappingParameters',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::KinesisAnalytics::ApplicationReferenceDataSource::JSONMappingParametersValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::KinesisAnalytics::ApplicationReferenceDataSource::JSONMappingParametersValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has RecordRowPath => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::KinesisAnalytics::ApplicationReferenceDataSource::CSVMappingParameters',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::KinesisAnalytics::ApplicationReferenceDataSource::CSVMappingParameters',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::KinesisAnalytics::ApplicationReferenceDataSource::CSVMappingParametersValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::KinesisAnalytics::ApplicationReferenceDataSource::CSVMappingParametersValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has RecordColumnDelimiter => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RecordRowDelimiter => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::KinesisAnalytics::ApplicationReferenceDataSource::MappingParameters',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::KinesisAnalytics::ApplicationReferenceDataSource::MappingParameters',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::KinesisAnalytics::ApplicationReferenceDataSource::MappingParametersValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::KinesisAnalytics::ApplicationReferenceDataSource::MappingParametersValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has CSVMappingParameters => (isa => 'Cfn::Resource::Properties::AWS::KinesisAnalytics::ApplicationReferenceDataSource::CSVMappingParameters', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has JSONMappingParameters => (isa => 'Cfn::Resource::Properties::AWS::KinesisAnalytics::ApplicationReferenceDataSource::JSONMappingParameters', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::KinesisAnalytics::ApplicationReferenceDataSource::RecordFormat',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::KinesisAnalytics::ApplicationReferenceDataSource::RecordFormat',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::KinesisAnalytics::ApplicationReferenceDataSource::RecordFormatValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::KinesisAnalytics::ApplicationReferenceDataSource::RecordFormatValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has MappingParameters => (isa => 'Cfn::Resource::Properties::AWS::KinesisAnalytics::ApplicationReferenceDataSource::MappingParameters', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RecordFormatType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::KinesisAnalytics::ApplicationReferenceDataSource::RecordColumn',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::KinesisAnalytics::ApplicationReferenceDataSource::RecordColumn',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::KinesisAnalytics::ApplicationReferenceDataSource::RecordColumn')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::KinesisAnalytics::ApplicationReferenceDataSource::RecordColumn',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::KinesisAnalytics::ApplicationReferenceDataSource::RecordColumn',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::KinesisAnalytics::ApplicationReferenceDataSource::RecordColumnValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::KinesisAnalytics::ApplicationReferenceDataSource::RecordColumnValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Mapping => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SqlType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::KinesisAnalytics::ApplicationReferenceDataSource::S3ReferenceDataSource',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::KinesisAnalytics::ApplicationReferenceDataSource::S3ReferenceDataSource',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::KinesisAnalytics::ApplicationReferenceDataSource::S3ReferenceDataSourceValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::KinesisAnalytics::ApplicationReferenceDataSource::S3ReferenceDataSourceValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has BucketARN => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has FileKey => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ReferenceRoleARN => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::KinesisAnalytics::ApplicationReferenceDataSource::ReferenceSchema',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::KinesisAnalytics::ApplicationReferenceDataSource::ReferenceSchema',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::KinesisAnalytics::ApplicationReferenceDataSource::ReferenceSchemaValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::KinesisAnalytics::ApplicationReferenceDataSource::ReferenceSchemaValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has RecordColumns => (isa => 'ArrayOfCfn::Resource::Properties::AWS::KinesisAnalytics::ApplicationReferenceDataSource::RecordColumn', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RecordEncoding => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RecordFormat => (isa => 'Cfn::Resource::Properties::AWS::KinesisAnalytics::ApplicationReferenceDataSource::RecordFormat', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::KinesisAnalytics::ApplicationReferenceDataSource::ReferenceDataSource',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::KinesisAnalytics::ApplicationReferenceDataSource::ReferenceDataSource',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::KinesisAnalytics::ApplicationReferenceDataSource::ReferenceDataSourceValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::KinesisAnalytics::ApplicationReferenceDataSource::ReferenceDataSourceValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ReferenceSchema => (isa => 'Cfn::Resource::Properties::AWS::KinesisAnalytics::ApplicationReferenceDataSource::ReferenceSchema', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has S3ReferenceDataSource => (isa => 'Cfn::Resource::Properties::AWS::KinesisAnalytics::ApplicationReferenceDataSource::S3ReferenceDataSource', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TableName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::KinesisAnalytics::ApplicationReferenceDataSource {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has ApplicationName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has ReferenceDataSource => (isa => 'Cfn::Resource::Properties::AWS::KinesisAnalytics::ApplicationReferenceDataSource::ReferenceDataSource', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
