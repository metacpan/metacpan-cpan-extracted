# AWS::Config::DeliveryChannel generated from spec 1.11.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::Config::DeliveryChannel',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::Config::DeliveryChannel->new( %$_ ) };

package Cfn::Resource::AWS::Config::DeliveryChannel {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::Config::DeliveryChannel', is => 'rw', coerce => 1);
  sub _build_attributes {
    [  ]
  }
}



subtype 'Cfn::Resource::Properties::AWS::Config::DeliveryChannel::ConfigSnapshotDeliveryProperties',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Config::DeliveryChannel::ConfigSnapshotDeliveryProperties',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::Config::DeliveryChannel::ConfigSnapshotDeliveryPropertiesValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::Config::DeliveryChannel::ConfigSnapshotDeliveryPropertiesValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has DeliveryFrequency => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::Config::DeliveryChannel {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has ConfigSnapshotDeliveryProperties => (isa => 'Cfn::Resource::Properties::AWS::Config::DeliveryChannel::ConfigSnapshotDeliveryProperties', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has S3BucketName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has S3KeyPrefix => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SnsTopicARN => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
