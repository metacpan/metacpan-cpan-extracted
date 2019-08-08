# AWS::WAFRegional::SizeConstraintSet generated from spec 5.0.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::WAFRegional::SizeConstraintSet',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::WAFRegional::SizeConstraintSet->new( %$_ ) };

package Cfn::Resource::AWS::WAFRegional::SizeConstraintSet {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::WAFRegional::SizeConstraintSet', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [  ]
  }
  sub supported_regions {
    [ 'ap-northeast-1','ap-northeast-2','ap-southeast-1','ap-southeast-2','eu-central-1','eu-north-1','eu-west-1','eu-west-2','us-east-1','us-east-2','us-west-1','us-west-2' ]
  }
}



subtype 'Cfn::Resource::Properties::AWS::WAFRegional::SizeConstraintSet::FieldToMatch',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::WAFRegional::SizeConstraintSet::FieldToMatch',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::WAFRegional::SizeConstraintSet::FieldToMatchValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::WAFRegional::SizeConstraintSet::FieldToMatchValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Data => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Type => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::WAFRegional::SizeConstraintSet::SizeConstraint',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::WAFRegional::SizeConstraintSet::SizeConstraint',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::WAFRegional::SizeConstraintSet::SizeConstraint')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::WAFRegional::SizeConstraintSet::SizeConstraint',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::WAFRegional::SizeConstraintSet::SizeConstraint',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::WAFRegional::SizeConstraintSet::SizeConstraintValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::WAFRegional::SizeConstraintSet::SizeConstraintValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ComparisonOperator => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has FieldToMatch => (isa => 'Cfn::Resource::Properties::AWS::WAFRegional::SizeConstraintSet::FieldToMatch', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Size => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TextTransformation => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::WAFRegional::SizeConstraintSet {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has SizeConstraints => (isa => 'ArrayOfCfn::Resource::Properties::AWS::WAFRegional::SizeConstraintSet::SizeConstraint', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
