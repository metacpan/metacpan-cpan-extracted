# AWS::SageMaker::NotebookInstanceLifecycleConfig generated from spec 2.5.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::SageMaker::NotebookInstanceLifecycleConfig',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::SageMaker::NotebookInstanceLifecycleConfig->new( %$_ ) };

package Cfn::Resource::AWS::SageMaker::NotebookInstanceLifecycleConfig {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::SageMaker::NotebookInstanceLifecycleConfig', is => 'rw', coerce => 1);
  sub _build_attributes {
    [ 'NotebookInstanceLifecycleConfigName' ]
  }
}


subtype 'ArrayOfCfn::Resource::Properties::AWS::SageMaker::NotebookInstanceLifecycleConfig::NotebookInstanceLifecycleHook',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::SageMaker::NotebookInstanceLifecycleConfig::NotebookInstanceLifecycleHook',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::SageMaker::NotebookInstanceLifecycleConfig::NotebookInstanceLifecycleHook')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::SageMaker::NotebookInstanceLifecycleConfig::NotebookInstanceLifecycleHook',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::SageMaker::NotebookInstanceLifecycleConfig::NotebookInstanceLifecycleHook',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::SageMaker::NotebookInstanceLifecycleConfig::NotebookInstanceLifecycleHookValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::SageMaker::NotebookInstanceLifecycleConfig::NotebookInstanceLifecycleHookValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Content => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::SageMaker::NotebookInstanceLifecycleConfig {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has NotebookInstanceLifecycleConfigName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has OnCreate => (isa => 'ArrayOfCfn::Resource::Properties::AWS::SageMaker::NotebookInstanceLifecycleConfig::NotebookInstanceLifecycleHook', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has OnStart => (isa => 'ArrayOfCfn::Resource::Properties::AWS::SageMaker::NotebookInstanceLifecycleConfig::NotebookInstanceLifecycleHook', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
