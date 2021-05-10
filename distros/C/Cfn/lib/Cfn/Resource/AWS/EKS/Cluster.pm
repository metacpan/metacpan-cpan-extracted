# AWS::EKS::Cluster generated from spec 34.0.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::EKS::Cluster',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::EKS::Cluster->new( %$_ ) };

package Cfn::Resource::AWS::EKS::Cluster {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::EKS::Cluster', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [ 'Arn','CertificateAuthorityData','ClusterSecurityGroupId','EncryptionConfigKeyArn','Endpoint' ]
  }
  sub supported_regions {
    [ 'af-south-1','ap-east-1','ap-northeast-1','ap-northeast-2','ap-northeast-3','ap-south-1','ap-southeast-1','ap-southeast-2','ca-central-1','cn-north-1','cn-northwest-1','eu-central-1','eu-north-1','eu-south-1','eu-west-1','eu-west-2','eu-west-3','me-south-1','sa-east-1','us-east-1','us-east-2','us-gov-east-1','us-gov-west-1','us-west-1','us-west-2' ]
  }
}



subtype 'Cfn::Resource::Properties::AWS::EKS::Cluster::Provider',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::EKS::Cluster::Provider',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::EKS::Cluster::Provider->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::EKS::Cluster::Provider {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has KeyArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::EKS::Cluster::ResourcesVpcConfig',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::EKS::Cluster::ResourcesVpcConfig',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::EKS::Cluster::ResourcesVpcConfig->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::EKS::Cluster::ResourcesVpcConfig {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has SecurityGroupIds => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SubnetIds => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::EKS::Cluster::KubernetesNetworkConfig',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::EKS::Cluster::KubernetesNetworkConfig',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::EKS::Cluster::KubernetesNetworkConfig->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::EKS::Cluster::KubernetesNetworkConfig {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ServiceIpv4Cidr => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::EKS::Cluster::EncryptionConfig',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::EKS::Cluster::EncryptionConfig',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::EKS::Cluster::EncryptionConfig')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::EKS::Cluster::EncryptionConfig',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::EKS::Cluster::EncryptionConfig',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::EKS::Cluster::EncryptionConfig->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::EKS::Cluster::EncryptionConfig {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Provider => (isa => 'Cfn::Resource::Properties::AWS::EKS::Cluster::Provider', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Resources => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::EKS::Cluster {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has EncryptionConfig => (isa => 'ArrayOfCfn::Resource::Properties::AWS::EKS::Cluster::EncryptionConfig', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has KubernetesNetworkConfig => (isa => 'Cfn::Resource::Properties::AWS::EKS::Cluster::KubernetesNetworkConfig', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has ResourcesVpcConfig => (isa => 'Cfn::Resource::Properties::AWS::EKS::Cluster::ResourcesVpcConfig', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has RoleArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Version => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::EKS::Cluster - Cfn resource for AWS::EKS::Cluster

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::EKS::Cluster.

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
