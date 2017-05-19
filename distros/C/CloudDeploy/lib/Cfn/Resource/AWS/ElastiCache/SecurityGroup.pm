use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::ElastiCache::SecurityGroup',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::ElastiCache::SecurityGroup->new( %$_ ) };

package Cfn::Resource::AWS::ElastiCache::SecurityGroup {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::ElastiCache::SecurityGroup', is => 'rw', coerce => 1, required => 1);
}

package Cfn::Resource::Properties::AWS::ElastiCache::SecurityGroup  {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  has Description => (isa => 'Cfn::Value', is => 'rw', coerce => 1, required => 1);
}

coerce 'Cfn::Resource::Properties::AWS::ElastiCache::SecurityGroupIngress',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::ElastiCache::SecurityGroupIngress->new( %$_ ) };

1;
