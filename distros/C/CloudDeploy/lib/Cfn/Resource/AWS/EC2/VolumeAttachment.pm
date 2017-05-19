use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::EC2::VolumeAttachment',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::EC2::VolumeAttachment->new( %$_ ) };

package Cfn::Resource::AWS::EC2::VolumeAttachment {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::EC2::VolumeAttachment', is => 'rw', coerce => 1, required => 1);
}

package Cfn::Resource::Properties::AWS::EC2::VolumeAttachment  {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  has Device => (isa => 'Cfn::Value', is => 'rw', coerce => 1, required => 1);
  has InstanceId => (isa => 'Cfn::Value', is => 'rw', coerce => 1, required => 1);
  has VolumeId => (isa => 'Cfn::Value', is => 'rw', coerce => 1, required => 1);
}

1;
