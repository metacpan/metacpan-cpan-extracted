use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::ElasticLoadBalancing::LoadBalancer',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::ElasticLoadBalancing::LoadBalancer->new( %$_ ) };

package Cfn::Resource::AWS::ElasticLoadBalancing::LoadBalancer {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::ElasticLoadBalancing::LoadBalancer', is => 'rw', coerce => 1, required => 1);
}

package Cfn::Resource::Properties::AWS::ElasticLoadBalancing::LoadBalancer  {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  has AccessLoggingPolicy => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has AppCookieStickinessPolicy => (isa => 'Cfn::Value::Array|Cfn::Value::Function', is => 'rw', coerce => 1);
  has AvailabilityZones => (isa => 'Cfn::Value::Array|Cfn::Value::Function', is => 'rw', coerce => 1);
  has ConnectionDrainingPolicy => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has CrossZone => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has ConnectionSettings => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has HealthCheck => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has Instances => (isa => 'Cfn::Value::Array|Cfn::Value::Function', is => 'rw', coerce => 1);
  has LBCookieStickinessPolicy => (isa => 'Cfn::Value::Array|Cfn::Value::Function', is => 'rw', coerce => 1);
  has Listeners => (isa => 'Cfn::Value::Array|Cfn::Value::Function', is => 'rw', coerce => 1, required => 1);
  has LoadBalancerName => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has Policies => (isa => 'Cfn::Value::Array|Cfn::Value::Function', is => 'rw', coerce => 1);
  has Scheme => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has SecurityGroups => (isa => 'Cfn::Value::Array|Cfn::Value::Function', is => 'rw', coerce => 1);
  has Subnets => (isa => 'Cfn::Value::Array|Cfn::Value::Function', is => 'rw', coerce => 1);
  has Tags => (isa => 'Cfn::Value::Array|Cfn::Value::Function', is => 'rw', coerce => 1);
}

1;
