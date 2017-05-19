use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::IAM::Policy',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::IAM::Policy->new( %$_ ) };

package Cfn::Resource::AWS::IAM::Policy {
  use Moose;
  use Moose::Util::TypeConstraints qw/find_type_constraint/;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::IAM::Policy', is => 'rw', coerce => 1, required => 1);

  sub addStatement {
    my ($self, @args) = @_;
    my @statements = map { find_type_constraint('Cfn::Value')->coerce($_) } @args;
    push @{ $self->Properties->PolicyDocument->Value->{Statement}->Value }, @statements;
  }
}

package Cfn::Resource::Properties::AWS::IAM::Policy {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  has Groups => (isa => 'Cfn::Value::Array|Cfn::Value::Function', is => 'rw', coerce => 1);
  has PolicyDocument => (isa => 'Cfn::Value', is => 'rw', coerce => 1, required => 1);
  has PolicyName => (isa => 'Cfn::Value', is => 'rw', coerce => 1, required => 1);
  has Roles => (isa => 'Cfn::Value::Array|Cfn::Value::Function', is => 'rw', coerce => 1);
  has Users => (isa => 'Cfn::Value::Array|Cfn::Value::Function', is => 'rw', coerce => 1);
}

1;
