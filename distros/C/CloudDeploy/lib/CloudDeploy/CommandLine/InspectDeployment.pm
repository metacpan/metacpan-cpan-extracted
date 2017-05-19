package CloudDeploy::CommandLine::InspectDeployment {
  use MooseX::App;
  use CloudDeploy::DeploymentCollection;
  use Data::Printer;

  parameter deploy_name => (
    is => 'rw',
    isa => 'Str',
    documentation => 'The name of the deployment in the database',
    required => 1,
  );

  sub run {
    my ($self) = @_;
    
    my $deployments = CloudDeploy::DeploymentCollection->new(account => $ENV{'CPSD_AWS_ACCOUNT'});
    my $deploy = $deployments->get_deployment($self->deploy_name);

    print "\nTYPE:\n";
    p $deploy->type;
    print "\nPARAMS:\n";
    p $deploy->params;
    print "\nOUTPUTS:\n";
    p $deploy->outputs;
    print "\nCOMMENTS:\n";
    if (defined $deploy->comments) { p $deploy->comments; print "\n"; }
    else { print "No comments available.\n\n"; }
  }
}

1;
