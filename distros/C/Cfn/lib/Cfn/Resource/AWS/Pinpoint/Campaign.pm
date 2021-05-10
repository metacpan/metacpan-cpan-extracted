# AWS::Pinpoint::Campaign generated from spec 34.0.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::Pinpoint::Campaign',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::Pinpoint::Campaign->new( %$_ ) };

package Cfn::Resource::AWS::Pinpoint::Campaign {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::Pinpoint::Campaign', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [ 'Arn','CampaignId' ]
  }
  sub supported_regions {
    [ 'ap-south-1','ap-southeast-2','eu-central-1','eu-west-1','us-east-1','us-west-2' ]
  }
}



subtype 'Cfn::Resource::Properties::AWS::Pinpoint::Campaign::SetDimension',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Pinpoint::Campaign::SetDimension',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Pinpoint::Campaign::SetDimension->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Pinpoint::Campaign::SetDimension {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has DimensionType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Values => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::Pinpoint::Campaign::EventDimensions',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Pinpoint::Campaign::EventDimensions',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Pinpoint::Campaign::EventDimensions->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Pinpoint::Campaign::EventDimensions {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Attributes => (isa => 'Cfn::Value::Json|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has EventType => (isa => 'Cfn::Resource::Properties::AWS::Pinpoint::Campaign::SetDimension', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Metrics => (isa => 'Cfn::Value::Json|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::Pinpoint::Campaign::QuietTime',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Pinpoint::Campaign::QuietTime',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Pinpoint::Campaign::QuietTime->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Pinpoint::Campaign::QuietTime {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has End => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Start => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::Pinpoint::Campaign::Message',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Pinpoint::Campaign::Message',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Pinpoint::Campaign::Message->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Pinpoint::Campaign::Message {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Action => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Body => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ImageIconUrl => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ImageSmallIconUrl => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ImageUrl => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has JsonBody => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has MediaUrl => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RawContent => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SilentPush => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TimeToLive => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Title => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Url => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::Pinpoint::Campaign::CampaignSmsMessage',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Pinpoint::Campaign::CampaignSmsMessage',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Pinpoint::Campaign::CampaignSmsMessage->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Pinpoint::Campaign::CampaignSmsMessage {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Body => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has EntityId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has MessageType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has OriginationNumber => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SenderId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TemplateId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::Pinpoint::Campaign::CampaignEventFilter',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Pinpoint::Campaign::CampaignEventFilter',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Pinpoint::Campaign::CampaignEventFilter->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Pinpoint::Campaign::CampaignEventFilter {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Dimensions => (isa => 'Cfn::Resource::Properties::AWS::Pinpoint::Campaign::EventDimensions', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has FilterType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::Pinpoint::Campaign::CampaignEmailMessage',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Pinpoint::Campaign::CampaignEmailMessage',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Pinpoint::Campaign::CampaignEmailMessage->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Pinpoint::Campaign::CampaignEmailMessage {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Body => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has FromAddress => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has HtmlBody => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Title => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::Pinpoint::Campaign::Schedule',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Pinpoint::Campaign::Schedule',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Pinpoint::Campaign::Schedule->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Pinpoint::Campaign::Schedule {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has EndTime => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has EventFilter => (isa => 'Cfn::Resource::Properties::AWS::Pinpoint::Campaign::CampaignEventFilter', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Frequency => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has IsLocalTime => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has QuietTime => (isa => 'Cfn::Resource::Properties::AWS::Pinpoint::Campaign::QuietTime', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has StartTime => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TimeZone => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::Pinpoint::Campaign::MessageConfiguration',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Pinpoint::Campaign::MessageConfiguration',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Pinpoint::Campaign::MessageConfiguration->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Pinpoint::Campaign::MessageConfiguration {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ADMMessage => (isa => 'Cfn::Resource::Properties::AWS::Pinpoint::Campaign::Message', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has APNSMessage => (isa => 'Cfn::Resource::Properties::AWS::Pinpoint::Campaign::Message', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has BaiduMessage => (isa => 'Cfn::Resource::Properties::AWS::Pinpoint::Campaign::Message', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DefaultMessage => (isa => 'Cfn::Resource::Properties::AWS::Pinpoint::Campaign::Message', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has EmailMessage => (isa => 'Cfn::Resource::Properties::AWS::Pinpoint::Campaign::CampaignEmailMessage', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has GCMMessage => (isa => 'Cfn::Resource::Properties::AWS::Pinpoint::Campaign::Message', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SMSMessage => (isa => 'Cfn::Resource::Properties::AWS::Pinpoint::Campaign::CampaignSmsMessage', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::Pinpoint::Campaign::WriteTreatmentResource',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::Pinpoint::Campaign::WriteTreatmentResource',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::Pinpoint::Campaign::WriteTreatmentResource')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::Pinpoint::Campaign::WriteTreatmentResource',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Pinpoint::Campaign::WriteTreatmentResource',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Pinpoint::Campaign::WriteTreatmentResource->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Pinpoint::Campaign::WriteTreatmentResource {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has MessageConfiguration => (isa => 'Cfn::Resource::Properties::AWS::Pinpoint::Campaign::MessageConfiguration', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Schedule => (isa => 'Cfn::Resource::Properties::AWS::Pinpoint::Campaign::Schedule', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SizePercent => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TreatmentDescription => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TreatmentName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::Pinpoint::Campaign::MetricDimension',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Pinpoint::Campaign::MetricDimension',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Pinpoint::Campaign::MetricDimension->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Pinpoint::Campaign::MetricDimension {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ComparisonOperator => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Value => (isa => 'Cfn::Value::Double', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::Pinpoint::Campaign::Limits',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Pinpoint::Campaign::Limits',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Pinpoint::Campaign::Limits->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Pinpoint::Campaign::Limits {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Daily => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has MaximumDuration => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has MessagesPerSecond => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Total => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::Pinpoint::Campaign::CampaignHook',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Pinpoint::Campaign::CampaignHook',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Pinpoint::Campaign::CampaignHook->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Pinpoint::Campaign::CampaignHook {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has LambdaFunctionName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Mode => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has WebUrl => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::Pinpoint::Campaign::AttributeDimension',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Pinpoint::Campaign::AttributeDimension',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Pinpoint::Campaign::AttributeDimension->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Pinpoint::Campaign::AttributeDimension {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AttributeType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Values => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::Pinpoint::Campaign {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has AdditionalTreatments => (isa => 'ArrayOfCfn::Resource::Properties::AWS::Pinpoint::Campaign::WriteTreatmentResource', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ApplicationId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has CampaignHook => (isa => 'Cfn::Resource::Properties::AWS::Pinpoint::Campaign::CampaignHook', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Description => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has HoldoutPercent => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has IsPaused => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Limits => (isa => 'Cfn::Resource::Properties::AWS::Pinpoint::Campaign::Limits', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has MessageConfiguration => (isa => 'Cfn::Resource::Properties::AWS::Pinpoint::Campaign::MessageConfiguration', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Schedule => (isa => 'Cfn::Resource::Properties::AWS::Pinpoint::Campaign::Schedule', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SegmentId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SegmentVersion => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Tags => (isa => 'Cfn::Value::Json|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TreatmentDescription => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TreatmentName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::Pinpoint::Campaign - Cfn resource for AWS::Pinpoint::Campaign

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::Pinpoint::Campaign.

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
