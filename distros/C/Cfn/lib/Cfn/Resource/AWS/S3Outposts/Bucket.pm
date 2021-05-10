# AWS::S3Outposts::Bucket generated from spec 34.0.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::S3Outposts::Bucket',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::S3Outposts::Bucket->new( %$_ ) };

package Cfn::Resource::AWS::S3Outposts::Bucket {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::S3Outposts::Bucket', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [ 'Arn' ]
  }
  sub supported_regions {
    [ 'af-south-1','ap-east-1','ap-northeast-1','ap-northeast-2','ap-south-1','ap-southeast-1','ap-southeast-2','ca-central-1','eu-central-1','eu-north-1','eu-south-1','eu-west-1','eu-west-2','eu-west-3','me-south-1','sa-east-1','us-east-1','us-east-2','us-west-1','us-west-2' ]
  }
}



subtype 'Cfn::Resource::Properties::AWS::S3Outposts::Bucket::AbortIncompleteMultipartUpload',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::S3Outposts::Bucket::AbortIncompleteMultipartUpload',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::S3Outposts::Bucket::AbortIncompleteMultipartUpload->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::S3Outposts::Bucket::AbortIncompleteMultipartUpload {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has DaysAfterInitiation => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::S3Outposts::Bucket::Rule',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::S3Outposts::Bucket::Rule',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::S3Outposts::Bucket::Rule')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::S3Outposts::Bucket::Rule',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::S3Outposts::Bucket::Rule',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::S3Outposts::Bucket::Rule->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::S3Outposts::Bucket::Rule {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AbortIncompleteMultipartUpload => (isa => 'Cfn::Resource::Properties::AWS::S3Outposts::Bucket::AbortIncompleteMultipartUpload', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ExpirationDate => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ExpirationInDays => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Filter => (isa => 'Cfn::Value::Json|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Id => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Status => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::S3Outposts::Bucket::LifecycleConfiguration',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::S3Outposts::Bucket::LifecycleConfiguration',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::S3Outposts::Bucket::LifecycleConfiguration->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::S3Outposts::Bucket::LifecycleConfiguration {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Rules => (isa => 'ArrayOfCfn::Resource::Properties::AWS::S3Outposts::Bucket::Rule', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::S3Outposts::Bucket {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has BucketName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has LifecycleConfiguration => (isa => 'Cfn::Resource::Properties::AWS::S3Outposts::Bucket::LifecycleConfiguration', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has OutpostId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Tags => (isa => 'ArrayOfCfn::Resource::Properties::TagType', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::S3Outposts::Bucket - Cfn resource for AWS::S3Outposts::Bucket

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::S3Outposts::Bucket.

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
