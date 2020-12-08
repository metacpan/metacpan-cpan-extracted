# AWS::Cognito::UserPoolRiskConfigurationAttachment generated from spec 18.4.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::Cognito::UserPoolRiskConfigurationAttachment',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::Cognito::UserPoolRiskConfigurationAttachment->new( %$_ ) };

package Cfn::Resource::AWS::Cognito::UserPoolRiskConfigurationAttachment {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::Cognito::UserPoolRiskConfigurationAttachment', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [  ]
  }
  sub supported_regions {
    [ 'ap-northeast-1','ap-northeast-2','ap-south-1','ap-southeast-1','ap-southeast-2','ca-central-1','eu-central-1','eu-west-1','eu-west-2','us-east-1','us-east-2','us-west-2' ]
  }
}



subtype 'Cfn::Resource::Properties::AWS::Cognito::UserPoolRiskConfigurationAttachment::NotifyEmailType',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Cognito::UserPoolRiskConfigurationAttachment::NotifyEmailType',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Cognito::UserPoolRiskConfigurationAttachment::NotifyEmailType->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Cognito::UserPoolRiskConfigurationAttachment::NotifyEmailType {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has HtmlBody => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Subject => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TextBody => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::Cognito::UserPoolRiskConfigurationAttachment::AccountTakeoverActionType',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Cognito::UserPoolRiskConfigurationAttachment::AccountTakeoverActionType',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Cognito::UserPoolRiskConfigurationAttachment::AccountTakeoverActionType->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Cognito::UserPoolRiskConfigurationAttachment::AccountTakeoverActionType {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has EventAction => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Notify => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::Cognito::UserPoolRiskConfigurationAttachment::NotifyConfigurationType',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Cognito::UserPoolRiskConfigurationAttachment::NotifyConfigurationType',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Cognito::UserPoolRiskConfigurationAttachment::NotifyConfigurationType->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Cognito::UserPoolRiskConfigurationAttachment::NotifyConfigurationType {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has BlockEmail => (isa => 'Cfn::Resource::Properties::AWS::Cognito::UserPoolRiskConfigurationAttachment::NotifyEmailType', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has From => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has MfaEmail => (isa => 'Cfn::Resource::Properties::AWS::Cognito::UserPoolRiskConfigurationAttachment::NotifyEmailType', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has NoActionEmail => (isa => 'Cfn::Resource::Properties::AWS::Cognito::UserPoolRiskConfigurationAttachment::NotifyEmailType', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ReplyTo => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SourceArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::Cognito::UserPoolRiskConfigurationAttachment::CompromisedCredentialsActionsType',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Cognito::UserPoolRiskConfigurationAttachment::CompromisedCredentialsActionsType',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Cognito::UserPoolRiskConfigurationAttachment::CompromisedCredentialsActionsType->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Cognito::UserPoolRiskConfigurationAttachment::CompromisedCredentialsActionsType {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has EventAction => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::Cognito::UserPoolRiskConfigurationAttachment::AccountTakeoverActionsType',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Cognito::UserPoolRiskConfigurationAttachment::AccountTakeoverActionsType',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Cognito::UserPoolRiskConfigurationAttachment::AccountTakeoverActionsType->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Cognito::UserPoolRiskConfigurationAttachment::AccountTakeoverActionsType {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has HighAction => (isa => 'Cfn::Resource::Properties::AWS::Cognito::UserPoolRiskConfigurationAttachment::AccountTakeoverActionType', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has LowAction => (isa => 'Cfn::Resource::Properties::AWS::Cognito::UserPoolRiskConfigurationAttachment::AccountTakeoverActionType', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has MediumAction => (isa => 'Cfn::Resource::Properties::AWS::Cognito::UserPoolRiskConfigurationAttachment::AccountTakeoverActionType', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::Cognito::UserPoolRiskConfigurationAttachment::RiskExceptionConfigurationType',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Cognito::UserPoolRiskConfigurationAttachment::RiskExceptionConfigurationType',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Cognito::UserPoolRiskConfigurationAttachment::RiskExceptionConfigurationType->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Cognito::UserPoolRiskConfigurationAttachment::RiskExceptionConfigurationType {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has BlockedIPRangeList => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SkippedIPRangeList => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::Cognito::UserPoolRiskConfigurationAttachment::CompromisedCredentialsRiskConfigurationType',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Cognito::UserPoolRiskConfigurationAttachment::CompromisedCredentialsRiskConfigurationType',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Cognito::UserPoolRiskConfigurationAttachment::CompromisedCredentialsRiskConfigurationType->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Cognito::UserPoolRiskConfigurationAttachment::CompromisedCredentialsRiskConfigurationType {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Actions => (isa => 'Cfn::Resource::Properties::AWS::Cognito::UserPoolRiskConfigurationAttachment::CompromisedCredentialsActionsType', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has EventFilter => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::Cognito::UserPoolRiskConfigurationAttachment::AccountTakeoverRiskConfigurationType',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Cognito::UserPoolRiskConfigurationAttachment::AccountTakeoverRiskConfigurationType',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Cognito::UserPoolRiskConfigurationAttachment::AccountTakeoverRiskConfigurationType->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Cognito::UserPoolRiskConfigurationAttachment::AccountTakeoverRiskConfigurationType {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Actions => (isa => 'Cfn::Resource::Properties::AWS::Cognito::UserPoolRiskConfigurationAttachment::AccountTakeoverActionsType', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has NotifyConfiguration => (isa => 'Cfn::Resource::Properties::AWS::Cognito::UserPoolRiskConfigurationAttachment::NotifyConfigurationType', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::Cognito::UserPoolRiskConfigurationAttachment {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has AccountTakeoverRiskConfiguration => (isa => 'Cfn::Resource::Properties::AWS::Cognito::UserPoolRiskConfigurationAttachment::AccountTakeoverRiskConfigurationType', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ClientId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has CompromisedCredentialsRiskConfiguration => (isa => 'Cfn::Resource::Properties::AWS::Cognito::UserPoolRiskConfigurationAttachment::CompromisedCredentialsRiskConfigurationType', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RiskExceptionConfiguration => (isa => 'Cfn::Resource::Properties::AWS::Cognito::UserPoolRiskConfigurationAttachment::RiskExceptionConfigurationType', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has UserPoolId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::Cognito::UserPoolRiskConfigurationAttachment - Cfn resource for AWS::Cognito::UserPoolRiskConfigurationAttachment

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::Cognito::UserPoolRiskConfigurationAttachment.

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
