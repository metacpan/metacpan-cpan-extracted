# AWS::EFS::AccessPoint generated from spec 34.0.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::EFS::AccessPoint',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::EFS::AccessPoint->new( %$_ ) };

package Cfn::Resource::AWS::EFS::AccessPoint {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::EFS::AccessPoint', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [ 'AccessPointId','Arn' ]
  }
  sub supported_regions {
    [ 'af-south-1','ap-east-1','ap-northeast-1','ap-northeast-2','ap-northeast-3','ap-south-1','ap-southeast-1','ap-southeast-2','ca-central-1','cn-north-1','cn-northwest-1','eu-central-1','eu-north-1','eu-south-1','eu-west-1','eu-west-2','eu-west-3','me-south-1','sa-east-1','us-east-1','us-east-2','us-gov-east-1','us-gov-west-1','us-west-1','us-west-2' ]
  }
}



subtype 'Cfn::Resource::Properties::AWS::EFS::AccessPoint::CreationInfo',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::EFS::AccessPoint::CreationInfo',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::EFS::AccessPoint::CreationInfo->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::EFS::AccessPoint::CreationInfo {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has OwnerGid => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has OwnerUid => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Permissions => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

subtype 'Cfn::Resource::Properties::AWS::EFS::AccessPoint::RootDirectory',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::EFS::AccessPoint::RootDirectory',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::EFS::AccessPoint::RootDirectory->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::EFS::AccessPoint::RootDirectory {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has CreationInfo => (isa => 'Cfn::Resource::Properties::AWS::EFS::AccessPoint::CreationInfo', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Path => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

subtype 'Cfn::Resource::Properties::AWS::EFS::AccessPoint::PosixUser',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::EFS::AccessPoint::PosixUser',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::EFS::AccessPoint::PosixUser->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::EFS::AccessPoint::PosixUser {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Gid => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has SecondaryGids => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Uid => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::EFS::AccessPoint::AccessPointTag',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::EFS::AccessPoint::AccessPointTag',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::EFS::AccessPoint::AccessPointTag')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::EFS::AccessPoint::AccessPointTag',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::EFS::AccessPoint::AccessPointTag',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::EFS::AccessPoint::AccessPointTag->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::EFS::AccessPoint::AccessPointTag {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Key => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Value => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::EFS::AccessPoint {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has AccessPointTags => (isa => 'ArrayOfCfn::Resource::Properties::AWS::EFS::AccessPoint::AccessPointTag', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ClientToken => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has FileSystemId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has PosixUser => (isa => 'Cfn::Resource::Properties::AWS::EFS::AccessPoint::PosixUser', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has RootDirectory => (isa => 'Cfn::Resource::Properties::AWS::EFS::AccessPoint::RootDirectory', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::EFS::AccessPoint - Cfn resource for AWS::EFS::AccessPoint

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::EFS::AccessPoint.

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
