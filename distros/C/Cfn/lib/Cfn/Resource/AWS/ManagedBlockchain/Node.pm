# AWS::ManagedBlockchain::Node generated from spec 34.0.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::ManagedBlockchain::Node',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::ManagedBlockchain::Node->new( %$_ ) };

package Cfn::Resource::AWS::ManagedBlockchain::Node {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::ManagedBlockchain::Node', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [ 'Arn','MemberId','NetworkId','NodeId' ]
  }
  sub supported_regions {
    [ 'ap-northeast-1','ap-northeast-2','ap-southeast-1','eu-central-1','eu-west-1','eu-west-2','us-east-1','us-east-2','us-west-2' ]
  }
}



subtype 'Cfn::Resource::Properties::AWS::ManagedBlockchain::Node::NodeConfiguration',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::ManagedBlockchain::Node::NodeConfiguration',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::ManagedBlockchain::Node::NodeConfiguration->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::ManagedBlockchain::Node::NodeConfiguration {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AvailabilityZone => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has InstanceType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::ManagedBlockchain::Node {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has MemberId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has NetworkId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has NodeConfiguration => (isa => 'Cfn::Resource::Properties::AWS::ManagedBlockchain::Node::NodeConfiguration', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::ManagedBlockchain::Node - Cfn resource for AWS::ManagedBlockchain::Node

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::ManagedBlockchain::Node.

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
