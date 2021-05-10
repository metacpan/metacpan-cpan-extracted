# AWS::CloudWatch::InsightRule generated from spec 22.0.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::CloudWatch::InsightRule',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::CloudWatch::InsightRule->new( %$_ ) };

package Cfn::Resource::AWS::CloudWatch::InsightRule {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::CloudWatch::InsightRule', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [ 'Arn','RuleName' ]
  }
  sub supported_regions {
    [ 'af-south-1','ap-east-1','ap-northeast-1','ap-northeast-2','ap-northeast-3','ap-south-1','ap-southeast-1','ap-southeast-2','ca-central-1','cn-north-1','cn-northwest-1','eu-central-1','eu-north-1','eu-south-1','eu-west-1','eu-west-2','eu-west-3','me-south-1','sa-east-1','us-east-1','us-east-2','us-gov-east-1','us-gov-west-1','us-west-1','us-west-2' ]
  }
}



subtype 'Cfn::Resource::Properties::AWS::CloudWatch::InsightRule::Tags',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::CloudWatch::InsightRule::Tags',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::CloudWatch::InsightRule::Tags->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::CloudWatch::InsightRule::Tags {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
}

package Cfn::Resource::Properties::AWS::CloudWatch::InsightRule {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has RuleBody => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RuleName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has RuleState => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Tags => (isa => 'Cfn::Resource::Properties::AWS::CloudWatch::InsightRule::Tags', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::CloudWatch::InsightRule - Cfn resource for AWS::CloudWatch::InsightRule

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::CloudWatch::InsightRule.

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
