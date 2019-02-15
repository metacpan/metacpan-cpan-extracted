# AWS::AppStream::DirectoryConfig generated from spec 2.15.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::AppStream::DirectoryConfig',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::AppStream::DirectoryConfig->new( %$_ ) };

package Cfn::Resource::AWS::AppStream::DirectoryConfig {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::AppStream::DirectoryConfig', is => 'rw', coerce => 1);
  sub _build_attributes {
    [  ]
  }
}



subtype 'Cfn::Resource::Properties::AWS::AppStream::DirectoryConfig::ServiceAccountCredentials',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppStream::DirectoryConfig::ServiceAccountCredentials',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::AppStream::DirectoryConfig::ServiceAccountCredentialsValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::AppStream::DirectoryConfig::ServiceAccountCredentialsValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AccountName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has AccountPassword => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::AppStream::DirectoryConfig {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has DirectoryName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has OrganizationalUnitDistinguishedNames => (isa => 'Cfn::Value::Array|Cfn::Value::Function', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ServiceAccountCredentials => (isa => 'Cfn::Resource::Properties::AWS::AppStream::DirectoryConfig::ServiceAccountCredentials', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
