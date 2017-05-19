use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::IAM::Group',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::IAM::Group->new( %$_ ) };

package Cfn::Resource::AWS::IAM::Group {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::IAM::Group', is => 'rw', coerce => 1, required => 1);
}

package Cfn::Resource::Properties::AWS::IAM::Group  {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  has Path => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has Policies => (isa => 'Cfn::Value::Array|Cfn::Value::Function', is => 'rw', coerce => 1);
}

1;
