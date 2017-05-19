package CCfnX::LocateAMI {
  use Moose;
  use Carp;
  use autodie;
  has name => (is => 'ro', isa => 'Str');
  use CloudDeploy::Config;

  has account => (is => 'ro', isa => 'Str', lazy => 1, default => sub { $ENV{'CPSD_AWS_ACCOUNT'} });
  has config => (is => 'ro', lazy => 1, default => sub { CloudDeploy::Config->new });
  has mongo => (is => 'ro', lazy => 1, default => sub { $_[0]->config->deploy_mongo });

  sub ami {
    my ($self, $region, $arch, $root) = @_;
    my $body = {
        name => $self->name, 
        account => $self->account,
        'outputs.arch' => lc($arch),
        'outputs.root' => lc($root),
        region => lc($region),
    };

    my $obj = $self->mongo->query(
      $body,
      { sort_by => { timestamp => -1 }, limit => 1 },
    )->next;

    confess "Didn't find deployment " . $self->name . " in account " . $self->account unless defined $obj;

    return $obj->{outputs}->{ami};
  }
  sub mapping {
    my ($self, $arch, $root) = @_;
    # Create a mapping for a specified arch and root type
  }
}

1;
