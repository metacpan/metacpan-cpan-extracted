# AWS::LakeFormation::DataLakeSettings generated from spec 5.3.0
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
       return Cfn::Resource::Properties::AWS::LakeFormation::DataLakeSettings::DataLakePrincipalValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::LakeFormation::DataLakeSettings::DataLakePrincipalValue {
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
       return Cfn::Resource::Properties::AWS::LakeFormation::DataLakeSettings::AdminsValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::LakeFormation::DataLakeSettings::AdminsValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
}

package Cfn::Resource::Properties::AWS::LakeFormation::DataLakeSettings {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has Admins => (isa => 'Cfn::Resource::Properties::AWS::LakeFormation::DataLakeSettings::Admins', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
