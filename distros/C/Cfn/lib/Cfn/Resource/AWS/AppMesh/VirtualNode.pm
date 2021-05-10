# AWS::AppMesh::VirtualNode generated from spec 34.0.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::AppMesh::VirtualNode',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::AppMesh::VirtualNode->new( %$_ ) };

package Cfn::Resource::AWS::AppMesh::VirtualNode {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::AppMesh::VirtualNode', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [ 'Arn','MeshName','MeshOwner','ResourceOwner','Uid','VirtualNodeName' ]
  }
  sub supported_regions {
    [ 'ap-northeast-1','ap-northeast-2','ap-south-1','ap-southeast-1','ap-southeast-2','ca-central-1','eu-central-1','eu-west-1','eu-west-2','us-east-1','us-east-2','us-west-1','us-west-2' ]
  }
}



subtype 'Cfn::Resource::Properties::AWS::AppMesh::VirtualNode::TlsValidationContextSdsTrust',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppMesh::VirtualNode::TlsValidationContextSdsTrust',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppMesh::VirtualNode::TlsValidationContextSdsTrust->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppMesh::VirtualNode::TlsValidationContextSdsTrust {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has SecretName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppMesh::VirtualNode::TlsValidationContextFileTrust',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppMesh::VirtualNode::TlsValidationContextFileTrust',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppMesh::VirtualNode::TlsValidationContextFileTrust->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppMesh::VirtualNode::TlsValidationContextFileTrust {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has CertificateChain => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppMesh::VirtualNode::TlsValidationContextAcmTrust',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppMesh::VirtualNode::TlsValidationContextAcmTrust',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppMesh::VirtualNode::TlsValidationContextAcmTrust->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppMesh::VirtualNode::TlsValidationContextAcmTrust {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has CertificateAuthorityArns => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppMesh::VirtualNode::SubjectAlternativeNameMatchers',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppMesh::VirtualNode::SubjectAlternativeNameMatchers',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppMesh::VirtualNode::SubjectAlternativeNameMatchers->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppMesh::VirtualNode::SubjectAlternativeNameMatchers {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Exact => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppMesh::VirtualNode::TlsValidationContextTrust',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppMesh::VirtualNode::TlsValidationContextTrust',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppMesh::VirtualNode::TlsValidationContextTrust->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppMesh::VirtualNode::TlsValidationContextTrust {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ACM => (isa => 'Cfn::Resource::Properties::AWS::AppMesh::VirtualNode::TlsValidationContextAcmTrust', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has File => (isa => 'Cfn::Resource::Properties::AWS::AppMesh::VirtualNode::TlsValidationContextFileTrust', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SDS => (isa => 'Cfn::Resource::Properties::AWS::AppMesh::VirtualNode::TlsValidationContextSdsTrust', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppMesh::VirtualNode::SubjectAlternativeNames',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppMesh::VirtualNode::SubjectAlternativeNames',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppMesh::VirtualNode::SubjectAlternativeNames->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppMesh::VirtualNode::SubjectAlternativeNames {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Match => (isa => 'Cfn::Resource::Properties::AWS::AppMesh::VirtualNode::SubjectAlternativeNameMatchers', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppMesh::VirtualNode::ListenerTlsSdsCertificate',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppMesh::VirtualNode::ListenerTlsSdsCertificate',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppMesh::VirtualNode::ListenerTlsSdsCertificate->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppMesh::VirtualNode::ListenerTlsSdsCertificate {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has SecretName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppMesh::VirtualNode::ListenerTlsFileCertificate',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppMesh::VirtualNode::ListenerTlsFileCertificate',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppMesh::VirtualNode::ListenerTlsFileCertificate->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppMesh::VirtualNode::ListenerTlsFileCertificate {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has CertificateChain => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has PrivateKey => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppMesh::VirtualNode::TlsValidationContext',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppMesh::VirtualNode::TlsValidationContext',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppMesh::VirtualNode::TlsValidationContext->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppMesh::VirtualNode::TlsValidationContext {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has SubjectAlternativeNames => (isa => 'Cfn::Resource::Properties::AWS::AppMesh::VirtualNode::SubjectAlternativeNames', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Trust => (isa => 'Cfn::Resource::Properties::AWS::AppMesh::VirtualNode::TlsValidationContextTrust', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppMesh::VirtualNode::ClientTlsCertificate',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppMesh::VirtualNode::ClientTlsCertificate',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppMesh::VirtualNode::ClientTlsCertificate->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppMesh::VirtualNode::ClientTlsCertificate {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has File => (isa => 'Cfn::Resource::Properties::AWS::AppMesh::VirtualNode::ListenerTlsFileCertificate', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SDS => (isa => 'Cfn::Resource::Properties::AWS::AppMesh::VirtualNode::ListenerTlsSdsCertificate', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppMesh::VirtualNode::ListenerTlsValidationContextTrust',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppMesh::VirtualNode::ListenerTlsValidationContextTrust',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppMesh::VirtualNode::ListenerTlsValidationContextTrust->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppMesh::VirtualNode::ListenerTlsValidationContextTrust {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has File => (isa => 'Cfn::Resource::Properties::AWS::AppMesh::VirtualNode::TlsValidationContextFileTrust', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SDS => (isa => 'Cfn::Resource::Properties::AWS::AppMesh::VirtualNode::TlsValidationContextSdsTrust', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppMesh::VirtualNode::ListenerTlsAcmCertificate',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppMesh::VirtualNode::ListenerTlsAcmCertificate',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppMesh::VirtualNode::ListenerTlsAcmCertificate->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppMesh::VirtualNode::ListenerTlsAcmCertificate {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has CertificateArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppMesh::VirtualNode::Duration',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppMesh::VirtualNode::Duration',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppMesh::VirtualNode::Duration->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppMesh::VirtualNode::Duration {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Unit => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Value => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppMesh::VirtualNode::ClientPolicyTls',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppMesh::VirtualNode::ClientPolicyTls',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppMesh::VirtualNode::ClientPolicyTls->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppMesh::VirtualNode::ClientPolicyTls {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Certificate => (isa => 'Cfn::Resource::Properties::AWS::AppMesh::VirtualNode::ClientTlsCertificate', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Enforce => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Ports => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Validation => (isa => 'Cfn::Resource::Properties::AWS::AppMesh::VirtualNode::TlsValidationContext', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppMesh::VirtualNode::VirtualNodeTcpConnectionPool',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppMesh::VirtualNode::VirtualNodeTcpConnectionPool',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppMesh::VirtualNode::VirtualNodeTcpConnectionPool->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppMesh::VirtualNode::VirtualNodeTcpConnectionPool {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has MaxConnections => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppMesh::VirtualNode::VirtualNodeHttpConnectionPool',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppMesh::VirtualNode::VirtualNodeHttpConnectionPool',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppMesh::VirtualNode::VirtualNodeHttpConnectionPool->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppMesh::VirtualNode::VirtualNodeHttpConnectionPool {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has MaxConnections => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has MaxPendingRequests => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppMesh::VirtualNode::VirtualNodeHttp2ConnectionPool',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppMesh::VirtualNode::VirtualNodeHttp2ConnectionPool',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppMesh::VirtualNode::VirtualNodeHttp2ConnectionPool->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppMesh::VirtualNode::VirtualNodeHttp2ConnectionPool {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has MaxRequests => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppMesh::VirtualNode::VirtualNodeGrpcConnectionPool',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppMesh::VirtualNode::VirtualNodeGrpcConnectionPool',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppMesh::VirtualNode::VirtualNodeGrpcConnectionPool->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppMesh::VirtualNode::VirtualNodeGrpcConnectionPool {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has MaxRequests => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppMesh::VirtualNode::TcpTimeout',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppMesh::VirtualNode::TcpTimeout',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppMesh::VirtualNode::TcpTimeout->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppMesh::VirtualNode::TcpTimeout {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Idle => (isa => 'Cfn::Resource::Properties::AWS::AppMesh::VirtualNode::Duration', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppMesh::VirtualNode::ListenerTlsValidationContext',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppMesh::VirtualNode::ListenerTlsValidationContext',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppMesh::VirtualNode::ListenerTlsValidationContext->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppMesh::VirtualNode::ListenerTlsValidationContext {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has SubjectAlternativeNames => (isa => 'Cfn::Resource::Properties::AWS::AppMesh::VirtualNode::SubjectAlternativeNames', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Trust => (isa => 'Cfn::Resource::Properties::AWS::AppMesh::VirtualNode::ListenerTlsValidationContextTrust', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppMesh::VirtualNode::ListenerTlsCertificate',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppMesh::VirtualNode::ListenerTlsCertificate',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppMesh::VirtualNode::ListenerTlsCertificate->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppMesh::VirtualNode::ListenerTlsCertificate {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ACM => (isa => 'Cfn::Resource::Properties::AWS::AppMesh::VirtualNode::ListenerTlsAcmCertificate', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has File => (isa => 'Cfn::Resource::Properties::AWS::AppMesh::VirtualNode::ListenerTlsFileCertificate', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SDS => (isa => 'Cfn::Resource::Properties::AWS::AppMesh::VirtualNode::ListenerTlsSdsCertificate', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppMesh::VirtualNode::HttpTimeout',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppMesh::VirtualNode::HttpTimeout',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppMesh::VirtualNode::HttpTimeout->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppMesh::VirtualNode::HttpTimeout {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Idle => (isa => 'Cfn::Resource::Properties::AWS::AppMesh::VirtualNode::Duration', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has PerRequest => (isa => 'Cfn::Resource::Properties::AWS::AppMesh::VirtualNode::Duration', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppMesh::VirtualNode::GrpcTimeout',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppMesh::VirtualNode::GrpcTimeout',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppMesh::VirtualNode::GrpcTimeout->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppMesh::VirtualNode::GrpcTimeout {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Idle => (isa => 'Cfn::Resource::Properties::AWS::AppMesh::VirtualNode::Duration', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has PerRequest => (isa => 'Cfn::Resource::Properties::AWS::AppMesh::VirtualNode::Duration', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppMesh::VirtualNode::FileAccessLog',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppMesh::VirtualNode::FileAccessLog',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppMesh::VirtualNode::FileAccessLog->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppMesh::VirtualNode::FileAccessLog {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Path => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppMesh::VirtualNode::ClientPolicy',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppMesh::VirtualNode::ClientPolicy',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppMesh::VirtualNode::ClientPolicy->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppMesh::VirtualNode::ClientPolicy {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has TLS => (isa => 'Cfn::Resource::Properties::AWS::AppMesh::VirtualNode::ClientPolicyTls', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::AppMesh::VirtualNode::AwsCloudMapInstanceAttribute',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::AppMesh::VirtualNode::AwsCloudMapInstanceAttribute',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::AppMesh::VirtualNode::AwsCloudMapInstanceAttribute')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::AppMesh::VirtualNode::AwsCloudMapInstanceAttribute',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppMesh::VirtualNode::AwsCloudMapInstanceAttribute',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppMesh::VirtualNode::AwsCloudMapInstanceAttribute->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppMesh::VirtualNode::AwsCloudMapInstanceAttribute {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Key => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Value => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppMesh::VirtualNode::VirtualServiceBackend',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppMesh::VirtualNode::VirtualServiceBackend',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppMesh::VirtualNode::VirtualServiceBackend->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppMesh::VirtualNode::VirtualServiceBackend {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ClientPolicy => (isa => 'Cfn::Resource::Properties::AWS::AppMesh::VirtualNode::ClientPolicy', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has VirtualServiceName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppMesh::VirtualNode::VirtualNodeConnectionPool',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppMesh::VirtualNode::VirtualNodeConnectionPool',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppMesh::VirtualNode::VirtualNodeConnectionPool->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppMesh::VirtualNode::VirtualNodeConnectionPool {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has GRPC => (isa => 'Cfn::Resource::Properties::AWS::AppMesh::VirtualNode::VirtualNodeGrpcConnectionPool', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has HTTP => (isa => 'Cfn::Resource::Properties::AWS::AppMesh::VirtualNode::VirtualNodeHttpConnectionPool', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has HTTP2 => (isa => 'Cfn::Resource::Properties::AWS::AppMesh::VirtualNode::VirtualNodeHttp2ConnectionPool', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TCP => (isa => 'Cfn::Resource::Properties::AWS::AppMesh::VirtualNode::VirtualNodeTcpConnectionPool', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppMesh::VirtualNode::PortMapping',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppMesh::VirtualNode::PortMapping',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppMesh::VirtualNode::PortMapping->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppMesh::VirtualNode::PortMapping {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Port => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Protocol => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppMesh::VirtualNode::OutlierDetection',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppMesh::VirtualNode::OutlierDetection',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppMesh::VirtualNode::OutlierDetection->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppMesh::VirtualNode::OutlierDetection {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has BaseEjectionDuration => (isa => 'Cfn::Resource::Properties::AWS::AppMesh::VirtualNode::Duration', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Interval => (isa => 'Cfn::Resource::Properties::AWS::AppMesh::VirtualNode::Duration', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has MaxEjectionPercent => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has MaxServerErrors => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppMesh::VirtualNode::ListenerTls',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppMesh::VirtualNode::ListenerTls',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppMesh::VirtualNode::ListenerTls->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppMesh::VirtualNode::ListenerTls {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Certificate => (isa => 'Cfn::Resource::Properties::AWS::AppMesh::VirtualNode::ListenerTlsCertificate', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Mode => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Validation => (isa => 'Cfn::Resource::Properties::AWS::AppMesh::VirtualNode::ListenerTlsValidationContext', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppMesh::VirtualNode::ListenerTimeout',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppMesh::VirtualNode::ListenerTimeout',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppMesh::VirtualNode::ListenerTimeout->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppMesh::VirtualNode::ListenerTimeout {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has GRPC => (isa => 'Cfn::Resource::Properties::AWS::AppMesh::VirtualNode::GrpcTimeout', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has HTTP => (isa => 'Cfn::Resource::Properties::AWS::AppMesh::VirtualNode::HttpTimeout', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has HTTP2 => (isa => 'Cfn::Resource::Properties::AWS::AppMesh::VirtualNode::HttpTimeout', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TCP => (isa => 'Cfn::Resource::Properties::AWS::AppMesh::VirtualNode::TcpTimeout', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppMesh::VirtualNode::HealthCheck',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppMesh::VirtualNode::HealthCheck',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppMesh::VirtualNode::HealthCheck->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppMesh::VirtualNode::HealthCheck {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has HealthyThreshold => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has IntervalMillis => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Path => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Port => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Protocol => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TimeoutMillis => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has UnhealthyThreshold => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppMesh::VirtualNode::DnsServiceDiscovery',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppMesh::VirtualNode::DnsServiceDiscovery',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppMesh::VirtualNode::DnsServiceDiscovery->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppMesh::VirtualNode::DnsServiceDiscovery {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Hostname => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppMesh::VirtualNode::AwsCloudMapServiceDiscovery',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppMesh::VirtualNode::AwsCloudMapServiceDiscovery',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppMesh::VirtualNode::AwsCloudMapServiceDiscovery->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppMesh::VirtualNode::AwsCloudMapServiceDiscovery {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Attributes => (isa => 'ArrayOfCfn::Resource::Properties::AWS::AppMesh::VirtualNode::AwsCloudMapInstanceAttribute', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has NamespaceName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ServiceName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppMesh::VirtualNode::AccessLog',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppMesh::VirtualNode::AccessLog',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppMesh::VirtualNode::AccessLog->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppMesh::VirtualNode::AccessLog {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has File => (isa => 'Cfn::Resource::Properties::AWS::AppMesh::VirtualNode::FileAccessLog', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppMesh::VirtualNode::ServiceDiscovery',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppMesh::VirtualNode::ServiceDiscovery',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppMesh::VirtualNode::ServiceDiscovery->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppMesh::VirtualNode::ServiceDiscovery {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AWSCloudMap => (isa => 'Cfn::Resource::Properties::AWS::AppMesh::VirtualNode::AwsCloudMapServiceDiscovery', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DNS => (isa => 'Cfn::Resource::Properties::AWS::AppMesh::VirtualNode::DnsServiceDiscovery', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppMesh::VirtualNode::Logging',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppMesh::VirtualNode::Logging',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppMesh::VirtualNode::Logging->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppMesh::VirtualNode::Logging {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AccessLog => (isa => 'Cfn::Resource::Properties::AWS::AppMesh::VirtualNode::AccessLog', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::AppMesh::VirtualNode::Listener',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::AppMesh::VirtualNode::Listener',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::AppMesh::VirtualNode::Listener')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::AppMesh::VirtualNode::Listener',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppMesh::VirtualNode::Listener',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppMesh::VirtualNode::Listener->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppMesh::VirtualNode::Listener {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ConnectionPool => (isa => 'Cfn::Resource::Properties::AWS::AppMesh::VirtualNode::VirtualNodeConnectionPool', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has HealthCheck => (isa => 'Cfn::Resource::Properties::AWS::AppMesh::VirtualNode::HealthCheck', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has OutlierDetection => (isa => 'Cfn::Resource::Properties::AWS::AppMesh::VirtualNode::OutlierDetection', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has PortMapping => (isa => 'Cfn::Resource::Properties::AWS::AppMesh::VirtualNode::PortMapping', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Timeout => (isa => 'Cfn::Resource::Properties::AWS::AppMesh::VirtualNode::ListenerTimeout', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TLS => (isa => 'Cfn::Resource::Properties::AWS::AppMesh::VirtualNode::ListenerTls', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppMesh::VirtualNode::BackendDefaults',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppMesh::VirtualNode::BackendDefaults',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppMesh::VirtualNode::BackendDefaults->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppMesh::VirtualNode::BackendDefaults {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ClientPolicy => (isa => 'Cfn::Resource::Properties::AWS::AppMesh::VirtualNode::ClientPolicy', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::AppMesh::VirtualNode::Backend',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::AppMesh::VirtualNode::Backend',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::AppMesh::VirtualNode::Backend')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::AppMesh::VirtualNode::Backend',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppMesh::VirtualNode::Backend',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppMesh::VirtualNode::Backend->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppMesh::VirtualNode::Backend {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has VirtualService => (isa => 'Cfn::Resource::Properties::AWS::AppMesh::VirtualNode::VirtualServiceBackend', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppMesh::VirtualNode::VirtualNodeSpec',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppMesh::VirtualNode::VirtualNodeSpec',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppMesh::VirtualNode::VirtualNodeSpec->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppMesh::VirtualNode::VirtualNodeSpec {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has BackendDefaults => (isa => 'Cfn::Resource::Properties::AWS::AppMesh::VirtualNode::BackendDefaults', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Backends => (isa => 'ArrayOfCfn::Resource::Properties::AWS::AppMesh::VirtualNode::Backend', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Listeners => (isa => 'ArrayOfCfn::Resource::Properties::AWS::AppMesh::VirtualNode::Listener', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Logging => (isa => 'Cfn::Resource::Properties::AWS::AppMesh::VirtualNode::Logging', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ServiceDiscovery => (isa => 'Cfn::Resource::Properties::AWS::AppMesh::VirtualNode::ServiceDiscovery', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::AppMesh::VirtualNode {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has MeshName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has MeshOwner => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Spec => (isa => 'Cfn::Resource::Properties::AWS::AppMesh::VirtualNode::VirtualNodeSpec', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Tags => (isa => 'ArrayOfCfn::Resource::Properties::TagType', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has VirtualNodeName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::AppMesh::VirtualNode - Cfn resource for AWS::AppMesh::VirtualNode

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::AppMesh::VirtualNode.

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
