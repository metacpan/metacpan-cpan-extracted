use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::Lambda::Permission',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::Lambda::Permission->new( %$_ ) };

package Cfn::Resource::AWS::Lambda::Permission {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::Lambda::Permission', is => 'rw', coerce => 1, required => 1);
}

package Cfn::Resource::Properties::AWS::Lambda::Permission {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  has FunctionName => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has Action => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has Principal => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has SourceArn => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has SourceAccount => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
}

1;
