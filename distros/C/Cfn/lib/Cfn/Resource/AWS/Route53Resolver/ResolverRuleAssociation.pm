# AWS::Route53Resolver::ResolverRuleAssociation generated from spec 14.3.0
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
    [ 'ap-east-1','ap-northeast-1','ap-southeast-1','ap-southeast-2','eu-north-1','eu-west-1','me-south-1','sa-east-1','us-east-1','us-east-2','us-gov-east-1','us-gov-west-1','us-west-2' ]
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
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::Route53Resolver::ResolverRuleAssociation - Cfn resource for AWS::Route53Resolver::ResolverRuleAssociation

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::Route53Resolver::ResolverRuleAssociation.

See L<Cfn> for more information on how to use it.

=head1 AUTHOR

    Jose Luis Martinez
    CAPSiDE
    jlmartinez@capside.com

=head1 COPYRIGHT and LICENSE

Copyright (c) 2013 by CAPSiDE
This code is distributed under the Apache 2 License. The full text of the 
license can be found in the LICENSE file included with this module.

=cut
