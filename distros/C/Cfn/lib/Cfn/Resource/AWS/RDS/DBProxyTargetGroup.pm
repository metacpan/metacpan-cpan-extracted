# AWS::RDS::DBProxyTargetGroup generated from spec 18.4.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::RDS::DBProxyTargetGroup',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::RDS::DBProxyTargetGroup->new( %$_ ) };

package Cfn::Resource::AWS::RDS::DBProxyTargetGroup {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::RDS::DBProxyTargetGroup', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [ 'TargetGroupArn' ]
  }
  sub supported_regions {
    [ 'ap-northeast-1','ap-northeast-2','ap-south-1','ap-southeast-1','ap-southeast-2','ca-central-1','eu-central-1','eu-west-1','eu-west-2','us-east-1','us-east-2','us-west-1','us-west-2' ]
  }
}



subtype 'Cfn::Resource::Properties::AWS::RDS::DBProxyTargetGroup::ConnectionPoolConfigurationInfoFormat',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::RDS::DBProxyTargetGroup::ConnectionPoolConfigurationInfoFormat',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::RDS::DBProxyTargetGroup::ConnectionPoolConfigurationInfoFormat->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::RDS::DBProxyTargetGroup::ConnectionPoolConfigurationInfoFormat {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ConnectionBorrowTimeout => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has InitQuery => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has MaxConnectionsPercent => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has MaxIdleConnectionsPercent => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SessionPinningFilters => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::RDS::DBProxyTargetGroup {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has ConnectionPoolConfigurationInfo => (isa => 'Cfn::Resource::Properties::AWS::RDS::DBProxyTargetGroup::ConnectionPoolConfigurationInfoFormat', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DBClusterIdentifiers => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DBInstanceIdentifiers => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DBProxyName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has TargetGroupName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::RDS::DBProxyTargetGroup - Cfn resource for AWS::RDS::DBProxyTargetGroup

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::RDS::DBProxyTargetGroup.

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
