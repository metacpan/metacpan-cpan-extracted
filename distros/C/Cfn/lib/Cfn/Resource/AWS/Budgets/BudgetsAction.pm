# AWS::Budgets::BudgetsAction generated from spec 34.0.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::Budgets::BudgetsAction',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::Budgets::BudgetsAction->new( %$_ ) };

package Cfn::Resource::AWS::Budgets::BudgetsAction {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::Budgets::BudgetsAction', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [ 'ActionId' ]
  }
  sub supported_regions {
    [ 'ap-northeast-1','ap-northeast-2','ap-south-1','ap-southeast-1','ap-southeast-2','ca-central-1','cn-north-1','cn-northwest-1','eu-central-1','eu-west-1','eu-west-2','eu-west-3','sa-east-1','us-east-1','us-east-2','us-west-1','us-west-2' ]
  }
}



subtype 'Cfn::Resource::Properties::AWS::Budgets::BudgetsAction::SsmActionDefinition',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Budgets::BudgetsAction::SsmActionDefinition',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Budgets::BudgetsAction::SsmActionDefinition->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Budgets::BudgetsAction::SsmActionDefinition {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has InstanceIds => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Region => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Subtype => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::Budgets::BudgetsAction::ScpActionDefinition',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Budgets::BudgetsAction::ScpActionDefinition',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Budgets::BudgetsAction::ScpActionDefinition->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Budgets::BudgetsAction::ScpActionDefinition {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has PolicyId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TargetIds => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::Budgets::BudgetsAction::IamActionDefinition',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Budgets::BudgetsAction::IamActionDefinition',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Budgets::BudgetsAction::IamActionDefinition->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Budgets::BudgetsAction::IamActionDefinition {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Groups => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has PolicyArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Roles => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Users => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::Budgets::BudgetsAction::Subscriber',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::Budgets::BudgetsAction::Subscriber',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::Budgets::BudgetsAction::Subscriber')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::Budgets::BudgetsAction::Subscriber',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Budgets::BudgetsAction::Subscriber',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Budgets::BudgetsAction::Subscriber->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Budgets::BudgetsAction::Subscriber {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Address => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Type => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::Budgets::BudgetsAction::Definition',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Budgets::BudgetsAction::Definition',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Budgets::BudgetsAction::Definition->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Budgets::BudgetsAction::Definition {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has IamActionDefinition => (isa => 'Cfn::Resource::Properties::AWS::Budgets::BudgetsAction::IamActionDefinition', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ScpActionDefinition => (isa => 'Cfn::Resource::Properties::AWS::Budgets::BudgetsAction::ScpActionDefinition', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SsmActionDefinition => (isa => 'Cfn::Resource::Properties::AWS::Budgets::BudgetsAction::SsmActionDefinition', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::Budgets::BudgetsAction::ActionThreshold',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Budgets::BudgetsAction::ActionThreshold',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Budgets::BudgetsAction::ActionThreshold->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Budgets::BudgetsAction::ActionThreshold {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Type => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Value => (isa => 'Cfn::Value::Double', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::Budgets::BudgetsAction {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has ActionThreshold => (isa => 'Cfn::Resource::Properties::AWS::Budgets::BudgetsAction::ActionThreshold', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ActionType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has ApprovalModel => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has BudgetName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Definition => (isa => 'Cfn::Resource::Properties::AWS::Budgets::BudgetsAction::Definition', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ExecutionRoleArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has NotificationType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Subscribers => (isa => 'ArrayOfCfn::Resource::Properties::AWS::Budgets::BudgetsAction::Subscriber', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::Budgets::BudgetsAction - Cfn resource for AWS::Budgets::BudgetsAction

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::Budgets::BudgetsAction.

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
