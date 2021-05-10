# AWS::GroundStation::MissionProfile generated from spec 34.0.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::GroundStation::MissionProfile',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::GroundStation::MissionProfile->new( %$_ ) };

package Cfn::Resource::AWS::GroundStation::MissionProfile {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::GroundStation::MissionProfile', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [ 'Arn','Id','Region' ]
  }
  sub supported_regions {
    [ 'af-south-1','ap-southeast-2','eu-central-1','eu-north-1','eu-west-1','me-south-1','us-east-1','us-east-2','us-west-2' ]
  }
}


subtype 'ArrayOfCfn::Resource::Properties::AWS::GroundStation::MissionProfile::DataflowEdge',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::GroundStation::MissionProfile::DataflowEdge',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       die 'Only accepts functions'; 
     }
   },
  from 'ArrayRef',
   via {
     Cfn::Value::Array->new(Value => [
       map { 
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::GroundStation::MissionProfile::DataflowEdge')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::GroundStation::MissionProfile::DataflowEdge',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::GroundStation::MissionProfile::DataflowEdge',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::GroundStation::MissionProfile::DataflowEdge->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::GroundStation::MissionProfile::DataflowEdge {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Destination => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Source => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::GroundStation::MissionProfile {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has ContactPostPassDurationSeconds => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ContactPrePassDurationSeconds => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DataflowEdges => (isa => 'ArrayOfCfn::Resource::Properties::AWS::GroundStation::MissionProfile::DataflowEdge', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has MinimumViableContactDurationSeconds => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Tags => (isa => 'ArrayOfCfn::Resource::Properties::TagType', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TrackingConfigArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::GroundStation::MissionProfile - Cfn resource for AWS::GroundStation::MissionProfile

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::GroundStation::MissionProfile.

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
