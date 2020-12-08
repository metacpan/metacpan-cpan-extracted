# AWS::IoTAnalytics::Channel generated from spec 20.1.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::IoTAnalytics::Channel',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::IoTAnalytics::Channel->new( %$_ ) };

package Cfn::Resource::AWS::IoTAnalytics::Channel {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::IoTAnalytics::Channel', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [  ]
  }
  sub supported_regions {
    [ 'ap-northeast-1','ap-southeast-2','cn-north-1','eu-central-1','eu-west-1','us-east-1','us-east-2','us-west-2' ]
  }
}



subtype 'Cfn::Resource::Properties::AWS::IoTAnalytics::Channel::ServiceManagedS3',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoTAnalytics::Channel::ServiceManagedS3',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::IoTAnalytics::Channel::ServiceManagedS3->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::IoTAnalytics::Channel::ServiceManagedS3 {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
}

subtype 'Cfn::Resource::Properties::AWS::IoTAnalytics::Channel::CustomerManagedS3',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoTAnalytics::Channel::CustomerManagedS3',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::IoTAnalytics::Channel::CustomerManagedS3->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::IoTAnalytics::Channel::CustomerManagedS3 {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Bucket => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has KeyPrefix => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RoleArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::IoTAnalytics::Channel::RetentionPeriod',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoTAnalytics::Channel::RetentionPeriod',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::IoTAnalytics::Channel::RetentionPeriod->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::IoTAnalytics::Channel::RetentionPeriod {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has NumberOfDays => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Unlimited => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::IoTAnalytics::Channel::ChannelStorage',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoTAnalytics::Channel::ChannelStorage',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::IoTAnalytics::Channel::ChannelStorage->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::IoTAnalytics::Channel::ChannelStorage {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has CustomerManagedS3 => (isa => 'Cfn::Resource::Properties::AWS::IoTAnalytics::Channel::CustomerManagedS3', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ServiceManagedS3 => (isa => 'Cfn::Resource::Properties::AWS::IoTAnalytics::Channel::ServiceManagedS3', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::IoTAnalytics::Channel {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has ChannelName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has ChannelStorage => (isa => 'Cfn::Resource::Properties::AWS::IoTAnalytics::Channel::ChannelStorage', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RetentionPeriod => (isa => 'Cfn::Resource::Properties::AWS::IoTAnalytics::Channel::RetentionPeriod', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Tags => (isa => 'ArrayOfCfn::Resource::Properties::TagType', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::IoTAnalytics::Channel - Cfn resource for AWS::IoTAnalytics::Channel

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::IoTAnalytics::Channel.

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
