# AWS::S3Outposts::Endpoint generated from spec 34.0.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::S3Outposts::Endpoint',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::S3Outposts::Endpoint->new( %$_ ) };

package Cfn::Resource::AWS::S3Outposts::Endpoint {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::S3Outposts::Endpoint', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [ 'Arn','CidrBlock','CreationTime','Id','NetworkInterfaces','Status' ]
  }
  sub supported_regions {
    [ 'af-south-1','ap-east-1','ap-northeast-1','ap-northeast-2','ap-south-1','ap-southeast-1','ap-southeast-2','ca-central-1','eu-central-1','eu-north-1','eu-south-1','eu-west-1','eu-west-2','eu-west-3','me-south-1','sa-east-1','us-east-1','us-east-2','us-west-1','us-west-2' ]
  }
}



subtype 'Cfn::Resource::Properties::AWS::S3Outposts::Endpoint::NetworkInterface',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::S3Outposts::Endpoint::NetworkInterface',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::S3Outposts::Endpoint::NetworkInterface->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::S3Outposts::Endpoint::NetworkInterface {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has NetworkInterfaceId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::S3Outposts::Endpoint {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has OutpostId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has SecurityGroupId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has SubnetId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::S3Outposts::Endpoint - Cfn resource for AWS::S3Outposts::Endpoint

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::S3Outposts::Endpoint.

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
