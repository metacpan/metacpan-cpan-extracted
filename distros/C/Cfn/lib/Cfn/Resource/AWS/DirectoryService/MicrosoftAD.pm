# AWS::DirectoryService::MicrosoftAD generated from spec 2.3.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::DirectoryService::MicrosoftAD',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::DirectoryService::MicrosoftAD->new( %$_ ) };

package Cfn::Resource::AWS::DirectoryService::MicrosoftAD {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::DirectoryService::MicrosoftAD', is => 'rw', coerce => 1);
  sub _build_attributes {
    [ 'Alias','DnsIpAddresses' ]
  }
}



subtype 'Cfn::Resource::Properties::AWS::DirectoryService::MicrosoftAD::VpcSettings',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::DirectoryService::MicrosoftAD::VpcSettings',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::DirectoryService::MicrosoftAD::VpcSettingsValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::DirectoryService::MicrosoftAD::VpcSettingsValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has SubnetIds => (isa => 'Cfn::Value::Array|Cfn::Value::Function', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has VpcId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::DirectoryService::MicrosoftAD {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has CreateAlias => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Edition => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has EnableSso => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Password => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has ShortName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has VpcSettings => (isa => 'Cfn::Resource::Properties::AWS::DirectoryService::MicrosoftAD::VpcSettings', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

1;
