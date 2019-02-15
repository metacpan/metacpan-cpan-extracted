# AWS::SecretsManager::RotationSchedule generated from spec 2.15.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::SecretsManager::RotationSchedule',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::SecretsManager::RotationSchedule->new( %$_ ) };

package Cfn::Resource::AWS::SecretsManager::RotationSchedule {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::SecretsManager::RotationSchedule', is => 'rw', coerce => 1);
  sub _build_attributes {
    [  ]
  }
}



subtype 'Cfn::Resource::Properties::AWS::SecretsManager::RotationSchedule::RotationRules',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::SecretsManager::RotationSchedule::RotationRules',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::SecretsManager::RotationSchedule::RotationRulesValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::SecretsManager::RotationSchedule::RotationRulesValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AutomaticallyAfterDays => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::SecretsManager::RotationSchedule {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has RotationLambdaARN => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RotationRules => (isa => 'Cfn::Resource::Properties::AWS::SecretsManager::RotationSchedule::RotationRules', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SecretId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

1;
