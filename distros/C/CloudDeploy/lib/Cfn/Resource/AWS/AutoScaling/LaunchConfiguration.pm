use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::AutoScaling::LaunchConfiguration',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::AutoScaling::LaunchConfiguration->new( %$_ ) };

package Cfn::Resource::AWS::AutoScaling::LaunchConfiguration {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::AutoScaling::LaunchConfiguration', is => 'rw', coerce => 1, required => 1);
}

package Cfn::Resource::Properties::AWS::AutoScaling::LaunchConfiguration {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  has AssociatePublicIpAddress => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has BlockDeviceMappings => (isa => 'Cfn::Value::Array|Cfn::Value::Function', is => 'rw', coerce => 1);
  has EbsOptimized => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has IamInstanceProfile => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has ImageId => (isa => 'Cfn::Value', is => 'rw', coerce => 1, required => 1);
  has InstanceMonitoring => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has InstanceType => (isa => 'Cfn::Value', is => 'rw', coerce => 1, required => 1);
  has KernelId => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has KeyName => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has RamDiskId => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has SecurityGroups => (isa => 'Cfn::Value::Array|Cfn::Value::Function', is => 'rw', coerce => 1);
  has SpotPrice => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has UserData => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
}

1;
