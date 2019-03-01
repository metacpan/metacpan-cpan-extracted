# AWS::DLM::LifecyclePolicy generated from spec 2.22.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::DLM::LifecyclePolicy',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::DLM::LifecyclePolicy->new( %$_ ) };

package Cfn::Resource::AWS::DLM::LifecyclePolicy {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::DLM::LifecyclePolicy', is => 'rw', coerce => 1);
  sub _build_attributes {
    [ 'Arn' ]
  }
}



subtype 'Cfn::Resource::Properties::AWS::DLM::LifecyclePolicy::RetainRule',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::DLM::LifecyclePolicy::RetainRule',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::DLM::LifecyclePolicy::RetainRuleValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::DLM::LifecyclePolicy::RetainRuleValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Count => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::DLM::LifecyclePolicy::CreateRule',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::DLM::LifecyclePolicy::CreateRule',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::DLM::LifecyclePolicy::CreateRuleValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::DLM::LifecyclePolicy::CreateRuleValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Interval => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has IntervalUnit => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Times => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::DLM::LifecyclePolicy::Schedule',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::DLM::LifecyclePolicy::Schedule',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::DLM::LifecyclePolicy::Schedule')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::DLM::LifecyclePolicy::Schedule',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::DLM::LifecyclePolicy::Schedule',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::DLM::LifecyclePolicy::ScheduleValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::DLM::LifecyclePolicy::ScheduleValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has CopyTags => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has CreateRule => (isa => 'Cfn::Resource::Properties::AWS::DLM::LifecyclePolicy::CreateRule', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RetainRule => (isa => 'Cfn::Resource::Properties::AWS::DLM::LifecyclePolicy::RetainRule', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TagsToAdd => (isa => 'ArrayOfCfn::Resource::Properties::TagType', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::DLM::LifecyclePolicy::PolicyDetails',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::DLM::LifecyclePolicy::PolicyDetails',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::DLM::LifecyclePolicy::PolicyDetailsValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::DLM::LifecyclePolicy::PolicyDetailsValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ResourceTypes => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Schedules => (isa => 'ArrayOfCfn::Resource::Properties::AWS::DLM::LifecyclePolicy::Schedule', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TargetTags => (isa => 'ArrayOfCfn::Resource::Properties::TagType', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::DLM::LifecyclePolicy {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has Description => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ExecutionRoleArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has PolicyDetails => (isa => 'Cfn::Resource::Properties::AWS::DLM::LifecyclePolicy::PolicyDetails', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has State => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
