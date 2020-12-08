# AWS::Pinpoint::ApplicationSettings generated from spec 18.4.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::Pinpoint::ApplicationSettings',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::Pinpoint::ApplicationSettings->new( %$_ ) };

package Cfn::Resource::AWS::Pinpoint::ApplicationSettings {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::Pinpoint::ApplicationSettings', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [  ]
  }
  sub supported_regions {
    [ 'ap-south-1','ap-southeast-2','eu-central-1','eu-west-1','us-east-1','us-west-2' ]
  }
}



subtype 'Cfn::Resource::Properties::AWS::Pinpoint::ApplicationSettings::QuietTime',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Pinpoint::ApplicationSettings::QuietTime',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Pinpoint::ApplicationSettings::QuietTime->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Pinpoint::ApplicationSettings::QuietTime {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has End => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Start => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::Pinpoint::ApplicationSettings::Limits',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Pinpoint::ApplicationSettings::Limits',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Pinpoint::ApplicationSettings::Limits->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Pinpoint::ApplicationSettings::Limits {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Daily => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has MaximumDuration => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has MessagesPerSecond => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Total => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::Pinpoint::ApplicationSettings::CampaignHook',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Pinpoint::ApplicationSettings::CampaignHook',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Pinpoint::ApplicationSettings::CampaignHook->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Pinpoint::ApplicationSettings::CampaignHook {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has LambdaFunctionName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Mode => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has WebUrl => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::Pinpoint::ApplicationSettings {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has ApplicationId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has CampaignHook => (isa => 'Cfn::Resource::Properties::AWS::Pinpoint::ApplicationSettings::CampaignHook', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has CloudWatchMetricsEnabled => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Limits => (isa => 'Cfn::Resource::Properties::AWS::Pinpoint::ApplicationSettings::Limits', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has QuietTime => (isa => 'Cfn::Resource::Properties::AWS::Pinpoint::ApplicationSettings::QuietTime', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::Pinpoint::ApplicationSettings - Cfn resource for AWS::Pinpoint::ApplicationSettings

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::Pinpoint::ApplicationSettings.

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
