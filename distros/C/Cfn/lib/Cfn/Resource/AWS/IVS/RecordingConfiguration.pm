# AWS::IVS::RecordingConfiguration generated from spec 34.0.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::IVS::RecordingConfiguration',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::IVS::RecordingConfiguration->new( %$_ ) };

package Cfn::Resource::AWS::IVS::RecordingConfiguration {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::IVS::RecordingConfiguration', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [ 'Arn','State' ]
  }
  sub supported_regions {
    [ 'eu-west-1','us-east-1','us-west-2' ]
  }
}



subtype 'Cfn::Resource::Properties::AWS::IVS::RecordingConfiguration::S3DestinationConfiguration',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IVS::RecordingConfiguration::S3DestinationConfiguration',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::IVS::RecordingConfiguration::S3DestinationConfiguration->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::IVS::RecordingConfiguration::S3DestinationConfiguration {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has BucketName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

subtype 'Cfn::Resource::Properties::AWS::IVS::RecordingConfiguration::DestinationConfiguration',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IVS::RecordingConfiguration::DestinationConfiguration',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::IVS::RecordingConfiguration::DestinationConfiguration->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::IVS::RecordingConfiguration::DestinationConfiguration {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has S3 => (isa => 'Cfn::Resource::Properties::AWS::IVS::RecordingConfiguration::S3DestinationConfiguration', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

package Cfn::Resource::Properties::AWS::IVS::RecordingConfiguration {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has DestinationConfiguration => (isa => 'Cfn::Resource::Properties::AWS::IVS::RecordingConfiguration::DestinationConfiguration', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Tags => (isa => 'ArrayOfCfn::Resource::Properties::TagType', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::IVS::RecordingConfiguration - Cfn resource for AWS::IVS::RecordingConfiguration

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::IVS::RecordingConfiguration.

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
