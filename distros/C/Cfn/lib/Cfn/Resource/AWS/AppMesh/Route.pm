# AWS::AppMesh::Route generated from spec 34.0.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::AppMesh::Route',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::AppMesh::Route->new( %$_ ) };

package Cfn::Resource::AWS::AppMesh::Route {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::AppMesh::Route', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [ 'Arn','MeshName','MeshOwner','ResourceOwner','RouteName','Uid','VirtualRouterName' ]
  }
  sub supported_regions {
    [ 'ap-northeast-1','ap-northeast-2','ap-south-1','ap-southeast-1','ap-southeast-2','ca-central-1','eu-central-1','eu-west-1','eu-west-2','us-east-1','us-east-2','us-west-1','us-west-2' ]
  }
}



subtype 'Cfn::Resource::Properties::AWS::AppMesh::Route::MatchRange',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppMesh::Route::MatchRange',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppMesh::Route::MatchRange->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppMesh::Route::MatchRange {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has End => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Start => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppMesh::Route::HeaderMatchMethod',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppMesh::Route::HeaderMatchMethod',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppMesh::Route::HeaderMatchMethod->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppMesh::Route::HeaderMatchMethod {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Exact => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Prefix => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Range => (isa => 'Cfn::Resource::Properties::AWS::AppMesh::Route::MatchRange', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Regex => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Suffix => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppMesh::Route::GrpcRouteMetadataMatchMethod',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppMesh::Route::GrpcRouteMetadataMatchMethod',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppMesh::Route::GrpcRouteMetadataMatchMethod->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppMesh::Route::GrpcRouteMetadataMatchMethod {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Exact => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Prefix => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Range => (isa => 'Cfn::Resource::Properties::AWS::AppMesh::Route::MatchRange', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Regex => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Suffix => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::AppMesh::Route::WeightedTarget',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::AppMesh::Route::WeightedTarget',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::AppMesh::Route::WeightedTarget')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::AppMesh::Route::WeightedTarget',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppMesh::Route::WeightedTarget',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppMesh::Route::WeightedTarget->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppMesh::Route::WeightedTarget {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has VirtualNode => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Weight => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::AppMesh::Route::HttpRouteHeader',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::AppMesh::Route::HttpRouteHeader',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::AppMesh::Route::HttpRouteHeader')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::AppMesh::Route::HttpRouteHeader',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppMesh::Route::HttpRouteHeader',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppMesh::Route::HttpRouteHeader->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppMesh::Route::HttpRouteHeader {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Invert => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Match => (isa => 'Cfn::Resource::Properties::AWS::AppMesh::Route::HeaderMatchMethod', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::AppMesh::Route::GrpcRouteMetadata',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::AppMesh::Route::GrpcRouteMetadata',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::AppMesh::Route::GrpcRouteMetadata')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::AppMesh::Route::GrpcRouteMetadata',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppMesh::Route::GrpcRouteMetadata',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppMesh::Route::GrpcRouteMetadata->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppMesh::Route::GrpcRouteMetadata {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Invert => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Match => (isa => 'Cfn::Resource::Properties::AWS::AppMesh::Route::GrpcRouteMetadataMatchMethod', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppMesh::Route::Duration',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppMesh::Route::Duration',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppMesh::Route::Duration->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppMesh::Route::Duration {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Unit => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Value => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppMesh::Route::TcpTimeout',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppMesh::Route::TcpTimeout',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppMesh::Route::TcpTimeout->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppMesh::Route::TcpTimeout {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Idle => (isa => 'Cfn::Resource::Properties::AWS::AppMesh::Route::Duration', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppMesh::Route::TcpRouteAction',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppMesh::Route::TcpRouteAction',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppMesh::Route::TcpRouteAction->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppMesh::Route::TcpRouteAction {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has WeightedTargets => (isa => 'ArrayOfCfn::Resource::Properties::AWS::AppMesh::Route::WeightedTarget', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppMesh::Route::HttpTimeout',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppMesh::Route::HttpTimeout',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppMesh::Route::HttpTimeout->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppMesh::Route::HttpTimeout {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Idle => (isa => 'Cfn::Resource::Properties::AWS::AppMesh::Route::Duration', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has PerRequest => (isa => 'Cfn::Resource::Properties::AWS::AppMesh::Route::Duration', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppMesh::Route::HttpRouteMatch',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppMesh::Route::HttpRouteMatch',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppMesh::Route::HttpRouteMatch->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppMesh::Route::HttpRouteMatch {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Headers => (isa => 'ArrayOfCfn::Resource::Properties::AWS::AppMesh::Route::HttpRouteHeader', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Method => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Prefix => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Scheme => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppMesh::Route::HttpRouteAction',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppMesh::Route::HttpRouteAction',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppMesh::Route::HttpRouteAction->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppMesh::Route::HttpRouteAction {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has WeightedTargets => (isa => 'ArrayOfCfn::Resource::Properties::AWS::AppMesh::Route::WeightedTarget', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppMesh::Route::HttpRetryPolicy',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppMesh::Route::HttpRetryPolicy',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppMesh::Route::HttpRetryPolicy->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppMesh::Route::HttpRetryPolicy {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has HttpRetryEvents => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has MaxRetries => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has PerRetryTimeout => (isa => 'Cfn::Resource::Properties::AWS::AppMesh::Route::Duration', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TcpRetryEvents => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppMesh::Route::GrpcTimeout',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppMesh::Route::GrpcTimeout',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppMesh::Route::GrpcTimeout->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppMesh::Route::GrpcTimeout {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Idle => (isa => 'Cfn::Resource::Properties::AWS::AppMesh::Route::Duration', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has PerRequest => (isa => 'Cfn::Resource::Properties::AWS::AppMesh::Route::Duration', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppMesh::Route::GrpcRouteMatch',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppMesh::Route::GrpcRouteMatch',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppMesh::Route::GrpcRouteMatch->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppMesh::Route::GrpcRouteMatch {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Metadata => (isa => 'ArrayOfCfn::Resource::Properties::AWS::AppMesh::Route::GrpcRouteMetadata', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has MethodName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ServiceName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppMesh::Route::GrpcRouteAction',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppMesh::Route::GrpcRouteAction',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppMesh::Route::GrpcRouteAction->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppMesh::Route::GrpcRouteAction {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has WeightedTargets => (isa => 'ArrayOfCfn::Resource::Properties::AWS::AppMesh::Route::WeightedTarget', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppMesh::Route::GrpcRetryPolicy',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppMesh::Route::GrpcRetryPolicy',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppMesh::Route::GrpcRetryPolicy->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppMesh::Route::GrpcRetryPolicy {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has GrpcRetryEvents => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has HttpRetryEvents => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has MaxRetries => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has PerRetryTimeout => (isa => 'Cfn::Resource::Properties::AWS::AppMesh::Route::Duration', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TcpRetryEvents => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppMesh::Route::TcpRoute',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppMesh::Route::TcpRoute',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppMesh::Route::TcpRoute->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppMesh::Route::TcpRoute {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Action => (isa => 'Cfn::Resource::Properties::AWS::AppMesh::Route::TcpRouteAction', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Timeout => (isa => 'Cfn::Resource::Properties::AWS::AppMesh::Route::TcpTimeout', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppMesh::Route::HttpRoute',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppMesh::Route::HttpRoute',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppMesh::Route::HttpRoute->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppMesh::Route::HttpRoute {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Action => (isa => 'Cfn::Resource::Properties::AWS::AppMesh::Route::HttpRouteAction', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Match => (isa => 'Cfn::Resource::Properties::AWS::AppMesh::Route::HttpRouteMatch', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RetryPolicy => (isa => 'Cfn::Resource::Properties::AWS::AppMesh::Route::HttpRetryPolicy', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Timeout => (isa => 'Cfn::Resource::Properties::AWS::AppMesh::Route::HttpTimeout', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppMesh::Route::GrpcRoute',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppMesh::Route::GrpcRoute',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppMesh::Route::GrpcRoute->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppMesh::Route::GrpcRoute {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Action => (isa => 'Cfn::Resource::Properties::AWS::AppMesh::Route::GrpcRouteAction', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Match => (isa => 'Cfn::Resource::Properties::AWS::AppMesh::Route::GrpcRouteMatch', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RetryPolicy => (isa => 'Cfn::Resource::Properties::AWS::AppMesh::Route::GrpcRetryPolicy', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Timeout => (isa => 'Cfn::Resource::Properties::AWS::AppMesh::Route::GrpcTimeout', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppMesh::Route::RouteSpec',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppMesh::Route::RouteSpec',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppMesh::Route::RouteSpec->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppMesh::Route::RouteSpec {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has GrpcRoute => (isa => 'Cfn::Resource::Properties::AWS::AppMesh::Route::GrpcRoute', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Http2Route => (isa => 'Cfn::Resource::Properties::AWS::AppMesh::Route::HttpRoute', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has HttpRoute => (isa => 'Cfn::Resource::Properties::AWS::AppMesh::Route::HttpRoute', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Priority => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TcpRoute => (isa => 'Cfn::Resource::Properties::AWS::AppMesh::Route::TcpRoute', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::AppMesh::Route {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has MeshName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has MeshOwner => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has RouteName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Spec => (isa => 'Cfn::Resource::Properties::AWS::AppMesh::Route::RouteSpec', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Tags => (isa => 'ArrayOfCfn::Resource::Properties::TagType', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has VirtualRouterName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::AppMesh::Route - Cfn resource for AWS::AppMesh::Route

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::AppMesh::Route.

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
