# AWS::MediaLive::Channel generated from spec 34.0.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::MediaLive::Channel->new( %$_ ) };

package Cfn::Resource::AWS::MediaLive::Channel {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [ 'Arn','Inputs' ]
  }
  sub supported_regions {
    [ 'ap-northeast-1','ap-northeast-2','ap-south-1','ap-southeast-1','ap-southeast-2','eu-central-1','eu-west-1','sa-east-1','us-east-1','us-west-2' ]
  }
}



subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::M3u8Settings',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::M3u8Settings',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::M3u8Settings->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::M3u8Settings {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AudioFramesPerPes => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has AudioPids => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has EcmPid => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has NielsenId3Behavior => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has PatInterval => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has PcrControl => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has PcrPeriod => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has PcrPid => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has PmtInterval => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has PmtPid => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ProgramNum => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Scte35Behavior => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Scte35Pid => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TimedMetadataBehavior => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TimedMetadataPid => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TransportStreamId => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has VideoPid => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::InputLocation',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::InputLocation',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::InputLocation->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::InputLocation {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has PasswordParam => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Uri => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Username => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::DvbTdtSettings',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::DvbTdtSettings',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::DvbTdtSettings->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::DvbTdtSettings {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has RepInterval => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::DvbSdtSettings',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::DvbSdtSettings',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::DvbSdtSettings->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::DvbSdtSettings {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has OutputSdt => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RepInterval => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ServiceName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ServiceProviderName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::DvbNitSettings',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::DvbNitSettings',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::DvbNitSettings->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::DvbNitSettings {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has NetworkId => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has NetworkName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RepInterval => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::StandardHlsSettings',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::StandardHlsSettings',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::StandardHlsSettings->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::StandardHlsSettings {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AudioRenditionSets => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has M3u8Settings => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::M3u8Settings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::RawSettings',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::RawSettings',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::RawSettings->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::RawSettings {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
}

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::M2tsSettings',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::M2tsSettings',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::M2tsSettings->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::M2tsSettings {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AbsentInputAudioBehavior => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Arib => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has AribCaptionsPid => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has AribCaptionsPidControl => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has AudioBufferModel => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has AudioFramesPerPes => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has AudioPids => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has AudioStreamType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Bitrate => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has BufferModel => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has CcDescriptor => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DvbNitSettings => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::DvbNitSettings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DvbSdtSettings => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::DvbSdtSettings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DvbSubPids => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DvbTdtSettings => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::DvbTdtSettings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DvbTeletextPid => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Ebif => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has EbpAudioInterval => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has EbpLookaheadMs => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has EbpPlacement => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has EcmPid => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has EsRateInPes => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has EtvPlatformPid => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has EtvSignalPid => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has FragmentTime => (isa => 'Cfn::Value::Double', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Klv => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has KlvDataPids => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has NielsenId3Behavior => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has NullPacketBitrate => (isa => 'Cfn::Value::Double', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has PatInterval => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has PcrControl => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has PcrPeriod => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has PcrPid => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has PmtInterval => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has PmtPid => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ProgramNum => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RateMode => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Scte27Pids => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Scte35Control => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Scte35Pid => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SegmentationMarkers => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SegmentationStyle => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SegmentationTime => (isa => 'Cfn::Value::Double', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TimedMetadataBehavior => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TimedMetadataPid => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TransportStreamId => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has VideoPid => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::FrameCaptureHlsSettings',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::FrameCaptureHlsSettings',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::FrameCaptureHlsSettings->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::FrameCaptureHlsSettings {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
}

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::Fmp4HlsSettings',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::Fmp4HlsSettings',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::Fmp4HlsSettings->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::Fmp4HlsSettings {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AudioRenditionSets => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has NielsenId3Behavior => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TimedMetadataBehavior => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::AudioOnlyHlsSettings',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::AudioOnlyHlsSettings',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::AudioOnlyHlsSettings->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::AudioOnlyHlsSettings {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AudioGroupId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has AudioOnlyImage => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::InputLocation', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has AudioTrackType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SegmentType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::UdpContainerSettings',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::UdpContainerSettings',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::UdpContainerSettings->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::UdpContainerSettings {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has M2tsSettings => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::M2tsSettings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::TemporalFilterSettings',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::TemporalFilterSettings',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::TemporalFilterSettings->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::TemporalFilterSettings {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has PostFilterSharpening => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Strength => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::StaticKeySettings',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::StaticKeySettings',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::StaticKeySettings->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::StaticKeySettings {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has KeyProviderServer => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::InputLocation', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has StaticKeyValue => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::Rec709Settings',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::Rec709Settings',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::Rec709Settings->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::Rec709Settings {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
}

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::Rec601Settings',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::Rec601Settings',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::Rec601Settings->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::Rec601Settings {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
}

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::OutputLocationRef',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::OutputLocationRef',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::OutputLocationRef->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::OutputLocationRef {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has DestinationRefId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::HlsWebdavSettings',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::HlsWebdavSettings',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::HlsWebdavSettings->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::HlsWebdavSettings {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ConnectionRetryInterval => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has FilecacheDuration => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has HttpTransferMode => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has NumRetries => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RestartDelay => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::HlsSettings',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::HlsSettings',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::HlsSettings->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::HlsSettings {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AudioOnlyHlsSettings => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::AudioOnlyHlsSettings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Fmp4HlsSettings => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::Fmp4HlsSettings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has FrameCaptureHlsSettings => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::FrameCaptureHlsSettings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has StandardHlsSettings => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::StandardHlsSettings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::HlsS3Settings',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::HlsS3Settings',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::HlsS3Settings->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::HlsS3Settings {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has CannedAcl => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::HlsMediaStoreSettings',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::HlsMediaStoreSettings',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::HlsMediaStoreSettings->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::HlsMediaStoreSettings {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ConnectionRetryInterval => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has FilecacheDuration => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has MediaStoreStorageClass => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has NumRetries => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RestartDelay => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::HlsBasicPutSettings',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::HlsBasicPutSettings',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::HlsBasicPutSettings->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::HlsBasicPutSettings {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ConnectionRetryInterval => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has FilecacheDuration => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has NumRetries => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RestartDelay => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::HlsAkamaiSettings',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::HlsAkamaiSettings',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::HlsAkamaiSettings->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::HlsAkamaiSettings {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ConnectionRetryInterval => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has FilecacheDuration => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has HttpTransferMode => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has NumRetries => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RestartDelay => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Salt => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Token => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::Hdr10Settings',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::Hdr10Settings',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::Hdr10Settings->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::Hdr10Settings {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has MaxCll => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has MaxFall => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::FrameCaptureS3Settings',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::FrameCaptureS3Settings',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::FrameCaptureS3Settings->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::FrameCaptureS3Settings {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has CannedAcl => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::FecOutputSettings',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::FecOutputSettings',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::FecOutputSettings->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::FecOutputSettings {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ColumnDepth => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has IncludeFec => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RowLength => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::ColorSpacePassthroughSettings',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::ColorSpacePassthroughSettings',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::ColorSpacePassthroughSettings->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::ColorSpacePassthroughSettings {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
}

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::CaptionRectangle',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::CaptionRectangle',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::CaptionRectangle->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::CaptionRectangle {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Height => (isa => 'Cfn::Value::Double', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has LeftOffset => (isa => 'Cfn::Value::Double', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TopOffset => (isa => 'Cfn::Value::Double', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Width => (isa => 'Cfn::Value::Double', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::MediaLive::Channel::AudioTrack',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::MediaLive::Channel::AudioTrack',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::MediaLive::Channel::AudioTrack')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::AudioTrack',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::AudioTrack',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::AudioTrack->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::AudioTrack {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Track => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::ArchiveS3Settings',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::ArchiveS3Settings',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::ArchiveS3Settings->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::ArchiveS3Settings {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has CannedAcl => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::ArchiveContainerSettings',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::ArchiveContainerSettings',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::ArchiveContainerSettings->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::ArchiveContainerSettings {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has M2tsSettings => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::M2tsSettings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RawSettings => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::RawSettings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::VideoSelectorProgramId',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::VideoSelectorProgramId',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::VideoSelectorProgramId->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::VideoSelectorProgramId {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ProgramId => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::VideoSelectorPid',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::VideoSelectorPid',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::VideoSelectorPid->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::VideoSelectorPid {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Pid => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::VideoBlackFailoverSettings',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::VideoBlackFailoverSettings',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::VideoBlackFailoverSettings->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::VideoBlackFailoverSettings {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has BlackDetectThreshold => (isa => 'Cfn::Value::Double', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has VideoBlackThresholdMsec => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::UdpOutputSettings',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::UdpOutputSettings',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::UdpOutputSettings->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::UdpOutputSettings {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has BufferMsec => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ContainerSettings => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::UdpContainerSettings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Destination => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::OutputLocationRef', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has FecOutputSettings => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::FecOutputSettings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::TeletextSourceSettings',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::TeletextSourceSettings',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::TeletextSourceSettings->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::TeletextSourceSettings {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has OutputRectangle => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::CaptionRectangle', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has PageNumber => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::Scte27SourceSettings',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::Scte27SourceSettings',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::Scte27SourceSettings->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::Scte27SourceSettings {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Pid => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::Scte20SourceSettings',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::Scte20SourceSettings',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::Scte20SourceSettings->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::Scte20SourceSettings {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Convert608To708 => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Source608ChannelNumber => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::RtmpOutputSettings',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::RtmpOutputSettings',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::RtmpOutputSettings->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::RtmpOutputSettings {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has CertificateMode => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ConnectionRetryInterval => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Destination => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::OutputLocationRef', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has NumRetries => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::MultiplexOutputSettings',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::MultiplexOutputSettings',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::MultiplexOutputSettings->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::MultiplexOutputSettings {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Destination => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::OutputLocationRef', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::MsSmoothOutputSettings',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::MsSmoothOutputSettings',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::MsSmoothOutputSettings->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::MsSmoothOutputSettings {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has H265PackagingType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has NameModifier => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::Mpeg2FilterSettings',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::Mpeg2FilterSettings',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::Mpeg2FilterSettings->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::Mpeg2FilterSettings {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has TemporalFilterSettings => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::TemporalFilterSettings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::MediaPackageOutputSettings',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::MediaPackageOutputSettings',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::MediaPackageOutputSettings->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::MediaPackageOutputSettings {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
}

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::KeyProviderSettings',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::KeyProviderSettings',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::KeyProviderSettings->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::KeyProviderSettings {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has StaticKeySettings => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::StaticKeySettings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::InputLossFailoverSettings',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::InputLossFailoverSettings',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::InputLossFailoverSettings->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::InputLossFailoverSettings {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has InputLossThresholdMsec => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::MediaLive::Channel::InputChannelLevel',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::MediaLive::Channel::InputChannelLevel',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::MediaLive::Channel::InputChannelLevel')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::InputChannelLevel',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::InputChannelLevel',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::InputChannelLevel->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::InputChannelLevel {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Gain => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has InputChannel => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::HlsOutputSettings',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::HlsOutputSettings',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::HlsOutputSettings->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::HlsOutputSettings {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has H265PackagingType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has HlsSettings => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::HlsSettings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has NameModifier => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SegmentModifier => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::HlsCdnSettings',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::HlsCdnSettings',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::HlsCdnSettings->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::HlsCdnSettings {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has HlsAkamaiSettings => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::HlsAkamaiSettings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has HlsBasicPutSettings => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::HlsBasicPutSettings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has HlsMediaStoreSettings => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::HlsMediaStoreSettings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has HlsS3Settings => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::HlsS3Settings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has HlsWebdavSettings => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::HlsWebdavSettings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::H265FilterSettings',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::H265FilterSettings',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::H265FilterSettings->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::H265FilterSettings {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has TemporalFilterSettings => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::TemporalFilterSettings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::H265ColorSpaceSettings',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::H265ColorSpaceSettings',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::H265ColorSpaceSettings->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::H265ColorSpaceSettings {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ColorSpacePassthroughSettings => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::ColorSpacePassthroughSettings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Hdr10Settings => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::Hdr10Settings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Rec601Settings => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::Rec601Settings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Rec709Settings => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::Rec709Settings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::H264FilterSettings',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::H264FilterSettings',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::H264FilterSettings->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::H264FilterSettings {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has TemporalFilterSettings => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::TemporalFilterSettings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::H264ColorSpaceSettings',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::H264ColorSpaceSettings',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::H264ColorSpaceSettings->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::H264ColorSpaceSettings {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ColorSpacePassthroughSettings => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::ColorSpacePassthroughSettings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Rec601Settings => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::Rec601Settings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Rec709Settings => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::Rec709Settings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::FrameCaptureOutputSettings',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::FrameCaptureOutputSettings',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::FrameCaptureOutputSettings->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::FrameCaptureOutputSettings {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has NameModifier => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::FrameCaptureCdnSettings',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::FrameCaptureCdnSettings',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::FrameCaptureCdnSettings->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::FrameCaptureCdnSettings {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has FrameCaptureS3Settings => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::FrameCaptureS3Settings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::EmbeddedSourceSettings',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::EmbeddedSourceSettings',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::EmbeddedSourceSettings->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::EmbeddedSourceSettings {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Convert608To708 => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Scte20Detection => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Source608ChannelNumber => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Source608TrackNumber => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::DvbSubSourceSettings',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::DvbSubSourceSettings',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::DvbSubSourceSettings->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::DvbSubSourceSettings {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Pid => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::MediaLive::Channel::CaptionLanguageMapping',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::MediaLive::Channel::CaptionLanguageMapping',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::MediaLive::Channel::CaptionLanguageMapping')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::CaptionLanguageMapping',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::CaptionLanguageMapping',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::CaptionLanguageMapping->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::CaptionLanguageMapping {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has CaptionChannel => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has LanguageCode => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has LanguageDescription => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::AudioTrackSelection',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::AudioTrackSelection',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::AudioTrackSelection->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::AudioTrackSelection {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Tracks => (isa => 'ArrayOfCfn::Resource::Properties::AWS::MediaLive::Channel::AudioTrack', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::AudioSilenceFailoverSettings',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::AudioSilenceFailoverSettings',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::AudioSilenceFailoverSettings->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::AudioSilenceFailoverSettings {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AudioSelectorName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has AudioSilenceThresholdMsec => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::AudioPidSelection',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::AudioPidSelection',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::AudioPidSelection->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::AudioPidSelection {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Pid => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::AudioLanguageSelection',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::AudioLanguageSelection',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::AudioLanguageSelection->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::AudioLanguageSelection {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has LanguageCode => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has LanguageSelectionPolicy => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::AribSourceSettings',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::AribSourceSettings',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::AribSourceSettings->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::AribSourceSettings {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
}

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::ArchiveOutputSettings',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::ArchiveOutputSettings',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::ArchiveOutputSettings->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::ArchiveOutputSettings {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ContainerSettings => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::ArchiveContainerSettings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Extension => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has NameModifier => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::ArchiveCdnSettings',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::ArchiveCdnSettings',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::ArchiveCdnSettings->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::ArchiveCdnSettings {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ArchiveS3Settings => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::ArchiveS3Settings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::AncillarySourceSettings',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::AncillarySourceSettings',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::AncillarySourceSettings->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::AncillarySourceSettings {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has SourceAncillaryChannelNumber => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::WebvttDestinationSettings',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::WebvttDestinationSettings',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::WebvttDestinationSettings->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::WebvttDestinationSettings {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
}

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::WavSettings',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::WavSettings',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::WavSettings->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::WavSettings {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has BitDepth => (isa => 'Cfn::Value::Double', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has CodingMode => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SampleRate => (isa => 'Cfn::Value::Double', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::VideoSelectorSettings',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::VideoSelectorSettings',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::VideoSelectorSettings->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::VideoSelectorSettings {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has VideoSelectorPid => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::VideoSelectorPid', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has VideoSelectorProgramId => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::VideoSelectorProgramId', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::VideoSelectorColorSpaceSettings',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::VideoSelectorColorSpaceSettings',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::VideoSelectorColorSpaceSettings->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::VideoSelectorColorSpaceSettings {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Hdr10Settings => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::Hdr10Settings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::UdpGroupSettings',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::UdpGroupSettings',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::UdpGroupSettings->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::UdpGroupSettings {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has InputLossAction => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TimedMetadataId3Frame => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TimedMetadataId3Period => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::TtmlDestinationSettings',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::TtmlDestinationSettings',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::TtmlDestinationSettings->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::TtmlDestinationSettings {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has StyleControl => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::TeletextDestinationSettings',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::TeletextDestinationSettings',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::TeletextDestinationSettings->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::TeletextDestinationSettings {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
}

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::SmpteTtDestinationSettings',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::SmpteTtDestinationSettings',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::SmpteTtDestinationSettings->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::SmpteTtDestinationSettings {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
}

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::Scte35TimeSignalApos',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::Scte35TimeSignalApos',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::Scte35TimeSignalApos->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::Scte35TimeSignalApos {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AdAvailOffset => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has NoRegionalBlackoutFlag => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has WebDeliveryAllowedFlag => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::Scte35SpliceInsert',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::Scte35SpliceInsert',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::Scte35SpliceInsert->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::Scte35SpliceInsert {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AdAvailOffset => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has NoRegionalBlackoutFlag => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has WebDeliveryAllowedFlag => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::Scte27DestinationSettings',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::Scte27DestinationSettings',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::Scte27DestinationSettings->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::Scte27DestinationSettings {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
}

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::Scte20PlusEmbeddedDestinationSettings',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::Scte20PlusEmbeddedDestinationSettings',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::Scte20PlusEmbeddedDestinationSettings->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::Scte20PlusEmbeddedDestinationSettings {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
}

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::RtmpGroupSettings',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::RtmpGroupSettings',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::RtmpGroupSettings->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::RtmpGroupSettings {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AdMarkers => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has AuthenticationScheme => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has CacheFullBehavior => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has CacheLength => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has CaptionData => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has InputLossAction => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RestartDelay => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::RtmpCaptionInfoDestinationSettings',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::RtmpCaptionInfoDestinationSettings',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::RtmpCaptionInfoDestinationSettings->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::RtmpCaptionInfoDestinationSettings {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
}

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::PassThroughSettings',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::PassThroughSettings',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::PassThroughSettings->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::PassThroughSettings {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
}

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::OutputSettings',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::OutputSettings',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::OutputSettings->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::OutputSettings {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ArchiveOutputSettings => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::ArchiveOutputSettings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has FrameCaptureOutputSettings => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::FrameCaptureOutputSettings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has HlsOutputSettings => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::HlsOutputSettings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has MediaPackageOutputSettings => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::MediaPackageOutputSettings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has MsSmoothOutputSettings => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::MsSmoothOutputSettings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has MultiplexOutputSettings => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::MultiplexOutputSettings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RtmpOutputSettings => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::RtmpOutputSettings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has UdpOutputSettings => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::UdpOutputSettings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::MultiplexGroupSettings',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::MultiplexGroupSettings',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::MultiplexGroupSettings->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::MultiplexGroupSettings {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
}

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::MsSmoothGroupSettings',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::MsSmoothGroupSettings',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::MsSmoothGroupSettings->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::MsSmoothGroupSettings {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AcquisitionPointId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has AudioOnlyTimecodeControl => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has CertificateMode => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ConnectionRetryInterval => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Destination => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::OutputLocationRef', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has EventId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has EventIdMode => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has EventStopBehavior => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has FilecacheDuration => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has FragmentLength => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has InputLossAction => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has NumRetries => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RestartDelay => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SegmentationMode => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SendDelayMs => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SparseTrackType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has StreamManifestBehavior => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TimestampOffset => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TimestampOffsetMode => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::Mpeg2Settings',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::Mpeg2Settings',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::Mpeg2Settings->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::Mpeg2Settings {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AdaptiveQuantization => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has AfdSignaling => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ColorMetadata => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ColorSpace => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DisplayAspectRatio => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has FilterSettings => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::Mpeg2FilterSettings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has FixedAfd => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has FramerateDenominator => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has FramerateNumerator => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has GopClosedCadence => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has GopNumBFrames => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has GopSize => (isa => 'Cfn::Value::Double', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has GopSizeUnits => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ScanType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SubgopLength => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TimecodeInsertion => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::Mp2Settings',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::Mp2Settings',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::Mp2Settings->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::Mp2Settings {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Bitrate => (isa => 'Cfn::Value::Double', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has CodingMode => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SampleRate => (isa => 'Cfn::Value::Double', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::MediaPackageGroupSettings',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::MediaPackageGroupSettings',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::MediaPackageGroupSettings->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::MediaPackageGroupSettings {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Destination => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::OutputLocationRef', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::HtmlMotionGraphicsSettings',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::HtmlMotionGraphicsSettings',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::HtmlMotionGraphicsSettings->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::HtmlMotionGraphicsSettings {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
}

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::HlsInputSettings',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::HlsInputSettings',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::HlsInputSettings->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::HlsInputSettings {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Bandwidth => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has BufferSegments => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Retries => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RetryInterval => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::HlsGroupSettings',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::HlsGroupSettings',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::HlsGroupSettings->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::HlsGroupSettings {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AdMarkers => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has BaseUrlContent => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has BaseUrlContent1 => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has BaseUrlManifest => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has BaseUrlManifest1 => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has CaptionLanguageMappings => (isa => 'ArrayOfCfn::Resource::Properties::AWS::MediaLive::Channel::CaptionLanguageMapping', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has CaptionLanguageSetting => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ClientCache => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has CodecSpecification => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ConstantIv => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Destination => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::OutputLocationRef', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DirectoryStructure => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DiscontinuityTags => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has EncryptionType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has HlsCdnSettings => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::HlsCdnSettings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has HlsId3SegmentTagging => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has IFrameOnlyPlaylists => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has IncompleteSegmentBehavior => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has IndexNSegments => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has InputLossAction => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has IvInManifest => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has IvSource => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has KeepSegments => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has KeyFormat => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has KeyFormatVersions => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has KeyProviderSettings => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::KeyProviderSettings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ManifestCompression => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ManifestDurationFormat => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has MinSegmentLength => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Mode => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has OutputSelection => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ProgramDateTime => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ProgramDateTimePeriod => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RedundantManifest => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SegmentationMode => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SegmentLength => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SegmentsPerSubdirectory => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has StreamInfResolution => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TimedMetadataId3Frame => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TimedMetadataId3Period => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TimestampDeltaMilliseconds => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TsFileMode => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::H265Settings',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::H265Settings',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::H265Settings->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::H265Settings {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AdaptiveQuantization => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has AfdSignaling => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has AlternativeTransferFunction => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Bitrate => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has BufSize => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ColorMetadata => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ColorSpaceSettings => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::H265ColorSpaceSettings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has FilterSettings => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::H265FilterSettings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has FixedAfd => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has FlickerAq => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has FramerateDenominator => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has FramerateNumerator => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has GopClosedCadence => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has GopSize => (isa => 'Cfn::Value::Double', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has GopSizeUnits => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Level => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has LookAheadRateControl => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has MaxBitrate => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has MinIInterval => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ParDenominator => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ParNumerator => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Profile => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has QvbrQualityLevel => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RateControlMode => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ScanType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SceneChangeDetect => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Slices => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Tier => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TimecodeInsertion => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::H264Settings',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::H264Settings',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::H264Settings->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::H264Settings {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AdaptiveQuantization => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has AfdSignaling => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Bitrate => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has BufFillPct => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has BufSize => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ColorMetadata => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ColorSpaceSettings => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::H264ColorSpaceSettings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has EntropyEncoding => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has FilterSettings => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::H264FilterSettings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has FixedAfd => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has FlickerAq => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ForceFieldPictures => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has FramerateControl => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has FramerateDenominator => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has FramerateNumerator => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has GopBReference => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has GopClosedCadence => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has GopNumBFrames => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has GopSize => (isa => 'Cfn::Value::Double', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has GopSizeUnits => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Level => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has LookAheadRateControl => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has MaxBitrate => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has MinIInterval => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has NumRefFrames => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ParControl => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ParDenominator => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ParNumerator => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Profile => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has QualityLevel => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has QvbrQualityLevel => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RateControlMode => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ScanType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SceneChangeDetect => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Slices => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Softness => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SpatialAq => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SubgopLength => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Syntax => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TemporalAq => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TimecodeInsertion => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::FrameCaptureSettings',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::FrameCaptureSettings',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::FrameCaptureSettings->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::FrameCaptureSettings {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has CaptureInterval => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has CaptureIntervalUnits => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::FrameCaptureGroupSettings',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::FrameCaptureGroupSettings',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::FrameCaptureGroupSettings->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::FrameCaptureGroupSettings {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Destination => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::OutputLocationRef', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has FrameCaptureCdnSettings => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::FrameCaptureCdnSettings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::FailoverConditionSettings',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::FailoverConditionSettings',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::FailoverConditionSettings->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::FailoverConditionSettings {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AudioSilenceSettings => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::AudioSilenceFailoverSettings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has InputLossSettings => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::InputLossFailoverSettings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has VideoBlackSettings => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::VideoBlackFailoverSettings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::EmbeddedPlusScte20DestinationSettings',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::EmbeddedPlusScte20DestinationSettings',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::EmbeddedPlusScte20DestinationSettings->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::EmbeddedPlusScte20DestinationSettings {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
}

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::EmbeddedDestinationSettings',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::EmbeddedDestinationSettings',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::EmbeddedDestinationSettings->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::EmbeddedDestinationSettings {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
}

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::EbuTtDDestinationSettings',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::EbuTtDDestinationSettings',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::EbuTtDDestinationSettings->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::EbuTtDDestinationSettings {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has CopyrightHolder => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has FillLineGap => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has FontFamily => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has StyleControl => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::Eac3Settings',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::Eac3Settings',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::Eac3Settings->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::Eac3Settings {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AttenuationControl => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Bitrate => (isa => 'Cfn::Value::Double', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has BitstreamMode => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has CodingMode => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DcFilter => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Dialnorm => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DrcLine => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DrcRf => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has LfeControl => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has LfeFilter => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has LoRoCenterMixLevel => (isa => 'Cfn::Value::Double', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has LoRoSurroundMixLevel => (isa => 'Cfn::Value::Double', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has LtRtCenterMixLevel => (isa => 'Cfn::Value::Double', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has LtRtSurroundMixLevel => (isa => 'Cfn::Value::Double', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has MetadataControl => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has PassthroughControl => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has PhaseControl => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has StereoDownmix => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SurroundExMode => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SurroundMode => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::DvbSubDestinationSettings',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::DvbSubDestinationSettings',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::DvbSubDestinationSettings->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::DvbSubDestinationSettings {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Alignment => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has BackgroundColor => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has BackgroundOpacity => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Font => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::InputLocation', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has FontColor => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has FontOpacity => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has FontResolution => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has FontSize => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has OutlineColor => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has OutlineSize => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ShadowColor => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ShadowOpacity => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ShadowXOffset => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ShadowYOffset => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TeletextGridControl => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has XPosition => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has YPosition => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::CaptionSelectorSettings',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::CaptionSelectorSettings',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::CaptionSelectorSettings->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::CaptionSelectorSettings {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AncillarySourceSettings => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::AncillarySourceSettings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has AribSourceSettings => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::AribSourceSettings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DvbSubSourceSettings => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::DvbSubSourceSettings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has EmbeddedSourceSettings => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::EmbeddedSourceSettings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Scte20SourceSettings => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::Scte20SourceSettings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Scte27SourceSettings => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::Scte27SourceSettings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TeletextSourceSettings => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::TeletextSourceSettings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::BurnInDestinationSettings',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::BurnInDestinationSettings',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::BurnInDestinationSettings->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::BurnInDestinationSettings {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Alignment => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has BackgroundColor => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has BackgroundOpacity => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Font => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::InputLocation', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has FontColor => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has FontOpacity => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has FontResolution => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has FontSize => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has OutlineColor => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has OutlineSize => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ShadowColor => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ShadowOpacity => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ShadowXOffset => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ShadowYOffset => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TeletextGridControl => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has XPosition => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has YPosition => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::AudioSelectorSettings',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::AudioSelectorSettings',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::AudioSelectorSettings->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::AudioSelectorSettings {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AudioLanguageSelection => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::AudioLanguageSelection', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has AudioPidSelection => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::AudioPidSelection', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has AudioTrackSelection => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::AudioTrackSelection', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::MediaLive::Channel::AudioChannelMapping',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::MediaLive::Channel::AudioChannelMapping',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::MediaLive::Channel::AudioChannelMapping')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::AudioChannelMapping',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::AudioChannelMapping',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::AudioChannelMapping->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::AudioChannelMapping {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has InputChannelLevels => (isa => 'ArrayOfCfn::Resource::Properties::AWS::MediaLive::Channel::InputChannelLevel', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has OutputChannel => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::AribDestinationSettings',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::AribDestinationSettings',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::AribDestinationSettings->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::AribDestinationSettings {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
}

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::ArchiveGroupSettings',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::ArchiveGroupSettings',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::ArchiveGroupSettings->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::ArchiveGroupSettings {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ArchiveCdnSettings => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::ArchiveCdnSettings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Destination => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::OutputLocationRef', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RolloverInterval => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::Ac3Settings',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::Ac3Settings',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::Ac3Settings->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::Ac3Settings {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Bitrate => (isa => 'Cfn::Value::Double', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has BitstreamMode => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has CodingMode => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Dialnorm => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DrcProfile => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has LfeFilter => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has MetadataControl => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::AacSettings',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::AacSettings',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::AacSettings->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::AacSettings {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Bitrate => (isa => 'Cfn::Value::Double', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has CodingMode => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has InputType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Profile => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RateControlMode => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RawFormat => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SampleRate => (isa => 'Cfn::Value::Double', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Spec => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has VbrQuality => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::VideoSelector',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::VideoSelector',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::VideoSelector->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::VideoSelector {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ColorSpace => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ColorSpaceSettings => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::VideoSelectorColorSpaceSettings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ColorSpaceUsage => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SelectorSettings => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::VideoSelectorSettings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::VideoCodecSettings',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::VideoCodecSettings',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::VideoCodecSettings->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::VideoCodecSettings {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has FrameCaptureSettings => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::FrameCaptureSettings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has H264Settings => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::H264Settings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has H265Settings => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::H265Settings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Mpeg2Settings => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::Mpeg2Settings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::RemixSettings',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::RemixSettings',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::RemixSettings->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::RemixSettings {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ChannelMappings => (isa => 'ArrayOfCfn::Resource::Properties::AWS::MediaLive::Channel::AudioChannelMapping', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ChannelsIn => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ChannelsOut => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::OutputGroupSettings',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::OutputGroupSettings',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::OutputGroupSettings->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::OutputGroupSettings {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ArchiveGroupSettings => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::ArchiveGroupSettings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has FrameCaptureGroupSettings => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::FrameCaptureGroupSettings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has HlsGroupSettings => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::HlsGroupSettings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has MediaPackageGroupSettings => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::MediaPackageGroupSettings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has MsSmoothGroupSettings => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::MsSmoothGroupSettings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has MultiplexGroupSettings => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::MultiplexGroupSettings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RtmpGroupSettings => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::RtmpGroupSettings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has UdpGroupSettings => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::UdpGroupSettings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::MediaLive::Channel::Output',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::MediaLive::Channel::Output',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::MediaLive::Channel::Output')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::Output',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::Output',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::Output->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::Output {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AudioDescriptionNames => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has CaptionDescriptionNames => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has OutputName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has OutputSettings => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::OutputSettings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has VideoDescriptionName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::NetworkInputSettings',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::NetworkInputSettings',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::NetworkInputSettings->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::NetworkInputSettings {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has HlsInputSettings => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::HlsInputSettings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ServerValidation => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::MotionGraphicsSettings',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::MotionGraphicsSettings',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::MotionGraphicsSettings->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::MotionGraphicsSettings {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has HtmlMotionGraphicsSettings => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::HtmlMotionGraphicsSettings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::InputLossBehavior',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::InputLossBehavior',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::InputLossBehavior->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::InputLossBehavior {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has BlackFrameMsec => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has InputLossImageColor => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has InputLossImageSlate => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::InputLocation', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has InputLossImageType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RepeatFrameMsec => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::MediaLive::Channel::FailoverCondition',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::MediaLive::Channel::FailoverCondition',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::MediaLive::Channel::FailoverCondition')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::FailoverCondition',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::FailoverCondition',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::FailoverCondition->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::FailoverCondition {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has FailoverConditionSettings => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::FailoverConditionSettings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::MediaLive::Channel::CaptionSelector',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::MediaLive::Channel::CaptionSelector',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::MediaLive::Channel::CaptionSelector')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::CaptionSelector',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::CaptionSelector',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::CaptionSelector->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::CaptionSelector {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has LanguageCode => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SelectorSettings => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::CaptionSelectorSettings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::CaptionDestinationSettings',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::CaptionDestinationSettings',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::CaptionDestinationSettings->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::CaptionDestinationSettings {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AribDestinationSettings => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::AribDestinationSettings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has BurnInDestinationSettings => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::BurnInDestinationSettings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DvbSubDestinationSettings => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::DvbSubDestinationSettings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has EbuTtDDestinationSettings => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::EbuTtDDestinationSettings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has EmbeddedDestinationSettings => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::EmbeddedDestinationSettings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has EmbeddedPlusScte20DestinationSettings => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::EmbeddedPlusScte20DestinationSettings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RtmpCaptionInfoDestinationSettings => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::RtmpCaptionInfoDestinationSettings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Scte20PlusEmbeddedDestinationSettings => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::Scte20PlusEmbeddedDestinationSettings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Scte27DestinationSettings => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::Scte27DestinationSettings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SmpteTtDestinationSettings => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::SmpteTtDestinationSettings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TeletextDestinationSettings => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::TeletextDestinationSettings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TtmlDestinationSettings => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::TtmlDestinationSettings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has WebvttDestinationSettings => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::WebvttDestinationSettings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::AvailSettings',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::AvailSettings',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::AvailSettings->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::AvailSettings {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Scte35SpliceInsert => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::Scte35SpliceInsert', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Scte35TimeSignalApos => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::Scte35TimeSignalApos', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::MediaLive::Channel::AudioSelector',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::MediaLive::Channel::AudioSelector',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::MediaLive::Channel::AudioSelector')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::AudioSelector',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::AudioSelector',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::AudioSelector->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::AudioSelector {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SelectorSettings => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::AudioSelectorSettings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::AudioNormalizationSettings',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::AudioNormalizationSettings',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::AudioNormalizationSettings->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::AudioNormalizationSettings {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Algorithm => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has AlgorithmControl => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TargetLkfs => (isa => 'Cfn::Value::Double', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::AudioCodecSettings',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::AudioCodecSettings',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::AudioCodecSettings->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::AudioCodecSettings {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AacSettings => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::AacSettings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Ac3Settings => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::Ac3Settings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Eac3Settings => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::Eac3Settings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Mp2Settings => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::Mp2Settings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has PassThroughSettings => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::PassThroughSettings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has WavSettings => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::WavSettings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::MediaLive::Channel::VideoDescription',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::MediaLive::Channel::VideoDescription',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::MediaLive::Channel::VideoDescription')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::VideoDescription',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::VideoDescription',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::VideoDescription->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::VideoDescription {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has CodecSettings => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::VideoCodecSettings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Height => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RespondToAfd => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ScalingBehavior => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Sharpness => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Width => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::TimecodeConfig',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::TimecodeConfig',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::TimecodeConfig->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::TimecodeConfig {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Source => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SyncThreshold => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::MediaLive::Channel::OutputGroup',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::MediaLive::Channel::OutputGroup',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::MediaLive::Channel::OutputGroup')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::OutputGroup',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::OutputGroup',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::OutputGroup->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::OutputGroup {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has OutputGroupSettings => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::OutputGroupSettings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Outputs => (isa => 'ArrayOfCfn::Resource::Properties::AWS::MediaLive::Channel::Output', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::MediaLive::Channel::OutputDestinationSettings',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::MediaLive::Channel::OutputDestinationSettings',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::MediaLive::Channel::OutputDestinationSettings')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::OutputDestinationSettings',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::OutputDestinationSettings',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::OutputDestinationSettings->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::OutputDestinationSettings {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has PasswordParam => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has StreamName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Url => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Username => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::NielsenConfiguration',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::NielsenConfiguration',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::NielsenConfiguration->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::NielsenConfiguration {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has DistributorId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has NielsenPcmToId3Tagging => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::MultiplexProgramChannelDestinationSettings',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::MultiplexProgramChannelDestinationSettings',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::MultiplexProgramChannelDestinationSettings->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::MultiplexProgramChannelDestinationSettings {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has MultiplexId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ProgramName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::MotionGraphicsConfiguration',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::MotionGraphicsConfiguration',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::MotionGraphicsConfiguration->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::MotionGraphicsConfiguration {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has MotionGraphicsInsertion => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has MotionGraphicsSettings => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::MotionGraphicsSettings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::MediaLive::Channel::MediaPackageOutputDestinationSettings',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::MediaLive::Channel::MediaPackageOutputDestinationSettings',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::MediaLive::Channel::MediaPackageOutputDestinationSettings')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::MediaPackageOutputDestinationSettings',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::MediaPackageOutputDestinationSettings',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::MediaPackageOutputDestinationSettings->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::MediaPackageOutputDestinationSettings {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ChannelId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::InputSettings',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::InputSettings',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::InputSettings->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::InputSettings {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AudioSelectors => (isa => 'ArrayOfCfn::Resource::Properties::AWS::MediaLive::Channel::AudioSelector', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has CaptionSelectors => (isa => 'ArrayOfCfn::Resource::Properties::AWS::MediaLive::Channel::CaptionSelector', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DeblockFilter => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DenoiseFilter => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has FilterStrength => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has InputFilter => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has NetworkInputSettings => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::NetworkInputSettings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Smpte2038DataPreference => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SourceEndBehavior => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has VideoSelector => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::VideoSelector', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::GlobalConfiguration',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::GlobalConfiguration',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::GlobalConfiguration->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::GlobalConfiguration {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has InitialAudioGain => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has InputEndAction => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has InputLossBehavior => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::InputLossBehavior', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has OutputLockingMode => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has OutputTimingSource => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SupportLowFramerateInputs => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::FeatureActivations',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::FeatureActivations',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::FeatureActivations->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::FeatureActivations {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has InputPrepareScheduleActions => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::MediaLive::Channel::CaptionDescription',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::MediaLive::Channel::CaptionDescription',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::MediaLive::Channel::CaptionDescription')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::CaptionDescription',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::CaptionDescription',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::CaptionDescription->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::CaptionDescription {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has CaptionSelectorName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DestinationSettings => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::CaptionDestinationSettings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has LanguageCode => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has LanguageDescription => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::BlackoutSlate',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::BlackoutSlate',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::BlackoutSlate->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::BlackoutSlate {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has BlackoutSlateImage => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::InputLocation', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has NetworkEndBlackout => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has NetworkEndBlackoutImage => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::InputLocation', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has NetworkId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has State => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::AvailConfiguration',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::AvailConfiguration',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::AvailConfiguration->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::AvailConfiguration {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AvailSettings => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::AvailSettings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::AvailBlanking',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::AvailBlanking',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::AvailBlanking->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::AvailBlanking {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AvailBlankingImage => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::InputLocation', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has State => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::AutomaticInputFailoverSettings',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::AutomaticInputFailoverSettings',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::AutomaticInputFailoverSettings->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::AutomaticInputFailoverSettings {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ErrorClearTimeMsec => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has FailoverConditions => (isa => 'ArrayOfCfn::Resource::Properties::AWS::MediaLive::Channel::FailoverCondition', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has InputPreference => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SecondaryInputId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::MediaLive::Channel::AudioDescription',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::MediaLive::Channel::AudioDescription',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::MediaLive::Channel::AudioDescription')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::AudioDescription',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::AudioDescription',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::AudioDescription->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::AudioDescription {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AudioNormalizationSettings => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::AudioNormalizationSettings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has AudioSelectorName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has AudioType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has AudioTypeControl => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has CodecSettings => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::AudioCodecSettings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has LanguageCode => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has LanguageCodeControl => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RemixSettings => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::RemixSettings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has StreamName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::VpcOutputSettings',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::VpcOutputSettings',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::VpcOutputSettings->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::VpcOutputSettings {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has PublicAddressAllocationIds => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SecurityGroupIds => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SubnetIds => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::MediaLive::Channel::OutputDestination',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::MediaLive::Channel::OutputDestination',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::MediaLive::Channel::OutputDestination')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::OutputDestination',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::OutputDestination',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::OutputDestination->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::OutputDestination {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Id => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has MediaPackageSettings => (isa => 'ArrayOfCfn::Resource::Properties::AWS::MediaLive::Channel::MediaPackageOutputDestinationSettings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has MultiplexSettings => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::MultiplexProgramChannelDestinationSettings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Settings => (isa => 'ArrayOfCfn::Resource::Properties::AWS::MediaLive::Channel::OutputDestinationSettings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::InputSpecification',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::InputSpecification',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::InputSpecification->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::InputSpecification {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Codec => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has MaximumBitrate => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Resolution => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::MediaLive::Channel::InputAttachment',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::MediaLive::Channel::InputAttachment',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::MediaLive::Channel::InputAttachment')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::InputAttachment',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::InputAttachment',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::InputAttachment->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::InputAttachment {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AutomaticInputFailoverSettings => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::AutomaticInputFailoverSettings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has InputAttachmentName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has InputId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has InputSettings => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::InputSettings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::EncoderSettings',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::EncoderSettings',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::EncoderSettings->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::EncoderSettings {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AudioDescriptions => (isa => 'ArrayOfCfn::Resource::Properties::AWS::MediaLive::Channel::AudioDescription', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has AvailBlanking => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::AvailBlanking', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has AvailConfiguration => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::AvailConfiguration', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has BlackoutSlate => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::BlackoutSlate', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has CaptionDescriptions => (isa => 'ArrayOfCfn::Resource::Properties::AWS::MediaLive::Channel::CaptionDescription', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has FeatureActivations => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::FeatureActivations', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has GlobalConfiguration => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::GlobalConfiguration', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has MotionGraphicsConfiguration => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::MotionGraphicsConfiguration', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has NielsenConfiguration => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::NielsenConfiguration', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has OutputGroups => (isa => 'ArrayOfCfn::Resource::Properties::AWS::MediaLive::Channel::OutputGroup', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TimecodeConfig => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::TimecodeConfig', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has VideoDescriptions => (isa => 'ArrayOfCfn::Resource::Properties::AWS::MediaLive::Channel::VideoDescription', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::CdiInputSpecification',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::CdiInputSpecification',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::CdiInputSpecification->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::Channel::CdiInputSpecification {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Resolution => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::MediaLive::Channel {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has CdiInputSpecification => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::CdiInputSpecification', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ChannelClass => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Destinations => (isa => 'ArrayOfCfn::Resource::Properties::AWS::MediaLive::Channel::OutputDestination', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has EncoderSettings => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::EncoderSettings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has InputAttachments => (isa => 'ArrayOfCfn::Resource::Properties::AWS::MediaLive::Channel::InputAttachment', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has InputSpecification => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::InputSpecification', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has LogLevel => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RoleArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Tags => (isa => 'Cfn::Value::Json|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Vpc => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::VpcOutputSettings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::MediaLive::Channel - Cfn resource for AWS::MediaLive::Channel

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::MediaLive::Channel.

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
