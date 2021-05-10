# AWS::S3::AccessPoint generated from spec 34.0.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::S3::AccessPoint',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::S3::AccessPoint->new( %$_ ) };

package Cfn::Resource::AWS::S3::AccessPoint {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::S3::AccessPoint', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [ 'NetworkOrigin' ]
  }
  sub supported_regions {
    [ 'af-south-1','ap-east-1','ap-northeast-1','ap-northeast-2','ap-northeast-3','ap-south-1','ap-southeast-1','ap-southeast-2','ca-central-1','cn-north-1','cn-northwest-1','eu-central-1','eu-north-1','eu-south-1','eu-west-1','eu-west-2','eu-west-3','me-south-1','sa-east-1','us-east-1','us-east-2','us-gov-east-1','us-gov-west-1','us-west-1','us-west-2' ]
  }
}



subtype 'Cfn::Resource::Properties::AWS::S3::AccessPoint::VpcConfiguration',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::S3::AccessPoint::VpcConfiguration',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::S3::AccessPoint::VpcConfiguration->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::S3::AccessPoint::VpcConfiguration {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has VpcId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

subtype 'Cfn::Resource::Properties::AWS::S3::AccessPoint::PublicAccessBlockConfiguration',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::S3::AccessPoint::PublicAccessBlockConfiguration',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::S3::AccessPoint::PublicAccessBlockConfiguration->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::S3::AccessPoint::PublicAccessBlockConfiguration {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has BlockPublicAcls => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has BlockPublicPolicy => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has IgnorePublicAcls => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has RestrictPublicBuckets => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

package Cfn::Resource::Properties::AWS::S3::AccessPoint {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has Bucket => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Policy => (isa => 'Cfn::Value::Json|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has PublicAccessBlockConfiguration => (isa => 'Cfn::Resource::Properties::AWS::S3::AccessPoint::PublicAccessBlockConfiguration', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has VpcConfiguration => (isa => 'Cfn::Resource::Properties::AWS::S3::AccessPoint::VpcConfiguration', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::S3::AccessPoint - Cfn resource for AWS::S3::AccessPoint

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::S3::AccessPoint.

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
