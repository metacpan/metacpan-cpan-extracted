use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::ElastiCache::SecurityGroupIngress',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::ElastiCache::SecurityGroupIngress->new( %$_ ) };

package Cfn::Resource::AWS::ElastiCache::SecurityGroupIngress {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::ElastiCache::SecurityGroupIngress', is => 'rw', coerce => 1, required => 1);
}

package Cfn::Resource::Properties::AWS::ElastiCache::SecurityGroupIngress  {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  has CacheSecurityGroupName => (isa => 'Cfn::Value', is => 'rw', coerce => 1, required => 1);
  has EC2SecurityGroupName => (isa => 'Cfn::Value', is => 'rw', coerce => 1, required => 1);
  has EC2SecurityGroupOwnerId => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
}

1;
