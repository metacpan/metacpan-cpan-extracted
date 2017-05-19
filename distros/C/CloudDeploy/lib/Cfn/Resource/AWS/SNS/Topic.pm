use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::SNS::Topic',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::SNS::Topic->new( %$_ ) };

package Cfn::Resource::AWS::SNS::Topic {
  use Moose;
  use Moose::Util::TypeConstraints qw/find_type_constraint/;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::SNS::Topic', is => 'rw', coerce => 1, required => 1);
}

package Cfn::Resource::Properties::AWS::SNS::Topic {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  has DisplayName => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has Subscription => (isa => 'Cfn::Value::Array|Cfn::Value::Function', is => 'rw', coerce => 1);
  has TopicName => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
}

1;
