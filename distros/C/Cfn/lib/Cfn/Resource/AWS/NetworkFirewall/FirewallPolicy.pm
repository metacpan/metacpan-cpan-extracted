# AWS::NetworkFirewall::FirewallPolicy generated from spec 34.0.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::NetworkFirewall::FirewallPolicy',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::NetworkFirewall::FirewallPolicy->new( %$_ ) };

package Cfn::Resource::AWS::NetworkFirewall::FirewallPolicy {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::NetworkFirewall::FirewallPolicy', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [ 'FirewallPolicyArn','FirewallPolicyId' ]
  }
  sub supported_regions {
    [ 'ap-northeast-1','ap-southeast-2','eu-central-1','eu-north-1','eu-west-1','us-east-1','us-east-2','us-west-2' ]
  }
}


subtype 'ArrayOfCfn::Resource::Properties::AWS::NetworkFirewall::FirewallPolicy::Dimension',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::NetworkFirewall::FirewallPolicy::Dimension',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::NetworkFirewall::FirewallPolicy::Dimension')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::NetworkFirewall::FirewallPolicy::Dimension',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::NetworkFirewall::FirewallPolicy::Dimension',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::NetworkFirewall::FirewallPolicy::Dimension->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::NetworkFirewall::FirewallPolicy::Dimension {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Value => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::NetworkFirewall::FirewallPolicy::PublishMetricAction',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::NetworkFirewall::FirewallPolicy::PublishMetricAction',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::NetworkFirewall::FirewallPolicy::PublishMetricAction->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::NetworkFirewall::FirewallPolicy::PublishMetricAction {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Dimensions => (isa => 'ArrayOfCfn::Resource::Properties::AWS::NetworkFirewall::FirewallPolicy::Dimension', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::NetworkFirewall::FirewallPolicy::ActionDefinition',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::NetworkFirewall::FirewallPolicy::ActionDefinition',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::NetworkFirewall::FirewallPolicy::ActionDefinition->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::NetworkFirewall::FirewallPolicy::ActionDefinition {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has PublishMetricAction => (isa => 'Cfn::Resource::Properties::AWS::NetworkFirewall::FirewallPolicy::PublishMetricAction', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::NetworkFirewall::FirewallPolicy::StatelessRuleGroupReference',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::NetworkFirewall::FirewallPolicy::StatelessRuleGroupReference',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::NetworkFirewall::FirewallPolicy::StatelessRuleGroupReference')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::NetworkFirewall::FirewallPolicy::StatelessRuleGroupReference',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::NetworkFirewall::FirewallPolicy::StatelessRuleGroupReference',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::NetworkFirewall::FirewallPolicy::StatelessRuleGroupReference->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::NetworkFirewall::FirewallPolicy::StatelessRuleGroupReference {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Priority => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ResourceArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::NetworkFirewall::FirewallPolicy::StatefulRuleGroupReference',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::NetworkFirewall::FirewallPolicy::StatefulRuleGroupReference',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::NetworkFirewall::FirewallPolicy::StatefulRuleGroupReference')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::NetworkFirewall::FirewallPolicy::StatefulRuleGroupReference',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::NetworkFirewall::FirewallPolicy::StatefulRuleGroupReference',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::NetworkFirewall::FirewallPolicy::StatefulRuleGroupReference->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::NetworkFirewall::FirewallPolicy::StatefulRuleGroupReference {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ResourceArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::NetworkFirewall::FirewallPolicy::CustomAction',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::NetworkFirewall::FirewallPolicy::CustomAction',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::NetworkFirewall::FirewallPolicy::CustomAction')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::NetworkFirewall::FirewallPolicy::CustomAction',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::NetworkFirewall::FirewallPolicy::CustomAction',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::NetworkFirewall::FirewallPolicy::CustomAction->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::NetworkFirewall::FirewallPolicy::CustomAction {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ActionDefinition => (isa => 'Cfn::Resource::Properties::AWS::NetworkFirewall::FirewallPolicy::ActionDefinition', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ActionName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::NetworkFirewall::FirewallPolicy::FirewallPolicy',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::NetworkFirewall::FirewallPolicy::FirewallPolicy',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::NetworkFirewall::FirewallPolicy::FirewallPolicy->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::NetworkFirewall::FirewallPolicy::FirewallPolicy {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has StatefulRuleGroupReferences => (isa => 'ArrayOfCfn::Resource::Properties::AWS::NetworkFirewall::FirewallPolicy::StatefulRuleGroupReference', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has StatelessCustomActions => (isa => 'ArrayOfCfn::Resource::Properties::AWS::NetworkFirewall::FirewallPolicy::CustomAction', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has StatelessDefaultActions => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has StatelessFragmentDefaultActions => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has StatelessRuleGroupReferences => (isa => 'ArrayOfCfn::Resource::Properties::AWS::NetworkFirewall::FirewallPolicy::StatelessRuleGroupReference', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::NetworkFirewall::FirewallPolicy {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has Description => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has FirewallPolicy => (isa => 'Cfn::Resource::Properties::AWS::NetworkFirewall::FirewallPolicy::FirewallPolicy', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has FirewallPolicyName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Tags => (isa => 'ArrayOfCfn::Resource::Properties::TagType', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::NetworkFirewall::FirewallPolicy - Cfn resource for AWS::NetworkFirewall::FirewallPolicy

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::NetworkFirewall::FirewallPolicy.

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
