# AWS::AppMesh::VirtualService generated from spec 18.4.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::AppMesh::VirtualService',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::AppMesh::VirtualService->new( %$_ ) };

package Cfn::Resource::AWS::AppMesh::VirtualService {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::AppMesh::VirtualService', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [ 'Arn','MeshName','MeshOwner','ResourceOwner','Uid','VirtualServiceName' ]
  }
  sub supported_regions {
    [ 'ap-northeast-1','ap-northeast-2','ap-south-1','ap-southeast-1','ap-southeast-2','ca-central-1','eu-central-1','eu-west-1','eu-west-2','us-east-1','us-east-2','us-west-1','us-west-2' ]
  }
}



subtype 'Cfn::Resource::Properties::AWS::AppMesh::VirtualService::VirtualRouterServiceProvider',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppMesh::VirtualService::VirtualRouterServiceProvider',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppMesh::VirtualService::VirtualRouterServiceProvider->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppMesh::VirtualService::VirtualRouterServiceProvider {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has VirtualRouterName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppMesh::VirtualService::VirtualNodeServiceProvider',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppMesh::VirtualService::VirtualNodeServiceProvider',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppMesh::VirtualService::VirtualNodeServiceProvider->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppMesh::VirtualService::VirtualNodeServiceProvider {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has VirtualNodeName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppMesh::VirtualService::VirtualServiceProvider',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppMesh::VirtualService::VirtualServiceProvider',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppMesh::VirtualService::VirtualServiceProvider->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppMesh::VirtualService::VirtualServiceProvider {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has VirtualNode => (isa => 'Cfn::Resource::Properties::AWS::AppMesh::VirtualService::VirtualNodeServiceProvider', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has VirtualRouter => (isa => 'Cfn::Resource::Properties::AWS::AppMesh::VirtualService::VirtualRouterServiceProvider', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppMesh::VirtualService::VirtualServiceSpec',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppMesh::VirtualService::VirtualServiceSpec',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppMesh::VirtualService::VirtualServiceSpec->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppMesh::VirtualService::VirtualServiceSpec {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Provider => (isa => 'Cfn::Resource::Properties::AWS::AppMesh::VirtualService::VirtualServiceProvider', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::AppMesh::VirtualService {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has MeshName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has MeshOwner => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Spec => (isa => 'Cfn::Resource::Properties::AWS::AppMesh::VirtualService::VirtualServiceSpec', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Tags => (isa => 'ArrayOfCfn::Resource::Properties::TagType', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has VirtualServiceName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::AppMesh::VirtualService - Cfn resource for AWS::AppMesh::VirtualService

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::AppMesh::VirtualService.

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
