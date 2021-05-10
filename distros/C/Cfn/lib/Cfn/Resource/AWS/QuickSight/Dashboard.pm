# AWS::QuickSight::Dashboard generated from spec 34.0.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::QuickSight::Dashboard',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::QuickSight::Dashboard->new( %$_ ) };

package Cfn::Resource::AWS::QuickSight::Dashboard {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::QuickSight::Dashboard', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [ 'Arn','CreatedTime','LastPublishedTime','LastUpdatedTime' ]
  }
  sub supported_regions {
    [ 'ap-northeast-1','ap-northeast-2','ap-south-1','ap-southeast-1','ap-southeast-2','ca-central-1','eu-central-1','eu-west-1','eu-west-2','sa-east-1','us-east-1','us-east-2','us-gov-west-1','us-west-2' ]
  }
}


subtype 'ArrayOfCfn::Resource::Properties::AWS::QuickSight::Dashboard::DataSetReference',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::QuickSight::Dashboard::DataSetReference',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::QuickSight::Dashboard::DataSetReference')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::QuickSight::Dashboard::DataSetReference',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::QuickSight::Dashboard::DataSetReference',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::QuickSight::Dashboard::DataSetReference->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::QuickSight::Dashboard::DataSetReference {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has DataSetArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DataSetPlaceholder => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::QuickSight::Dashboard::StringParameter',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::QuickSight::Dashboard::StringParameter',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::QuickSight::Dashboard::StringParameter')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::QuickSight::Dashboard::StringParameter',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::QuickSight::Dashboard::StringParameter',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::QuickSight::Dashboard::StringParameter->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::QuickSight::Dashboard::StringParameter {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Values => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::QuickSight::Dashboard::SheetControlsOption',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::QuickSight::Dashboard::SheetControlsOption',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::QuickSight::Dashboard::SheetControlsOption->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::QuickSight::Dashboard::SheetControlsOption {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has VisibilityState => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::QuickSight::Dashboard::IntegerParameter',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::QuickSight::Dashboard::IntegerParameter',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::QuickSight::Dashboard::IntegerParameter')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::QuickSight::Dashboard::IntegerParameter',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::QuickSight::Dashboard::IntegerParameter',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::QuickSight::Dashboard::IntegerParameter->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::QuickSight::Dashboard::IntegerParameter {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Values => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::QuickSight::Dashboard::ExportToCSVOption',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::QuickSight::Dashboard::ExportToCSVOption',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::QuickSight::Dashboard::ExportToCSVOption->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::QuickSight::Dashboard::ExportToCSVOption {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AvailabilityStatus => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::QuickSight::Dashboard::DecimalParameter',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::QuickSight::Dashboard::DecimalParameter',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::QuickSight::Dashboard::DecimalParameter')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::QuickSight::Dashboard::DecimalParameter',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::QuickSight::Dashboard::DecimalParameter',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::QuickSight::Dashboard::DecimalParameter->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::QuickSight::Dashboard::DecimalParameter {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Values => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::QuickSight::Dashboard::DateTimeParameter',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::QuickSight::Dashboard::DateTimeParameter',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::QuickSight::Dashboard::DateTimeParameter')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::QuickSight::Dashboard::DateTimeParameter',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::QuickSight::Dashboard::DateTimeParameter',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::QuickSight::Dashboard::DateTimeParameter->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::QuickSight::Dashboard::DateTimeParameter {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Values => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::QuickSight::Dashboard::DashboardSourceTemplate',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::QuickSight::Dashboard::DashboardSourceTemplate',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::QuickSight::Dashboard::DashboardSourceTemplate->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::QuickSight::Dashboard::DashboardSourceTemplate {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Arn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DataSetReferences => (isa => 'ArrayOfCfn::Resource::Properties::AWS::QuickSight::Dashboard::DataSetReference', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::QuickSight::Dashboard::AdHocFilteringOption',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::QuickSight::Dashboard::AdHocFilteringOption',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::QuickSight::Dashboard::AdHocFilteringOption->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::QuickSight::Dashboard::AdHocFilteringOption {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AvailabilityStatus => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::QuickSight::Dashboard::ResourcePermission',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::QuickSight::Dashboard::ResourcePermission',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::QuickSight::Dashboard::ResourcePermission')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::QuickSight::Dashboard::ResourcePermission',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::QuickSight::Dashboard::ResourcePermission',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::QuickSight::Dashboard::ResourcePermission->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::QuickSight::Dashboard::ResourcePermission {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Actions => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Principal => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::QuickSight::Dashboard::Parameters',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::QuickSight::Dashboard::Parameters',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::QuickSight::Dashboard::Parameters->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::QuickSight::Dashboard::Parameters {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has DateTimeParameters => (isa => 'ArrayOfCfn::Resource::Properties::AWS::QuickSight::Dashboard::DateTimeParameter', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DecimalParameters => (isa => 'ArrayOfCfn::Resource::Properties::AWS::QuickSight::Dashboard::DecimalParameter', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has IntegerParameters => (isa => 'ArrayOfCfn::Resource::Properties::AWS::QuickSight::Dashboard::IntegerParameter', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has StringParameters => (isa => 'ArrayOfCfn::Resource::Properties::AWS::QuickSight::Dashboard::StringParameter', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::QuickSight::Dashboard::DashboardSourceEntity',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::QuickSight::Dashboard::DashboardSourceEntity',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::QuickSight::Dashboard::DashboardSourceEntity->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::QuickSight::Dashboard::DashboardSourceEntity {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has SourceTemplate => (isa => 'Cfn::Resource::Properties::AWS::QuickSight::Dashboard::DashboardSourceTemplate', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::QuickSight::Dashboard::DashboardPublishOptions',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::QuickSight::Dashboard::DashboardPublishOptions',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::QuickSight::Dashboard::DashboardPublishOptions->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::QuickSight::Dashboard::DashboardPublishOptions {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AdHocFilteringOption => (isa => 'Cfn::Resource::Properties::AWS::QuickSight::Dashboard::AdHocFilteringOption', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ExportToCSVOption => (isa => 'Cfn::Resource::Properties::AWS::QuickSight::Dashboard::ExportToCSVOption', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SheetControlsOption => (isa => 'Cfn::Resource::Properties::AWS::QuickSight::Dashboard::SheetControlsOption', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::QuickSight::Dashboard {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has AwsAccountId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has DashboardId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has DashboardPublishOptions => (isa => 'Cfn::Resource::Properties::AWS::QuickSight::Dashboard::DashboardPublishOptions', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Parameters => (isa => 'Cfn::Resource::Properties::AWS::QuickSight::Dashboard::Parameters', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Permissions => (isa => 'ArrayOfCfn::Resource::Properties::AWS::QuickSight::Dashboard::ResourcePermission', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SourceEntity => (isa => 'Cfn::Resource::Properties::AWS::QuickSight::Dashboard::DashboardSourceEntity', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Tags => (isa => 'ArrayOfCfn::Resource::Properties::TagType', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ThemeArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has VersionDescription => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::QuickSight::Dashboard - Cfn resource for AWS::QuickSight::Dashboard

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::QuickSight::Dashboard.

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
