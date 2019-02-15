# AWS::Kinesis::StreamConsumer generated from spec 2.15.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::Kinesis::StreamConsumer',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::Kinesis::StreamConsumer->new( %$_ ) };

package Cfn::Resource::AWS::Kinesis::StreamConsumer {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::Kinesis::StreamConsumer', is => 'rw', coerce => 1);
  sub _build_attributes {
    [ 'ConsumerARN','ConsumerCreationTimestamp','ConsumerName','ConsumerStatus','StreamARN' ]
  }
}



package Cfn::Resource::Properties::AWS::Kinesis::StreamConsumer {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has ConsumerName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has StreamARN => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

1;
