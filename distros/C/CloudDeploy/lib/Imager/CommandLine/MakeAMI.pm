package Imager::CommandLine::MakeAMI {
  use MooseX::App;

  #parameter =>

  use DateTime;
  use Term::ANSIColor;
  use CloudDeploy::Utils;
  use CloudDeploy::DeploymentCollection;

  parameter deploy_class => (is => 'ro', isa => 'Str', required => 1);
  option comments => (is => 'ro', isa => 'Str|Undef', documentation => "Comments to include with deployment");

  sub run {
    my ($self) = @_;

    my $module = load_class($self->deploy_class);
    my $obj = $module->{class}->new(params => $module->{params_class}->new_with_options(argv => $self->extra_argv));

    if (not ($obj->isa('CCfnX::MakeAMIBase') or $obj->isa('CCfnX::MakeAMIBaseVPC'))){
      die "Can't make an AMI: Please check base classes are CCfnX::MakeAMIBase or CCfnX::MakeAMIBaseVPC" . $obj;
    }

    my $deployments = CloudDeploy::DeploymentCollection->new(account => $ENV{'CPSD_AWS_ACCOUNT'});
    my $lastday = DateTime->now()->subtract(days => 1);
    my @list = $deployments->search_log_deployments({
                  'params.name' => $obj->params->name,
                  'timestamp' => { '$gt' => $lastday->datetime() }
                }, 1);

    if (@list) {
      print color('bold yellow'),
            "WARNING: an AMI deployment with the same name was created in the last 24 hours!\n",
            color('reset')
    }

    my $deployer = $obj->get_deployer({
      access_key => $ENV{AWS_ACCESS_KEY_ID},
      secret_key => $ENV{AWS_SECRET_ACCESS_KEY},
      account    => $ENV{CPSD_AWS_ACCOUNT},
      comments   => $self->comments,
    },'CCfnX::CloudFormationDeployer', 'CCfnX::PersistentDeployment');

    if ($deployments->deployment_exists($obj->params->name)) {
      my $stack;
      eval {
        $stack = $deployer->cfn->DescribeStacks(StackName => $deployer->name)->Stacks->[0];
      };

      unless (defined $stack and $obj->params->onlysnapshot) {
        if (defined $stack) {
          die "Stack already exists in AWS and option 'onlysnapshot' was not found.\n";
        }
        else {
          print "Found existing deployment with no matching AWS stack. Undeploying...\n";
          $deployer->undeploy;
        }
      }
    }

    $deployer = $obj->get_deployer({
      access_key => $ENV{AWS_ACCESS_KEY_ID},
      secret_key => $ENV{AWS_SECRET_ACCESS_KEY},
      account    => $ENV{CPSD_AWS_ACCOUNT},
      comments   => $self->comments,
    },'CCfnX::CloudFormationDeployer', 'CCfnX::PersistentDeployment', 'CCfnX::MakeAMI');

    $deployer->deploy;
  }
}

1;
