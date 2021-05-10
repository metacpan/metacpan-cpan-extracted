# AWS::GroundStation::Config generated from spec 34.0.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::GroundStation::Config',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::GroundStation::Config->new( %$_ ) };

package Cfn::Resource::AWS::GroundStation::Config {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::GroundStation::Config', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [ 'Arn','Id','Type' ]
  }
  sub supported_regions {
    [ 'af-south-1','ap-southeast-2','eu-central-1','eu-north-1','eu-west-1','me-south-1','us-east-1','us-east-2','us-west-2' ]
  }
}



subtype 'Cfn::Resource::Properties::AWS::GroundStation::Config::FrequencyBandwidth',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::GroundStation::Config::FrequencyBandwidth',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::GroundStation::Config::FrequencyBandwidth->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::GroundStation::Config::FrequencyBandwidth {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Units => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Value => (isa => 'Cfn::Value::Double', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::GroundStation::Config::Frequency',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::GroundStation::Config::Frequency',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::GroundStation::Config::Frequency->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::GroundStation::Config::Frequency {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Units => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Value => (isa => 'Cfn::Value::Double', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::GroundStation::Config::UplinkSpectrumConfig',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::GroundStation::Config::UplinkSpectrumConfig',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::GroundStation::Config::UplinkSpectrumConfig->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::GroundStation::Config::UplinkSpectrumConfig {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has CenterFrequency => (isa => 'Cfn::Resource::Properties::AWS::GroundStation::Config::Frequency', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Polarization => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::GroundStation::Config::SpectrumConfig',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::GroundStation::Config::SpectrumConfig',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::GroundStation::Config::SpectrumConfig->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::GroundStation::Config::SpectrumConfig {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Bandwidth => (isa => 'Cfn::Resource::Properties::AWS::GroundStation::Config::FrequencyBandwidth', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has CenterFrequency => (isa => 'Cfn::Resource::Properties::AWS::GroundStation::Config::Frequency', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Polarization => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::GroundStation::Config::Eirp',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::GroundStation::Config::Eirp',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::GroundStation::Config::Eirp->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::GroundStation::Config::Eirp {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Units => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Value => (isa => 'Cfn::Value::Double', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::GroundStation::Config::DemodulationConfig',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::GroundStation::Config::DemodulationConfig',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::GroundStation::Config::DemodulationConfig->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::GroundStation::Config::DemodulationConfig {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has UnvalidatedJson => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::GroundStation::Config::DecodeConfig',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::GroundStation::Config::DecodeConfig',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::GroundStation::Config::DecodeConfig->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::GroundStation::Config::DecodeConfig {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has UnvalidatedJson => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::GroundStation::Config::UplinkEchoConfig',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::GroundStation::Config::UplinkEchoConfig',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::GroundStation::Config::UplinkEchoConfig->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::GroundStation::Config::UplinkEchoConfig {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AntennaUplinkConfigArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Enabled => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::GroundStation::Config::TrackingConfig',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::GroundStation::Config::TrackingConfig',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::GroundStation::Config::TrackingConfig->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::GroundStation::Config::TrackingConfig {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Autotrack => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::GroundStation::Config::S3RecordingConfig',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::GroundStation::Config::S3RecordingConfig',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::GroundStation::Config::S3RecordingConfig->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::GroundStation::Config::S3RecordingConfig {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has BucketArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Prefix => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RoleArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::GroundStation::Config::DataflowEndpointConfig',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::GroundStation::Config::DataflowEndpointConfig',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::GroundStation::Config::DataflowEndpointConfig->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::GroundStation::Config::DataflowEndpointConfig {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has DataflowEndpointName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DataflowEndpointRegion => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::GroundStation::Config::AntennaUplinkConfig',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::GroundStation::Config::AntennaUplinkConfig',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::GroundStation::Config::AntennaUplinkConfig->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::GroundStation::Config::AntennaUplinkConfig {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has SpectrumConfig => (isa => 'Cfn::Resource::Properties::AWS::GroundStation::Config::UplinkSpectrumConfig', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TargetEirp => (isa => 'Cfn::Resource::Properties::AWS::GroundStation::Config::Eirp', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TransmitDisabled => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::GroundStation::Config::AntennaDownlinkDemodDecodeConfig',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::GroundStation::Config::AntennaDownlinkDemodDecodeConfig',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::GroundStation::Config::AntennaDownlinkDemodDecodeConfig->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::GroundStation::Config::AntennaDownlinkDemodDecodeConfig {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has DecodeConfig => (isa => 'Cfn::Resource::Properties::AWS::GroundStation::Config::DecodeConfig', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DemodulationConfig => (isa => 'Cfn::Resource::Properties::AWS::GroundStation::Config::DemodulationConfig', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SpectrumConfig => (isa => 'Cfn::Resource::Properties::AWS::GroundStation::Config::SpectrumConfig', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::GroundStation::Config::AntennaDownlinkConfig',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::GroundStation::Config::AntennaDownlinkConfig',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::GroundStation::Config::AntennaDownlinkConfig->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::GroundStation::Config::AntennaDownlinkConfig {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has SpectrumConfig => (isa => 'Cfn::Resource::Properties::AWS::GroundStation::Config::SpectrumConfig', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::GroundStation::Config::ConfigData',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::GroundStation::Config::ConfigData',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::GroundStation::Config::ConfigData->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::GroundStation::Config::ConfigData {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AntennaDownlinkConfig => (isa => 'Cfn::Resource::Properties::AWS::GroundStation::Config::AntennaDownlinkConfig', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has AntennaDownlinkDemodDecodeConfig => (isa => 'Cfn::Resource::Properties::AWS::GroundStation::Config::AntennaDownlinkDemodDecodeConfig', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has AntennaUplinkConfig => (isa => 'Cfn::Resource::Properties::AWS::GroundStation::Config::AntennaUplinkConfig', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DataflowEndpointConfig => (isa => 'Cfn::Resource::Properties::AWS::GroundStation::Config::DataflowEndpointConfig', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has S3RecordingConfig => (isa => 'Cfn::Resource::Properties::AWS::GroundStation::Config::S3RecordingConfig', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TrackingConfig => (isa => 'Cfn::Resource::Properties::AWS::GroundStation::Config::TrackingConfig', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has UplinkEchoConfig => (isa => 'Cfn::Resource::Properties::AWS::GroundStation::Config::UplinkEchoConfig', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::GroundStation::Config {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has ConfigData => (isa => 'Cfn::Resource::Properties::AWS::GroundStation::Config::ConfigData', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Tags => (isa => 'ArrayOfCfn::Resource::Properties::TagType', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::GroundStation::Config - Cfn resource for AWS::GroundStation::Config

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::GroundStation::Config.

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
