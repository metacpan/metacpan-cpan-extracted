use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::EFS::MountTarget',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::EFS::MountTarget->new( %$_ ) };

package Cfn::Resource::AWS::EFS::MountTarget {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::EFS::MountTarget', is => 'rw', coerce => 1, required => 1);
}

package Cfn::Resource::Properties::AWS::EFS::MountTarget {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  has FileSystemId => (isa => 'Cfn::Value', is => 'rw', coerce => 1, required => 1);
  has IpAddress => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has SecurityGroups => (isa => 'Cfn::Value::Array|Cfn::Value::Function', is => 'rw', coerce => 1, required => 1);
  has SubnetId => (isa => 'Cfn::Value', is => 'rw', coerce => 1, required => 1);
}

1;
