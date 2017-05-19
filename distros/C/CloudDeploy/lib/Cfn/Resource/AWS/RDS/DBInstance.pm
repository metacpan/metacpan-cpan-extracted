use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::RDS::DBInstance',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::RDS::DBInstance->new( %$_ ) };

package Cfn::Resource::AWS::RDS::DBInstance {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::RDS::DBInstance', is => 'rw', coerce => 1, required => 1);
}

package Cfn::Resource::Properties::AWS::RDS::DBInstance  {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  has AllocatedStorage => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has AllowMajorVersionUpgrade => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has AutoMinorVersionUpgrade => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has AvailabilityZone => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has BackupRetentionPeriod => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has DBInstanceClass => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has DBInstanceIdentifier => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has DBName => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has DBParameterGroupName => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has DBSecurityGroups => (isa => 'Cfn::Value::Array|Cfn::Value::Function', is => 'rw', coerce => 1);
  has DBSnapshotIdentifier => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has DBSubnetGroupName => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has Engine => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has EngineVersion => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has Iops => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has LicenseModel => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has MasterUsername => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has MasterUserPassword => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has MultiAZ => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has Port => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has PreferredBackupWindow => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has PreferredMaintenanceWindow => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has SourceDBInstanceIdentifier => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has Tags => (isa => 'Cfn::Value::Array|Cfn::Value::Function', is => 'rw', coerce => 1);
  has VPCSecurityGroups => (isa => 'Cfn::Value::Array|Cfn::Value::Function', is => 'rw', coerce => 1);
  has PubliclyAccessible => (isa=> 'Cfn::Value', is => 'rw', coerce => 1);
}

1;
