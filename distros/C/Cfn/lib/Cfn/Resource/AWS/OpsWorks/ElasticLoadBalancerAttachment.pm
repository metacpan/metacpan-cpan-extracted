# AWS::OpsWorks::ElasticLoadBalancerAttachment generated from spec 1.11.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::OpsWorks::ElasticLoadBalancerAttachment',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::OpsWorks::ElasticLoadBalancerAttachment->new( %$_ ) };

package Cfn::Resource::AWS::OpsWorks::ElasticLoadBalancerAttachment {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::OpsWorks::ElasticLoadBalancerAttachment', is => 'rw', coerce => 1);
  sub _build_attributes {
    [  ]
  }
}



package Cfn::Resource::Properties::AWS::OpsWorks::ElasticLoadBalancerAttachment {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has ElasticLoadBalancerName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has LayerId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
