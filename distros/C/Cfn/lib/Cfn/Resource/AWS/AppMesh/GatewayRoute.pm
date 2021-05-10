# AWS::AppMesh::GatewayRoute generated from spec 34.0.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::AppMesh::GatewayRoute',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::AppMesh::GatewayRoute->new( %$_ ) };

package Cfn::Resource::AWS::AppMesh::GatewayRoute {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::AppMesh::GatewayRoute', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [ 'Arn','GatewayRouteName','MeshName','MeshOwner','ResourceOwner','Uid','VirtualGatewayName' ]
  }
  sub supported_regions {
    [ 'ap-east-1','ap-northeast-1','ap-northeast-2','ap-south-1','ap-southeast-2','ca-central-1','eu-central-1','eu-north-1','eu-west-1','eu-west-2','eu-west-3','me-south-1','sa-east-1','us-east-1','us-east-2','us-west-1','us-west-2' ]
  }
}



subtype 'Cfn::Resource::Properties::AWS::AppMesh::GatewayRoute::GatewayRouteVirtualService',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppMesh::GatewayRoute::GatewayRouteVirtualService',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppMesh::GatewayRoute::GatewayRouteVirtualService->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppMesh::GatewayRoute::GatewayRouteVirtualService {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has VirtualServiceName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppMesh::GatewayRoute::GatewayRouteTarget',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppMesh::GatewayRoute::GatewayRouteTarget',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppMesh::GatewayRoute::GatewayRouteTarget->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppMesh::GatewayRoute::GatewayRouteTarget {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has VirtualService => (isa => 'Cfn::Resource::Properties::AWS::AppMesh::GatewayRoute::GatewayRouteVirtualService', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppMesh::GatewayRoute::HttpGatewayRouteMatch',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppMesh::GatewayRoute::HttpGatewayRouteMatch',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppMesh::GatewayRoute::HttpGatewayRouteMatch->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppMesh::GatewayRoute::HttpGatewayRouteMatch {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Prefix => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppMesh::GatewayRoute::HttpGatewayRouteAction',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppMesh::GatewayRoute::HttpGatewayRouteAction',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppMesh::GatewayRoute::HttpGatewayRouteAction->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppMesh::GatewayRoute::HttpGatewayRouteAction {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Target => (isa => 'Cfn::Resource::Properties::AWS::AppMesh::GatewayRoute::GatewayRouteTarget', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppMesh::GatewayRoute::GrpcGatewayRouteMatch',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppMesh::GatewayRoute::GrpcGatewayRouteMatch',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppMesh::GatewayRoute::GrpcGatewayRouteMatch->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppMesh::GatewayRoute::GrpcGatewayRouteMatch {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ServiceName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppMesh::GatewayRoute::GrpcGatewayRouteAction',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppMesh::GatewayRoute::GrpcGatewayRouteAction',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppMesh::GatewayRoute::GrpcGatewayRouteAction->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppMesh::GatewayRoute::GrpcGatewayRouteAction {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Target => (isa => 'Cfn::Resource::Properties::AWS::AppMesh::GatewayRoute::GatewayRouteTarget', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppMesh::GatewayRoute::HttpGatewayRoute',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppMesh::GatewayRoute::HttpGatewayRoute',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppMesh::GatewayRoute::HttpGatewayRoute->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppMesh::GatewayRoute::HttpGatewayRoute {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Action => (isa => 'Cfn::Resource::Properties::AWS::AppMesh::GatewayRoute::HttpGatewayRouteAction', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Match => (isa => 'Cfn::Resource::Properties::AWS::AppMesh::GatewayRoute::HttpGatewayRouteMatch', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppMesh::GatewayRoute::GrpcGatewayRoute',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppMesh::GatewayRoute::GrpcGatewayRoute',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppMesh::GatewayRoute::GrpcGatewayRoute->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppMesh::GatewayRoute::GrpcGatewayRoute {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Action => (isa => 'Cfn::Resource::Properties::AWS::AppMesh::GatewayRoute::GrpcGatewayRouteAction', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Match => (isa => 'Cfn::Resource::Properties::AWS::AppMesh::GatewayRoute::GrpcGatewayRouteMatch', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppMesh::GatewayRoute::GatewayRouteSpec',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppMesh::GatewayRoute::GatewayRouteSpec',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppMesh::GatewayRoute::GatewayRouteSpec->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppMesh::GatewayRoute::GatewayRouteSpec {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has GrpcRoute => (isa => 'Cfn::Resource::Properties::AWS::AppMesh::GatewayRoute::GrpcGatewayRoute', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Http2Route => (isa => 'Cfn::Resource::Properties::AWS::AppMesh::GatewayRoute::HttpGatewayRoute', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has HttpRoute => (isa => 'Cfn::Resource::Properties::AWS::AppMesh::GatewayRoute::HttpGatewayRoute', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::AppMesh::GatewayRoute {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has GatewayRouteName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has MeshName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has MeshOwner => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Spec => (isa => 'Cfn::Resource::Properties::AWS::AppMesh::GatewayRoute::GatewayRouteSpec', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Tags => (isa => 'ArrayOfCfn::Resource::Properties::TagType', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has VirtualGatewayName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::AppMesh::GatewayRoute - Cfn resource for AWS::AppMesh::GatewayRoute

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::AppMesh::GatewayRoute.

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
