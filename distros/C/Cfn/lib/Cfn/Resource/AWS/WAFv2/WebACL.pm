# AWS::WAFv2::WebACL generated from spec 34.0.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::WAFv2::WebACL',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::WAFv2::WebACL->new( %$_ ) };

package Cfn::Resource::AWS::WAFv2::WebACL {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::WebACL', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [ 'Arn','Capacity','Id','LabelNamespace' ]
  }
  sub supported_regions {
    [ 'af-south-1','ap-east-1','ap-northeast-1','ap-northeast-2','ap-south-1','ap-southeast-1','ap-southeast-2','ca-central-1','cn-north-1','cn-northwest-1','eu-central-1','eu-north-1','eu-south-1','eu-west-1','eu-west-2','eu-west-3','me-south-1','sa-east-1','us-east-1','us-east-2','us-gov-east-1','us-gov-west-1','us-west-1','us-west-2' ]
  }
}



subtype 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::JsonMatchPattern',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::JsonMatchPattern',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::WAFv2::WebACL::JsonMatchPattern->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::WAFv2::WebACL::JsonMatchPattern {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has All => (isa => 'Cfn::Value::Json|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has IncludedPaths => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::JsonBody',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::JsonBody',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::WAFv2::WebACL::JsonBody->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::WAFv2::WebACL::JsonBody {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has InvalidFallbackBehavior => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has MatchPattern => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::JsonMatchPattern', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has MatchScope => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::WAFv2::WebACL::TextTransformation',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::WAFv2::WebACL::TextTransformation',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::WAFv2::WebACL::TextTransformation')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::TextTransformation',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::TextTransformation',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::WAFv2::WebACL::TextTransformation->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::WAFv2::WebACL::TextTransformation {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Priority => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Type => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::IPSetForwardedIPConfiguration',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::IPSetForwardedIPConfiguration',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::WAFv2::WebACL::IPSetForwardedIPConfiguration->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::WAFv2::WebACL::IPSetForwardedIPConfiguration {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has FallbackBehavior => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has HeaderName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Position => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::ForwardedIPConfiguration',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::ForwardedIPConfiguration',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::WAFv2::WebACL::ForwardedIPConfiguration->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::WAFv2::WebACL::ForwardedIPConfiguration {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has FallbackBehavior => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has HeaderName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::FieldToMatch',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::FieldToMatch',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::WAFv2::WebACL::FieldToMatch->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::WAFv2::WebACL::FieldToMatch {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AllQueryArguments => (isa => 'Cfn::Value::Json|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Body => (isa => 'Cfn::Value::Json|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has JsonBody => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::JsonBody', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Method => (isa => 'Cfn::Value::Json|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has QueryString => (isa => 'Cfn::Value::Json|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SingleHeader => (isa => 'Cfn::Value::Json|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SingleQueryArgument => (isa => 'Cfn::Value::Json|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has UriPath => (isa => 'Cfn::Value::Json|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::WAFv2::WebACL::ExcludedRule',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::WAFv2::WebACL::ExcludedRule',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::WAFv2::WebACL::ExcludedRule')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::ExcludedRule',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::ExcludedRule',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::WAFv2::WebACL::ExcludedRule->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::WAFv2::WebACL::ExcludedRule {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::XssMatchStatement',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::XssMatchStatement',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::WAFv2::WebACL::XssMatchStatement->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::WAFv2::WebACL::XssMatchStatement {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has FieldToMatch => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::FieldToMatch', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TextTransformations => (isa => 'ArrayOfCfn::Resource::Properties::AWS::WAFv2::WebACL::TextTransformation', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::SqliMatchStatement',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::SqliMatchStatement',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::WAFv2::WebACL::SqliMatchStatement->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::WAFv2::WebACL::SqliMatchStatement {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has FieldToMatch => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::FieldToMatch', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TextTransformations => (isa => 'ArrayOfCfn::Resource::Properties::AWS::WAFv2::WebACL::TextTransformation', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::SizeConstraintStatement',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::SizeConstraintStatement',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::WAFv2::WebACL::SizeConstraintStatement->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::WAFv2::WebACL::SizeConstraintStatement {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ComparisonOperator => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has FieldToMatch => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::FieldToMatch', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Size => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TextTransformations => (isa => 'ArrayOfCfn::Resource::Properties::AWS::WAFv2::WebACL::TextTransformation', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::RuleGroupReferenceStatement',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::RuleGroupReferenceStatement',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::WAFv2::WebACL::RuleGroupReferenceStatement->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::WAFv2::WebACL::RuleGroupReferenceStatement {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Arn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ExcludedRules => (isa => 'ArrayOfCfn::Resource::Properties::AWS::WAFv2::WebACL::ExcludedRule', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::RegexPatternSetReferenceStatement',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::RegexPatternSetReferenceStatement',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::WAFv2::WebACL::RegexPatternSetReferenceStatement->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::WAFv2::WebACL::RegexPatternSetReferenceStatement {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Arn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has FieldToMatch => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::FieldToMatch', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TextTransformations => (isa => 'ArrayOfCfn::Resource::Properties::AWS::WAFv2::WebACL::TextTransformation', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::LabelMatchStatement',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::LabelMatchStatement',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::WAFv2::WebACL::LabelMatchStatement->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::WAFv2::WebACL::LabelMatchStatement {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Key => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Scope => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::IPSetReferenceStatement',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::IPSetReferenceStatement',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::WAFv2::WebACL::IPSetReferenceStatement->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::WAFv2::WebACL::IPSetReferenceStatement {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Arn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has IPSetForwardedIPConfig => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::IPSetForwardedIPConfiguration', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::GeoMatchStatement',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::GeoMatchStatement',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::WAFv2::WebACL::GeoMatchStatement->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::WAFv2::WebACL::GeoMatchStatement {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has CountryCodes => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ForwardedIPConfig => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::ForwardedIPConfiguration', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::ByteMatchStatement',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::ByteMatchStatement',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::WAFv2::WebACL::ByteMatchStatement->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::WAFv2::WebACL::ByteMatchStatement {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has FieldToMatch => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::FieldToMatch', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has PositionalConstraint => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SearchString => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SearchStringBase64 => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TextTransformations => (isa => 'ArrayOfCfn::Resource::Properties::AWS::WAFv2::WebACL::TextTransformation', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::WAFv2::WebACL::StatementThree',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::WAFv2::WebACL::StatementThree',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::WAFv2::WebACL::StatementThree')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::StatementThree',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::StatementThree',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::WAFv2::WebACL::StatementThree->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::WAFv2::WebACL::StatementThree {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ByteMatchStatement => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::ByteMatchStatement', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has GeoMatchStatement => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::GeoMatchStatement', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has IPSetReferenceStatement => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::IPSetReferenceStatement', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has LabelMatchStatement => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::LabelMatchStatement', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RegexPatternSetReferenceStatement => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::RegexPatternSetReferenceStatement', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RuleGroupReferenceStatement => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::RuleGroupReferenceStatement', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SizeConstraintStatement => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::SizeConstraintStatement', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SqliMatchStatement => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::SqliMatchStatement', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has XssMatchStatement => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::XssMatchStatement', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::RateBasedStatementTwo',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::RateBasedStatementTwo',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::WAFv2::WebACL::RateBasedStatementTwo->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::WAFv2::WebACL::RateBasedStatementTwo {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AggregateKeyType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ForwardedIPConfig => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::ForwardedIPConfiguration', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Limit => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ScopeDownStatement => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::StatementThree', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::OrStatementTwo',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::OrStatementTwo',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::WAFv2::WebACL::OrStatementTwo->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::WAFv2::WebACL::OrStatementTwo {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Statements => (isa => 'ArrayOfCfn::Resource::Properties::AWS::WAFv2::WebACL::StatementThree', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::NotStatementTwo',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::NotStatementTwo',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::WAFv2::WebACL::NotStatementTwo->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::WAFv2::WebACL::NotStatementTwo {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Statement => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::StatementThree', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::WAFv2::WebACL::CustomHTTPHeader',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::WAFv2::WebACL::CustomHTTPHeader',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::WAFv2::WebACL::CustomHTTPHeader')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::CustomHTTPHeader',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::CustomHTTPHeader',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::WAFv2::WebACL::CustomHTTPHeader->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::WAFv2::WebACL::CustomHTTPHeader {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Value => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::AndStatementTwo',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::AndStatementTwo',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::WAFv2::WebACL::AndStatementTwo->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::WAFv2::WebACL::AndStatementTwo {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Statements => (isa => 'ArrayOfCfn::Resource::Properties::AWS::WAFv2::WebACL::StatementThree', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::WAFv2::WebACL::StatementTwo',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::WAFv2::WebACL::StatementTwo',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::WAFv2::WebACL::StatementTwo')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::StatementTwo',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::StatementTwo',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::WAFv2::WebACL::StatementTwo->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::WAFv2::WebACL::StatementTwo {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AndStatement => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::AndStatementTwo', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ByteMatchStatement => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::ByteMatchStatement', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has GeoMatchStatement => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::GeoMatchStatement', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has IPSetReferenceStatement => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::IPSetReferenceStatement', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has LabelMatchStatement => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::LabelMatchStatement', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has NotStatement => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::NotStatementTwo', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has OrStatement => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::OrStatementTwo', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RateBasedStatement => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::RateBasedStatementTwo', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RegexPatternSetReferenceStatement => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::RegexPatternSetReferenceStatement', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RuleGroupReferenceStatement => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::RuleGroupReferenceStatement', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SizeConstraintStatement => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::SizeConstraintStatement', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SqliMatchStatement => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::SqliMatchStatement', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has XssMatchStatement => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::XssMatchStatement', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::CustomResponse',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::CustomResponse',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::WAFv2::WebACL::CustomResponse->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::WAFv2::WebACL::CustomResponse {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has CustomResponseBodyKey => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ResponseCode => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ResponseHeaders => (isa => 'ArrayOfCfn::Resource::Properties::AWS::WAFv2::WebACL::CustomHTTPHeader', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::CustomRequestHandling',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::CustomRequestHandling',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::WAFv2::WebACL::CustomRequestHandling->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::WAFv2::WebACL::CustomRequestHandling {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has InsertHeaders => (isa => 'ArrayOfCfn::Resource::Properties::AWS::WAFv2::WebACL::CustomHTTPHeader', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::RateBasedStatementOne',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::RateBasedStatementOne',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::WAFv2::WebACL::RateBasedStatementOne->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::WAFv2::WebACL::RateBasedStatementOne {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AggregateKeyType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ForwardedIPConfig => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::ForwardedIPConfiguration', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Limit => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ScopeDownStatement => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::StatementTwo', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::OrStatementOne',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::OrStatementOne',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::WAFv2::WebACL::OrStatementOne->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::WAFv2::WebACL::OrStatementOne {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Statements => (isa => 'ArrayOfCfn::Resource::Properties::AWS::WAFv2::WebACL::StatementTwo', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::NotStatementOne',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::NotStatementOne',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::WAFv2::WebACL::NotStatementOne->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::WAFv2::WebACL::NotStatementOne {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Statement => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::StatementTwo', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::ManagedRuleGroupStatement',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::ManagedRuleGroupStatement',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::WAFv2::WebACL::ManagedRuleGroupStatement->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::WAFv2::WebACL::ManagedRuleGroupStatement {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ExcludedRules => (isa => 'ArrayOfCfn::Resource::Properties::AWS::WAFv2::WebACL::ExcludedRule', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ScopeDownStatement => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::StatementTwo', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has VendorName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::CountAction',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::CountAction',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::WAFv2::WebACL::CountAction->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::WAFv2::WebACL::CountAction {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has CustomRequestHandling => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::CustomRequestHandling', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::BlockAction',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::BlockAction',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::WAFv2::WebACL::BlockAction->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::WAFv2::WebACL::BlockAction {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has CustomResponse => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::CustomResponse', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::AndStatementOne',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::AndStatementOne',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::WAFv2::WebACL::AndStatementOne->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::WAFv2::WebACL::AndStatementOne {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Statements => (isa => 'ArrayOfCfn::Resource::Properties::AWS::WAFv2::WebACL::StatementTwo', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::AllowAction',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::AllowAction',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::WAFv2::WebACL::AllowAction->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::WAFv2::WebACL::AllowAction {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has CustomRequestHandling => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::CustomRequestHandling', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::VisibilityConfig',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::VisibilityConfig',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::WAFv2::WebACL::VisibilityConfig->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::WAFv2::WebACL::VisibilityConfig {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has CloudWatchMetricsEnabled => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has MetricName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SampledRequestsEnabled => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::StatementOne',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::StatementOne',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::WAFv2::WebACL::StatementOne->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::WAFv2::WebACL::StatementOne {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AndStatement => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::AndStatementOne', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ByteMatchStatement => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::ByteMatchStatement', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has GeoMatchStatement => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::GeoMatchStatement', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has IPSetReferenceStatement => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::IPSetReferenceStatement', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has LabelMatchStatement => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::LabelMatchStatement', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ManagedRuleGroupStatement => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::ManagedRuleGroupStatement', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has NotStatement => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::NotStatementOne', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has OrStatement => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::OrStatementOne', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RateBasedStatement => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::RateBasedStatementOne', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RegexPatternSetReferenceStatement => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::RegexPatternSetReferenceStatement', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RuleGroupReferenceStatement => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::RuleGroupReferenceStatement', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SizeConstraintStatement => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::SizeConstraintStatement', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SqliMatchStatement => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::SqliMatchStatement', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has XssMatchStatement => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::XssMatchStatement', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::RuleAction',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::RuleAction',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::WAFv2::WebACL::RuleAction->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::WAFv2::WebACL::RuleAction {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Allow => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::AllowAction', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Block => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::BlockAction', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Count => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::CountAction', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::OverrideAction',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::OverrideAction',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::WAFv2::WebACL::OverrideAction->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::WAFv2::WebACL::OverrideAction {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Count => (isa => 'Cfn::Value::Json|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has None => (isa => 'Cfn::Value::Json|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::WAFv2::WebACL::Label',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::WAFv2::WebACL::Label',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::WAFv2::WebACL::Label')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::Label',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::Label',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::WAFv2::WebACL::Label->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::WAFv2::WebACL::Label {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::WAFv2::WebACL::Rule',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::WAFv2::WebACL::Rule',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::WAFv2::WebACL::Rule')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::Rule',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::Rule',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::WAFv2::WebACL::Rule->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::WAFv2::WebACL::Rule {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Action => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::RuleAction', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has OverrideAction => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::OverrideAction', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Priority => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RuleLabels => (isa => 'ArrayOfCfn::Resource::Properties::AWS::WAFv2::WebACL::Label', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Statement => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::StatementOne', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has VisibilityConfig => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::VisibilityConfig', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::DefaultAction',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::DefaultAction',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::WAFv2::WebACL::DefaultAction->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::WAFv2::WebACL::DefaultAction {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Allow => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::AllowAction', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Block => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::BlockAction', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'MapOfCfn::Resource::Properties::AWS::WAFv2::WebACL::CustomResponseBody',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Hash') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'MapOfCfn::Resource::Properties::AWS::WAFv2::WebACL::CustomResponseBody',
  from 'HashRef',
   via {
     my $arg = $_;
     if (my $f = Cfn::TypeLibrary::try_function($arg)) {
       return $f
     } else {
       Cfn::Value::Hash->new(Value => {
         map { $_ => Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::WAFv2::WebACL::CustomResponseBody')->coerce($arg->{$_}) } keys %$arg
       });
     }
   };

subtype 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::CustomResponseBody',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::CustomResponseBody',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::WAFv2::WebACL::CustomResponseBody->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::WAFv2::WebACL::CustomResponseBody {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Content => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ContentType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::WAFv2::WebACL {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has CustomResponseBodies => (isa => 'MapOfCfn::Resource::Properties::AWS::WAFv2::WebACL::CustomResponseBody', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DefaultAction => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::DefaultAction', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Description => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Rules => (isa => 'ArrayOfCfn::Resource::Properties::AWS::WAFv2::WebACL::Rule', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Scope => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Tags => (isa => 'ArrayOfCfn::Resource::Properties::TagType', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has VisibilityConfig => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::WebACL::VisibilityConfig', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::WAFv2::WebACL - Cfn resource for AWS::WAFv2::WebACL

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::WAFv2::WebACL.

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
