package Imager::CommandLine::MakeVagrant {
  use MooseX::App;
  use CloudDeploy::Utils;

  parameter ami_class => (is => 'ro', isa => 'Str', required => 1);

  sub run {
    my ($self) = @_;

    my $module = load_class($self->ami_class);
    my $obj = $module->{class}->new(params => $module->{params_class}->new_with_options(argv => $self->extra_argv));

    die "Class is not a CCfnX::MakeAMIBase" if (not $obj->isa('CCfnX::MakeAMIBase'));

    my $deployer = $obj->get_deployer({
    },'CCfnX::VagrantDeployer');

    $deployer->deploy;
  }
}

1;
