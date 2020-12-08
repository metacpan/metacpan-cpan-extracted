# AWS::SES::ReceiptRuleSet generated from spec 14.3.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::SES::ReceiptRuleSet',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::SES::ReceiptRuleSet->new( %$_ ) };

package Cfn::Resource::AWS::SES::ReceiptRuleSet {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::SES::ReceiptRuleSet', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [  ]
  }
  sub supported_regions {
    [ 'eu-west-1','us-east-1','us-west-2' ]
  }
}



package Cfn::Resource::Properties::AWS::SES::ReceiptRuleSet {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has RuleSetName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::SES::ReceiptRuleSet - Cfn resource for AWS::SES::ReceiptRuleSet

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::SES::ReceiptRuleSet.

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
