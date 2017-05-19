use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::SQS::QueuePolicy',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::SQS::QueuePolicy->new( %$_ ) };

package Cfn::Resource::AWS::SQS::QueuePolicy {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::SQS::QueuePolicy', is => 'rw', coerce => 1, required => 1);
}

package Cfn::Resource::Properties::AWS::SQS::QueuePolicy {
  use Moose;
  extends 'Cfn::Resource::Properties';
  has PolicyDocument => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has Queues => (isa => 'Cfn::Value::Array|Cfn::Value::Function', is => 'rw', coerce => 1);
}

1;
