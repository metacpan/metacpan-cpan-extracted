package CCfnX::Parameter::InstanceType {
  use Moose;
  extends 'Cfn::Parameter';

  has '+Type' => (default => 'String');
  has '+Default' => (default => 't1.micro');
  has '+Description' => (default => 'Type of instance');
  has '+AllowedValues' => (default => sub { [ "t1.micro", "t2.micro", "t2.small", "t2.medium", "m1.small", "m1.medium", "m1.large", "m1.xlarge", "m2.xlarge", "m2.2xlarge", "m2.4xlarge", "m3.medium", "m3.large", "m3.xlarge", "m3.2xlarge", "c1.medium", "c1.xlarge", "c3.large", "c3.xlarge", "c3.2xlarge", "c3.4xlarge", "c3.8xlarge", "cc1.4xlarge", "g2.2xlarge", "r3.large", "r3.xlarge", "r3.2xlarge", "r3.4xlarge", "r3.8xlarge", "i2.xlarge", "i2.2xlarge", "i2.4xlarge", "i2.8xlarge", "hs1.8xlarge" ] });
}

1;
