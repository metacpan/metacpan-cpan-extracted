# AWS::ElasticLoadBalancingV2::ListenerRule generated from spec 34.0.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::ElasticLoadBalancingV2::ListenerRule',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::ElasticLoadBalancingV2::ListenerRule->new( %$_ ) };

package Cfn::Resource::AWS::ElasticLoadBalancingV2::ListenerRule {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::ElasticLoadBalancingV2::ListenerRule', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [ 'IsDefault','RuleArn' ]
  }
  sub supported_regions {
    [ 'af-south-1','ap-east-1','ap-northeast-1','ap-northeast-2','ap-northeast-3','ap-south-1','ap-southeast-1','ap-southeast-2','ca-central-1','cn-north-1','cn-northwest-1','eu-central-1','eu-north-1','eu-south-1','eu-west-1','eu-west-2','eu-west-3','me-south-1','sa-east-1','us-east-1','us-east-2','us-gov-east-1','us-gov-west-1','us-west-1','us-west-2' ]
  }
}


subtype 'ArrayOfCfn::Resource::Properties::AWS::ElasticLoadBalancingV2::ListenerRule::TargetGroupTuple',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::ElasticLoadBalancingV2::ListenerRule::TargetGroupTuple',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::ElasticLoadBalancingV2::ListenerRule::TargetGroupTuple')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::ElasticLoadBalancingV2::ListenerRule::TargetGroupTuple',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::ElasticLoadBalancingV2::ListenerRule::TargetGroupTuple',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::ElasticLoadBalancingV2::ListenerRule::TargetGroupTuple->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::ElasticLoadBalancingV2::ListenerRule::TargetGroupTuple {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has TargetGroupArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Weight => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::ElasticLoadBalancingV2::ListenerRule::TargetGroupStickinessConfig',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::ElasticLoadBalancingV2::ListenerRule::TargetGroupStickinessConfig',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::ElasticLoadBalancingV2::ListenerRule::TargetGroupStickinessConfig->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::ElasticLoadBalancingV2::ListenerRule::TargetGroupStickinessConfig {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has DurationSeconds => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Enabled => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::ElasticLoadBalancingV2::ListenerRule::QueryStringKeyValue',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::ElasticLoadBalancingV2::ListenerRule::QueryStringKeyValue',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::ElasticLoadBalancingV2::ListenerRule::QueryStringKeyValue')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::ElasticLoadBalancingV2::ListenerRule::QueryStringKeyValue',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::ElasticLoadBalancingV2::ListenerRule::QueryStringKeyValue',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::ElasticLoadBalancingV2::ListenerRule::QueryStringKeyValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::ElasticLoadBalancingV2::ListenerRule::QueryStringKeyValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Key => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Value => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::ElasticLoadBalancingV2::ListenerRule::SourceIpConfig',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::ElasticLoadBalancingV2::ListenerRule::SourceIpConfig',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::ElasticLoadBalancingV2::ListenerRule::SourceIpConfig->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::ElasticLoadBalancingV2::ListenerRule::SourceIpConfig {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Values => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::ElasticLoadBalancingV2::ListenerRule::RedirectConfig',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::ElasticLoadBalancingV2::ListenerRule::RedirectConfig',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::ElasticLoadBalancingV2::ListenerRule::RedirectConfig->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::ElasticLoadBalancingV2::ListenerRule::RedirectConfig {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Host => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Path => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Port => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Protocol => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Query => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has StatusCode => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::ElasticLoadBalancingV2::ListenerRule::QueryStringConfig',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::ElasticLoadBalancingV2::ListenerRule::QueryStringConfig',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::ElasticLoadBalancingV2::ListenerRule::QueryStringConfig->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::ElasticLoadBalancingV2::ListenerRule::QueryStringConfig {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Values => (isa => 'ArrayOfCfn::Resource::Properties::AWS::ElasticLoadBalancingV2::ListenerRule::QueryStringKeyValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::ElasticLoadBalancingV2::ListenerRule::PathPatternConfig',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::ElasticLoadBalancingV2::ListenerRule::PathPatternConfig',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::ElasticLoadBalancingV2::ListenerRule::PathPatternConfig->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::ElasticLoadBalancingV2::ListenerRule::PathPatternConfig {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Values => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::ElasticLoadBalancingV2::ListenerRule::HttpRequestMethodConfig',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::ElasticLoadBalancingV2::ListenerRule::HttpRequestMethodConfig',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::ElasticLoadBalancingV2::ListenerRule::HttpRequestMethodConfig->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::ElasticLoadBalancingV2::ListenerRule::HttpRequestMethodConfig {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Values => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::ElasticLoadBalancingV2::ListenerRule::HttpHeaderConfig',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::ElasticLoadBalancingV2::ListenerRule::HttpHeaderConfig',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::ElasticLoadBalancingV2::ListenerRule::HttpHeaderConfig->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::ElasticLoadBalancingV2::ListenerRule::HttpHeaderConfig {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has HttpHeaderName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Values => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::ElasticLoadBalancingV2::ListenerRule::HostHeaderConfig',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::ElasticLoadBalancingV2::ListenerRule::HostHeaderConfig',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::ElasticLoadBalancingV2::ListenerRule::HostHeaderConfig->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::ElasticLoadBalancingV2::ListenerRule::HostHeaderConfig {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Values => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::ElasticLoadBalancingV2::ListenerRule::ForwardConfig',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::ElasticLoadBalancingV2::ListenerRule::ForwardConfig',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::ElasticLoadBalancingV2::ListenerRule::ForwardConfig->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::ElasticLoadBalancingV2::ListenerRule::ForwardConfig {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has TargetGroups => (isa => 'ArrayOfCfn::Resource::Properties::AWS::ElasticLoadBalancingV2::ListenerRule::TargetGroupTuple', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TargetGroupStickinessConfig => (isa => 'Cfn::Resource::Properties::AWS::ElasticLoadBalancingV2::ListenerRule::TargetGroupStickinessConfig', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::ElasticLoadBalancingV2::ListenerRule::FixedResponseConfig',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::ElasticLoadBalancingV2::ListenerRule::FixedResponseConfig',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::ElasticLoadBalancingV2::ListenerRule::FixedResponseConfig->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::ElasticLoadBalancingV2::ListenerRule::FixedResponseConfig {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ContentType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has MessageBody => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has StatusCode => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::ElasticLoadBalancingV2::ListenerRule::AuthenticateOidcConfig',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::ElasticLoadBalancingV2::ListenerRule::AuthenticateOidcConfig',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::ElasticLoadBalancingV2::ListenerRule::AuthenticateOidcConfig->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::ElasticLoadBalancingV2::ListenerRule::AuthenticateOidcConfig {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AuthenticationRequestExtraParams => (isa => 'Cfn::Value::Hash|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has AuthorizationEndpoint => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ClientId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ClientSecret => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Issuer => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has OnUnauthenticatedRequest => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Scope => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SessionCookieName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SessionTimeout => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TokenEndpoint => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has UseExistingClientSecret => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has UserInfoEndpoint => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::ElasticLoadBalancingV2::ListenerRule::AuthenticateCognitoConfig',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::ElasticLoadBalancingV2::ListenerRule::AuthenticateCognitoConfig',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::ElasticLoadBalancingV2::ListenerRule::AuthenticateCognitoConfig->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::ElasticLoadBalancingV2::ListenerRule::AuthenticateCognitoConfig {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AuthenticationRequestExtraParams => (isa => 'Cfn::Value::Hash|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has OnUnauthenticatedRequest => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Scope => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SessionCookieName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SessionTimeout => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has UserPoolArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has UserPoolClientId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has UserPoolDomain => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::ElasticLoadBalancingV2::ListenerRule::RuleCondition',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::ElasticLoadBalancingV2::ListenerRule::RuleCondition',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::ElasticLoadBalancingV2::ListenerRule::RuleCondition')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::ElasticLoadBalancingV2::ListenerRule::RuleCondition',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::ElasticLoadBalancingV2::ListenerRule::RuleCondition',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::ElasticLoadBalancingV2::ListenerRule::RuleCondition->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::ElasticLoadBalancingV2::ListenerRule::RuleCondition {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Field => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has HostHeaderConfig => (isa => 'Cfn::Resource::Properties::AWS::ElasticLoadBalancingV2::ListenerRule::HostHeaderConfig', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has HttpHeaderConfig => (isa => 'Cfn::Resource::Properties::AWS::ElasticLoadBalancingV2::ListenerRule::HttpHeaderConfig', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has HttpRequestMethodConfig => (isa => 'Cfn::Resource::Properties::AWS::ElasticLoadBalancingV2::ListenerRule::HttpRequestMethodConfig', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has PathPatternConfig => (isa => 'Cfn::Resource::Properties::AWS::ElasticLoadBalancingV2::ListenerRule::PathPatternConfig', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has QueryStringConfig => (isa => 'Cfn::Resource::Properties::AWS::ElasticLoadBalancingV2::ListenerRule::QueryStringConfig', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SourceIpConfig => (isa => 'Cfn::Resource::Properties::AWS::ElasticLoadBalancingV2::ListenerRule::SourceIpConfig', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Values => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::ElasticLoadBalancingV2::ListenerRule::Action',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::ElasticLoadBalancingV2::ListenerRule::Action',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::ElasticLoadBalancingV2::ListenerRule::Action')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::ElasticLoadBalancingV2::ListenerRule::Action',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::ElasticLoadBalancingV2::ListenerRule::Action',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::ElasticLoadBalancingV2::ListenerRule::Action->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::ElasticLoadBalancingV2::ListenerRule::Action {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AuthenticateCognitoConfig => (isa => 'Cfn::Resource::Properties::AWS::ElasticLoadBalancingV2::ListenerRule::AuthenticateCognitoConfig', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has AuthenticateOidcConfig => (isa => 'Cfn::Resource::Properties::AWS::ElasticLoadBalancingV2::ListenerRule::AuthenticateOidcConfig', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has FixedResponseConfig => (isa => 'Cfn::Resource::Properties::AWS::ElasticLoadBalancingV2::ListenerRule::FixedResponseConfig', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ForwardConfig => (isa => 'Cfn::Resource::Properties::AWS::ElasticLoadBalancingV2::ListenerRule::ForwardConfig', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Order => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RedirectConfig => (isa => 'Cfn::Resource::Properties::AWS::ElasticLoadBalancingV2::ListenerRule::RedirectConfig', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TargetGroupArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Type => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::ElasticLoadBalancingV2::ListenerRule {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has Actions => (isa => 'ArrayOfCfn::Resource::Properties::AWS::ElasticLoadBalancingV2::ListenerRule::Action', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Conditions => (isa => 'ArrayOfCfn::Resource::Properties::AWS::ElasticLoadBalancingV2::ListenerRule::RuleCondition', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ListenerArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Priority => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::ElasticLoadBalancingV2::ListenerRule - Cfn resource for AWS::ElasticLoadBalancingV2::ListenerRule

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::ElasticLoadBalancingV2::ListenerRule.

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
