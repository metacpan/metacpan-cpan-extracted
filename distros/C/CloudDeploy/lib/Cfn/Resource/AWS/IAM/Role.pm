use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::IAM::Role',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::IAM::Role->new( %$_ ) };

package Cfn::Resource::AWS::IAM::Role {
  use Moose;
  use Moose::Util::TypeConstraints qw/find_type_constraint/;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::IAM::Role', is => 'rw', coerce => 1, required => 1);

  sub addPolicy {
    my ($self, @args) = @_;
    my @policies = map { find_type_constraint('Cfn::Value')->coerce($_) } @args;
    push @{ $self->Properties->Policies->Value }, @policies;
  }
}

package Cfn::Resource::Properties::AWS::IAM::Role {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  has AssumeRolePolicyDocument => (isa => 'Cfn::Value', is => 'rw', coerce => 1, required => 1);
  has Path => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has Policies => (isa => 'Cfn::Value::Array|Cfn::Value::Function', is => 'rw', coerce => 1);
  has ManagedPolicyArns => (isa => 'Cfn::Value::Array|Cfn::Value::Function', is => 'rw', coerce => 1);
  has RoleName => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
}

1;
