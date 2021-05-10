# AWS::Cognito::UserPool generated from spec 22.0.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::Cognito::UserPool',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::Cognito::UserPool->new( %$_ ) };

package Cfn::Resource::AWS::Cognito::UserPool {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::Cognito::UserPool', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [ 'Arn','ProviderName','ProviderURL' ]
  }
  sub supported_regions {
    [ 'ap-northeast-1','ap-northeast-2','ap-south-1','ap-southeast-1','ap-southeast-2','ca-central-1','eu-central-1','eu-west-1','eu-west-2','us-east-1','us-east-2','us-west-2' ]
  }
}



subtype 'Cfn::Resource::Properties::AWS::Cognito::UserPool::StringAttributeConstraints',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Cognito::UserPool::StringAttributeConstraints',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Cognito::UserPool::StringAttributeConstraints->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Cognito::UserPool::StringAttributeConstraints {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has MaxLength => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has MinLength => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::Cognito::UserPool::RecoveryOption',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::Cognito::UserPool::RecoveryOption',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::Cognito::UserPool::RecoveryOption')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::Cognito::UserPool::RecoveryOption',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Cognito::UserPool::RecoveryOption',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Cognito::UserPool::RecoveryOption->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Cognito::UserPool::RecoveryOption {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Priority => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::Cognito::UserPool::PasswordPolicy',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Cognito::UserPool::PasswordPolicy',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Cognito::UserPool::PasswordPolicy->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Cognito::UserPool::PasswordPolicy {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has MinimumLength => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RequireLowercase => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RequireNumbers => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RequireSymbols => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RequireUppercase => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TemporaryPasswordValidityDays => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::Cognito::UserPool::NumberAttributeConstraints',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Cognito::UserPool::NumberAttributeConstraints',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Cognito::UserPool::NumberAttributeConstraints->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Cognito::UserPool::NumberAttributeConstraints {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has MaxValue => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has MinValue => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::Cognito::UserPool::InviteMessageTemplate',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Cognito::UserPool::InviteMessageTemplate',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Cognito::UserPool::InviteMessageTemplate->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Cognito::UserPool::InviteMessageTemplate {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has EmailMessage => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has EmailSubject => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SMSMessage => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::Cognito::UserPool::CustomSMSSender',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Cognito::UserPool::CustomSMSSender',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Cognito::UserPool::CustomSMSSender->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Cognito::UserPool::CustomSMSSender {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has LambdaArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has LambdaVersion => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::Cognito::UserPool::CustomEmailSender',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Cognito::UserPool::CustomEmailSender',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Cognito::UserPool::CustomEmailSender->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Cognito::UserPool::CustomEmailSender {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has LambdaArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has LambdaVersion => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::Cognito::UserPool::VerificationMessageTemplate',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Cognito::UserPool::VerificationMessageTemplate',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Cognito::UserPool::VerificationMessageTemplate->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Cognito::UserPool::VerificationMessageTemplate {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has DefaultEmailOption => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has EmailMessage => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has EmailMessageByLink => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has EmailSubject => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has EmailSubjectByLink => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SmsMessage => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::Cognito::UserPool::UsernameConfiguration',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Cognito::UserPool::UsernameConfiguration',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Cognito::UserPool::UsernameConfiguration->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Cognito::UserPool::UsernameConfiguration {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has CaseSensitive => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::Cognito::UserPool::UserPoolAddOns',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Cognito::UserPool::UserPoolAddOns',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Cognito::UserPool::UserPoolAddOns->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Cognito::UserPool::UserPoolAddOns {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AdvancedSecurityMode => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::Cognito::UserPool::SmsConfiguration',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Cognito::UserPool::SmsConfiguration',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Cognito::UserPool::SmsConfiguration->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Cognito::UserPool::SmsConfiguration {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ExternalId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SnsCallerArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::Cognito::UserPool::SchemaAttribute',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::Cognito::UserPool::SchemaAttribute',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::Cognito::UserPool::SchemaAttribute')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::Cognito::UserPool::SchemaAttribute',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Cognito::UserPool::SchemaAttribute',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Cognito::UserPool::SchemaAttribute->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Cognito::UserPool::SchemaAttribute {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AttributeDataType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DeveloperOnlyAttribute => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Mutable => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has NumberAttributeConstraints => (isa => 'Cfn::Resource::Properties::AWS::Cognito::UserPool::NumberAttributeConstraints', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Required => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has StringAttributeConstraints => (isa => 'Cfn::Resource::Properties::AWS::Cognito::UserPool::StringAttributeConstraints', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::Cognito::UserPool::Policies',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Cognito::UserPool::Policies',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Cognito::UserPool::Policies->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Cognito::UserPool::Policies {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has PasswordPolicy => (isa => 'Cfn::Resource::Properties::AWS::Cognito::UserPool::PasswordPolicy', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::Cognito::UserPool::LambdaConfig',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Cognito::UserPool::LambdaConfig',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Cognito::UserPool::LambdaConfig->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Cognito::UserPool::LambdaConfig {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has CreateAuthChallenge => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has CustomEmailSender => (isa => 'Cfn::Resource::Properties::AWS::Cognito::UserPool::CustomEmailSender', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has CustomMessage => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has CustomSMSSender => (isa => 'Cfn::Resource::Properties::AWS::Cognito::UserPool::CustomSMSSender', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DefineAuthChallenge => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has KMSKeyID => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has PostAuthentication => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has PostConfirmation => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has PreAuthentication => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has PreSignUp => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has PreTokenGeneration => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has UserMigration => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has VerifyAuthChallengeResponse => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::Cognito::UserPool::EmailConfiguration',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Cognito::UserPool::EmailConfiguration',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Cognito::UserPool::EmailConfiguration->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Cognito::UserPool::EmailConfiguration {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ConfigurationSet => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has EmailSendingAccount => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has From => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ReplyToEmailAddress => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SourceArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::Cognito::UserPool::DeviceConfiguration',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Cognito::UserPool::DeviceConfiguration',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Cognito::UserPool::DeviceConfiguration->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Cognito::UserPool::DeviceConfiguration {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ChallengeRequiredOnNewDevice => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DeviceOnlyRememberedOnUserPrompt => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::Cognito::UserPool::AdminCreateUserConfig',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Cognito::UserPool::AdminCreateUserConfig',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Cognito::UserPool::AdminCreateUserConfig->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Cognito::UserPool::AdminCreateUserConfig {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AllowAdminCreateUserOnly => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has InviteMessageTemplate => (isa => 'Cfn::Resource::Properties::AWS::Cognito::UserPool::InviteMessageTemplate', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has UnusedAccountValidityDays => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::Cognito::UserPool::AccountRecoverySetting',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Cognito::UserPool::AccountRecoverySetting',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Cognito::UserPool::AccountRecoverySetting->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Cognito::UserPool::AccountRecoverySetting {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has RecoveryMechanisms => (isa => 'ArrayOfCfn::Resource::Properties::AWS::Cognito::UserPool::RecoveryOption', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::Cognito::UserPool {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has AccountRecoverySetting => (isa => 'Cfn::Resource::Properties::AWS::Cognito::UserPool::AccountRecoverySetting', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has AdminCreateUserConfig => (isa => 'Cfn::Resource::Properties::AWS::Cognito::UserPool::AdminCreateUserConfig', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has AliasAttributes => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has AutoVerifiedAttributes => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DeviceConfiguration => (isa => 'Cfn::Resource::Properties::AWS::Cognito::UserPool::DeviceConfiguration', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has EmailConfiguration => (isa => 'Cfn::Resource::Properties::AWS::Cognito::UserPool::EmailConfiguration', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has EmailVerificationMessage => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has EmailVerificationSubject => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has EnabledMfas => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has LambdaConfig => (isa => 'Cfn::Resource::Properties::AWS::Cognito::UserPool::LambdaConfig', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has MfaConfiguration => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Policies => (isa => 'Cfn::Resource::Properties::AWS::Cognito::UserPool::Policies', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Schema => (isa => 'ArrayOfCfn::Resource::Properties::AWS::Cognito::UserPool::SchemaAttribute', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SmsAuthenticationMessage => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SmsConfiguration => (isa => 'Cfn::Resource::Properties::AWS::Cognito::UserPool::SmsConfiguration', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SmsVerificationMessage => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has UserPoolAddOns => (isa => 'Cfn::Resource::Properties::AWS::Cognito::UserPool::UserPoolAddOns', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has UserPoolName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has UserPoolTags => (isa => 'Cfn::Value::Json|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has UsernameAttributes => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has UsernameConfiguration => (isa => 'Cfn::Resource::Properties::AWS::Cognito::UserPool::UsernameConfiguration', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has VerificationMessageTemplate => (isa => 'Cfn::Resource::Properties::AWS::Cognito::UserPool::VerificationMessageTemplate', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::Cognito::UserPool - Cfn resource for AWS::Cognito::UserPool

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::Cognito::UserPool.

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
