use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::EC2::Volume',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::EC2::Volume->new( %$_ ) };

package Cfn::Resource::AWS::EC2::Volume {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::EC2::Volume', is => 'rw', coerce => 1, required => 1);
}

package Cfn::Resource::Properties::AWS::EC2::Volume  {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  has AvailabilityZone => (isa => 'Cfn::Value', is => 'rw', coerce => 1, required => 1);
  has Iops => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has Size => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has SnapshotId => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has Encrypted => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has Tags => (isa => 'Cfn::Value::Array|Cfn::Value::Function', is => 'rw', coerce => 1);
  # TODO: VolumeType has a restriction
  has VolumeType => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
}

1;
