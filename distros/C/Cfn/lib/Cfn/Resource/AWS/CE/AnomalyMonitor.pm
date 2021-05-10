# AWS::CE::AnomalyMonitor generated from spec 34.0.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::CE::AnomalyMonitor',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::CE::AnomalyMonitor->new( %$_ ) };

package Cfn::Resource::AWS::CE::AnomalyMonitor {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::CE::AnomalyMonitor', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [ 'CreationDate','DimensionalValueCount','LastEvaluatedDate','LastUpdatedDate','MonitorArn' ]
  }
  sub supported_regions {
    [ 'us-east-1' ]
  }
}



package Cfn::Resource::Properties::AWS::CE::AnomalyMonitor {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has MonitorDimension => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has MonitorName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has MonitorSpecification => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has MonitorType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::CE::AnomalyMonitor - Cfn resource for AWS::CE::AnomalyMonitor

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::CE::AnomalyMonitor.

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
