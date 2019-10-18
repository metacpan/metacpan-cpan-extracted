# AWS::Cognito::UserPoolRiskConfigurationAttachment generated from spec 6.3.0
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
       return Cfn::Resource::Properties::AWS::Cognito::UserPoolRiskConfigurationAttachment::NotifyEmailTypeValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::Cognito::UserPoolRiskConfigurationAttachment::NotifyEmailTypeValue {
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
       return Cfn::Resource::Properties::AWS::Cognito::UserPoolRiskConfigurationAttachment::AccountTakeoverActionTypeValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::Cognito::UserPoolRiskConfigurationAttachment::AccountTakeoverActionTypeValue {
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
       return Cfn::Resource::Properties::AWS::Cognito::UserPoolRiskConfigurationAttachment::NotifyConfigurationTypeValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::Cognito::UserPoolRiskConfigurationAttachment::NotifyConfigurationTypeValue {
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
       return Cfn::Resource::Properties::AWS::Cognito::UserPoolRiskConfigurationAttachment::CompromisedCredentialsActionsTypeValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::Cognito::UserPoolRiskConfigurationAttachment::CompromisedCredentialsActionsTypeValue {
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
       return Cfn::Resource::Properties::AWS::Cognito::UserPoolRiskConfigurationAttachment::AccountTakeoverActionsTypeValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::Cognito::UserPoolRiskConfigurationAttachment::AccountTakeoverActionsTypeValue {
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
       return Cfn::Resource::Properties::AWS::Cognito::UserPoolRiskConfigurationAttachment::RiskExceptionConfigurationTypeValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::Cognito::UserPoolRiskConfigurationAttachment::RiskExceptionConfigurationTypeValue {
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
       return Cfn::Resource::Properties::AWS::Cognito::UserPoolRiskConfigurationAttachment::CompromisedCredentialsRiskConfigurationTypeValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::Cognito::UserPoolRiskConfigurationAttachment::CompromisedCredentialsRiskConfigurationTypeValue {
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
       return Cfn::Resource::Properties::AWS::Cognito::UserPoolRiskConfigurationAttachment::AccountTakeoverRiskConfigurationTypeValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::Cognito::UserPoolRiskConfigurationAttachment::AccountTakeoverRiskConfigurationTypeValue {
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
