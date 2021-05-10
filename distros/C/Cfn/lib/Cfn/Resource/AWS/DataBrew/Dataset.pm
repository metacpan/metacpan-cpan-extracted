# AWS::DataBrew::Dataset generated from spec 34.0.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::DataBrew::Dataset',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::DataBrew::Dataset->new( %$_ ) };

package Cfn::Resource::AWS::DataBrew::Dataset {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::DataBrew::Dataset', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [  ]
  }
  sub supported_regions {
    [ 'ap-northeast-1','ap-northeast-2','ap-south-1','ap-southeast-1','ap-southeast-2','ca-central-1','eu-central-1','eu-north-1','eu-west-1','eu-west-2','eu-west-3','sa-east-1','us-east-1','us-east-2','us-west-1','us-west-2' ]
  }
}


subtype 'ArrayOfCfn::Resource::Properties::AWS::DataBrew::Dataset::FilterValue',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::DataBrew::Dataset::FilterValue',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::DataBrew::Dataset::FilterValue')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::DataBrew::Dataset::FilterValue',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::DataBrew::Dataset::FilterValue',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::DataBrew::Dataset::FilterValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::DataBrew::Dataset::FilterValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Value => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ValueReference => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::DataBrew::Dataset::FilterExpression',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::DataBrew::Dataset::FilterExpression',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::DataBrew::Dataset::FilterExpression->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::DataBrew::Dataset::FilterExpression {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Expression => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ValuesMap => (isa => 'ArrayOfCfn::Resource::Properties::AWS::DataBrew::Dataset::FilterValue', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::DataBrew::Dataset::DatetimeOptions',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::DataBrew::Dataset::DatetimeOptions',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::DataBrew::Dataset::DatetimeOptions->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::DataBrew::Dataset::DatetimeOptions {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Format => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has LocaleCode => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TimezoneOffset => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::DataBrew::Dataset::S3Location',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::DataBrew::Dataset::S3Location',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::DataBrew::Dataset::S3Location->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::DataBrew::Dataset::S3Location {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Bucket => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Key => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::DataBrew::Dataset::DatasetParameter',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::DataBrew::Dataset::DatasetParameter',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::DataBrew::Dataset::DatasetParameter->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::DataBrew::Dataset::DatasetParameter {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has CreateColumn => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DatetimeOptions => (isa => 'Cfn::Resource::Properties::AWS::DataBrew::Dataset::DatetimeOptions', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Filter => (isa => 'Cfn::Resource::Properties::AWS::DataBrew::Dataset::FilterExpression', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Type => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::DataBrew::Dataset::PathParameter',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::DataBrew::Dataset::PathParameter',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::DataBrew::Dataset::PathParameter')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::DataBrew::Dataset::PathParameter',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::DataBrew::Dataset::PathParameter',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::DataBrew::Dataset::PathParameter->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::DataBrew::Dataset::PathParameter {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has DatasetParameter => (isa => 'Cfn::Resource::Properties::AWS::DataBrew::Dataset::DatasetParameter', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has PathParameterName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::DataBrew::Dataset::JsonOptions',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::DataBrew::Dataset::JsonOptions',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::DataBrew::Dataset::JsonOptions->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::DataBrew::Dataset::JsonOptions {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has MultiLine => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::DataBrew::Dataset::FilesLimit',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::DataBrew::Dataset::FilesLimit',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::DataBrew::Dataset::FilesLimit->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::DataBrew::Dataset::FilesLimit {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has MaxFiles => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Order => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has OrderedBy => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::DataBrew::Dataset::ExcelOptions',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::DataBrew::Dataset::ExcelOptions',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::DataBrew::Dataset::ExcelOptions->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::DataBrew::Dataset::ExcelOptions {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has HeaderRow => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SheetIndexes => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SheetNames => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::DataBrew::Dataset::DatabaseInputDefinition',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::DataBrew::Dataset::DatabaseInputDefinition',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::DataBrew::Dataset::DatabaseInputDefinition->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::DataBrew::Dataset::DatabaseInputDefinition {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has DatabaseTableName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has GlueConnectionName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TempDirectory => (isa => 'Cfn::Resource::Properties::AWS::DataBrew::Dataset::S3Location', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::DataBrew::Dataset::DataCatalogInputDefinition',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::DataBrew::Dataset::DataCatalogInputDefinition',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::DataBrew::Dataset::DataCatalogInputDefinition->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::DataBrew::Dataset::DataCatalogInputDefinition {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has CatalogId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DatabaseName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TableName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TempDirectory => (isa => 'Cfn::Resource::Properties::AWS::DataBrew::Dataset::S3Location', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::DataBrew::Dataset::CsvOptions',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::DataBrew::Dataset::CsvOptions',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::DataBrew::Dataset::CsvOptions->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::DataBrew::Dataset::CsvOptions {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Delimiter => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has HeaderRow => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::DataBrew::Dataset::PathOptions',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::DataBrew::Dataset::PathOptions',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::DataBrew::Dataset::PathOptions->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::DataBrew::Dataset::PathOptions {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has FilesLimit => (isa => 'Cfn::Resource::Properties::AWS::DataBrew::Dataset::FilesLimit', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has LastModifiedDateCondition => (isa => 'Cfn::Resource::Properties::AWS::DataBrew::Dataset::FilterExpression', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Parameters => (isa => 'ArrayOfCfn::Resource::Properties::AWS::DataBrew::Dataset::PathParameter', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::DataBrew::Dataset::Input',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::DataBrew::Dataset::Input',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::DataBrew::Dataset::Input->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::DataBrew::Dataset::Input {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has DatabaseInputDefinition => (isa => 'Cfn::Resource::Properties::AWS::DataBrew::Dataset::DatabaseInputDefinition', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DataCatalogInputDefinition => (isa => 'Cfn::Resource::Properties::AWS::DataBrew::Dataset::DataCatalogInputDefinition', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has S3InputDefinition => (isa => 'Cfn::Resource::Properties::AWS::DataBrew::Dataset::S3Location', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::DataBrew::Dataset::FormatOptions',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::DataBrew::Dataset::FormatOptions',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::DataBrew::Dataset::FormatOptions->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::DataBrew::Dataset::FormatOptions {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Csv => (isa => 'Cfn::Resource::Properties::AWS::DataBrew::Dataset::CsvOptions', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Excel => (isa => 'Cfn::Resource::Properties::AWS::DataBrew::Dataset::ExcelOptions', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Json => (isa => 'Cfn::Resource::Properties::AWS::DataBrew::Dataset::JsonOptions', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::DataBrew::Dataset {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has Format => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has FormatOptions => (isa => 'Cfn::Resource::Properties::AWS::DataBrew::Dataset::FormatOptions', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Input => (isa => 'Cfn::Resource::Properties::AWS::DataBrew::Dataset::Input', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has PathOptions => (isa => 'Cfn::Resource::Properties::AWS::DataBrew::Dataset::PathOptions', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Tags => (isa => 'ArrayOfCfn::Resource::Properties::TagType', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::DataBrew::Dataset - Cfn resource for AWS::DataBrew::Dataset

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::DataBrew::Dataset.

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
