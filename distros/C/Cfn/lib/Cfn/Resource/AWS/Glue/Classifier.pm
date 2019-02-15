# AWS::Glue::Classifier generated from spec 2.6.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::Glue::Classifier',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::Glue::Classifier->new( %$_ ) };

package Cfn::Resource::AWS::Glue::Classifier {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::Glue::Classifier', is => 'rw', coerce => 1);
  sub _build_attributes {
    [  ]
  }
}



subtype 'Cfn::Resource::Properties::AWS::Glue::Classifier::XMLClassifier',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Glue::Classifier::XMLClassifier',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::Glue::Classifier::XMLClassifierValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::Glue::Classifier::XMLClassifierValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Classification => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has RowTag => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::Glue::Classifier::JsonClassifier',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Glue::Classifier::JsonClassifier',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::Glue::Classifier::JsonClassifierValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::Glue::Classifier::JsonClassifierValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has JsonPath => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

subtype 'Cfn::Resource::Properties::AWS::Glue::Classifier::GrokClassifier',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Glue::Classifier::GrokClassifier',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::Glue::Classifier::GrokClassifierValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::Glue::Classifier::GrokClassifierValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Classification => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has CustomPatterns => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has GrokPattern => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

package Cfn::Resource::Properties::AWS::Glue::Classifier {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has GrokClassifier => (isa => 'Cfn::Resource::Properties::AWS::Glue::Classifier::GrokClassifier', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has JsonClassifier => (isa => 'Cfn::Resource::Properties::AWS::Glue::Classifier::JsonClassifier', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has XMLClassifier => (isa => 'Cfn::Resource::Properties::AWS::Glue::Classifier::XMLClassifier', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
