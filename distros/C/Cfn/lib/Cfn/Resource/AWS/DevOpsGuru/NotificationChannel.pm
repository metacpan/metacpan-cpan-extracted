# AWS::DevOpsGuru::NotificationChannel generated from spec 22.0.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::DevOpsGuru::NotificationChannel',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::DevOpsGuru::NotificationChannel->new( %$_ ) };

package Cfn::Resource::AWS::DevOpsGuru::NotificationChannel {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::DevOpsGuru::NotificationChannel', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [ 'Id' ]
  }
  sub supported_regions {
    [ 'ap-northeast-1','eu-west-1','us-east-1','us-east-2','us-west-2' ]
  }
}



subtype 'Cfn::Resource::Properties::AWS::DevOpsGuru::NotificationChannel::SnsChannelConfig',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::DevOpsGuru::NotificationChannel::SnsChannelConfig',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::DevOpsGuru::NotificationChannel::SnsChannelConfig->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::DevOpsGuru::NotificationChannel::SnsChannelConfig {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has TopicArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

subtype 'Cfn::Resource::Properties::AWS::DevOpsGuru::NotificationChannel::NotificationChannelConfig',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::DevOpsGuru::NotificationChannel::NotificationChannelConfig',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::DevOpsGuru::NotificationChannel::NotificationChannelConfig->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::DevOpsGuru::NotificationChannel::NotificationChannelConfig {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Sns => (isa => 'Cfn::Resource::Properties::AWS::DevOpsGuru::NotificationChannel::SnsChannelConfig', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

package Cfn::Resource::Properties::AWS::DevOpsGuru::NotificationChannel {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has Config => (isa => 'Cfn::Resource::Properties::AWS::DevOpsGuru::NotificationChannel::NotificationChannelConfig', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::DevOpsGuru::NotificationChannel - Cfn resource for AWS::DevOpsGuru::NotificationChannel

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::DevOpsGuru::NotificationChannel.

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
