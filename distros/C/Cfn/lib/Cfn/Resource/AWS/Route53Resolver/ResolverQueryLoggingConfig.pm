# AWS::Route53Resolver::ResolverQueryLoggingConfig generated from spec 20.1.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::Route53Resolver::ResolverQueryLoggingConfig',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::Route53Resolver::ResolverQueryLoggingConfig->new( %$_ ) };

package Cfn::Resource::AWS::Route53Resolver::ResolverQueryLoggingConfig {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::Route53Resolver::ResolverQueryLoggingConfig', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [ 'Arn','AssociationCount','CreationTime','CreatorRequestId','Id','OwnerId','ShareStatus','Status' ]
  }
  sub supported_regions {
    [ 'af-south-1','ap-east-1','ap-northeast-1','ap-northeast-2','ap-south-1','ap-southeast-1','ap-southeast-2','ca-central-1','eu-central-1','eu-north-1','eu-south-1','eu-west-1','eu-west-2','eu-west-3','me-south-1','sa-east-1','us-east-1','us-east-2','us-gov-east-1','us-gov-west-1','us-west-1','us-west-2' ]
  }
}



package Cfn::Resource::Properties::AWS::Route53Resolver::ResolverQueryLoggingConfig {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has DestinationArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::Route53Resolver::ResolverQueryLoggingConfig - Cfn resource for AWS::Route53Resolver::ResolverQueryLoggingConfig

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::Route53Resolver::ResolverQueryLoggingConfig.

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
