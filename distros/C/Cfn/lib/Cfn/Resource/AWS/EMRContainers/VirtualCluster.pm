# AWS::EMRContainers::VirtualCluster generated from spec 34.0.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::EMRContainers::VirtualCluster',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::EMRContainers::VirtualCluster->new( %$_ ) };

package Cfn::Resource::AWS::EMRContainers::VirtualCluster {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::EMRContainers::VirtualCluster', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [ 'Arn','Id' ]
  }
  sub supported_regions {
    [ 'ap-northeast-1','ap-northeast-2','ap-south-1','ap-southeast-1','ap-southeast-2','ca-central-1','eu-central-1','eu-west-1','eu-west-2','us-east-1','us-east-2','us-west-1','us-west-2' ]
  }
}



subtype 'Cfn::Resource::Properties::AWS::EMRContainers::VirtualCluster::EksInfo',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::EMRContainers::VirtualCluster::EksInfo',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::EMRContainers::VirtualCluster::EksInfo->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::EMRContainers::VirtualCluster::EksInfo {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Namespace => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

subtype 'Cfn::Resource::Properties::AWS::EMRContainers::VirtualCluster::ContainerInfo',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::EMRContainers::VirtualCluster::ContainerInfo',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::EMRContainers::VirtualCluster::ContainerInfo->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::EMRContainers::VirtualCluster::ContainerInfo {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has EksInfo => (isa => 'Cfn::Resource::Properties::AWS::EMRContainers::VirtualCluster::EksInfo', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

subtype 'Cfn::Resource::Properties::AWS::EMRContainers::VirtualCluster::ContainerProvider',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::EMRContainers::VirtualCluster::ContainerProvider',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::EMRContainers::VirtualCluster::ContainerProvider->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::EMRContainers::VirtualCluster::ContainerProvider {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Id => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Info => (isa => 'Cfn::Resource::Properties::AWS::EMRContainers::VirtualCluster::ContainerInfo', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Type => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

package Cfn::Resource::Properties::AWS::EMRContainers::VirtualCluster {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has ContainerProvider => (isa => 'Cfn::Resource::Properties::AWS::EMRContainers::VirtualCluster::ContainerProvider', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Tags => (isa => 'ArrayOfCfn::Resource::Properties::TagType', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::EMRContainers::VirtualCluster - Cfn resource for AWS::EMRContainers::VirtualCluster

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::EMRContainers::VirtualCluster.

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
