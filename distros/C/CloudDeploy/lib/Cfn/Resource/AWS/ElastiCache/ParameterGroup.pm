use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::ElastiCache::ParameterGroup',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::ElastiCache::ParameterGroup->new( %$_ ) };

package Cfn::Resource::AWS::ElastiCache::ParameterGroup {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::ElastiCache::ParameterGroup', is => 'rw', coerce => 1, required => 1);
}

package Cfn::Resource::Properties::AWS::ElastiCache::ParameterGroup  {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  has CacheParameterGroupFamily => (isa => 'Cfn::Value', is => 'rw', coerce => 1, required => 1);
  has Description => (isa => 'Cfn::Value', is => 'rw', coerce => 1, required => 1);
  has Properties => (isa => 'Cfn::Value', is => 'rw', coerce => 1, required => 1);
}

1;
