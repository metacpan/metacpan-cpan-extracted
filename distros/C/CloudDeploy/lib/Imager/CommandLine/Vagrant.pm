package Imager::CommandLine::Vagrant {
  use MooseX::App;
  use CloudDeploy::Utils;

  parameter ami_class => (is => 'ro', isa => 'Str', required => 1);

  sub run {
    my ($self) = @_;

    my $module = load_class($self->ami_class);

    my $obj = $module->{class}->new;

    die "Class is not a CCfnX::MakeAMIBase" if (not $obj->isa('CCfnX::MakeAMIBase'));

    my $deployer = $obj->get_deployer({
#    access_key => $ENV{AWS_ACCESS_KEY_ID},
#    secret_key => $ENV{AWS_SECRET_ACCESS_KEY},
#    account    => $ENV{CPSD_AWS_ACCOUNT},
    },'CCfnX::VagrantDeployer');

    #if ($obj->params->update) {
    #  $deployer->redeploy;
    #} else {

      $deployer->deploy;

    #}
  }
}

1;
