package CloudDeploy::CommandLine::ListDeployments {
  use MooseX::App;
  use CloudDeploy::DeploymentCollection;

  option extended => (
    is => 'ro',
    isa => 'Bool',
    documentation => 'If specified, will list account, status and type of deploy',
    default => 0,
  );

  sub run {
    my ($self) = @_;
    
    my $deployments = CloudDeploy::DeploymentCollection->new(account => $ENV{'CPSD_AWS_ACCOUNT'});
    my @list = $deployments->customer_deployments;
      
    foreach my $deploy_name (@list) {
      if ($self->extended) {
        my $deploy = $deployments->get_deployment($deploy_name);
        printf "%s\t%s\t%s\t%s\n", $deploy->name, $deploy->account, $deploy->status, $deploy->type
      } else {
        printf "%s\n", $deploy_name;
      }
    }
  }
}

1;

