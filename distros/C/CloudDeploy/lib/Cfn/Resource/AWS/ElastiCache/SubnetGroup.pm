use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::ElastiCache::SubnetGroup',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::ElastiCache::SubnetGroup->new( %$_ ) };

package Cfn::Resource::AWS::ElastiCache::SubnetGroup  {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::ElastiCache::SubnetGroup', is => 'rw', coerce => 1, required => 1);
}

package Cfn::Resource::Properties::AWS::ElastiCache::SubnetGroup {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  has Description => (isa => 'Cfn::Value', is => 'rw', coerce => 1, required => 1);
  has SubnetIds => (isa => 'Cfn::Value::Array|Cfn::Value::Function', is => 'rw', coerce => 1, required => 1);
}

1;
