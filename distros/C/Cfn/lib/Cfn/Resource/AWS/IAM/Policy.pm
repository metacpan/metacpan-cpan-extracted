# AWS::IAM::Policy generated from spec 2.22.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::IAM::Policy',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::IAM::Policy->new( %$_ ) };

package Cfn::Resource::AWS::IAM::Policy {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::IAM::Policy', is => 'rw', coerce => 1);
  sub _build_attributes {
    [  ]
  }
  sub addStatement {
    my ($self, @args) = @_;
    require Moose::Util::TypeConstraints;
    my @statements = map { Moose::Util::TypeConstraints::find_type_constraint('Cfn::Value')->coerce($_) } @args;
    push @{ $self->Properties->PolicyDocument->Value->{Statement}->Value }, @statements;
  }
  
}



package Cfn::Resource::Properties::AWS::IAM::Policy {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has Groups => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has PolicyDocument => (isa => 'Cfn::Value::Json|Cfn::DynamicValue', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has PolicyName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Roles => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Users => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
