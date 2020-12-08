# AWS::KinesisAnalyticsV2::ApplicationCloudWatchLoggingOption generated from spec 18.4.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::ApplicationCloudWatchLoggingOption',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::ApplicationCloudWatchLoggingOption->new( %$_ ) };

package Cfn::Resource::AWS::KinesisAnalyticsV2::ApplicationCloudWatchLoggingOption {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::ApplicationCloudWatchLoggingOption', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [  ]
  }
  sub supported_regions {
    [ 'ap-northeast-1','ap-northeast-2','ap-southeast-1','ap-southeast-2','eu-central-1','eu-west-1','eu-west-2','us-east-1','us-east-2','us-west-2' ]
  }
}



subtype 'Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::ApplicationCloudWatchLoggingOption::CloudWatchLoggingOption',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::ApplicationCloudWatchLoggingOption::CloudWatchLoggingOption',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::KinesisAnalyticsV2::ApplicationCloudWatchLoggingOption::CloudWatchLoggingOption->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::KinesisAnalyticsV2::ApplicationCloudWatchLoggingOption::CloudWatchLoggingOption {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has LogStreamARN => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::ApplicationCloudWatchLoggingOption {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has ApplicationName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has CloudWatchLoggingOption => (isa => 'Cfn::Resource::Properties::AWS::KinesisAnalyticsV2::ApplicationCloudWatchLoggingOption::CloudWatchLoggingOption', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::KinesisAnalyticsV2::ApplicationCloudWatchLoggingOption - Cfn resource for AWS::KinesisAnalyticsV2::ApplicationCloudWatchLoggingOption

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::KinesisAnalyticsV2::ApplicationCloudWatchLoggingOption.

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
