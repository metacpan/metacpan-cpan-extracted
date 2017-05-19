use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::Redshift::Cluster',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::Redshift::Cluster->new( %$_ ) };

package Cfn::Resource::AWS::Redshift::Cluster {
        use Moose;
        extends 'Cfn::Resource';
        has Properties => (isa => 'Cfn::Resource::Properties::AWS::Redshift::Cluster', is => 'rw', coerce => 1, required => 1);
}

package Cfn::Resource::Properties::AWS::Redshift::Cluster  {
        use Moose;
        use MooseX::StrictConstructor;
        extends 'Cfn::Resource::Properties';
        has AllowVersionUpgrade => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
        has AutomatedSnapshotRetentionPeriod => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
        has AvailabilityZone => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
        has ClusterParameterGroupName => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
        has ClusterSecurityGroups => (isa => 'Cfn::Value::Array|Cfn::Value::Function', is => 'rw', coerce => 1);
        has ClusterSubnetGroupName => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
        has ClusterType => (isa => 'Cfn::Value', is => 'rw', coerce => 1, required => 1);
        has ClusterVersion => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
        has DBName => (isa => 'Cfn::Value', is => 'rw', coerce => 1, required => 1);
        has ElasticIp => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
        has Encrypted => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
        has HsmClientCertificateIdentifier => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
        has HsmConfigurationIdentifier => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
        has KmsKeyId => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
        has MasterUsername => (isa => 'Cfn::Value', is => 'rw', coerce => 1, required => 1);
        has MasterUserPassword => (isa => 'Cfn::Value', is => 'rw', coerce => 1, required => 1);
        has NodeType => (isa => 'Cfn::Value', is => 'rw', coerce => 1, required => 1);
        has NumberOfNodes => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
        has OwnerAccount => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
        has Port => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
        has PreferredMaintenanceWindow => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
        has PubliclyAccessible => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
        has SnapshotClusterIdentifier => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
        has SnapshotIdentifier => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
        has VpcSecurityGroupIds => (isa => 'Cfn::Value::Array|Cfn::Value::Function', is => 'rw', coerce => 1);
}

1;

