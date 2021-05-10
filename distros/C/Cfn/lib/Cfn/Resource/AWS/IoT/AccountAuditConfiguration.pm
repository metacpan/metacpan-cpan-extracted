# AWS::IoT::AccountAuditConfiguration generated from spec 34.0.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::IoT::AccountAuditConfiguration',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::IoT::AccountAuditConfiguration->new( %$_ ) };

package Cfn::Resource::AWS::IoT::AccountAuditConfiguration {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::IoT::AccountAuditConfiguration', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [  ]
  }
  sub supported_regions {
    [ 'ap-east-1','ap-northeast-1','ap-northeast-2','ap-south-1','ap-southeast-1','ap-southeast-2','ca-central-1','cn-north-1','cn-northwest-1','eu-central-1','eu-north-1','eu-west-1','eu-west-2','eu-west-3','me-south-1','us-east-1','us-east-2','us-gov-east-1','us-gov-west-1','us-west-1','us-west-2' ]
  }
}



subtype 'Cfn::Resource::Properties::AWS::IoT::AccountAuditConfiguration::AuditNotificationTarget',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoT::AccountAuditConfiguration::AuditNotificationTarget',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::IoT::AccountAuditConfiguration::AuditNotificationTarget->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::IoT::AccountAuditConfiguration::AuditNotificationTarget {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Enabled => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RoleArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TargetArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::IoT::AccountAuditConfiguration::AuditCheckConfiguration',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoT::AccountAuditConfiguration::AuditCheckConfiguration',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::IoT::AccountAuditConfiguration::AuditCheckConfiguration->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::IoT::AccountAuditConfiguration::AuditCheckConfiguration {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Enabled => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::IoT::AccountAuditConfiguration::AuditNotificationTargetConfigurations',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoT::AccountAuditConfiguration::AuditNotificationTargetConfigurations',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::IoT::AccountAuditConfiguration::AuditNotificationTargetConfigurations->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::IoT::AccountAuditConfiguration::AuditNotificationTargetConfigurations {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Sns => (isa => 'Cfn::Resource::Properties::AWS::IoT::AccountAuditConfiguration::AuditNotificationTarget', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::IoT::AccountAuditConfiguration::AuditCheckConfigurations',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoT::AccountAuditConfiguration::AuditCheckConfigurations',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::IoT::AccountAuditConfiguration::AuditCheckConfigurations->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::IoT::AccountAuditConfiguration::AuditCheckConfigurations {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AuthenticatedCognitoRoleOverlyPermissiveCheck => (isa => 'Cfn::Resource::Properties::AWS::IoT::AccountAuditConfiguration::AuditCheckConfiguration', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has CaCertificateExpiringCheck => (isa => 'Cfn::Resource::Properties::AWS::IoT::AccountAuditConfiguration::AuditCheckConfiguration', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has CaCertificateKeyQualityCheck => (isa => 'Cfn::Resource::Properties::AWS::IoT::AccountAuditConfiguration::AuditCheckConfiguration', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ConflictingClientIdsCheck => (isa => 'Cfn::Resource::Properties::AWS::IoT::AccountAuditConfiguration::AuditCheckConfiguration', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DeviceCertificateExpiringCheck => (isa => 'Cfn::Resource::Properties::AWS::IoT::AccountAuditConfiguration::AuditCheckConfiguration', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DeviceCertificateKeyQualityCheck => (isa => 'Cfn::Resource::Properties::AWS::IoT::AccountAuditConfiguration::AuditCheckConfiguration', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DeviceCertificateSharedCheck => (isa => 'Cfn::Resource::Properties::AWS::IoT::AccountAuditConfiguration::AuditCheckConfiguration', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has IotPolicyOverlyPermissiveCheck => (isa => 'Cfn::Resource::Properties::AWS::IoT::AccountAuditConfiguration::AuditCheckConfiguration', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has IotRoleAliasAllowsAccessToUnusedServicesCheck => (isa => 'Cfn::Resource::Properties::AWS::IoT::AccountAuditConfiguration::AuditCheckConfiguration', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has IotRoleAliasOverlyPermissiveCheck => (isa => 'Cfn::Resource::Properties::AWS::IoT::AccountAuditConfiguration::AuditCheckConfiguration', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has LoggingDisabledCheck => (isa => 'Cfn::Resource::Properties::AWS::IoT::AccountAuditConfiguration::AuditCheckConfiguration', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RevokedCaCertificateStillActiveCheck => (isa => 'Cfn::Resource::Properties::AWS::IoT::AccountAuditConfiguration::AuditCheckConfiguration', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RevokedDeviceCertificateStillActiveCheck => (isa => 'Cfn::Resource::Properties::AWS::IoT::AccountAuditConfiguration::AuditCheckConfiguration', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has UnauthenticatedCognitoRoleOverlyPermissiveCheck => (isa => 'Cfn::Resource::Properties::AWS::IoT::AccountAuditConfiguration::AuditCheckConfiguration', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::IoT::AccountAuditConfiguration {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has AccountId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has AuditCheckConfigurations => (isa => 'Cfn::Resource::Properties::AWS::IoT::AccountAuditConfiguration::AuditCheckConfigurations', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has AuditNotificationTargetConfigurations => (isa => 'Cfn::Resource::Properties::AWS::IoT::AccountAuditConfiguration::AuditNotificationTargetConfigurations', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RoleArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::IoT::AccountAuditConfiguration - Cfn resource for AWS::IoT::AccountAuditConfiguration

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::IoT::AccountAuditConfiguration.

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
