# AWS::DataSync::LocationNFS generated from spec 34.0.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::DataSync::LocationNFS',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::DataSync::LocationNFS->new( %$_ ) };

package Cfn::Resource::AWS::DataSync::LocationNFS {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::DataSync::LocationNFS', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [ 'LocationArn','LocationUri' ]
  }
  sub supported_regions {
    [ 'af-south-1','ap-east-1','ap-northeast-1','ap-northeast-2','ap-south-1','ap-southeast-1','ap-southeast-2','ca-central-1','eu-central-1','eu-north-1','eu-south-1','eu-west-1','eu-west-2','eu-west-3','me-south-1','sa-east-1','us-east-1','us-east-2','us-gov-east-1','us-gov-west-1','us-west-1','us-west-2' ]
  }
}



subtype 'Cfn::Resource::Properties::AWS::DataSync::LocationNFS::OnPremConfig',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::DataSync::LocationNFS::OnPremConfig',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::DataSync::LocationNFS::OnPremConfig->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::DataSync::LocationNFS::OnPremConfig {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AgentArns => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

subtype 'Cfn::Resource::Properties::AWS::DataSync::LocationNFS::MountOptions',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::DataSync::LocationNFS::MountOptions',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::DataSync::LocationNFS::MountOptions->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::DataSync::LocationNFS::MountOptions {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Version => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

package Cfn::Resource::Properties::AWS::DataSync::LocationNFS {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has MountOptions => (isa => 'Cfn::Resource::Properties::AWS::DataSync::LocationNFS::MountOptions', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has OnPremConfig => (isa => 'Cfn::Resource::Properties::AWS::DataSync::LocationNFS::OnPremConfig', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has ServerHostname => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Subdirectory => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Tags => (isa => 'ArrayOfCfn::Resource::Properties::TagType', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::DataSync::LocationNFS - Cfn resource for AWS::DataSync::LocationNFS

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::DataSync::LocationNFS.

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
