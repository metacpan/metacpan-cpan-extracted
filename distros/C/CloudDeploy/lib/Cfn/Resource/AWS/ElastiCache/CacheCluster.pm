use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::ElastiCache::CacheCluster',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::ElastiCache::CacheCluster->new( %$_ ) };

package Cfn::Resource::AWS::ElastiCache::CacheCluster {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::ElastiCache::CacheCluster', is => 'rw', coerce => 1, required => 1);
}

package Cfn::Resource::Properties::AWS::ElastiCache::CacheCluster  {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  has AutoMinorVersionUpgrade => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has CacheNodeType => (isa => 'Cfn::Value', is => 'rw', coerce => 1, required => 1);
  has CacheParameterGroupName => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has CacheSecurityGroupNames => (isa => 'Cfn::Value::Array|Cfn::Value::Function', is => 'rw', coerce => 1);
  has CacheSubnetGroupName => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has ClusterName => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has Engine => (isa => 'Cfn::Value', is => 'rw', coerce => 1, required => 1);
  has EngineVersion => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has NotificationTopicArn => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has NumCacheNodes => (isa => 'Cfn::Value', is => 'rw', coerce => 1, required => 1);
  has Port => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has PreferredAvailabilityZone => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has PreferredMaintenanceWindow => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has SnapshotArns => (isa => 'Cfn::Value::Array|Cfn::Value::Function', is => 'rw', coerce => 1);
  has Tags => (isa => 'Cfn::Value::Array|Cfn::Value::Function', is => 'rw', coerce => 1);  
  has VpcSecurityGroupIds => (isa => 'Cfn::Value::Array|Cfn::Value::Function', is => 'rw', coerce => 1);
}

1;
