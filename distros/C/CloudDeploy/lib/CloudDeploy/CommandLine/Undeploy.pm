package CloudDeploy::CommandLine::Undeploy {
  use MooseX::App;
  use CCfnX::Deployment;
  use CloudDeploy::Utils;
  use CloudDeploy::DeploymentCollection;
  use Term::ANSIColor;
  use Moose::Util::TypeConstraints qw/enum/;

  parameter deployment => (is => 'ro', isa => 'Str');
  option comments => (is => 'ro', isa => 'Str|Undef', documentation => "Comments to include with deployment");
  option mode => (
    is => 'ro', 
    isa=> enum([ qw/cfn deployment_engine/ ]),
    documentation => "Whether to activate the new deployment engine or not. Needed for all non CloudFormation related deployments. One of: cfn, deployment_engine",
    default=>'cfn'
  );

  sub run {
    my ($self) = @_;

    if($self->mode eq 'cfn'){
      my $deployer = CCfnX::Deployment->new_with_roles(
        { name => $self->deployment,
          account => $ENV{CPSD_AWS_ACCOUNT},
          access_key => $ENV{AWS_ACCESS_KEY_ID},
          secret_key => $ENV{AWS_SECRET_ACCESS_KEY},
        },
        'CCfnX::CloudFormationDeployer', 'CCfnX::PersistentDeployment'
      );

      # Initialize deployment from MongoDB
      $deployer->get_from_mongo;
      $deployer->comments($self->comments);

      # Do not remove the eval! This is required to catch exceptions when stack does not exist on AWS. 
      # If you cancel a deployment or are waiting for a stack deletion, at one point the stack won't
      # exist and we need to catch the exception to carry on anyway without dying.
      my $stack;
      eval {
        $stack = $deployer->cfn->DescribeStacks(StackName => $deployer->name)->Stacks->[0];
      };

      if (defined $stack) {
        my $resources;
        eval {
          $resources = $deployer->cfn->ListStackResources(StackName => $deployer->name);
        };
        if ($@){
          die "CloudFormation threw an error trying to describe stack resources. Review stack status and try again";
        }

        print color('bold red'),
        "\nWARNING: You are about to delete ALL resources from this stack on AWS!\n\n",
        color('reset');
        print color('bold yellow'), "Resources included in this stack:\n\n";

        foreach my $resource (@{ $resources->StackResourceSummaries }) {
          print $resource->LogicalResourceId, "  (", $resource->ResourceType, ")\n";
        }

        print color('bold red'), "\nType the stack name to confirm you want to delete ALL resources: ";
        chomp(my $input=<STDIN>);
        print color('reset'), "\n";

        if ($deployer->name ne $input) {
          die "Name not matched. Aborting delete stack.\n";
        }
      }

      $deployer->undeploy;
    } elsif ($self->mode eq 'deployment_engine') {
      
      my $module = load_class($self->deployment);
      my $obj = $module->{class}->new(params => $module->{params_class}->new_with_options(argv => $self->extra_argv));
      my $deployer = $obj->get_deployer({
        account    => $ENV{CPSD_AWS_ACCOUNT},
      },'CCfnX::DeploymentEngine');
      
      $deployer->undeploy;
    }

  }
}

1;
