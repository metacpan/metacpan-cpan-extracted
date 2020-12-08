# AWS::KinesisAnalyticsV2::ApplicationReferenceDataSource generated from spec 18.4.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::ApplicationReferenceDataSource',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::ApplicationReferenceDataSource->new( %$_ ) };

package Cfn::Resource::AWS::KinesisAnalyticsV2::ApplicationReferenceDataSource {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::ApplicationReferenceDataSource', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [  ]
  }
  sub supported_regions {
    [ 'ap-northeast-1','ap-northeast-2','ap-southeast-1','ap-southeast-2','eu-central-1','eu-west-1','eu-west-2','us-east-1','us-east-2','us-west-2' ]
  }
}



subtype 'Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::ApplicationReferenceDataSource::JSONMappingParameters',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::ApplicationReferenceDataSource::JSONMappingParameters',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::KinesisAnalyticsV2::ApplicationReferenceDataSource::JSONMappingParameters->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::KinesisAnalyticsV2::ApplicationReferenceDataSource::JSONMappingParameters {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has RecordRowPath => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::ApplicationReferenceDataSource::CSVMappingParameters',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::ApplicationReferenceDataSource::CSVMappingParameters',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::KinesisAnalyticsV2::ApplicationReferenceDataSource::CSVMappingParameters->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::KinesisAnalyticsV2::ApplicationReferenceDataSource::CSVMappingParameters {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has RecordColumnDelimiter => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RecordRowDelimiter => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::ApplicationReferenceDataSource::MappingParameters',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::ApplicationReferenceDataSource::MappingParameters',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::KinesisAnalyticsV2::ApplicationReferenceDataSource::MappingParameters->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::KinesisAnalyticsV2::ApplicationReferenceDataSource::MappingParameters {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has CSVMappingParameters => (isa => 'Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::ApplicationReferenceDataSource::CSVMappingParameters', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has JSONMappingParameters => (isa => 'Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::ApplicationReferenceDataSource::JSONMappingParameters', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::ApplicationReferenceDataSource::RecordFormat',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::ApplicationReferenceDataSource::RecordFormat',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::KinesisAnalyticsV2::ApplicationReferenceDataSource::RecordFormat->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::KinesisAnalyticsV2::ApplicationReferenceDataSource::RecordFormat {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has MappingParameters => (isa => 'Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::ApplicationReferenceDataSource::MappingParameters', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RecordFormatType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::KinesisAnalyticsV2::ApplicationReferenceDataSource::RecordColumn',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::KinesisAnalyticsV2::ApplicationReferenceDataSource::RecordColumn',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::ApplicationReferenceDataSource::RecordColumn')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::ApplicationReferenceDataSource::RecordColumn',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::ApplicationReferenceDataSource::RecordColumn',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::KinesisAnalyticsV2::ApplicationReferenceDataSource::RecordColumn->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::KinesisAnalyticsV2::ApplicationReferenceDataSource::RecordColumn {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Mapping => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SqlType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::ApplicationReferenceDataSource::S3ReferenceDataSource',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::ApplicationReferenceDataSource::S3ReferenceDataSource',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::KinesisAnalyticsV2::ApplicationReferenceDataSource::S3ReferenceDataSource->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::KinesisAnalyticsV2::ApplicationReferenceDataSource::S3ReferenceDataSource {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has BucketARN => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has FileKey => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::ApplicationReferenceDataSource::ReferenceSchema',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::ApplicationReferenceDataSource::ReferenceSchema',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::KinesisAnalyticsV2::ApplicationReferenceDataSource::ReferenceSchema->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::KinesisAnalyticsV2::ApplicationReferenceDataSource::ReferenceSchema {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has RecordColumns => (isa => 'ArrayOfCfn::Resource::Properties::AWS::KinesisAnalyticsV2::ApplicationReferenceDataSource::RecordColumn', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RecordEncoding => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RecordFormat => (isa => 'Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::ApplicationReferenceDataSource::RecordFormat', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::ApplicationReferenceDataSource::ReferenceDataSource',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::ApplicationReferenceDataSource::ReferenceDataSource',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::KinesisAnalyticsV2::ApplicationReferenceDataSource::ReferenceDataSource->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::KinesisAnalyticsV2::ApplicationReferenceDataSource::ReferenceDataSource {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ReferenceSchema => (isa => 'Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::ApplicationReferenceDataSource::ReferenceSchema', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has S3ReferenceDataSource => (isa => 'Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::ApplicationReferenceDataSource::S3ReferenceDataSource', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TableName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

package Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::ApplicationReferenceDataSource {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has ApplicationName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has ReferenceDataSource => (isa => 'Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::ApplicationReferenceDataSource::ReferenceDataSource', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::KinesisAnalyticsV2::ApplicationReferenceDataSource - Cfn resource for AWS::KinesisAnalyticsV2::ApplicationReferenceDataSource

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::KinesisAnalyticsV2::ApplicationReferenceDataSource.

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
