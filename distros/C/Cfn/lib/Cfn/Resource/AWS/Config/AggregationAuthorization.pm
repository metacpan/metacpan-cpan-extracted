# AWS::Config::AggregationAuthorization generated from spec 34.0.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::Config::AggregationAuthorization',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::Config::AggregationAuthorization->new( %$_ ) };

package Cfn::Resource::AWS::Config::AggregationAuthorization {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::Config::AggregationAuthorization', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [  ]
  }
  sub supported_regions {
    [ 'af-south-1','ap-east-1','ap-northeast-1','ap-southeast-1','ap-southeast-2','eu-central-1','eu-north-1','eu-south-1','eu-west-1','me-south-1','us-east-1','us-east-2','us-gov-east-1','us-gov-west-1','us-west-1','us-west-2' ]
  }
}



package Cfn::Resource::Properties::AWS::Config::AggregationAuthorization {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has AuthorizedAccountId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has AuthorizedAwsRegion => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Tags => (isa => 'ArrayOfCfn::Resource::Properties::TagType', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::Config::AggregationAuthorization - Cfn resource for AWS::Config::AggregationAuthorization

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::Config::AggregationAuthorization.

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
