# AWS::ACMPCA::CertificateAuthority generated from spec 34.0.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::ACMPCA::CertificateAuthority',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::ACMPCA::CertificateAuthority->new( %$_ ) };

package Cfn::Resource::AWS::ACMPCA::CertificateAuthority {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::ACMPCA::CertificateAuthority', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [ 'Arn','CertificateSigningRequest' ]
  }
  sub supported_regions {
    [ 'af-south-1','ap-east-1','ap-northeast-1','ap-northeast-2','ap-south-1','ap-southeast-1','ap-southeast-2','ca-central-1','eu-central-1','eu-north-1','eu-south-1','eu-west-1','eu-west-2','eu-west-3','me-south-1','sa-east-1','us-east-1','us-east-2','us-gov-east-1','us-gov-west-1','us-west-1','us-west-2' ]
  }
}



subtype 'Cfn::Resource::Properties::AWS::ACMPCA::CertificateAuthority::Subject',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::ACMPCA::CertificateAuthority::Subject',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::ACMPCA::CertificateAuthority::Subject->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::ACMPCA::CertificateAuthority::Subject {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has CommonName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Country => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has DistinguishedNameQualifier => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has GenerationQualifier => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has GivenName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Initials => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Locality => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Organization => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has OrganizationalUnit => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Pseudonym => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has SerialNumber => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has State => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Surname => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Title => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

subtype 'Cfn::Resource::Properties::AWS::ACMPCA::CertificateAuthority::OtherName',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::ACMPCA::CertificateAuthority::OtherName',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::ACMPCA::CertificateAuthority::OtherName->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::ACMPCA::CertificateAuthority::OtherName {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has TypeId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Value => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

subtype 'Cfn::Resource::Properties::AWS::ACMPCA::CertificateAuthority::EdiPartyName',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::ACMPCA::CertificateAuthority::EdiPartyName',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::ACMPCA::CertificateAuthority::EdiPartyName->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::ACMPCA::CertificateAuthority::EdiPartyName {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has NameAssigner => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has PartyName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

subtype 'Cfn::Resource::Properties::AWS::ACMPCA::CertificateAuthority::GeneralName',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::ACMPCA::CertificateAuthority::GeneralName',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::ACMPCA::CertificateAuthority::GeneralName->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::ACMPCA::CertificateAuthority::GeneralName {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has DirectoryName => (isa => 'Cfn::Resource::Properties::AWS::ACMPCA::CertificateAuthority::Subject', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has DnsName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has EdiPartyName => (isa => 'Cfn::Resource::Properties::AWS::ACMPCA::CertificateAuthority::EdiPartyName', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has IpAddress => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has OtherName => (isa => 'Cfn::Resource::Properties::AWS::ACMPCA::CertificateAuthority::OtherName', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has RegisteredId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Rfc822Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has UniformResourceIdentifier => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

subtype 'Cfn::Resource::Properties::AWS::ACMPCA::CertificateAuthority::AccessMethod',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::ACMPCA::CertificateAuthority::AccessMethod',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::ACMPCA::CertificateAuthority::AccessMethod->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::ACMPCA::CertificateAuthority::AccessMethod {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AccessMethodType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has CustomObjectIdentifier => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::ACMPCA::CertificateAuthority::AccessDescription',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::ACMPCA::CertificateAuthority::AccessDescription',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::ACMPCA::CertificateAuthority::AccessDescription')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::ACMPCA::CertificateAuthority::AccessDescription',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::ACMPCA::CertificateAuthority::AccessDescription',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::ACMPCA::CertificateAuthority::AccessDescription->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::ACMPCA::CertificateAuthority::AccessDescription {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AccessLocation => (isa => 'Cfn::Resource::Properties::AWS::ACMPCA::CertificateAuthority::GeneralName', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has AccessMethod => (isa => 'Cfn::Resource::Properties::AWS::ACMPCA::CertificateAuthority::AccessMethod', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

subtype 'Cfn::Resource::Properties::AWS::ACMPCA::CertificateAuthority::SubjectInformationAccess',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::ACMPCA::CertificateAuthority::SubjectInformationAccess',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::ACMPCA::CertificateAuthority::SubjectInformationAccess->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::ACMPCA::CertificateAuthority::SubjectInformationAccess {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has SubjectInformationAccess => (isa => 'ArrayOfCfn::Resource::Properties::AWS::ACMPCA::CertificateAuthority::AccessDescription', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

subtype 'Cfn::Resource::Properties::AWS::ACMPCA::CertificateAuthority::KeyUsage',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::ACMPCA::CertificateAuthority::KeyUsage',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::ACMPCA::CertificateAuthority::KeyUsage->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::ACMPCA::CertificateAuthority::KeyUsage {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has CRLSign => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has DataEncipherment => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has DecipherOnly => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has DigitalSignature => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has EncipherOnly => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has KeyAgreement => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has KeyCertSign => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has KeyEncipherment => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has NonRepudiation => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

subtype 'Cfn::Resource::Properties::AWS::ACMPCA::CertificateAuthority::CrlConfiguration',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::ACMPCA::CertificateAuthority::CrlConfiguration',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::ACMPCA::CertificateAuthority::CrlConfiguration->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::ACMPCA::CertificateAuthority::CrlConfiguration {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has CustomCname => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Enabled => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ExpirationInDays => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has S3BucketName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::ACMPCA::CertificateAuthority::RevocationConfiguration',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::ACMPCA::CertificateAuthority::RevocationConfiguration',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::ACMPCA::CertificateAuthority::RevocationConfiguration->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::ACMPCA::CertificateAuthority::RevocationConfiguration {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has CrlConfiguration => (isa => 'Cfn::Resource::Properties::AWS::ACMPCA::CertificateAuthority::CrlConfiguration', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::ACMPCA::CertificateAuthority::CsrExtensions',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::ACMPCA::CertificateAuthority::CsrExtensions',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::ACMPCA::CertificateAuthority::CsrExtensions->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::ACMPCA::CertificateAuthority::CsrExtensions {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has KeyUsage => (isa => 'Cfn::Resource::Properties::AWS::ACMPCA::CertificateAuthority::KeyUsage', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has SubjectInformationAccess => (isa => 'Cfn::Resource::Properties::AWS::ACMPCA::CertificateAuthority::SubjectInformationAccess', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

package Cfn::Resource::Properties::AWS::ACMPCA::CertificateAuthority {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has CsrExtensions => (isa => 'Cfn::Resource::Properties::AWS::ACMPCA::CertificateAuthority::CsrExtensions', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has KeyAlgorithm => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has RevocationConfiguration => (isa => 'Cfn::Resource::Properties::AWS::ACMPCA::CertificateAuthority::RevocationConfiguration', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SigningAlgorithm => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Subject => (isa => 'Cfn::Resource::Properties::AWS::ACMPCA::CertificateAuthority::Subject', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Tags => (isa => 'ArrayOfCfn::Resource::Properties::TagType', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Type => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::ACMPCA::CertificateAuthority - Cfn resource for AWS::ACMPCA::CertificateAuthority

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::ACMPCA::CertificateAuthority.

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
