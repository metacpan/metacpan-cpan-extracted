# AWS::Route53Resolver::ResolverRuleAssociation generated from spec 10.2.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::Route53Resolver::ResolverRuleAssociation',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::Route53Resolver::ResolverRuleAssociation->new( %$_ ) };

package Cfn::Resource::AWS::Route53Resolver::ResolverRuleAssociation {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::Route53Resolver::ResolverRuleAssociation', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [ 'Name','ResolverRuleAssociationId','ResolverRuleId','VPCId' ]
  }
  sub supported_regions {
    [ 'ap-east-1','ap-northeast-1','ap-southeast-1','ap-southeast-2','eu-north-1','eu-west-1','us-east-1','us-east-2','us-gov-east-1','us-gov-west-1','us-west-2' ]
  }
}



package Cfn::Resource::Properties::AWS::Route53Resolver::ResolverRuleAssociation {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has ResolverRuleId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has VPCId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

1;
