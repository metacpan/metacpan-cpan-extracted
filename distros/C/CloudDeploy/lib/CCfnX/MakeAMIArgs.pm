package CCfnX::MakeAMIArgs {
  use Moose;
  extends 'CCfnX::InstanceArgs';
  has template => (is => 'ro', isa => 'ArrayRef[Str]', required => 1);
  has ami => (is => 'ro', isa => 'Str', required => 1, documentation => 'AMI to base the image upon. Takes it as the base AMI, and applies templates to it');
  has os_family => (is => 'ro', isa => 'Str', default => 'linux');
  has devel => (is => 'ro', isa => 'Bool', default => 0, documentation => 'Leaves the instance turned on after executing all templates for debugging pourposes');
  has onlysnapshot => (is => 'ro', isa => 'Bool', default => 0, documentation => 'If the stack has been created with --devel, you can continue the process of converting the instance to AMI with this option');
  has amitag => (is => 'ro', isa => 'Str', documentation => 'Optional: when registering this AMI, we\'ll use this tag to identify it. It should be unique for the region of deployment and the name of the AMI');
}

1;
