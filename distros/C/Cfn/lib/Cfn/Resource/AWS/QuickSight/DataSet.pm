# AWS::QuickSight::DataSet generated from spec 34.0.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::QuickSight::DataSet',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::QuickSight::DataSet->new( %$_ ) };

package Cfn::Resource::AWS::QuickSight::DataSet {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::QuickSight::DataSet', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [ 'Arn','ConsumedSpiceCapacityInBytes','CreatedTime','LastUpdatedTime','OutputColumns' ]
  }
  sub supported_regions {
    [ 'ap-northeast-1','ap-northeast-2','ap-south-1','ap-southeast-1','ap-southeast-2','ca-central-1','eu-central-1','eu-west-1','eu-west-2','sa-east-1','us-east-1','us-east-2','us-gov-west-1','us-west-2' ]
  }
}



subtype 'Cfn::Resource::Properties::AWS::QuickSight::DataSet::ColumnDescription',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::QuickSight::DataSet::ColumnDescription',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::QuickSight::DataSet::ColumnDescription->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::QuickSight::DataSet::ColumnDescription {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Text => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::QuickSight::DataSet::JoinKeyProperties',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::QuickSight::DataSet::JoinKeyProperties',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::QuickSight::DataSet::JoinKeyProperties->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::QuickSight::DataSet::JoinKeyProperties {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has UniqueKey => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::QuickSight::DataSet::ColumnTag',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::QuickSight::DataSet::ColumnTag',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::QuickSight::DataSet::ColumnTag')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::QuickSight::DataSet::ColumnTag',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::QuickSight::DataSet::ColumnTag',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::QuickSight::DataSet::ColumnTag->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::QuickSight::DataSet::ColumnTag {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ColumnDescription => (isa => 'Cfn::Resource::Properties::AWS::QuickSight::DataSet::ColumnDescription', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ColumnGeographicRole => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::QuickSight::DataSet::CalculatedColumn',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::QuickSight::DataSet::CalculatedColumn',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::QuickSight::DataSet::CalculatedColumn')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::QuickSight::DataSet::CalculatedColumn',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::QuickSight::DataSet::CalculatedColumn',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::QuickSight::DataSet::CalculatedColumn->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::QuickSight::DataSet::CalculatedColumn {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ColumnId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ColumnName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Expression => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::QuickSight::DataSet::UploadSettings',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::QuickSight::DataSet::UploadSettings',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::QuickSight::DataSet::UploadSettings->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::QuickSight::DataSet::UploadSettings {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ContainsHeader => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Delimiter => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Format => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has StartFromRow => (isa => 'Cfn::Value::Double', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TextQualifier => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::QuickSight::DataSet::TagColumnOperation',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::QuickSight::DataSet::TagColumnOperation',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::QuickSight::DataSet::TagColumnOperation->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::QuickSight::DataSet::TagColumnOperation {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ColumnName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Tags => (isa => 'ArrayOfCfn::Resource::Properties::AWS::QuickSight::DataSet::ColumnTag', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::QuickSight::DataSet::RenameColumnOperation',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::QuickSight::DataSet::RenameColumnOperation',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::QuickSight::DataSet::RenameColumnOperation->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::QuickSight::DataSet::RenameColumnOperation {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ColumnName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has NewColumnName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::QuickSight::DataSet::ProjectOperation',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::QuickSight::DataSet::ProjectOperation',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::QuickSight::DataSet::ProjectOperation->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::QuickSight::DataSet::ProjectOperation {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ProjectedColumns => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::QuickSight::DataSet::JoinInstruction',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::QuickSight::DataSet::JoinInstruction',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::QuickSight::DataSet::JoinInstruction->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::QuickSight::DataSet::JoinInstruction {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has LeftJoinKeyProperties => (isa => 'Cfn::Resource::Properties::AWS::QuickSight::DataSet::JoinKeyProperties', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has LeftOperand => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has OnClause => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RightJoinKeyProperties => (isa => 'Cfn::Resource::Properties::AWS::QuickSight::DataSet::JoinKeyProperties', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RightOperand => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Type => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::QuickSight::DataSet::InputColumn',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::QuickSight::DataSet::InputColumn',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::QuickSight::DataSet::InputColumn')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::QuickSight::DataSet::InputColumn',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::QuickSight::DataSet::InputColumn',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::QuickSight::DataSet::InputColumn->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::QuickSight::DataSet::InputColumn {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Type => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::QuickSight::DataSet::FilterOperation',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::QuickSight::DataSet::FilterOperation',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::QuickSight::DataSet::FilterOperation->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::QuickSight::DataSet::FilterOperation {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ConditionExpression => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::QuickSight::DataSet::CreateColumnsOperation',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::QuickSight::DataSet::CreateColumnsOperation',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::QuickSight::DataSet::CreateColumnsOperation->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::QuickSight::DataSet::CreateColumnsOperation {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Columns => (isa => 'ArrayOfCfn::Resource::Properties::AWS::QuickSight::DataSet::CalculatedColumn', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::QuickSight::DataSet::CastColumnTypeOperation',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::QuickSight::DataSet::CastColumnTypeOperation',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::QuickSight::DataSet::CastColumnTypeOperation->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::QuickSight::DataSet::CastColumnTypeOperation {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ColumnName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Format => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has NewColumnType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::QuickSight::DataSet::TransformOperation',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::QuickSight::DataSet::TransformOperation',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::QuickSight::DataSet::TransformOperation')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::QuickSight::DataSet::TransformOperation',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::QuickSight::DataSet::TransformOperation',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::QuickSight::DataSet::TransformOperation->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::QuickSight::DataSet::TransformOperation {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has CastColumnTypeOperation => (isa => 'Cfn::Resource::Properties::AWS::QuickSight::DataSet::CastColumnTypeOperation', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has CreateColumnsOperation => (isa => 'Cfn::Resource::Properties::AWS::QuickSight::DataSet::CreateColumnsOperation', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has FilterOperation => (isa => 'Cfn::Resource::Properties::AWS::QuickSight::DataSet::FilterOperation', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ProjectOperation => (isa => 'Cfn::Resource::Properties::AWS::QuickSight::DataSet::ProjectOperation', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RenameColumnOperation => (isa => 'Cfn::Resource::Properties::AWS::QuickSight::DataSet::RenameColumnOperation', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TagColumnOperation => (isa => 'Cfn::Resource::Properties::AWS::QuickSight::DataSet::TagColumnOperation', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::QuickSight::DataSet::S3Source',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::QuickSight::DataSet::S3Source',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::QuickSight::DataSet::S3Source->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::QuickSight::DataSet::S3Source {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has DataSourceArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has InputColumns => (isa => 'ArrayOfCfn::Resource::Properties::AWS::QuickSight::DataSet::InputColumn', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has UploadSettings => (isa => 'Cfn::Resource::Properties::AWS::QuickSight::DataSet::UploadSettings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::QuickSight::DataSet::RelationalTable',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::QuickSight::DataSet::RelationalTable',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::QuickSight::DataSet::RelationalTable->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::QuickSight::DataSet::RelationalTable {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Catalog => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DataSourceArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has InputColumns => (isa => 'ArrayOfCfn::Resource::Properties::AWS::QuickSight::DataSet::InputColumn', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Schema => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::QuickSight::DataSet::LogicalTableSource',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::QuickSight::DataSet::LogicalTableSource',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::QuickSight::DataSet::LogicalTableSource->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::QuickSight::DataSet::LogicalTableSource {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has JoinInstruction => (isa => 'Cfn::Resource::Properties::AWS::QuickSight::DataSet::JoinInstruction', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has PhysicalTableId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::QuickSight::DataSet::GeoSpatialColumnGroup',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::QuickSight::DataSet::GeoSpatialColumnGroup',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::QuickSight::DataSet::GeoSpatialColumnGroup->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::QuickSight::DataSet::GeoSpatialColumnGroup {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Columns => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has CountryCode => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::QuickSight::DataSet::CustomSql',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::QuickSight::DataSet::CustomSql',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::QuickSight::DataSet::CustomSql->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::QuickSight::DataSet::CustomSql {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Columns => (isa => 'ArrayOfCfn::Resource::Properties::AWS::QuickSight::DataSet::InputColumn', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DataSourceArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SqlQuery => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::QuickSight::DataSet::RowLevelPermissionDataSet',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::QuickSight::DataSet::RowLevelPermissionDataSet',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::QuickSight::DataSet::RowLevelPermissionDataSet->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::QuickSight::DataSet::RowLevelPermissionDataSet {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Arn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Namespace => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has PermissionPolicy => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::QuickSight::DataSet::ResourcePermission',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::QuickSight::DataSet::ResourcePermission',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::QuickSight::DataSet::ResourcePermission')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::QuickSight::DataSet::ResourcePermission',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::QuickSight::DataSet::ResourcePermission',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::QuickSight::DataSet::ResourcePermission->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::QuickSight::DataSet::ResourcePermission {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Actions => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Principal => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'MapOfCfn::Resource::Properties::AWS::QuickSight::DataSet::PhysicalTable',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Hash') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'MapOfCfn::Resource::Properties::AWS::QuickSight::DataSet::PhysicalTable',
  from 'HashRef',
   via {
     my $arg = $_;
     if (my $f = Cfn::TypeLibrary::try_function($arg)) {
       return $f
     } else {
       Cfn::Value::Hash->new(Value => {
         map { $_ => Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::QuickSight::DataSet::PhysicalTable')->coerce($arg->{$_}) } keys %$arg
       });
     }
   };

subtype 'Cfn::Resource::Properties::AWS::QuickSight::DataSet::PhysicalTable',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::QuickSight::DataSet::PhysicalTable',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::QuickSight::DataSet::PhysicalTable->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::QuickSight::DataSet::PhysicalTable {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has CustomSql => (isa => 'Cfn::Resource::Properties::AWS::QuickSight::DataSet::CustomSql', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RelationalTable => (isa => 'Cfn::Resource::Properties::AWS::QuickSight::DataSet::RelationalTable', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has S3Source => (isa => 'Cfn::Resource::Properties::AWS::QuickSight::DataSet::S3Source', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::QuickSight::DataSet::OutputColumn',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::QuickSight::DataSet::OutputColumn',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::QuickSight::DataSet::OutputColumn->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::QuickSight::DataSet::OutputColumn {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Description => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Type => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'MapOfCfn::Resource::Properties::AWS::QuickSight::DataSet::LogicalTable',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Hash') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'MapOfCfn::Resource::Properties::AWS::QuickSight::DataSet::LogicalTable',
  from 'HashRef',
   via {
     my $arg = $_;
     if (my $f = Cfn::TypeLibrary::try_function($arg)) {
       return $f
     } else {
       Cfn::Value::Hash->new(Value => {
         map { $_ => Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::QuickSight::DataSet::LogicalTable')->coerce($arg->{$_}) } keys %$arg
       });
     }
   };

subtype 'Cfn::Resource::Properties::AWS::QuickSight::DataSet::LogicalTable',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::QuickSight::DataSet::LogicalTable',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::QuickSight::DataSet::LogicalTable->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::QuickSight::DataSet::LogicalTable {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Alias => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DataTransforms => (isa => 'ArrayOfCfn::Resource::Properties::AWS::QuickSight::DataSet::TransformOperation', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Source => (isa => 'Cfn::Resource::Properties::AWS::QuickSight::DataSet::LogicalTableSource', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::QuickSight::DataSet::IngestionWaitPolicy',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::QuickSight::DataSet::IngestionWaitPolicy',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::QuickSight::DataSet::IngestionWaitPolicy->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::QuickSight::DataSet::IngestionWaitPolicy {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has IngestionWaitTimeInHours => (isa => 'Cfn::Value::Double', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has WaitForSpiceIngestion => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'MapOfCfn::Resource::Properties::AWS::QuickSight::DataSet::FieldFolder',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Hash') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'MapOfCfn::Resource::Properties::AWS::QuickSight::DataSet::FieldFolder',
  from 'HashRef',
   via {
     my $arg = $_;
     if (my $f = Cfn::TypeLibrary::try_function($arg)) {
       return $f
     } else {
       Cfn::Value::Hash->new(Value => {
         map { $_ => Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::QuickSight::DataSet::FieldFolder')->coerce($arg->{$_}) } keys %$arg
       });
     }
   };

subtype 'Cfn::Resource::Properties::AWS::QuickSight::DataSet::FieldFolder',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::QuickSight::DataSet::FieldFolder',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::QuickSight::DataSet::FieldFolder->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::QuickSight::DataSet::FieldFolder {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Columns => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Description => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::QuickSight::DataSet::ColumnLevelPermissionRule',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::QuickSight::DataSet::ColumnLevelPermissionRule',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::QuickSight::DataSet::ColumnLevelPermissionRule')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::QuickSight::DataSet::ColumnLevelPermissionRule',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::QuickSight::DataSet::ColumnLevelPermissionRule',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::QuickSight::DataSet::ColumnLevelPermissionRule->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::QuickSight::DataSet::ColumnLevelPermissionRule {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ColumnNames => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Principals => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::QuickSight::DataSet::ColumnGroup',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::QuickSight::DataSet::ColumnGroup',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::QuickSight::DataSet::ColumnGroup')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::QuickSight::DataSet::ColumnGroup',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::QuickSight::DataSet::ColumnGroup',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::QuickSight::DataSet::ColumnGroup->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::QuickSight::DataSet::ColumnGroup {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has GeoSpatialColumnGroup => (isa => 'Cfn::Resource::Properties::AWS::QuickSight::DataSet::GeoSpatialColumnGroup', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::QuickSight::DataSet {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has AwsAccountId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has ColumnGroups => (isa => 'ArrayOfCfn::Resource::Properties::AWS::QuickSight::DataSet::ColumnGroup', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ColumnLevelPermissionRules => (isa => 'ArrayOfCfn::Resource::Properties::AWS::QuickSight::DataSet::ColumnLevelPermissionRule', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DataSetId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has FieldFolders => (isa => 'MapOfCfn::Resource::Properties::AWS::QuickSight::DataSet::FieldFolder', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ImportMode => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has IngestionWaitPolicy => (isa => 'Cfn::Resource::Properties::AWS::QuickSight::DataSet::IngestionWaitPolicy', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has LogicalTableMap => (isa => 'MapOfCfn::Resource::Properties::AWS::QuickSight::DataSet::LogicalTable', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Permissions => (isa => 'ArrayOfCfn::Resource::Properties::AWS::QuickSight::DataSet::ResourcePermission', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has PhysicalTableMap => (isa => 'MapOfCfn::Resource::Properties::AWS::QuickSight::DataSet::PhysicalTable', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RowLevelPermissionDataSet => (isa => 'Cfn::Resource::Properties::AWS::QuickSight::DataSet::RowLevelPermissionDataSet', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Tags => (isa => 'ArrayOfCfn::Resource::Properties::TagType', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::QuickSight::DataSet - Cfn resource for AWS::QuickSight::DataSet

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::QuickSight::DataSet.

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
