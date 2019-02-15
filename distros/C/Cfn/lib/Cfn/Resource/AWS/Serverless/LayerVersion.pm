use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::Serverless::LayerVersion',
    from 'HashRef',
    via { Cfn::Resource::Properties::AWS::Serverless::LayerVersion->new(%$_) };

package Cfn::Resource::AWS::Serverless::LayerVersion {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => ( isa => 'Cfn::Resource::Properties::AWS::Serverless::LayerVersion', is => 'rw', coerce => 1 );

  sub _build_attributes {
    []
  }
}

package Cfn::Resource::Properties::AWS::Serverless::LayerVersion {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';

  has LayerName   => ( isa => 'Cfn::Value::String', is => 'rw', coerce => 1 );
  has Description => ( isa => 'Cfn::Value::String', is => 'rw', coerce => 1 );
  has ContentUri => ( isa => 'Cfn::Value', is => 'rw', coerce => 1, required => 1 );
  has CompatibleRuntimes => ( isa => 'Cfn::Value::String', is => 'rw', coerce => 1 );
  has LicenseInfo => ( isa => 'Cfn::Value::String', is => 'rw', coerce => 1 );
  has RetentionPolicy => ( isa => 'Cfn::Value::String', is => 'rw', coerce => 1 );
}

1;
