# AWS::LakeFormation::DataLakeSettings generated from spec 20.1.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::LakeFormation::DataLakeSettings',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::LakeFormation::DataLakeSettings->new( %$_ ) };

package Cfn::Resource::AWS::LakeFormation::DataLakeSettings {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::LakeFormation::DataLakeSettings', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [  ]
  }
  sub supported_regions {
    [ 'ap-northeast-1','eu-west-1','us-east-1','us-east-2','us-west-2' ]
  }
}



subtype 'Cfn::Resource::Properties::AWS::LakeFormation::DataLakeSettings::DataLakePrincipal',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::LakeFormation::DataLakeSettings::DataLakePrincipal',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::LakeFormation::DataLakeSettings::DataLakePrincipal->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::LakeFormation::DataLakeSettings::DataLakePrincipal {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has DataLakePrincipalIdentifier => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::LakeFormation::DataLakeSettings::Admins',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::LakeFormation::DataLakeSettings::Admins',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::LakeFormation::DataLakeSettings::Admins->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::LakeFormation::DataLakeSettings::Admins {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
}

package Cfn::Resource::Properties::AWS::LakeFormation::DataLakeSettings {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has Admins => (isa => 'Cfn::Resource::Properties::AWS::LakeFormation::DataLakeSettings::Admins', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TrustedResourceOwners => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::LakeFormation::DataLakeSettings - Cfn resource for AWS::LakeFormation::DataLakeSettings

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::LakeFormation::DataLakeSettings.

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
