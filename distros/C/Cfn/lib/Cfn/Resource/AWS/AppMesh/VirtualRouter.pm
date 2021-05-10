# AWS::AppMesh::VirtualRouter generated from spec 34.0.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::AppMesh::VirtualRouter',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::AppMesh::VirtualRouter->new( %$_ ) };

package Cfn::Resource::AWS::AppMesh::VirtualRouter {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::AppMesh::VirtualRouter', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [ 'Arn','MeshName','MeshOwner','ResourceOwner','Uid','VirtualRouterName' ]
  }
  sub supported_regions {
    [ 'ap-northeast-1','ap-northeast-2','ap-south-1','ap-southeast-1','ap-southeast-2','ca-central-1','eu-central-1','eu-west-1','eu-west-2','us-east-1','us-east-2','us-west-1','us-west-2' ]
  }
}



subtype 'Cfn::Resource::Properties::AWS::AppMesh::VirtualRouter::PortMapping',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppMesh::VirtualRouter::PortMapping',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppMesh::VirtualRouter::PortMapping->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppMesh::VirtualRouter::PortMapping {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Port => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Protocol => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::AppMesh::VirtualRouter::VirtualRouterListener',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::AppMesh::VirtualRouter::VirtualRouterListener',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::AppMesh::VirtualRouter::VirtualRouterListener')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::AppMesh::VirtualRouter::VirtualRouterListener',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppMesh::VirtualRouter::VirtualRouterListener',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppMesh::VirtualRouter::VirtualRouterListener->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppMesh::VirtualRouter::VirtualRouterListener {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has PortMapping => (isa => 'Cfn::Resource::Properties::AWS::AppMesh::VirtualRouter::PortMapping', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppMesh::VirtualRouter::VirtualRouterSpec',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppMesh::VirtualRouter::VirtualRouterSpec',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppMesh::VirtualRouter::VirtualRouterSpec->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppMesh::VirtualRouter::VirtualRouterSpec {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Listeners => (isa => 'ArrayOfCfn::Resource::Properties::AWS::AppMesh::VirtualRouter::VirtualRouterListener', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::AppMesh::VirtualRouter {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has MeshName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has MeshOwner => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Spec => (isa => 'Cfn::Resource::Properties::AWS::AppMesh::VirtualRouter::VirtualRouterSpec', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Tags => (isa => 'ArrayOfCfn::Resource::Properties::TagType', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has VirtualRouterName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::AppMesh::VirtualRouter - Cfn resource for AWS::AppMesh::VirtualRouter

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::AppMesh::VirtualRouter.

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
