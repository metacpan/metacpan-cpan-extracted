# AWS::AmazonMQ::ConfigurationAssociation generated from spec 34.0.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::AmazonMQ::ConfigurationAssociation',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::AmazonMQ::ConfigurationAssociation->new( %$_ ) };

package Cfn::Resource::AWS::AmazonMQ::ConfigurationAssociation {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::AmazonMQ::ConfigurationAssociation', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [  ]
  }
  sub supported_regions {
    [ 'ap-northeast-1','ap-northeast-2','ap-northeast-3','ap-south-1','ap-southeast-1','ap-southeast-2','ca-central-1','eu-central-1','eu-south-1','eu-west-1','eu-west-3','us-east-1','us-east-2','us-west-1','us-west-2' ]
  }
}



subtype 'Cfn::Resource::Properties::AWS::AmazonMQ::ConfigurationAssociation::ConfigurationId',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AmazonMQ::ConfigurationAssociation::ConfigurationId',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AmazonMQ::ConfigurationAssociation::ConfigurationId->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AmazonMQ::ConfigurationAssociation::ConfigurationId {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Id => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Revision => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::AmazonMQ::ConfigurationAssociation {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has Broker => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Configuration => (isa => 'Cfn::Resource::Properties::AWS::AmazonMQ::ConfigurationAssociation::ConfigurationId', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::AmazonMQ::ConfigurationAssociation - Cfn resource for AWS::AmazonMQ::ConfigurationAssociation

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::AmazonMQ::ConfigurationAssociation.

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
