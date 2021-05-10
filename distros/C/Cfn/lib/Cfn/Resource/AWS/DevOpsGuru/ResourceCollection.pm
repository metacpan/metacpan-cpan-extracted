# AWS::DevOpsGuru::ResourceCollection generated from spec 22.0.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::DevOpsGuru::ResourceCollection',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::DevOpsGuru::ResourceCollection->new( %$_ ) };

package Cfn::Resource::AWS::DevOpsGuru::ResourceCollection {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::DevOpsGuru::ResourceCollection', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [ 'ResourceCollectionType' ]
  }
  sub supported_regions {
    [ 'ap-northeast-1','eu-west-1','us-east-1','us-east-2','us-west-2' ]
  }
}



subtype 'Cfn::Resource::Properties::AWS::DevOpsGuru::ResourceCollection::CloudFormationCollectionFilter',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::DevOpsGuru::ResourceCollection::CloudFormationCollectionFilter',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::DevOpsGuru::ResourceCollection::CloudFormationCollectionFilter->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::DevOpsGuru::ResourceCollection::CloudFormationCollectionFilter {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has StackNames => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::DevOpsGuru::ResourceCollection::ResourceCollectionFilter',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::DevOpsGuru::ResourceCollection::ResourceCollectionFilter',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::DevOpsGuru::ResourceCollection::ResourceCollectionFilter->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::DevOpsGuru::ResourceCollection::ResourceCollectionFilter {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has CloudFormation => (isa => 'Cfn::Resource::Properties::AWS::DevOpsGuru::ResourceCollection::CloudFormationCollectionFilter', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::DevOpsGuru::ResourceCollection {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has ResourceCollectionFilter => (isa => 'Cfn::Resource::Properties::AWS::DevOpsGuru::ResourceCollection::ResourceCollectionFilter', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::DevOpsGuru::ResourceCollection - Cfn resource for AWS::DevOpsGuru::ResourceCollection

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::DevOpsGuru::ResourceCollection.

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
