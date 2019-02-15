# AWS::ECR::Repository generated from spec 1.11.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::ECR::Repository',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::ECR::Repository->new( %$_ ) };

package Cfn::Resource::AWS::ECR::Repository {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::ECR::Repository', is => 'rw', coerce => 1);
  sub _build_attributes {
    [ 'Arn' ]
  }
}



subtype 'Cfn::Resource::Properties::AWS::ECR::Repository::LifecyclePolicy',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::ECR::Repository::LifecyclePolicy',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::ECR::Repository::LifecyclePolicyValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::ECR::Repository::LifecyclePolicyValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has LifecyclePolicyText => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RegistryId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::ECR::Repository {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has LifecyclePolicy => (isa => 'Cfn::Resource::Properties::AWS::ECR::Repository::LifecyclePolicy', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RepositoryName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has RepositoryPolicyText => (isa => 'Cfn::Value::Json', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
