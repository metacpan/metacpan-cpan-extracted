# AWS::CE::CostCategory generated from spec 34.0.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::CE::CostCategory',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::CE::CostCategory->new( %$_ ) };

package Cfn::Resource::AWS::CE::CostCategory {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::CE::CostCategory', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [ 'Arn','EffectiveStart' ]
  }
  sub supported_regions {
    [ 'cn-northwest-1','us-east-1' ]
  }
}



package Cfn::Resource::Properties::AWS::CE::CostCategory {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has DefaultValue => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has RuleVersion => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Rules => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::CE::CostCategory - Cfn resource for AWS::CE::CostCategory

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::CE::CostCategory.

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
