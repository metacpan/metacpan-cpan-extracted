use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::EFS::FileSystem',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::EFS::FileSystem->new( %$_ ) };

package Cfn::Resource::AWS::EFS::FileSystem {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::EFS::FileSystem', is => 'rw', coerce => 1, required => 1);
}

package Cfn::Resource::Properties::AWS::EFS::FileSystem {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  has FileSystemTags => (isa => 'Cfn::Value::Array|Cfn::Value::Function', is => 'rw', coerce => 1);
  has PerformanceMode => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
}

1;
