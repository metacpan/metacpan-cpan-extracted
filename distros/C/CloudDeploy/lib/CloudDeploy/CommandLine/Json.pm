package CloudDeploy::CommandLine::Json {
  use MooseX::App;  
  use CloudDeploy::Utils;
  use CloudDeploy::DeploymentCollection;

  parameter deployment => (is => 'ro', isa => 'Str', required => 1);
  option pretty => (is => 'ro', isa => 'Bool', default => 1);
 
  sub run {
    my ($self) = @_;

    if (my ($deploy_name) = ($self->deployment =~ m/^deploy\:(.*)$/)) {
      my $deployments = CloudDeploy::DeploymentCollection->new(account => $ENV{'CPSD_AWS_ACCOUNT'});
      my $deploy      = $deployments->get_deployment($deploy_name);

      my $module = load_class($deploy->type);

      my @attached =
        map { $_->name }
        grep { $_->does('Attached') }
        $module->{params_class}->meta->get_all_attributes;

      my $params = $deploy->params;
      delete $params->{ $_ } for (@attached);

      my $merged_params = $module->{params_class}->new_with_options(%{ $params }, argv => $self->extra_argv);
      my $obj = $module->{class}->new(params => $merged_params);

      my $deployer = $obj->get_deployer({
        account    => $ENV{CPSD_AWS_ACCOUNT},
      },'CCfnX::ConsoleDeployer');
      $deployer->deploy;
    } else {
      my $module = load_class($self->deployment);
      my $obj = $module->{class}->new(params => $module->{params_class}->new_with_options(argv => $self->extra_argv));

      my $deployer = $obj->get_deployer({
         account    => $ENV{CPSD_AWS_ACCOUNT},
      },'CCfnX::ConsoleDeployer');
      $deployer->deploy;
    }
  }
}

1;
