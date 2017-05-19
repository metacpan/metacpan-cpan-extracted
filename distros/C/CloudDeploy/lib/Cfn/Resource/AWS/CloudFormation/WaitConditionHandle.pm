use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::CloudFormation::WaitConditionHandle',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::CloudFormation::WaitConditionHandle->new( %$_ ) };

package Cfn::Resource::AWS::CloudFormation::WaitConditionHandle {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::CloudFormation::WaitConditionHandle', is => 'rw', coerce => 1, required => 1);
}

package Cfn::Resource::Properties::AWS::CloudFormation::WaitConditionHandle {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
}

1;
