# AWS::IoT::TopicRuleDestination generated from spec 22.0.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::IoT::TopicRuleDestination',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::IoT::TopicRuleDestination->new( %$_ ) };

package Cfn::Resource::AWS::IoT::TopicRuleDestination {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::IoT::TopicRuleDestination', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [ 'Arn','StatusReason' ]
  }
  sub supported_regions {
    [ 'ap-east-1','ap-northeast-1','ap-northeast-2','ap-south-1','ap-southeast-1','ap-southeast-2','ca-central-1','cn-north-1','cn-northwest-1','eu-central-1','eu-north-1','eu-west-1','eu-west-2','eu-west-3','me-south-1','sa-east-1','us-east-1','us-east-2','us-gov-east-1','us-gov-west-1','us-west-1','us-west-2' ]
  }
}



subtype 'Cfn::Resource::Properties::AWS::IoT::TopicRuleDestination::VpcDestinationProperties',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoT::TopicRuleDestination::VpcDestinationProperties',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::IoT::TopicRuleDestination::VpcDestinationProperties->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::IoT::TopicRuleDestination::VpcDestinationProperties {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has RoleArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has SecurityGroups => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has SubnetIds => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has VpcId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

subtype 'Cfn::Resource::Properties::AWS::IoT::TopicRuleDestination::HttpUrlDestinationSummary',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoT::TopicRuleDestination::HttpUrlDestinationSummary',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::IoT::TopicRuleDestination::HttpUrlDestinationSummary->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::IoT::TopicRuleDestination::HttpUrlDestinationSummary {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ConfirmationUrl => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

package Cfn::Resource::Properties::AWS::IoT::TopicRuleDestination {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has HttpUrlProperties => (isa => 'Cfn::Resource::Properties::AWS::IoT::TopicRuleDestination::HttpUrlDestinationSummary', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Status => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has VpcProperties => (isa => 'Cfn::Resource::Properties::AWS::IoT::TopicRuleDestination::VpcDestinationProperties', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::IoT::TopicRuleDestination - Cfn resource for AWS::IoT::TopicRuleDestination

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::IoT::TopicRuleDestination.

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
