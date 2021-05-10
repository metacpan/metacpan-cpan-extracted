# AWS::IoT::MitigationAction generated from spec 34.0.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::IoT::MitigationAction',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::IoT::MitigationAction->new( %$_ ) };

package Cfn::Resource::AWS::IoT::MitigationAction {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::IoT::MitigationAction', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [ 'MitigationActionArn','MitigationActionId' ]
  }
  sub supported_regions {
    [ 'ap-east-1','ap-northeast-1','ap-northeast-2','ap-south-1','ap-southeast-1','ap-southeast-2','ca-central-1','cn-north-1','cn-northwest-1','eu-central-1','eu-north-1','eu-west-1','eu-west-2','eu-west-3','me-south-1','us-east-1','us-east-2','us-gov-east-1','us-gov-west-1','us-west-1','us-west-2' ]
  }
}



subtype 'Cfn::Resource::Properties::AWS::IoT::MitigationAction::UpdateDeviceCertificateParams',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoT::MitigationAction::UpdateDeviceCertificateParams',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::IoT::MitigationAction::UpdateDeviceCertificateParams->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::IoT::MitigationAction::UpdateDeviceCertificateParams {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Action => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::IoT::MitigationAction::UpdateCACertificateParams',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoT::MitigationAction::UpdateCACertificateParams',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::IoT::MitigationAction::UpdateCACertificateParams->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::IoT::MitigationAction::UpdateCACertificateParams {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Action => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::IoT::MitigationAction::ReplaceDefaultPolicyVersionParams',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoT::MitigationAction::ReplaceDefaultPolicyVersionParams',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::IoT::MitigationAction::ReplaceDefaultPolicyVersionParams->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::IoT::MitigationAction::ReplaceDefaultPolicyVersionParams {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has TemplateName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::IoT::MitigationAction::PublishFindingToSnsParams',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoT::MitigationAction::PublishFindingToSnsParams',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::IoT::MitigationAction::PublishFindingToSnsParams->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::IoT::MitigationAction::PublishFindingToSnsParams {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has TopicArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::IoT::MitigationAction::EnableIoTLoggingParams',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoT::MitigationAction::EnableIoTLoggingParams',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::IoT::MitigationAction::EnableIoTLoggingParams->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::IoT::MitigationAction::EnableIoTLoggingParams {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has LogLevel => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RoleArnForLogging => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::IoT::MitigationAction::AddThingsToThingGroupParams',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoT::MitigationAction::AddThingsToThingGroupParams',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::IoT::MitigationAction::AddThingsToThingGroupParams->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::IoT::MitigationAction::AddThingsToThingGroupParams {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has OverrideDynamicGroups => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ThingGroupNames => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::IoT::MitigationAction::ActionParams',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoT::MitigationAction::ActionParams',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::IoT::MitigationAction::ActionParams->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::IoT::MitigationAction::ActionParams {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AddThingsToThingGroupParams => (isa => 'Cfn::Resource::Properties::AWS::IoT::MitigationAction::AddThingsToThingGroupParams', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has EnableIoTLoggingParams => (isa => 'Cfn::Resource::Properties::AWS::IoT::MitigationAction::EnableIoTLoggingParams', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has PublishFindingToSnsParams => (isa => 'Cfn::Resource::Properties::AWS::IoT::MitigationAction::PublishFindingToSnsParams', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ReplaceDefaultPolicyVersionParams => (isa => 'Cfn::Resource::Properties::AWS::IoT::MitigationAction::ReplaceDefaultPolicyVersionParams', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has UpdateCACertificateParams => (isa => 'Cfn::Resource::Properties::AWS::IoT::MitigationAction::UpdateCACertificateParams', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has UpdateDeviceCertificateParams => (isa => 'Cfn::Resource::Properties::AWS::IoT::MitigationAction::UpdateDeviceCertificateParams', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::IoT::MitigationAction {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has ActionName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has ActionParams => (isa => 'Cfn::Resource::Properties::AWS::IoT::MitigationAction::ActionParams', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RoleArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Tags => (isa => 'ArrayOfCfn::Resource::Properties::TagType', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::IoT::MitigationAction - Cfn resource for AWS::IoT::MitigationAction

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::IoT::MitigationAction.

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
