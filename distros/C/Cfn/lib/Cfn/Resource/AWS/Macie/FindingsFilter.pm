# AWS::Macie::FindingsFilter generated from spec 34.0.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::Macie::FindingsFilter',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::Macie::FindingsFilter->new( %$_ ) };

package Cfn::Resource::AWS::Macie::FindingsFilter {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::Macie::FindingsFilter', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [ 'Arn','FindingsFilterListItems','Id' ]
  }
  sub supported_regions {
    [ 'ap-east-1','ap-northeast-1','ap-northeast-2','ap-northeast-3','ap-south-1','ap-southeast-1','ap-southeast-2','ca-central-1','eu-central-1','eu-north-1','eu-west-1','eu-west-2','eu-west-3','sa-east-1','us-east-1','us-east-2','us-west-1','us-west-2' ]
  }
}



subtype 'Cfn::Resource::Properties::AWS::Macie::FindingsFilter::Criterion',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Macie::FindingsFilter::Criterion',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Macie::FindingsFilter::Criterion->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Macie::FindingsFilter::Criterion {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
}

subtype 'Cfn::Resource::Properties::AWS::Macie::FindingsFilter::FindingsFilterListItem',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Macie::FindingsFilter::FindingsFilterListItem',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Macie::FindingsFilter::FindingsFilterListItem->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Macie::FindingsFilter::FindingsFilterListItem {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Id => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::Macie::FindingsFilter::FindingCriteria',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Macie::FindingsFilter::FindingCriteria',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Macie::FindingsFilter::FindingCriteria->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Macie::FindingsFilter::FindingCriteria {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Criterion => (isa => 'Cfn::Resource::Properties::AWS::Macie::FindingsFilter::Criterion', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::Macie::FindingsFilter {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has Action => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Description => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has FindingCriteria => (isa => 'Cfn::Resource::Properties::AWS::Macie::FindingsFilter::FindingCriteria', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Position => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::Macie::FindingsFilter - Cfn resource for AWS::Macie::FindingsFilter

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::Macie::FindingsFilter.

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
