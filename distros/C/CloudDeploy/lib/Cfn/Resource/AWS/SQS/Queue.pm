use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::SQS::Queue',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::SQS::Queue->new( %$_ ) };

package Cfn::Resource::AWS::SQS::Queue {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::SQS::Queue', is => 'rw', coerce => 1, required => 1);
}

package Cfn::Resource::Properties::AWS::SQS::Queue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  has DelaySeconds => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has MaximumMessageSize => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has MessageRetentionPeriod => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has QueueName => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has ReceiveMessageWaitTimeSeconds => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has RedrivePolicy => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has VisibilityTimeout => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
}

1;
