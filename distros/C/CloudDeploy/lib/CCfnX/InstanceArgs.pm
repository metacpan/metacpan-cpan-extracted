package CCfnX::InstanceArgs {
  use Moose;
  extends 'CCfnX::CommonArgs';
  has instance_type => (is => 'ro', isa => 'Str', default => 't2.micro');
  has keypair => (is => 'ro', isa => 'Str');
}

1;
