# AWS::WAFRegional::SqlInjectionMatchSet generated from spec 18.4.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::WAFRegional::SqlInjectionMatchSet',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::WAFRegional::SqlInjectionMatchSet->new( %$_ ) };

package Cfn::Resource::AWS::WAFRegional::SqlInjectionMatchSet {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::WAFRegional::SqlInjectionMatchSet', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [  ]
  }
  sub supported_regions {
    [ 'ap-northeast-1','ap-northeast-2','ap-southeast-1','ap-southeast-2','eu-central-1','eu-north-1','eu-west-1','eu-west-2','us-east-1','us-east-2','us-west-1','us-west-2' ]
  }
}



subtype 'Cfn::Resource::Properties::AWS::WAFRegional::SqlInjectionMatchSet::FieldToMatch',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::WAFRegional::SqlInjectionMatchSet::FieldToMatch',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::WAFRegional::SqlInjectionMatchSet::FieldToMatch->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::WAFRegional::SqlInjectionMatchSet::FieldToMatch {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Data => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Type => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::WAFRegional::SqlInjectionMatchSet::SqlInjectionMatchTuple',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::WAFRegional::SqlInjectionMatchSet::SqlInjectionMatchTuple',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::WAFRegional::SqlInjectionMatchSet::SqlInjectionMatchTuple')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::WAFRegional::SqlInjectionMatchSet::SqlInjectionMatchTuple',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::WAFRegional::SqlInjectionMatchSet::SqlInjectionMatchTuple',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::WAFRegional::SqlInjectionMatchSet::SqlInjectionMatchTuple->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::WAFRegional::SqlInjectionMatchSet::SqlInjectionMatchTuple {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has FieldToMatch => (isa => 'Cfn::Resource::Properties::AWS::WAFRegional::SqlInjectionMatchSet::FieldToMatch', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TextTransformation => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::WAFRegional::SqlInjectionMatchSet {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has SqlInjectionMatchTuples => (isa => 'ArrayOfCfn::Resource::Properties::AWS::WAFRegional::SqlInjectionMatchSet::SqlInjectionMatchTuple', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::WAFRegional::SqlInjectionMatchSet - Cfn resource for AWS::WAFRegional::SqlInjectionMatchSet

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::WAFRegional::SqlInjectionMatchSet.

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
