# AWS::WAFv2::RuleGroup generated from spec 34.0.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::WAFv2::RuleGroup->new( %$_ ) };

package Cfn::Resource::AWS::WAFv2::RuleGroup {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [ 'Arn','AvailableLabels','ConsumedLabels','Id','LabelNamespace' ]
  }
  sub supported_regions {
    [ 'af-south-1','ap-east-1','ap-northeast-1','ap-northeast-2','ap-south-1','ap-southeast-1','ap-southeast-2','ca-central-1','cn-north-1','cn-northwest-1','eu-central-1','eu-north-1','eu-south-1','eu-west-1','eu-west-2','eu-west-3','me-south-1','sa-east-1','us-east-1','us-east-2','us-gov-east-1','us-gov-west-1','us-west-1','us-west-2' ]
  }
}



subtype 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::JsonMatchPattern',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::JsonMatchPattern',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::WAFv2::RuleGroup::JsonMatchPattern->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::WAFv2::RuleGroup::JsonMatchPattern {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has All => (isa => 'Cfn::Value::Json|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has IncludedPaths => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::JsonBody',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::JsonBody',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::WAFv2::RuleGroup::JsonBody->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::WAFv2::RuleGroup::JsonBody {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has InvalidFallbackBehavior => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has MatchPattern => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::JsonMatchPattern', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has MatchScope => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::WAFv2::RuleGroup::TextTransformation',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::WAFv2::RuleGroup::TextTransformation',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::TextTransformation')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::TextTransformation',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::TextTransformation',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::WAFv2::RuleGroup::TextTransformation->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::WAFv2::RuleGroup::TextTransformation {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Priority => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Type => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::IPSetForwardedIPConfiguration',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::IPSetForwardedIPConfiguration',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::WAFv2::RuleGroup::IPSetForwardedIPConfiguration->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::WAFv2::RuleGroup::IPSetForwardedIPConfiguration {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has FallbackBehavior => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has HeaderName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Position => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::ForwardedIPConfiguration',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::ForwardedIPConfiguration',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::WAFv2::RuleGroup::ForwardedIPConfiguration->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::WAFv2::RuleGroup::ForwardedIPConfiguration {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has FallbackBehavior => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has HeaderName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::FieldToMatch',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::FieldToMatch',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::WAFv2::RuleGroup::FieldToMatch->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::WAFv2::RuleGroup::FieldToMatch {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AllQueryArguments => (isa => 'Cfn::Value::Json|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Body => (isa => 'Cfn::Value::Json|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has JsonBody => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::JsonBody', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Method => (isa => 'Cfn::Value::Json|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has QueryString => (isa => 'Cfn::Value::Json|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SingleHeader => (isa => 'Cfn::Value::Json|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SingleQueryArgument => (isa => 'Cfn::Value::Json|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has UriPath => (isa => 'Cfn::Value::Json|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::XssMatchStatement',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::XssMatchStatement',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::WAFv2::RuleGroup::XssMatchStatement->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::WAFv2::RuleGroup::XssMatchStatement {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has FieldToMatch => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::FieldToMatch', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TextTransformations => (isa => 'ArrayOfCfn::Resource::Properties::AWS::WAFv2::RuleGroup::TextTransformation', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::SqliMatchStatement',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::SqliMatchStatement',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::WAFv2::RuleGroup::SqliMatchStatement->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::WAFv2::RuleGroup::SqliMatchStatement {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has FieldToMatch => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::FieldToMatch', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TextTransformations => (isa => 'ArrayOfCfn::Resource::Properties::AWS::WAFv2::RuleGroup::TextTransformation', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::SizeConstraintStatement',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::SizeConstraintStatement',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::WAFv2::RuleGroup::SizeConstraintStatement->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::WAFv2::RuleGroup::SizeConstraintStatement {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ComparisonOperator => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has FieldToMatch => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::FieldToMatch', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Size => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TextTransformations => (isa => 'ArrayOfCfn::Resource::Properties::AWS::WAFv2::RuleGroup::TextTransformation', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::RegexPatternSetReferenceStatement',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::RegexPatternSetReferenceStatement',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::WAFv2::RuleGroup::RegexPatternSetReferenceStatement->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::WAFv2::RuleGroup::RegexPatternSetReferenceStatement {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Arn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has FieldToMatch => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::FieldToMatch', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TextTransformations => (isa => 'ArrayOfCfn::Resource::Properties::AWS::WAFv2::RuleGroup::TextTransformation', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::LabelMatchStatement',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::LabelMatchStatement',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::WAFv2::RuleGroup::LabelMatchStatement->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::WAFv2::RuleGroup::LabelMatchStatement {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Key => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Scope => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::IPSetReferenceStatement',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::IPSetReferenceStatement',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::WAFv2::RuleGroup::IPSetReferenceStatement->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::WAFv2::RuleGroup::IPSetReferenceStatement {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Arn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has IPSetForwardedIPConfig => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::IPSetForwardedIPConfiguration', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::GeoMatchStatement',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::GeoMatchStatement',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::WAFv2::RuleGroup::GeoMatchStatement->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::WAFv2::RuleGroup::GeoMatchStatement {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has CountryCodes => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ForwardedIPConfig => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::ForwardedIPConfiguration', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::ByteMatchStatement',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::ByteMatchStatement',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::WAFv2::RuleGroup::ByteMatchStatement->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::WAFv2::RuleGroup::ByteMatchStatement {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has FieldToMatch => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::FieldToMatch', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has PositionalConstraint => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SearchString => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SearchStringBase64 => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TextTransformations => (isa => 'ArrayOfCfn::Resource::Properties::AWS::WAFv2::RuleGroup::TextTransformation', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::WAFv2::RuleGroup::StatementThree',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::WAFv2::RuleGroup::StatementThree',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::StatementThree')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::StatementThree',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::StatementThree',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::WAFv2::RuleGroup::StatementThree->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::WAFv2::RuleGroup::StatementThree {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ByteMatchStatement => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::ByteMatchStatement', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has GeoMatchStatement => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::GeoMatchStatement', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has IPSetReferenceStatement => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::IPSetReferenceStatement', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has LabelMatchStatement => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::LabelMatchStatement', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RegexPatternSetReferenceStatement => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::RegexPatternSetReferenceStatement', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SizeConstraintStatement => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::SizeConstraintStatement', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SqliMatchStatement => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::SqliMatchStatement', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has XssMatchStatement => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::XssMatchStatement', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::RateBasedStatementTwo',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::RateBasedStatementTwo',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::WAFv2::RuleGroup::RateBasedStatementTwo->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::WAFv2::RuleGroup::RateBasedStatementTwo {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AggregateKeyType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ForwardedIPConfig => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::ForwardedIPConfiguration', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Limit => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ScopeDownStatement => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::StatementThree', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::OrStatementTwo',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::OrStatementTwo',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::WAFv2::RuleGroup::OrStatementTwo->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::WAFv2::RuleGroup::OrStatementTwo {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Statements => (isa => 'ArrayOfCfn::Resource::Properties::AWS::WAFv2::RuleGroup::StatementThree', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::NotStatementTwo',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::NotStatementTwo',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::WAFv2::RuleGroup::NotStatementTwo->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::WAFv2::RuleGroup::NotStatementTwo {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Statement => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::StatementThree', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::AndStatementTwo',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::AndStatementTwo',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::WAFv2::RuleGroup::AndStatementTwo->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::WAFv2::RuleGroup::AndStatementTwo {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Statements => (isa => 'ArrayOfCfn::Resource::Properties::AWS::WAFv2::RuleGroup::StatementThree', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::WAFv2::RuleGroup::StatementTwo',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::WAFv2::RuleGroup::StatementTwo',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::StatementTwo')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::StatementTwo',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::StatementTwo',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::WAFv2::RuleGroup::StatementTwo->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::WAFv2::RuleGroup::StatementTwo {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AndStatement => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::AndStatementTwo', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ByteMatchStatement => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::ByteMatchStatement', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has GeoMatchStatement => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::GeoMatchStatement', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has IPSetReferenceStatement => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::IPSetReferenceStatement', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has LabelMatchStatement => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::LabelMatchStatement', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has NotStatement => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::NotStatementTwo', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has OrStatement => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::OrStatementTwo', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RateBasedStatement => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::RateBasedStatementTwo', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RegexPatternSetReferenceStatement => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::RegexPatternSetReferenceStatement', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SizeConstraintStatement => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::SizeConstraintStatement', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SqliMatchStatement => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::SqliMatchStatement', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has XssMatchStatement => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::XssMatchStatement', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::RateBasedStatementOne',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::RateBasedStatementOne',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::WAFv2::RuleGroup::RateBasedStatementOne->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::WAFv2::RuleGroup::RateBasedStatementOne {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AggregateKeyType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ForwardedIPConfig => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::ForwardedIPConfiguration', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Limit => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ScopeDownStatement => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::StatementTwo', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::OrStatementOne',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::OrStatementOne',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::WAFv2::RuleGroup::OrStatementOne->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::WAFv2::RuleGroup::OrStatementOne {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Statements => (isa => 'ArrayOfCfn::Resource::Properties::AWS::WAFv2::RuleGroup::StatementTwo', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::NotStatementOne',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::NotStatementOne',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::WAFv2::RuleGroup::NotStatementOne->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::WAFv2::RuleGroup::NotStatementOne {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Statement => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::StatementTwo', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::AndStatementOne',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::AndStatementOne',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::WAFv2::RuleGroup::AndStatementOne->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::WAFv2::RuleGroup::AndStatementOne {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Statements => (isa => 'ArrayOfCfn::Resource::Properties::AWS::WAFv2::RuleGroup::StatementTwo', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::VisibilityConfig',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::VisibilityConfig',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::WAFv2::RuleGroup::VisibilityConfig->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::WAFv2::RuleGroup::VisibilityConfig {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has CloudWatchMetricsEnabled => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has MetricName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SampledRequestsEnabled => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::StatementOne',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::StatementOne',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::WAFv2::RuleGroup::StatementOne->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::WAFv2::RuleGroup::StatementOne {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AndStatement => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::AndStatementOne', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ByteMatchStatement => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::ByteMatchStatement', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has GeoMatchStatement => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::GeoMatchStatement', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has IPSetReferenceStatement => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::IPSetReferenceStatement', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has LabelMatchStatement => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::LabelMatchStatement', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has NotStatement => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::NotStatementOne', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has OrStatement => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::OrStatementOne', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RateBasedStatement => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::RateBasedStatementOne', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RegexPatternSetReferenceStatement => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::RegexPatternSetReferenceStatement', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SizeConstraintStatement => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::SizeConstraintStatement', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SqliMatchStatement => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::SqliMatchStatement', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has XssMatchStatement => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::XssMatchStatement', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::RuleAction',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::RuleAction',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::WAFv2::RuleGroup::RuleAction->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::WAFv2::RuleGroup::RuleAction {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Allow => (isa => 'Cfn::Value::Json|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Block => (isa => 'Cfn::Value::Json|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Count => (isa => 'Cfn::Value::Json|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::WAFv2::RuleGroup::Label',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::WAFv2::RuleGroup::Label',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::Label')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::Label',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::Label',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::WAFv2::RuleGroup::Label->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::WAFv2::RuleGroup::Label {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::WAFv2::RuleGroup::Rule',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::WAFv2::RuleGroup::Rule',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::Rule')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::Rule',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::Rule',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::WAFv2::RuleGroup::Rule->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::WAFv2::RuleGroup::Rule {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Action => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::RuleAction', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Priority => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RuleLabels => (isa => 'ArrayOfCfn::Resource::Properties::AWS::WAFv2::RuleGroup::Label', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Statement => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::StatementOne', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has VisibilityConfig => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::VisibilityConfig', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::LabelSummary',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::LabelSummary',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::WAFv2::RuleGroup::LabelSummary->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::WAFv2::RuleGroup::LabelSummary {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'MapOfCfn::Resource::Properties::AWS::WAFv2::RuleGroup::CustomResponseBody',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Hash') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'MapOfCfn::Resource::Properties::AWS::WAFv2::RuleGroup::CustomResponseBody',
  from 'HashRef',
   via {
     my $arg = $_;
     if (my $f = Cfn::TypeLibrary::try_function($arg)) {
       return $f
     } else {
       Cfn::Value::Hash->new(Value => {
         map { $_ => Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::CustomResponseBody')->coerce($arg->{$_}) } keys %$arg
       });
     }
   };

subtype 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::CustomResponseBody',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::CustomResponseBody',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::WAFv2::RuleGroup::CustomResponseBody->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::WAFv2::RuleGroup::CustomResponseBody {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Content => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ContentType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::WAFv2::RuleGroup {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has Capacity => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has CustomResponseBodies => (isa => 'MapOfCfn::Resource::Properties::AWS::WAFv2::RuleGroup::CustomResponseBody', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Description => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Rules => (isa => 'ArrayOfCfn::Resource::Properties::AWS::WAFv2::RuleGroup::Rule', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Scope => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Tags => (isa => 'ArrayOfCfn::Resource::Properties::TagType', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has VisibilityConfig => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::VisibilityConfig', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::WAFv2::RuleGroup - Cfn resource for AWS::WAFv2::RuleGroup

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::WAFv2::RuleGroup.

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
