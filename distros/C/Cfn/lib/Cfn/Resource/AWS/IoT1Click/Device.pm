# AWS::IoT1Click::Device generated from spec 2.8.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::IoT1Click::Device',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::IoT1Click::Device->new( %$_ ) };

package Cfn::Resource::AWS::IoT1Click::Device {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::IoT1Click::Device', is => 'rw', coerce => 1);
  sub _build_attributes {
    [ 'Arn','DeviceId','Enabled' ]
  }
}



package Cfn::Resource::Properties::AWS::IoT1Click::Device {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has DeviceId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Enabled => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
