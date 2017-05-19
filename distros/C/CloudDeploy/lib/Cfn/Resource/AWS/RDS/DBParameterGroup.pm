use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::RDS::DBParameterGroup',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::RDS::DBParameterGroup->new( %$_ ) };

package Cfn::Resource::AWS::RDS::DBParameterGroup {
        use Moose;
        extends 'Cfn::Resource';
        has Properties => (isa => 'Cfn::Resource::Properties::AWS::RDS::DBParameterGroup', is => 'rw', coerce => 1, required => 1);
}

package Cfn::Resource::Properties::AWS::RDS::DBParameterGroup  {
        use Moose;
        use MooseX::StrictConstructor;
        extends 'Cfn::Resource::Properties';
        has Description => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
        has Family => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
        has Parameters => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
        has Tags => (isa => 'Cfn::Value::Array|Cfn::Value::Function', is => 'rw', coerce => 1);
}

1;
