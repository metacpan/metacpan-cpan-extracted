# AWS::SageMaker::NotebookInstanceLifecycleConfig generated from spec 18.4.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::SageMaker::NotebookInstanceLifecycleConfig',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::SageMaker::NotebookInstanceLifecycleConfig->new( %$_ ) };

package Cfn::Resource::AWS::SageMaker::NotebookInstanceLifecycleConfig {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::SageMaker::NotebookInstanceLifecycleConfig', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [ 'NotebookInstanceLifecycleConfigName' ]
  }
  sub supported_regions {
    [ 'ap-northeast-1','eu-west-1','us-east-1','us-east-2','us-west-2' ]
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
       return Cfn::Resource::Properties::Object::AWS::SageMaker::NotebookInstanceLifecycleConfig::NotebookInstanceLifecycleHook->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::SageMaker::NotebookInstanceLifecycleConfig::NotebookInstanceLifecycleHook {
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
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::SageMaker::NotebookInstanceLifecycleConfig - Cfn resource for AWS::SageMaker::NotebookInstanceLifecycleConfig

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::SageMaker::NotebookInstanceLifecycleConfig.

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
