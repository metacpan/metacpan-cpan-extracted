# AWS::WAFv2::RuleGroup generated from spec 10.0.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::WAFv2::RuleGroup->new( %$_ ) };

package Cfn::Resource::AWS::WAFv2::RuleGroup {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [ 'Arn','Id' ]
  }
  sub supported_regions {
    [ 'ap-northeast-1','ap-south-1','ap-southeast-1','ap-southeast-2','ca-central-1','eu-central-1','eu-west-1','eu-west-2','eu-west-3','sa-east-1','us-east-1','us-east-2','us-west-1','us-west-2' ]
  }
}



subtype 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::UriPath',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::UriPath',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::UriPathValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::UriPathValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
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
       return Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::TextTransformationValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::TextTransformationValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Priority => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Type => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::SingleQueryArgument',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::SingleQueryArgument',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::SingleQueryArgumentValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::SingleQueryArgumentValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::SingleHeader',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::SingleHeader',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::SingleHeaderValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::SingleHeaderValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::QueryString',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::QueryString',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::QueryStringValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::QueryStringValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
}

subtype 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::Method',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::Method',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::MethodValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::MethodValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
}

subtype 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::Body',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::Body',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::BodyValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::BodyValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
}

subtype 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::AllQueryArguments',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::AllQueryArguments',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::AllQueryArgumentsValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::AllQueryArgumentsValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
}

subtype 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::TextTransformations',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::TextTransformations',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::TextTransformationsValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::TextTransformationsValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has TextTransformations => (isa => 'ArrayOfCfn::Resource::Properties::AWS::WAFv2::RuleGroup::TextTransformation', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::FieldToMatch',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::FieldToMatch',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::FieldToMatchValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::FieldToMatchValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AllQueryArguments => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::AllQueryArguments', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Body => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::Body', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Method => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::Method', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has QueryString => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::QueryString', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SingleHeader => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::SingleHeader', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SingleQueryArgument => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::SingleQueryArgument', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has UriPath => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::UriPath', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::CountryCodes',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::CountryCodes',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::CountryCodesValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::CountryCodesValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has CountryCodes => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::XssMatchStatement',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::XssMatchStatement',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::XssMatchStatementValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::XssMatchStatementValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has FieldToMatch => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::FieldToMatch', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TextTransformations => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::TextTransformations', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::SqliMatchStatement',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::SqliMatchStatement',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::SqliMatchStatementValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::SqliMatchStatementValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has FieldToMatch => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::FieldToMatch', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TextTransformations => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::TextTransformations', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::SizeConstraintStatement',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::SizeConstraintStatement',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::SizeConstraintStatementValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::SizeConstraintStatementValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ComparisonOperator => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has FieldToMatch => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::FieldToMatch', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Size => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TextTransformations => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::TextTransformations', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::RegexPatternSetReferenceStatement',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::RegexPatternSetReferenceStatement',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::RegexPatternSetReferenceStatementValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::RegexPatternSetReferenceStatementValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Arn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has FieldToMatch => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::FieldToMatch', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TextTransformations => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::TextTransformations', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::IPSetReferenceStatement',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::IPSetReferenceStatement',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::IPSetReferenceStatementValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::IPSetReferenceStatementValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Arn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::GeoMatchStatement',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::GeoMatchStatement',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::GeoMatchStatementValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::GeoMatchStatementValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has CountryCodes => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::CountryCodes', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::ByteMatchStatement',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::ByteMatchStatement',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::ByteMatchStatementValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::ByteMatchStatementValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has FieldToMatch => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::FieldToMatch', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has PositionalConstraint => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SearchString => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SearchStringBase64 => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TextTransformations => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::TextTransformations', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
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
       return Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::StatementThreeValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::StatementThreeValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ByteMatchStatement => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::ByteMatchStatement', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has GeoMatchStatement => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::GeoMatchStatement', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has IPSetReferenceStatement => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::IPSetReferenceStatement', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RegexPatternSetReferenceStatement => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::RegexPatternSetReferenceStatement', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SizeConstraintStatement => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::SizeConstraintStatement', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SqliMatchStatement => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::SqliMatchStatement', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has XssMatchStatement => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::XssMatchStatement', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::StatementThrees',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::StatementThrees',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::StatementThreesValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::StatementThreesValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has StatementThrees => (isa => 'ArrayOfCfn::Resource::Properties::AWS::WAFv2::RuleGroup::StatementThree', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::RateBasedStatementTwo',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::RateBasedStatementTwo',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::RateBasedStatementTwoValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::RateBasedStatementTwoValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AggregateKeyType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Limit => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
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
       return Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::OrStatementTwoValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::OrStatementTwoValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Statements => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::StatementThrees', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::NotStatementTwo',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::NotStatementTwo',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::NotStatementTwoValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::NotStatementTwoValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Statement => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::StatementThree', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::AndStatementTwo',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::AndStatementTwo',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::AndStatementTwoValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::AndStatementTwoValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Statements => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::StatementThrees', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
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
       return Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::StatementTwoValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::StatementTwoValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AndStatement => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::AndStatementTwo', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ByteMatchStatement => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::ByteMatchStatement', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has GeoMatchStatement => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::GeoMatchStatement', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has IPSetReferenceStatement => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::IPSetReferenceStatement', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has NotStatement => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::NotStatementTwo', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has OrStatement => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::OrStatementTwo', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RateBasedStatement => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::RateBasedStatementTwo', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RegexPatternSetReferenceStatement => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::RegexPatternSetReferenceStatement', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SizeConstraintStatement => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::SizeConstraintStatement', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SqliMatchStatement => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::SqliMatchStatement', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has XssMatchStatement => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::XssMatchStatement', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::StatementTwos',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::StatementTwos',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::StatementTwosValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::StatementTwosValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has StatementTwos => (isa => 'ArrayOfCfn::Resource::Properties::AWS::WAFv2::RuleGroup::StatementTwo', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::RateBasedStatementOne',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::RateBasedStatementOne',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::RateBasedStatementOneValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::RateBasedStatementOneValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AggregateKeyType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Limit => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
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
       return Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::OrStatementOneValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::OrStatementOneValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Statements => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::StatementTwos', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::NotStatementOne',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::NotStatementOne',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::NotStatementOneValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::NotStatementOneValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Statement => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::StatementTwo', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::CountAction',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::CountAction',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::CountActionValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::CountActionValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
}

subtype 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::BlockAction',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::BlockAction',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::BlockActionValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::BlockActionValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
}

subtype 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::AndStatementOne',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::AndStatementOne',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::AndStatementOneValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::AndStatementOneValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Statements => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::StatementTwos', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::AllowAction',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::AllowAction',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::AllowActionValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::AllowActionValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
}

subtype 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::VisibilityConfig',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::VisibilityConfig',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::VisibilityConfigValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::VisibilityConfigValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has CloudWatchMetricsEnabled => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has MetricName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SampledRequestsEnabled => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::StatementOne',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::StatementOne',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::StatementOneValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::StatementOneValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AndStatement => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::AndStatementOne', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ByteMatchStatement => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::ByteMatchStatement', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has GeoMatchStatement => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::GeoMatchStatement', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has IPSetReferenceStatement => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::IPSetReferenceStatement', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
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
       return Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::RuleActionValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::RuleActionValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Allow => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::AllowAction', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Block => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::BlockAction', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Count => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::CountAction', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
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
       return Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::RuleValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::RuleValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Action => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::RuleAction', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Priority => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Statement => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::StatementOne', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has VisibilityConfig => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::VisibilityConfig', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::TagList',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::TagList',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::TagListValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::TagListValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has TagList => (isa => 'ArrayOfCfn::Resource::Properties::TagType', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::Rules',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::Rules',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::RulesValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::RulesValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Rules => (isa => 'ArrayOfCfn::Resource::Properties::AWS::WAFv2::RuleGroup::Rule', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::WAFv2::RuleGroup {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has Capacity => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Description => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Rules => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::Rules', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Scope => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Tags => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::TagList', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has VisibilityConfig => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::RuleGroup::VisibilityConfig', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
