use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::IAM::InstanceProfile',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::IAM::InstanceProfile->new( %$_ ) };

package Cfn::Resource::AWS::IAM::InstanceProfile {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::IAM::InstanceProfile', is => 'rw', coerce => 1, required => 1);
}

package Cfn::Resource::Properties::AWS::IAM::InstanceProfile  {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  has Path => (isa => 'Cfn::Value', is => 'rw', coerce => 1, required => 1);
  has Roles => (isa => 'Cfn::Value::Array|Cfn::Value::Function', is => 'rw', coerce => 1, required => 1);
}

1;
