# AWS::WAFv2::RegexPatternSet generated from spec 10.0.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::WAFv2::RegexPatternSet',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::WAFv2::RegexPatternSet->new( %$_ ) };

package Cfn::Resource::AWS::WAFv2::RegexPatternSet {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::RegexPatternSet', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [ 'Arn','Id' ]
  }
  sub supported_regions {
    [ 'ap-northeast-1','ap-south-1','ap-southeast-1','ap-southeast-2','ca-central-1','eu-central-1','eu-west-1','eu-west-2','eu-west-3','sa-east-1','us-east-1','us-east-2','us-west-1','us-west-2' ]
  }
}


subtype 'ArrayOfCfn::Resource::Properties::AWS::WAFv2::RegexPatternSet::Regex',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::WAFv2::RegexPatternSet::Regex',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::WAFv2::RegexPatternSet::Regex')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::WAFv2::RegexPatternSet::Regex',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::WAFv2::RegexPatternSet::Regex',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::WAFv2::RegexPatternSet::RegexValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::WAFv2::RegexPatternSet::RegexValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has RegexString => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::WAFv2::RegexPatternSet::TagList',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::WAFv2::RegexPatternSet::TagList',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::WAFv2::RegexPatternSet::TagListValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::WAFv2::RegexPatternSet::TagListValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has TagList => (isa => 'ArrayOfCfn::Resource::Properties::TagType', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::WAFv2::RegexPatternSet::RegularExpressionList',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::WAFv2::RegexPatternSet::RegularExpressionList',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::WAFv2::RegexPatternSet::RegularExpressionListValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::WAFv2::RegexPatternSet::RegularExpressionListValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has RegularExpressionList => (isa => 'ArrayOfCfn::Resource::Properties::AWS::WAFv2::RegexPatternSet::Regex', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::WAFv2::RegexPatternSet {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has Description => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RegularExpressionList => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::RegexPatternSet::RegularExpressionList', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Scope => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Tags => (isa => 'Cfn::Resource::Properties::AWS::WAFv2::RegexPatternSet::TagList', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
