# AWS::Cognito::UserPoolDomain generated from spec 6.3.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::Cognito::UserPoolDomain',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::Cognito::UserPoolDomain->new( %$_ ) };

package Cfn::Resource::AWS::Cognito::UserPoolDomain {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::Cognito::UserPoolDomain', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [  ]
  }
  sub supported_regions {
    [ 'ap-northeast-1','ap-northeast-2','ap-south-1','ap-southeast-1','ap-southeast-2','ca-central-1','eu-central-1','eu-west-1','eu-west-2','us-east-1','us-east-2','us-west-2' ]
  }
}



subtype 'Cfn::Resource::Properties::AWS::Cognito::UserPoolDomain::CustomDomainConfigType',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Cognito::UserPoolDomain::CustomDomainConfigType',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::Cognito::UserPoolDomain::CustomDomainConfigTypeValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::Cognito::UserPoolDomain::CustomDomainConfigTypeValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has CertificateArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::Cognito::UserPoolDomain {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has CustomDomainConfig => (isa => 'Cfn::Resource::Properties::AWS::Cognito::UserPoolDomain::CustomDomainConfigType', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Domain => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has UserPoolId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

1;
