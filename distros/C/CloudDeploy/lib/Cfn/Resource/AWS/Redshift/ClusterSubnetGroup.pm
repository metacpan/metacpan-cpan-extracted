use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::Redshift::ClusterSubnetGroup',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::Redshift::ClusterSubnetGroup->new( %$_ ) };

package Cfn::Resource::AWS::Redshift::ClusterSubnetGroup {
        use Moose;
        extends 'Cfn::Resource';
        has Properties => (isa => 'Cfn::Resource::Properties::AWS::Redshift::ClusterSubnetGroup', is => 'rw', coerce => 1, required => 1);
}

package Cfn::Resource::Properties::AWS::Redshift::ClusterSubnetGroup  {
        use Moose;
        use MooseX::StrictConstructor;
        extends 'Cfn::Resource::Properties';
        has Description => (isa => 'Cfn::Value', is => 'rw', coerce => 1, required => 1);
        has SubnetIds => (isa => 'Cfn::Value::Array|Cfn::Value::Function', is => 'rw', coerce => 1, required => 1);
}

1;

