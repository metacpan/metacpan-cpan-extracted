use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::Serverless::StateMachine',
    from 'HashRef',
    via { Cfn::Resource::Properties::AWS::Serverless::StateMachine->new(%$_) };

package Cfn::Resource::AWS::Serverless::StateMachine {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => ( isa => 'Cfn::Resource::Properties::AWS::Serverless::StateMachine', is => 'rw', coerce => 1 );

  sub supported_regions {
    require Cfn::Resource::AWS::Lambda::Function;
    Cfn::Resource::AWS::Lambda::Function->supported_regions;
  }

  sub AttributeList {
    ['Name']
  }
}

package Cfn::Resource::Properties::AWS::Serverless::StateMachine {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';

  has Definition => ( isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has DefinitionSubstitutions => ( isa => 'Cfn::Value', is => 'rw', coerce => 1 );
  has DefinitionUri => ( isa => 'Cfn::Value', is => 'rw', coerce => 1 );
  has Events => ( isa => 'Cfn::Value', is => 'rw', coerce => 1 );
  has Logging => ( isa => 'Cfn::Value', is => 'rw', coerce => 1 );
  has Domain => ( isa => 'Cfn::Value', is => 'rw', coerce => 1 );
  has Logging => ( isa => 'Cfn::Value', is => 'rw', coerce => 1 );
  has Name => ( isa => 'Cfn::Value::String', is => 'rw', coerce => 1 );
  has Policies => ( isa => 'Cfn::Value', is => 'rw', coerce => 1 );
  has Role => ( isa => 'Cfn::Value::String', is => 'rw', coerce => 1 );
  has Tags => ( isa => 'Cfn::Value', is => 'rw', coerce => 1 );
  has Type => ( isa => 'Cfn::Value::String', is => 'rw', coerce => 1);
}

1;
