# AWS::MediaLive::Channel generated from spec 4.1.0
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



subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::VideoSelectorProgramId',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::VideoSelectorProgramId',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::MediaLive::Channel::VideoSelectorProgramIdValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::MediaLive::Channel::VideoSelectorProgramIdValue {
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
       return Cfn::Resource::Properties::AWS::MediaLive::Channel::VideoSelectorPidValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::MediaLive::Channel::VideoSelectorPidValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Pid => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::TeletextSourceSettings',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::TeletextSourceSettings',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::MediaLive::Channel::TeletextSourceSettingsValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::MediaLive::Channel::TeletextSourceSettingsValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
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
       return Cfn::Resource::Properties::AWS::MediaLive::Channel::Scte27SourceSettingsValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::MediaLive::Channel::Scte27SourceSettingsValue {
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
       return Cfn::Resource::Properties::AWS::MediaLive::Channel::Scte20SourceSettingsValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::MediaLive::Channel::Scte20SourceSettingsValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Convert608To708 => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Source608ChannelNumber => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::EmbeddedSourceSettings',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::EmbeddedSourceSettings',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::MediaLive::Channel::EmbeddedSourceSettingsValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::MediaLive::Channel::EmbeddedSourceSettingsValue {
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
       return Cfn::Resource::Properties::AWS::MediaLive::Channel::DvbSubSourceSettingsValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::MediaLive::Channel::DvbSubSourceSettingsValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Pid => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::AudioPidSelection',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::AudioPidSelection',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::MediaLive::Channel::AudioPidSelectionValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::MediaLive::Channel::AudioPidSelectionValue {
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
       return Cfn::Resource::Properties::AWS::MediaLive::Channel::AudioLanguageSelectionValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::MediaLive::Channel::AudioLanguageSelectionValue {
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
       return Cfn::Resource::Properties::AWS::MediaLive::Channel::AribSourceSettingsValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::MediaLive::Channel::AribSourceSettingsValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
}

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::VideoSelectorSettings',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::VideoSelectorSettings',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::MediaLive::Channel::VideoSelectorSettingsValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::MediaLive::Channel::VideoSelectorSettingsValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has VideoSelectorPid => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::VideoSelectorPid', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has VideoSelectorProgramId => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::VideoSelectorProgramId', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::HlsInputSettings',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::HlsInputSettings',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::MediaLive::Channel::HlsInputSettingsValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::MediaLive::Channel::HlsInputSettingsValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Bandwidth => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has BufferSegments => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Retries => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RetryInterval => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::CaptionSelectorSettings',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::CaptionSelectorSettings',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::MediaLive::Channel::CaptionSelectorSettingsValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::MediaLive::Channel::CaptionSelectorSettingsValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AribSourceSettings => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::AribSourceSettings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DvbSubSourceSettings => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::DvbSubSourceSettings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has EmbeddedSourceSettings => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::EmbeddedSourceSettings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Scte20SourceSettings => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::Scte20SourceSettings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Scte27SourceSettings => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::Scte27SourceSettings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TeletextSourceSettings => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::TeletextSourceSettings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::AudioSelectorSettings',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::AudioSelectorSettings',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::MediaLive::Channel::AudioSelectorSettingsValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::MediaLive::Channel::AudioSelectorSettingsValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AudioLanguageSelection => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::AudioLanguageSelection', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has AudioPidSelection => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::AudioPidSelection', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::VideoSelector',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::VideoSelector',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::MediaLive::Channel::VideoSelectorValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::MediaLive::Channel::VideoSelectorValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ColorSpace => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ColorSpaceUsage => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SelectorSettings => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::VideoSelectorSettings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MediaLive::Channel::NetworkInputSettings',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::Channel::NetworkInputSettings',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::MediaLive::Channel::NetworkInputSettingsValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::MediaLive::Channel::NetworkInputSettingsValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has HlsInputSettings => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::HlsInputSettings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ServerValidation => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
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
       return Cfn::Resource::Properties::AWS::MediaLive::Channel::CaptionSelectorValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::MediaLive::Channel::CaptionSelectorValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has LanguageCode => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SelectorSettings => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::CaptionSelectorSettings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
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
       return Cfn::Resource::Properties::AWS::MediaLive::Channel::AudioSelectorValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::MediaLive::Channel::AudioSelectorValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SelectorSettings => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::AudioSelectorSettings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
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
       return Cfn::Resource::Properties::AWS::MediaLive::Channel::OutputDestinationSettingsValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::MediaLive::Channel::OutputDestinationSettingsValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has PasswordParam => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has StreamName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Url => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Username => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
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
       return Cfn::Resource::Properties::AWS::MediaLive::Channel::MediaPackageOutputDestinationSettingsValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::MediaLive::Channel::MediaPackageOutputDestinationSettingsValue {
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
       return Cfn::Resource::Properties::AWS::MediaLive::Channel::InputSettingsValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::MediaLive::Channel::InputSettingsValue {
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
  has SourceEndBehavior => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has VideoSelector => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::VideoSelector', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
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
       return Cfn::Resource::Properties::AWS::MediaLive::Channel::OutputDestinationValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::MediaLive::Channel::OutputDestinationValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Id => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has MediaPackageSettings => (isa => 'ArrayOfCfn::Resource::Properties::AWS::MediaLive::Channel::MediaPackageOutputDestinationSettings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
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
       return Cfn::Resource::Properties::AWS::MediaLive::Channel::InputSpecificationValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::MediaLive::Channel::InputSpecificationValue {
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
       return Cfn::Resource::Properties::AWS::MediaLive::Channel::InputAttachmentValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::MediaLive::Channel::InputAttachmentValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has InputAttachmentName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has InputId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has InputSettings => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::InputSettings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::MediaLive::Channel {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has ChannelClass => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Destinations => (isa => 'ArrayOfCfn::Resource::Properties::AWS::MediaLive::Channel::OutputDestination', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has EncoderSettings => (isa => 'Cfn::Value::Json|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has InputAttachments => (isa => 'ArrayOfCfn::Resource::Properties::AWS::MediaLive::Channel::InputAttachment', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has InputSpecification => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::Channel::InputSpecification', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has LogLevel => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RoleArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Tags => (isa => 'Cfn::Value::Json|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
