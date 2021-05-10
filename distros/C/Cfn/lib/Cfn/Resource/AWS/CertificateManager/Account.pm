# AWS::CertificateManager::Account generated from spec 34.0.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::CertificateManager::Account',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::CertificateManager::Account->new( %$_ ) };

package Cfn::Resource::AWS::CertificateManager::Account {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::CertificateManager::Account', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [ 'AccountId' ]
  }
  sub supported_regions {
    [ 'af-south-1','ap-east-1','ap-northeast-1','ap-northeast-2','ap-northeast-3','ap-south-1','ap-southeast-1','ap-southeast-2','ca-central-1','cn-north-1','cn-northwest-1','eu-central-1','eu-north-1','eu-south-1','eu-west-1','eu-west-2','eu-west-3','me-south-1','sa-east-1','us-east-1','us-east-2','us-gov-east-1','us-gov-west-1','us-west-1','us-west-2' ]
  }
}



subtype 'Cfn::Resource::Properties::AWS::CertificateManager::Account::ExpiryEventsConfiguration',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::CertificateManager::Account::ExpiryEventsConfiguration',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::CertificateManager::Account::ExpiryEventsConfiguration->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::CertificateManager::Account::ExpiryEventsConfiguration {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has DaysBeforeExpiry => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::CertificateManager::Account {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has ExpiryEventsConfiguration => (isa => 'Cfn::Resource::Properties::AWS::CertificateManager::Account::ExpiryEventsConfiguration', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::CertificateManager::Account - Cfn resource for AWS::CertificateManager::Account

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::CertificateManager::Account.

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
