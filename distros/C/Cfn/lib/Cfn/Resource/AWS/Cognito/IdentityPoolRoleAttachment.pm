# AWS::Cognito::IdentityPoolRoleAttachment generated from spec 2.22.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::Cognito::IdentityPoolRoleAttachment',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::Cognito::IdentityPoolRoleAttachment->new( %$_ ) };

package Cfn::Resource::AWS::Cognito::IdentityPoolRoleAttachment {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::Cognito::IdentityPoolRoleAttachment', is => 'rw', coerce => 1);
  sub _build_attributes {
    [  ]
  }
}


subtype 'ArrayOfCfn::Resource::Properties::AWS::Cognito::IdentityPoolRoleAttachment::MappingRule',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::Cognito::IdentityPoolRoleAttachment::MappingRule',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::Cognito::IdentityPoolRoleAttachment::MappingRule')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::Cognito::IdentityPoolRoleAttachment::MappingRule',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Cognito::IdentityPoolRoleAttachment::MappingRule',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::Cognito::IdentityPoolRoleAttachment::MappingRuleValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::Cognito::IdentityPoolRoleAttachment::MappingRuleValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Claim => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has MatchType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RoleARN => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Value => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::Cognito::IdentityPoolRoleAttachment::RulesConfigurationType',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Cognito::IdentityPoolRoleAttachment::RulesConfigurationType',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::Cognito::IdentityPoolRoleAttachment::RulesConfigurationTypeValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::Cognito::IdentityPoolRoleAttachment::RulesConfigurationTypeValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Rules => (isa => 'ArrayOfCfn::Resource::Properties::AWS::Cognito::IdentityPoolRoleAttachment::MappingRule', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::Cognito::IdentityPoolRoleAttachment::RoleMapping',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Cognito::IdentityPoolRoleAttachment::RoleMapping',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::Cognito::IdentityPoolRoleAttachment::RoleMappingValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::Cognito::IdentityPoolRoleAttachment::RoleMappingValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AmbiguousRoleResolution => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RulesConfiguration => (isa => 'Cfn::Resource::Properties::AWS::Cognito::IdentityPoolRoleAttachment::RulesConfigurationType', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Type => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::Cognito::IdentityPoolRoleAttachment {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has IdentityPoolId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has RoleMappings => (isa => 'Cfn::Value::Json|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Roles => (isa => 'Cfn::Value::Json|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
