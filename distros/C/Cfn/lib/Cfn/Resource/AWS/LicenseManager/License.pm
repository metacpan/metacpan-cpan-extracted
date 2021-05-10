# AWS::LicenseManager::License generated from spec 34.0.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::LicenseManager::License',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::LicenseManager::License->new( %$_ ) };

package Cfn::Resource::AWS::LicenseManager::License {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::LicenseManager::License', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [ 'LicenseArn','Version' ]
  }
  sub supported_regions {
    [ 'ap-northeast-1','ap-southeast-2','eu-central-1','eu-west-1','sa-east-1','us-east-1','us-east-2','us-west-2' ]
  }
}



subtype 'Cfn::Resource::Properties::AWS::LicenseManager::License::ProvisionalConfiguration',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::LicenseManager::License::ProvisionalConfiguration',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::LicenseManager::License::ProvisionalConfiguration->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::LicenseManager::License::ProvisionalConfiguration {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has MaxTimeToLiveInMinutes => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::LicenseManager::License::BorrowConfiguration',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::LicenseManager::License::BorrowConfiguration',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::LicenseManager::License::BorrowConfiguration->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::LicenseManager::License::BorrowConfiguration {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AllowEarlyCheckIn => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has MaxTimeToLiveInMinutes => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::LicenseManager::License::ValidityDateFormat',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::LicenseManager::License::ValidityDateFormat',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::LicenseManager::License::ValidityDateFormat->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::LicenseManager::License::ValidityDateFormat {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Begin => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has End => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::LicenseManager::License::Metadata',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::LicenseManager::License::Metadata',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::LicenseManager::License::Metadata')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::LicenseManager::License::Metadata',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::LicenseManager::License::Metadata',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::LicenseManager::License::Metadata->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::LicenseManager::License::Metadata {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Value => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::LicenseManager::License::IssuerData',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::LicenseManager::License::IssuerData',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::LicenseManager::License::IssuerData->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::LicenseManager::License::IssuerData {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SignKey => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::LicenseManager::License::Entitlement',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::LicenseManager::License::Entitlement',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::LicenseManager::License::Entitlement')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::LicenseManager::License::Entitlement',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::LicenseManager::License::Entitlement',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::LicenseManager::License::Entitlement->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::LicenseManager::License::Entitlement {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AllowCheckIn => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has MaxCount => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Overage => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Unit => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Value => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::LicenseManager::License::ConsumptionConfiguration',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::LicenseManager::License::ConsumptionConfiguration',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::LicenseManager::License::ConsumptionConfiguration->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::LicenseManager::License::ConsumptionConfiguration {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has BorrowConfiguration => (isa => 'Cfn::Resource::Properties::AWS::LicenseManager::License::BorrowConfiguration', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ProvisionalConfiguration => (isa => 'Cfn::Resource::Properties::AWS::LicenseManager::License::ProvisionalConfiguration', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RenewType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::LicenseManager::License {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has Beneficiary => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ConsumptionConfiguration => (isa => 'Cfn::Resource::Properties::AWS::LicenseManager::License::ConsumptionConfiguration', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Entitlements => (isa => 'ArrayOfCfn::Resource::Properties::AWS::LicenseManager::License::Entitlement', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has HomeRegion => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Issuer => (isa => 'Cfn::Resource::Properties::AWS::LicenseManager::License::IssuerData', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has LicenseMetadata => (isa => 'ArrayOfCfn::Resource::Properties::AWS::LicenseManager::License::Metadata', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has LicenseName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ProductName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ProductSKU => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Status => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Validity => (isa => 'Cfn::Resource::Properties::AWS::LicenseManager::License::ValidityDateFormat', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::LicenseManager::License - Cfn resource for AWS::LicenseManager::License

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::LicenseManager::License.

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
