# AWS::EC2::ClientVpnEndpoint generated from spec 21.0.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::EC2::ClientVpnEndpoint',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::EC2::ClientVpnEndpoint->new( %$_ ) };

package Cfn::Resource::AWS::EC2::ClientVpnEndpoint {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::EC2::ClientVpnEndpoint', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [  ]
  }
  sub supported_regions {
    [ 'ap-northeast-1','ap-northeast-2','ap-south-1','ap-southeast-1','ap-southeast-2','ca-central-1','eu-central-1','eu-north-1','eu-west-1','eu-west-2','sa-east-1','us-east-1','us-east-2','us-west-1','us-west-2' ]
  }
}



subtype 'Cfn::Resource::Properties::AWS::EC2::ClientVpnEndpoint::FederatedAuthenticationRequest',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::EC2::ClientVpnEndpoint::FederatedAuthenticationRequest',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::EC2::ClientVpnEndpoint::FederatedAuthenticationRequest->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::EC2::ClientVpnEndpoint::FederatedAuthenticationRequest {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has SAMLProviderArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SelfServiceSAMLProviderArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::EC2::ClientVpnEndpoint::DirectoryServiceAuthenticationRequest',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::EC2::ClientVpnEndpoint::DirectoryServiceAuthenticationRequest',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::EC2::ClientVpnEndpoint::DirectoryServiceAuthenticationRequest->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::EC2::ClientVpnEndpoint::DirectoryServiceAuthenticationRequest {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has DirectoryId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::EC2::ClientVpnEndpoint::CertificateAuthenticationRequest',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::EC2::ClientVpnEndpoint::CertificateAuthenticationRequest',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::EC2::ClientVpnEndpoint::CertificateAuthenticationRequest->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::EC2::ClientVpnEndpoint::CertificateAuthenticationRequest {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ClientRootCertificateChainArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::EC2::ClientVpnEndpoint::TagSpecification',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::EC2::ClientVpnEndpoint::TagSpecification',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::EC2::ClientVpnEndpoint::TagSpecification')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::EC2::ClientVpnEndpoint::TagSpecification',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::EC2::ClientVpnEndpoint::TagSpecification',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::EC2::ClientVpnEndpoint::TagSpecification->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::EC2::ClientVpnEndpoint::TagSpecification {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ResourceType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Tags => (isa => 'ArrayOfCfn::Resource::Properties::TagType', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::EC2::ClientVpnEndpoint::ConnectionLogOptions',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::EC2::ClientVpnEndpoint::ConnectionLogOptions',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::EC2::ClientVpnEndpoint::ConnectionLogOptions->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::EC2::ClientVpnEndpoint::ConnectionLogOptions {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has CloudwatchLogGroup => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has CloudwatchLogStream => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Enabled => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::EC2::ClientVpnEndpoint::ClientConnectOptions',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::EC2::ClientVpnEndpoint::ClientConnectOptions',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::EC2::ClientVpnEndpoint::ClientConnectOptions->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::EC2::ClientVpnEndpoint::ClientConnectOptions {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Enabled => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has LambdaFunctionArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::EC2::ClientVpnEndpoint::ClientAuthenticationRequest',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::EC2::ClientVpnEndpoint::ClientAuthenticationRequest',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::EC2::ClientVpnEndpoint::ClientAuthenticationRequest')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::EC2::ClientVpnEndpoint::ClientAuthenticationRequest',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::EC2::ClientVpnEndpoint::ClientAuthenticationRequest',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::EC2::ClientVpnEndpoint::ClientAuthenticationRequest->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::EC2::ClientVpnEndpoint::ClientAuthenticationRequest {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ActiveDirectory => (isa => 'Cfn::Resource::Properties::AWS::EC2::ClientVpnEndpoint::DirectoryServiceAuthenticationRequest', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has FederatedAuthentication => (isa => 'Cfn::Resource::Properties::AWS::EC2::ClientVpnEndpoint::FederatedAuthenticationRequest', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has MutualAuthentication => (isa => 'Cfn::Resource::Properties::AWS::EC2::ClientVpnEndpoint::CertificateAuthenticationRequest', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Type => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::EC2::ClientVpnEndpoint {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has AuthenticationOptions => (isa => 'ArrayOfCfn::Resource::Properties::AWS::EC2::ClientVpnEndpoint::ClientAuthenticationRequest', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has ClientCidrBlock => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has ClientConnectOptions => (isa => 'Cfn::Resource::Properties::AWS::EC2::ClientVpnEndpoint::ClientConnectOptions', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ConnectionLogOptions => (isa => 'Cfn::Resource::Properties::AWS::EC2::ClientVpnEndpoint::ConnectionLogOptions', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Description => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DnsServers => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SecurityGroupIds => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SelfServicePortal => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ServerCertificateArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SplitTunnel => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TagSpecifications => (isa => 'ArrayOfCfn::Resource::Properties::AWS::EC2::ClientVpnEndpoint::TagSpecification', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has TransportProtocol => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has VpcId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has VpnPort => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::EC2::ClientVpnEndpoint - Cfn resource for AWS::EC2::ClientVpnEndpoint

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::EC2::ClientVpnEndpoint.

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
