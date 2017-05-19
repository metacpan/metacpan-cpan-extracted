use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::EC2::Instance',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::EC2::Instance->new( %$_ ) };

package Cfn::Resource::AWS::EC2::Instance {
   use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::EC2::Instance', is => 'rw', coerce => 1, required => 1);
}

package Cfn::Resource::Properties::AWS::EC2::Instance  {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  has AvailabilityZone => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has BlockDeviceMappings => (isa => 'Cfn::Value::Array|Cfn::Value::Function', is => 'rw', coerce => 1);
  has DisableApiTermination => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has EbsOptimized => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has IamInstanceProfile => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has ImageId => (isa => 'Cfn::Value', is => 'rw', coerce => 1, required => 1);
  has InstanceType => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has KernelId => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has KeyName => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has Monitoring => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has NetworkInterfaces => (isa => 'Cfn::Value::Array|Cfn::Value::Function', is => 'rw', coerce => 1);
  has PlacementGroupName => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has PrivateIpAddress => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has RamdiskId => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has SecurityGroupIds => (isa => 'Cfn::Value::Array|Cfn::Value::Function', is => 'rw', coerce => 1);
  has SecurityGroups => (isa => 'Cfn::Value::Array|Cfn::Value::Function', is => 'rw', coerce => 1);
  has SourceDestCheck => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has SubnetId => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has Tags => (isa => 'Cfn::Value::Array|Cfn::Value::Function', is => 'rw', coerce => 1);
  has Tenancy => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has UserData => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has Volumes => (isa => 'Cfn::Value::Array|Cfn::Value::Function', is => 'rw', coerce => 1);
}

1;
