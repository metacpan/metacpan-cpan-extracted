use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::Redshift::ClusterParameterGroup',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::Redshift::ClusterParameterGroup->new( %$_ ) };

package Cfn::Resource::AWS::Redshift::ClusterParameterGroup {
        use Moose;
        extends 'Cfn::Resource';
        has Properties => (isa => 'Cfn::Resource::Properties::AWS::Redshift::ClusterParameterGroup', is => 'rw', coerce => 1, required => 1);
}

package Cfn::Resource::Properties::AWS::Redshift::ClusterParameterGroup  {
        use Moose;
        use MooseX::StrictConstructor;
        extends 'Cfn::Resource::Properties';
        has Description => (isa => 'Cfn::Value', is => 'rw', coerce => 1, required => 1);
        has ParameterGroupFamily => (isa => 'Cfn::Value', is => 'rw', coerce => 1, required => 1);
        has Parameters => (isa => 'Cfn::Value::Array|Cfn::Value::Function', is => 'rw', coerce => 1);
}

1;

