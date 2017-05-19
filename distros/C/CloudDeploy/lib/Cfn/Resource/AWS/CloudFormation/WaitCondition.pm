use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::CloudFormation::WaitCondition',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::CloudFormation::WaitCondition->new( %$_ ) };

package Cfn::Resource::Properties::AWS::CloudFormation::WaitCondition {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  has Count => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has Handle => (isa => 'Cfn::Value', is => 'rw', coerce => 1, required => 1);
  has Timeout => (isa => 'Cfn::Value', is => 'rw', coerce => 1, required => 1);
}

package Cfn::Resource::AWS::CloudFormation::WaitCondition {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::CloudFormation::WaitCondition', is => 'rw', coerce => 1, required => 1);
}

1;
