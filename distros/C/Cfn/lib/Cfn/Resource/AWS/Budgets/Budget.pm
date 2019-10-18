# AWS::Budgets::Budget generated from spec 6.3.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::Budgets::Budget',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::Budgets::Budget->new( %$_ ) };

package Cfn::Resource::AWS::Budgets::Budget {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::Budgets::Budget', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [  ]
  }
  sub supported_regions {
    [ 'ap-northeast-1','ap-northeast-2','ap-south-1','ap-southeast-1','ap-southeast-2','ca-central-1','eu-central-1','eu-west-1','eu-west-2','sa-east-1','us-east-1','us-east-2','us-west-1','us-west-2' ]
  }
}



subtype 'Cfn::Resource::Properties::AWS::Budgets::Budget::TimePeriod',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Budgets::Budget::TimePeriod',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::Budgets::Budget::TimePeriodValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::Budgets::Budget::TimePeriodValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has End => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Start => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::Budgets::Budget::Subscriber',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::Budgets::Budget::Subscriber',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::Budgets::Budget::Subscriber')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::Budgets::Budget::Subscriber',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Budgets::Budget::Subscriber',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::Budgets::Budget::SubscriberValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::Budgets::Budget::SubscriberValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Address => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SubscriptionType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::Budgets::Budget::Spend',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Budgets::Budget::Spend',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::Budgets::Budget::SpendValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::Budgets::Budget::SpendValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Amount => (isa => 'Cfn::Value::Double', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Unit => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::Budgets::Budget::Notification',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Budgets::Budget::Notification',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::Budgets::Budget::NotificationValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::Budgets::Budget::NotificationValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ComparisonOperator => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has NotificationType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Threshold => (isa => 'Cfn::Value::Double', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ThresholdType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::Budgets::Budget::CostTypes',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Budgets::Budget::CostTypes',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::Budgets::Budget::CostTypesValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::Budgets::Budget::CostTypesValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has IncludeCredit => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has IncludeDiscount => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has IncludeOtherSubscription => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has IncludeRecurring => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has IncludeRefund => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has IncludeSubscription => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has IncludeSupport => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has IncludeTax => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has IncludeUpfront => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has UseAmortized => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has UseBlended => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::Budgets::Budget::NotificationWithSubscribers',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::Budgets::Budget::NotificationWithSubscribers',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::Budgets::Budget::NotificationWithSubscribers')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::Budgets::Budget::NotificationWithSubscribers',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Budgets::Budget::NotificationWithSubscribers',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::Budgets::Budget::NotificationWithSubscribersValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::Budgets::Budget::NotificationWithSubscribersValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Notification => (isa => 'Cfn::Resource::Properties::AWS::Budgets::Budget::Notification', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Subscribers => (isa => 'ArrayOfCfn::Resource::Properties::AWS::Budgets::Budget::Subscriber', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::Budgets::Budget::BudgetData',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Budgets::Budget::BudgetData',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::Budgets::Budget::BudgetDataValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::Budgets::Budget::BudgetDataValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has BudgetLimit => (isa => 'Cfn::Resource::Properties::AWS::Budgets::Budget::Spend', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has BudgetName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has BudgetType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has CostFilters => (isa => 'Cfn::Value::Json|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has CostTypes => (isa => 'Cfn::Resource::Properties::AWS::Budgets::Budget::CostTypes', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has PlannedBudgetLimits => (isa => 'Cfn::Value::Json|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has TimePeriod => (isa => 'Cfn::Resource::Properties::AWS::Budgets::Budget::TimePeriod', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TimeUnit => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::Budgets::Budget {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has Budget => (isa => 'Cfn::Resource::Properties::AWS::Budgets::Budget::BudgetData', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has NotificationsWithSubscribers => (isa => 'ArrayOfCfn::Resource::Properties::AWS::Budgets::Budget::NotificationWithSubscribers', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

1;
