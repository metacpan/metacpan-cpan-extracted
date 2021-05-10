# AWS::ACMPCA::Certificate generated from spec 34.0.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::ACMPCA::Certificate',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::ACMPCA::Certificate->new( %$_ ) };

package Cfn::Resource::AWS::ACMPCA::Certificate {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::ACMPCA::Certificate', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [ 'Arn','Certificate' ]
  }
  sub supported_regions {
    [ 'af-south-1','ap-east-1','ap-northeast-1','ap-northeast-2','ap-south-1','ap-southeast-1','ap-southeast-2','ca-central-1','eu-central-1','eu-north-1','eu-south-1','eu-west-1','eu-west-2','eu-west-3','me-south-1','sa-east-1','us-east-1','us-east-2','us-gov-east-1','us-gov-west-1','us-west-1','us-west-2' ]
  }
}



subtype 'Cfn::Resource::Properties::AWS::ACMPCA::Certificate::Qualifier',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::ACMPCA::Certificate::Qualifier',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::ACMPCA::Certificate::Qualifier->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::ACMPCA::Certificate::Qualifier {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has CpsUri => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::ACMPCA::Certificate::PolicyQualifierInfo',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::ACMPCA::Certificate::PolicyQualifierInfo',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::ACMPCA::Certificate::PolicyQualifierInfo')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::ACMPCA::Certificate::PolicyQualifierInfo',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::ACMPCA::Certificate::PolicyQualifierInfo',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::ACMPCA::Certificate::PolicyQualifierInfo->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::ACMPCA::Certificate::PolicyQualifierInfo {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has PolicyQualifierId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Qualifier => (isa => 'Cfn::Resource::Properties::AWS::ACMPCA::Certificate::Qualifier', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

subtype 'Cfn::Resource::Properties::AWS::ACMPCA::Certificate::Subject',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::ACMPCA::Certificate::Subject',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::ACMPCA::Certificate::Subject->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::ACMPCA::Certificate::Subject {
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

subtype 'Cfn::Resource::Properties::AWS::ACMPCA::Certificate::PolicyQualifierInfoList',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::ACMPCA::Certificate::PolicyQualifierInfoList',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::ACMPCA::Certificate::PolicyQualifierInfoList->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::ACMPCA::Certificate::PolicyQualifierInfoList {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has PolicyQualifierInfoList => (isa => 'ArrayOfCfn::Resource::Properties::AWS::ACMPCA::Certificate::PolicyQualifierInfo', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

subtype 'Cfn::Resource::Properties::AWS::ACMPCA::Certificate::OtherName',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::ACMPCA::Certificate::OtherName',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::ACMPCA::Certificate::OtherName->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::ACMPCA::Certificate::OtherName {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has TypeId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Value => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

subtype 'Cfn::Resource::Properties::AWS::ACMPCA::Certificate::EdiPartyName',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::ACMPCA::Certificate::EdiPartyName',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::ACMPCA::Certificate::EdiPartyName->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::ACMPCA::Certificate::EdiPartyName {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has NameAssigner => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has PartyName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::ACMPCA::Certificate::PolicyInformation',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::ACMPCA::Certificate::PolicyInformation',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::ACMPCA::Certificate::PolicyInformation')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::ACMPCA::Certificate::PolicyInformation',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::ACMPCA::Certificate::PolicyInformation',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::ACMPCA::Certificate::PolicyInformation->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::ACMPCA::Certificate::PolicyInformation {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has CertPolicyId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has PolicyQualifiers => (isa => 'Cfn::Resource::Properties::AWS::ACMPCA::Certificate::PolicyQualifierInfoList', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::ACMPCA::Certificate::GeneralName',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::ACMPCA::Certificate::GeneralName',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::ACMPCA::Certificate::GeneralName')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::ACMPCA::Certificate::GeneralName',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::ACMPCA::Certificate::GeneralName',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::ACMPCA::Certificate::GeneralName->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::ACMPCA::Certificate::GeneralName {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has DirectoryName => (isa => 'Cfn::Resource::Properties::AWS::ACMPCA::Certificate::Subject', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has DnsName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has EdiPartyName => (isa => 'Cfn::Resource::Properties::AWS::ACMPCA::Certificate::EdiPartyName', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has IpAddress => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has OtherName => (isa => 'Cfn::Resource::Properties::AWS::ACMPCA::Certificate::OtherName', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has RegisteredId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Rfc822Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has UniformResourceIdentifier => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::ACMPCA::Certificate::ExtendedKeyUsage',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::ACMPCA::Certificate::ExtendedKeyUsage',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::ACMPCA::Certificate::ExtendedKeyUsage')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::ACMPCA::Certificate::ExtendedKeyUsage',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::ACMPCA::Certificate::ExtendedKeyUsage',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::ACMPCA::Certificate::ExtendedKeyUsage->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::ACMPCA::Certificate::ExtendedKeyUsage {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ExtendedKeyUsageObjectIdentifier => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has ExtendedKeyUsageType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

subtype 'Cfn::Resource::Properties::AWS::ACMPCA::Certificate::KeyUsage',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::ACMPCA::Certificate::KeyUsage',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::ACMPCA::Certificate::KeyUsage->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::ACMPCA::Certificate::KeyUsage {
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

subtype 'Cfn::Resource::Properties::AWS::ACMPCA::Certificate::GeneralNameList',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::ACMPCA::Certificate::GeneralNameList',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::ACMPCA::Certificate::GeneralNameList->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::ACMPCA::Certificate::GeneralNameList {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has GeneralNameList => (isa => 'ArrayOfCfn::Resource::Properties::AWS::ACMPCA::Certificate::GeneralName', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

subtype 'Cfn::Resource::Properties::AWS::ACMPCA::Certificate::ExtendedKeyUsageList',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::ACMPCA::Certificate::ExtendedKeyUsageList',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::ACMPCA::Certificate::ExtendedKeyUsageList->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::ACMPCA::Certificate::ExtendedKeyUsageList {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ExtendedKeyUsageList => (isa => 'ArrayOfCfn::Resource::Properties::AWS::ACMPCA::Certificate::ExtendedKeyUsage', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

subtype 'Cfn::Resource::Properties::AWS::ACMPCA::Certificate::CertificatePolicyList',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::ACMPCA::Certificate::CertificatePolicyList',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::ACMPCA::Certificate::CertificatePolicyList->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::ACMPCA::Certificate::CertificatePolicyList {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has CertificatePolicyList => (isa => 'ArrayOfCfn::Resource::Properties::AWS::ACMPCA::Certificate::PolicyInformation', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

subtype 'Cfn::Resource::Properties::AWS::ACMPCA::Certificate::Extensions',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::ACMPCA::Certificate::Extensions',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::ACMPCA::Certificate::Extensions->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::ACMPCA::Certificate::Extensions {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has CertificatePolicies => (isa => 'Cfn::Resource::Properties::AWS::ACMPCA::Certificate::CertificatePolicyList', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has ExtendedKeyUsage => (isa => 'Cfn::Resource::Properties::AWS::ACMPCA::Certificate::ExtendedKeyUsageList', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has KeyUsage => (isa => 'Cfn::Resource::Properties::AWS::ACMPCA::Certificate::KeyUsage', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has SubjectAlternativeNames => (isa => 'Cfn::Resource::Properties::AWS::ACMPCA::Certificate::GeneralNameList', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

subtype 'Cfn::Resource::Properties::AWS::ACMPCA::Certificate::Validity',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::ACMPCA::Certificate::Validity',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::ACMPCA::Certificate::Validity->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::ACMPCA::Certificate::Validity {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Type => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Value => (isa => 'Cfn::Value::Double', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

subtype 'Cfn::Resource::Properties::AWS::ACMPCA::Certificate::ApiPassthrough',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::ACMPCA::Certificate::ApiPassthrough',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::ACMPCA::Certificate::ApiPassthrough->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::ACMPCA::Certificate::ApiPassthrough {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Extensions => (isa => 'Cfn::Resource::Properties::AWS::ACMPCA::Certificate::Extensions', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Subject => (isa => 'Cfn::Resource::Properties::AWS::ACMPCA::Certificate::Subject', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

package Cfn::Resource::Properties::AWS::ACMPCA::Certificate {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has ApiPassthrough => (isa => 'Cfn::Resource::Properties::AWS::ACMPCA::Certificate::ApiPassthrough', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has CertificateAuthorityArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has CertificateSigningRequest => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has SigningAlgorithm => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has TemplateArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Validity => (isa => 'Cfn::Resource::Properties::AWS::ACMPCA::Certificate::Validity', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has ValidityNotBefore => (isa => 'Cfn::Resource::Properties::AWS::ACMPCA::Certificate::Validity', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::ACMPCA::Certificate - Cfn resource for AWS::ACMPCA::Certificate

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::ACMPCA::Certificate.

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
