# AWS::EKS::Cluster generated from spec 2.4.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::EKS::Cluster',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::EKS::Cluster->new( %$_ ) };

package Cfn::Resource::AWS::EKS::Cluster {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::EKS::Cluster', is => 'rw', coerce => 1);
  sub _build_attributes {
    [ 'Arn','CertificateAuthorityData','Endpoint' ]
  }
}



subtype 'Cfn::Resource::Properties::AWS::EKS::Cluster::ResourcesVpcConfig',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::EKS::Cluster::ResourcesVpcConfig',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::EKS::Cluster::ResourcesVpcConfigValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::EKS::Cluster::ResourcesVpcConfigValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has SecurityGroupIds => (isa => 'Cfn::Value::Array|Cfn::Value::Function', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SubnetIds => (isa => 'Cfn::Value::Array|Cfn::Value::Function', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::EKS::Cluster {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has ResourcesVpcConfig => (isa => 'Cfn::Resource::Properties::AWS::EKS::Cluster::ResourcesVpcConfig', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has RoleArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Version => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

1;
