use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::SNS::Subscription',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::SNS::Subscription->new( %$_ ) };

package Cfn::Resource::AWS::SNS::Subscription {
  use Moose;
  use Moose::Util::TypeConstraints qw/find_type_constraint/;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::SNS::Subscription', is => 'rw', coerce => 1, required => 1);
}

package Cfn::Resource::Properties::AWS::SNS::Subscription {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  has Endpoint => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has Protocol => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has TopicArn => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
}

1;

