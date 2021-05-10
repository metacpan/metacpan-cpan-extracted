# AWS::IoTAnalytics::Dataset generated from spec 34.0.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::IoTAnalytics::Dataset',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::IoTAnalytics::Dataset->new( %$_ ) };

package Cfn::Resource::AWS::IoTAnalytics::Dataset {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::IoTAnalytics::Dataset', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [  ]
  }
  sub supported_regions {
    [ 'ap-northeast-1','ap-southeast-2','cn-north-1','eu-central-1','eu-west-1','us-east-1','us-east-2','us-west-2' ]
  }
}



subtype 'Cfn::Resource::Properties::AWS::IoTAnalytics::Dataset::OutputFileUriValue',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoTAnalytics::Dataset::OutputFileUriValue',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::IoTAnalytics::Dataset::OutputFileUriValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::IoTAnalytics::Dataset::OutputFileUriValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has FileName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::IoTAnalytics::Dataset::GlueConfiguration',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoTAnalytics::Dataset::GlueConfiguration',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::IoTAnalytics::Dataset::GlueConfiguration->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::IoTAnalytics::Dataset::GlueConfiguration {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has DatabaseName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TableName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::IoTAnalytics::Dataset::DeltaTime',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoTAnalytics::Dataset::DeltaTime',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::IoTAnalytics::Dataset::DeltaTime->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::IoTAnalytics::Dataset::DeltaTime {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has OffsetSeconds => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TimeExpression => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::IoTAnalytics::Dataset::DatasetContentVersionValue',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoTAnalytics::Dataset::DatasetContentVersionValue',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::IoTAnalytics::Dataset::DatasetContentVersionValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::IoTAnalytics::Dataset::DatasetContentVersionValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has DatasetName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::IoTAnalytics::Dataset::Variable',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::IoTAnalytics::Dataset::Variable',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::IoTAnalytics::Dataset::Variable')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::IoTAnalytics::Dataset::Variable',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoTAnalytics::Dataset::Variable',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::IoTAnalytics::Dataset::Variable->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::IoTAnalytics::Dataset::Variable {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has DatasetContentVersionValue => (isa => 'Cfn::Resource::Properties::AWS::IoTAnalytics::Dataset::DatasetContentVersionValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DoubleValue => (isa => 'Cfn::Value::Double', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has OutputFileUriValue => (isa => 'Cfn::Resource::Properties::AWS::IoTAnalytics::Dataset::OutputFileUriValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has StringValue => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has VariableName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::IoTAnalytics::Dataset::S3DestinationConfiguration',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoTAnalytics::Dataset::S3DestinationConfiguration',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::IoTAnalytics::Dataset::S3DestinationConfiguration->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::IoTAnalytics::Dataset::S3DestinationConfiguration {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Bucket => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has GlueConfiguration => (isa => 'Cfn::Resource::Properties::AWS::IoTAnalytics::Dataset::GlueConfiguration', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Key => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RoleArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::IoTAnalytics::Dataset::ResourceConfiguration',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoTAnalytics::Dataset::ResourceConfiguration',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::IoTAnalytics::Dataset::ResourceConfiguration->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::IoTAnalytics::Dataset::ResourceConfiguration {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ComputeType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has VolumeSizeInGB => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::IoTAnalytics::Dataset::IotEventsDestinationConfiguration',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoTAnalytics::Dataset::IotEventsDestinationConfiguration',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::IoTAnalytics::Dataset::IotEventsDestinationConfiguration->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::IoTAnalytics::Dataset::IotEventsDestinationConfiguration {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has InputName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RoleArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::IoTAnalytics::Dataset::Filter',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::IoTAnalytics::Dataset::Filter',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::IoTAnalytics::Dataset::Filter')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::IoTAnalytics::Dataset::Filter',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoTAnalytics::Dataset::Filter',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::IoTAnalytics::Dataset::Filter->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::IoTAnalytics::Dataset::Filter {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has DeltaTime => (isa => 'Cfn::Resource::Properties::AWS::IoTAnalytics::Dataset::DeltaTime', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::IoTAnalytics::Dataset::DeltaTimeSessionWindowConfiguration',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoTAnalytics::Dataset::DeltaTimeSessionWindowConfiguration',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::IoTAnalytics::Dataset::DeltaTimeSessionWindowConfiguration->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::IoTAnalytics::Dataset::DeltaTimeSessionWindowConfiguration {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has TimeoutInMinutes => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::IoTAnalytics::Dataset::TriggeringDataset',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoTAnalytics::Dataset::TriggeringDataset',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::IoTAnalytics::Dataset::TriggeringDataset->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::IoTAnalytics::Dataset::TriggeringDataset {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has DatasetName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::IoTAnalytics::Dataset::Schedule',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoTAnalytics::Dataset::Schedule',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::IoTAnalytics::Dataset::Schedule->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::IoTAnalytics::Dataset::Schedule {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ScheduleExpression => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::IoTAnalytics::Dataset::QueryAction',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoTAnalytics::Dataset::QueryAction',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::IoTAnalytics::Dataset::QueryAction->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::IoTAnalytics::Dataset::QueryAction {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Filters => (isa => 'ArrayOfCfn::Resource::Properties::AWS::IoTAnalytics::Dataset::Filter', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SqlQuery => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::IoTAnalytics::Dataset::LateDataRuleConfiguration',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoTAnalytics::Dataset::LateDataRuleConfiguration',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::IoTAnalytics::Dataset::LateDataRuleConfiguration->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::IoTAnalytics::Dataset::LateDataRuleConfiguration {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has DeltaTimeSessionWindowConfiguration => (isa => 'Cfn::Resource::Properties::AWS::IoTAnalytics::Dataset::DeltaTimeSessionWindowConfiguration', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::IoTAnalytics::Dataset::DatasetContentDeliveryRuleDestination',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoTAnalytics::Dataset::DatasetContentDeliveryRuleDestination',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::IoTAnalytics::Dataset::DatasetContentDeliveryRuleDestination->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::IoTAnalytics::Dataset::DatasetContentDeliveryRuleDestination {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has IotEventsDestinationConfiguration => (isa => 'Cfn::Resource::Properties::AWS::IoTAnalytics::Dataset::IotEventsDestinationConfiguration', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has S3DestinationConfiguration => (isa => 'Cfn::Resource::Properties::AWS::IoTAnalytics::Dataset::S3DestinationConfiguration', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::IoTAnalytics::Dataset::ContainerAction',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoTAnalytics::Dataset::ContainerAction',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::IoTAnalytics::Dataset::ContainerAction->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::IoTAnalytics::Dataset::ContainerAction {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ExecutionRoleArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Image => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ResourceConfiguration => (isa => 'Cfn::Resource::Properties::AWS::IoTAnalytics::Dataset::ResourceConfiguration', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Variables => (isa => 'ArrayOfCfn::Resource::Properties::AWS::IoTAnalytics::Dataset::Variable', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::IoTAnalytics::Dataset::VersioningConfiguration',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoTAnalytics::Dataset::VersioningConfiguration',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::IoTAnalytics::Dataset::VersioningConfiguration->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::IoTAnalytics::Dataset::VersioningConfiguration {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has MaxVersions => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Unlimited => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::IoTAnalytics::Dataset::Trigger',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::IoTAnalytics::Dataset::Trigger',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::IoTAnalytics::Dataset::Trigger')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::IoTAnalytics::Dataset::Trigger',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoTAnalytics::Dataset::Trigger',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::IoTAnalytics::Dataset::Trigger->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::IoTAnalytics::Dataset::Trigger {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Schedule => (isa => 'Cfn::Resource::Properties::AWS::IoTAnalytics::Dataset::Schedule', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TriggeringDataset => (isa => 'Cfn::Resource::Properties::AWS::IoTAnalytics::Dataset::TriggeringDataset', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::IoTAnalytics::Dataset::RetentionPeriod',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoTAnalytics::Dataset::RetentionPeriod',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::IoTAnalytics::Dataset::RetentionPeriod->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::IoTAnalytics::Dataset::RetentionPeriod {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has NumberOfDays => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Unlimited => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::IoTAnalytics::Dataset::LateDataRule',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::IoTAnalytics::Dataset::LateDataRule',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::IoTAnalytics::Dataset::LateDataRule')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::IoTAnalytics::Dataset::LateDataRule',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoTAnalytics::Dataset::LateDataRule',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::IoTAnalytics::Dataset::LateDataRule->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::IoTAnalytics::Dataset::LateDataRule {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has RuleConfiguration => (isa => 'Cfn::Resource::Properties::AWS::IoTAnalytics::Dataset::LateDataRuleConfiguration', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RuleName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::IoTAnalytics::Dataset::DatasetContentDeliveryRule',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::IoTAnalytics::Dataset::DatasetContentDeliveryRule',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::IoTAnalytics::Dataset::DatasetContentDeliveryRule')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::IoTAnalytics::Dataset::DatasetContentDeliveryRule',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoTAnalytics::Dataset::DatasetContentDeliveryRule',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::IoTAnalytics::Dataset::DatasetContentDeliveryRule->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::IoTAnalytics::Dataset::DatasetContentDeliveryRule {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Destination => (isa => 'Cfn::Resource::Properties::AWS::IoTAnalytics::Dataset::DatasetContentDeliveryRuleDestination', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has EntryName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::IoTAnalytics::Dataset::Action',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::IoTAnalytics::Dataset::Action',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::IoTAnalytics::Dataset::Action')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::IoTAnalytics::Dataset::Action',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoTAnalytics::Dataset::Action',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::IoTAnalytics::Dataset::Action->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::IoTAnalytics::Dataset::Action {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ActionName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ContainerAction => (isa => 'Cfn::Resource::Properties::AWS::IoTAnalytics::Dataset::ContainerAction', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has QueryAction => (isa => 'Cfn::Resource::Properties::AWS::IoTAnalytics::Dataset::QueryAction', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::IoTAnalytics::Dataset {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has Actions => (isa => 'ArrayOfCfn::Resource::Properties::AWS::IoTAnalytics::Dataset::Action', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ContentDeliveryRules => (isa => 'ArrayOfCfn::Resource::Properties::AWS::IoTAnalytics::Dataset::DatasetContentDeliveryRule', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DatasetName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has LateDataRules => (isa => 'ArrayOfCfn::Resource::Properties::AWS::IoTAnalytics::Dataset::LateDataRule', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RetentionPeriod => (isa => 'Cfn::Resource::Properties::AWS::IoTAnalytics::Dataset::RetentionPeriod', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Tags => (isa => 'ArrayOfCfn::Resource::Properties::TagType', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Triggers => (isa => 'ArrayOfCfn::Resource::Properties::AWS::IoTAnalytics::Dataset::Trigger', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has VersioningConfiguration => (isa => 'Cfn::Resource::Properties::AWS::IoTAnalytics::Dataset::VersioningConfiguration', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::IoTAnalytics::Dataset - Cfn resource for AWS::IoTAnalytics::Dataset

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::IoTAnalytics::Dataset.

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
