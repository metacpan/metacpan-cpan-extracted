use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::SNS::TopicPolicy',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::SNS::TopicPolicy->new( %$_ ) };

package Cfn::Resource::AWS::SNS::TopicPolicy {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::SNS::TopicPolicy', is => 'rw', coerce => 1, required => 1);
}

package Cfn::Resource::Properties::AWS::SNS::TopicPolicy {
  use Moose;
  extends 'Cfn::Resource::Properties';
  has PolicyDocument => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has Topics => (isa => 'Cfn::Value::Array|Cfn::Value::Function', is => 'rw', coerce => 1);
}

1;
