# AWS::IoTSiteWise::AssetModel generated from spec 34.0.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::IoTSiteWise::AssetModel',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::IoTSiteWise::AssetModel->new( %$_ ) };

package Cfn::Resource::AWS::IoTSiteWise::AssetModel {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::IoTSiteWise::AssetModel', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [ 'AssetModelArn','AssetModelId' ]
  }
  sub supported_regions {
    [ 'ap-southeast-1','ap-southeast-2','cn-north-1','eu-central-1','eu-west-1','us-east-1','us-west-2' ]
  }
}



subtype 'Cfn::Resource::Properties::AWS::IoTSiteWise::AssetModel::VariableValue',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoTSiteWise::AssetModel::VariableValue',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::IoTSiteWise::AssetModel::VariableValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::IoTSiteWise::AssetModel::VariableValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has HierarchyLogicalId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has PropertyLogicalId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::IoTSiteWise::AssetModel::TumblingWindow',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoTSiteWise::AssetModel::TumblingWindow',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::IoTSiteWise::AssetModel::TumblingWindow->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::IoTSiteWise::AssetModel::TumblingWindow {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Interval => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::IoTSiteWise::AssetModel::MetricWindow',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoTSiteWise::AssetModel::MetricWindow',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::IoTSiteWise::AssetModel::MetricWindow->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::IoTSiteWise::AssetModel::MetricWindow {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Tumbling => (isa => 'Cfn::Resource::Properties::AWS::IoTSiteWise::AssetModel::TumblingWindow', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::IoTSiteWise::AssetModel::ExpressionVariable',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::IoTSiteWise::AssetModel::ExpressionVariable',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::IoTSiteWise::AssetModel::ExpressionVariable')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::IoTSiteWise::AssetModel::ExpressionVariable',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoTSiteWise::AssetModel::ExpressionVariable',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::IoTSiteWise::AssetModel::ExpressionVariable->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::IoTSiteWise::AssetModel::ExpressionVariable {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Value => (isa => 'Cfn::Resource::Properties::AWS::IoTSiteWise::AssetModel::VariableValue', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::IoTSiteWise::AssetModel::Transform',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoTSiteWise::AssetModel::Transform',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::IoTSiteWise::AssetModel::Transform->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::IoTSiteWise::AssetModel::Transform {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Expression => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Variables => (isa => 'ArrayOfCfn::Resource::Properties::AWS::IoTSiteWise::AssetModel::ExpressionVariable', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::IoTSiteWise::AssetModel::Metric',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoTSiteWise::AssetModel::Metric',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::IoTSiteWise::AssetModel::Metric->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::IoTSiteWise::AssetModel::Metric {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Expression => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Variables => (isa => 'ArrayOfCfn::Resource::Properties::AWS::IoTSiteWise::AssetModel::ExpressionVariable', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Window => (isa => 'Cfn::Resource::Properties::AWS::IoTSiteWise::AssetModel::MetricWindow', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::IoTSiteWise::AssetModel::Attribute',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoTSiteWise::AssetModel::Attribute',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::IoTSiteWise::AssetModel::Attribute->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::IoTSiteWise::AssetModel::Attribute {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has DefaultValue => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::IoTSiteWise::AssetModel::PropertyType',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoTSiteWise::AssetModel::PropertyType',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::IoTSiteWise::AssetModel::PropertyType->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::IoTSiteWise::AssetModel::PropertyType {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Attribute => (isa => 'Cfn::Resource::Properties::AWS::IoTSiteWise::AssetModel::Attribute', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Metric => (isa => 'Cfn::Resource::Properties::AWS::IoTSiteWise::AssetModel::Metric', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Transform => (isa => 'Cfn::Resource::Properties::AWS::IoTSiteWise::AssetModel::Transform', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TypeName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::IoTSiteWise::AssetModel::AssetModelProperty',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::IoTSiteWise::AssetModel::AssetModelProperty',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::IoTSiteWise::AssetModel::AssetModelProperty')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::IoTSiteWise::AssetModel::AssetModelProperty',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoTSiteWise::AssetModel::AssetModelProperty',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::IoTSiteWise::AssetModel::AssetModelProperty->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::IoTSiteWise::AssetModel::AssetModelProperty {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has DataType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DataTypeSpec => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has LogicalId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Type => (isa => 'Cfn::Resource::Properties::AWS::IoTSiteWise::AssetModel::PropertyType', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Unit => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::IoTSiteWise::AssetModel::AssetModelHierarchy',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::IoTSiteWise::AssetModel::AssetModelHierarchy',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::IoTSiteWise::AssetModel::AssetModelHierarchy')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::IoTSiteWise::AssetModel::AssetModelHierarchy',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoTSiteWise::AssetModel::AssetModelHierarchy',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::IoTSiteWise::AssetModel::AssetModelHierarchy->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::IoTSiteWise::AssetModel::AssetModelHierarchy {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ChildAssetModelId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has LogicalId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::IoTSiteWise::AssetModel::AssetModelCompositeModel',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::IoTSiteWise::AssetModel::AssetModelCompositeModel',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::IoTSiteWise::AssetModel::AssetModelCompositeModel')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::IoTSiteWise::AssetModel::AssetModelCompositeModel',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoTSiteWise::AssetModel::AssetModelCompositeModel',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::IoTSiteWise::AssetModel::AssetModelCompositeModel->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::IoTSiteWise::AssetModel::AssetModelCompositeModel {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has CompositeModelProperties => (isa => 'ArrayOfCfn::Resource::Properties::AWS::IoTSiteWise::AssetModel::AssetModelProperty', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Description => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Type => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::IoTSiteWise::AssetModel {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has AssetModelCompositeModels => (isa => 'ArrayOfCfn::Resource::Properties::AWS::IoTSiteWise::AssetModel::AssetModelCompositeModel', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has AssetModelDescription => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has AssetModelHierarchies => (isa => 'ArrayOfCfn::Resource::Properties::AWS::IoTSiteWise::AssetModel::AssetModelHierarchy', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has AssetModelName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has AssetModelProperties => (isa => 'ArrayOfCfn::Resource::Properties::AWS::IoTSiteWise::AssetModel::AssetModelProperty', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Tags => (isa => 'ArrayOfCfn::Resource::Properties::TagType', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::IoTSiteWise::AssetModel - Cfn resource for AWS::IoTSiteWise::AssetModel

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::IoTSiteWise::AssetModel.

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
