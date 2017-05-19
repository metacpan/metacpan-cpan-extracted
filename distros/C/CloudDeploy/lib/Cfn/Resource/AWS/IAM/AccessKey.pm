use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::IAM::AccessKey',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::IAM::AccessKey->new( %$_ ) };

package Cfn::Resource::AWS::IAM::AccessKey {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::IAM::AccessKey', is => 'rw', coerce => 1, required => 1);
}

package Cfn::Resource::Properties::AWS::IAM::AccessKey  {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  has Serial => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  # TODO: Status has extra restrictions
  has Status => (isa => 'Cfn::Value', is => 'rw', coerce => 1, required => 0);
  has UserName => (isa => 'Cfn::Value', is => 'rw', coerce => 1, required => 1);
}

1;
