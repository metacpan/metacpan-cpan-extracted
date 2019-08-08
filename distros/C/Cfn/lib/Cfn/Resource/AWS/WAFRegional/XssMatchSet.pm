# AWS::WAFRegional::XssMatchSet generated from spec 5.0.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::WAFRegional::XssMatchSet',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::WAFRegional::XssMatchSet->new( %$_ ) };

package Cfn::Resource::AWS::WAFRegional::XssMatchSet {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::WAFRegional::XssMatchSet', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [  ]
  }
  sub supported_regions {
    [ 'ap-northeast-1','ap-northeast-2','ap-southeast-1','ap-southeast-2','eu-central-1','eu-north-1','eu-west-1','eu-west-2','us-east-1','us-east-2','us-west-1','us-west-2' ]
  }
}



subtype 'Cfn::Resource::Properties::AWS::WAFRegional::XssMatchSet::FieldToMatch',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::WAFRegional::XssMatchSet::FieldToMatch',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::WAFRegional::XssMatchSet::FieldToMatchValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::WAFRegional::XssMatchSet::FieldToMatchValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Data => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Type => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::WAFRegional::XssMatchSet::XssMatchTuple',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::WAFRegional::XssMatchSet::XssMatchTuple',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::WAFRegional::XssMatchSet::XssMatchTuple')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::WAFRegional::XssMatchSet::XssMatchTuple',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::WAFRegional::XssMatchSet::XssMatchTuple',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::WAFRegional::XssMatchSet::XssMatchTupleValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::WAFRegional::XssMatchSet::XssMatchTupleValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has FieldToMatch => (isa => 'Cfn::Resource::Properties::AWS::WAFRegional::XssMatchSet::FieldToMatch', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TextTransformation => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::WAFRegional::XssMatchSet {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has XssMatchTuples => (isa => 'ArrayOfCfn::Resource::Properties::AWS::WAFRegional::XssMatchSet::XssMatchTuple', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
