package CCfnX::CommonArgs {
  use Moose;
  with 'MooseX::Getopt';
  has name => (is => 'ro', isa => 'Str', required => 1);
  has account => (is => 'ro', isa => 'Str', default => sub { $ENV{CPSD_AWS_ACCOUNT} });
  has update => (is => 'ro', isa => 'Bool', default => 0);
  has region  => (is => 'ro', isa => 'Str', default => sub { $ENV{ AWS_REGION } });
}

1;
