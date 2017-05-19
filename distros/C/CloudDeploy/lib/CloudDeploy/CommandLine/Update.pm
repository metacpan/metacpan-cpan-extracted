package CloudDeploy::CommandLine::Update {
  use MooseX::App;  
  use CloudDeploy::Utils;
  use CloudDeploy::DeploymentCollection;
  use Moose::Util::TypeConstraints qw/enum/;

  parameter deployment => (is => 'ro', isa => 'Str', required => 1);

  option comments => (is => 'ro', isa => 'Str|Undef', documentation => "Comments to include with deployment");

  option class => (
    is => 'ro',
    isa => 'Str',
    documentation => 'Override the class that is read from the database. Use with care: the new class should be able to accept the same parameters as the old class'
  );

  option mode => (
    is => 'ro', 
    isa=> enum([ qw/cfn deployment_engine/ ]),
    documentation => "Whether to activate the new deployment engine or not. Needed for all non CloudFormation related deployments. One of: cfn, deployment_engine",
    default=>'cfn'
  );

  option no_version_control => (
    is => 'ro',
    isa => 'Bool',
    documentation => "DANGEROUS!!! Disables stack version control. This will bypass all attempts of clouddeploy detecting other people's updates while you are working",
    default => 0,
  );

  sub run {
    my ($self) = @_;    

    if( $self->mode eq 'cfn' ) {
      my $deployments = CloudDeploy::DeploymentCollection->new(account => $ENV{'CPSD_AWS_ACCOUNT'});
      my $deploy      = $deployments->get_deployment($self->deployment);

      my $class = (defined $self->class) ? $self->class : $deploy->type;

      my $module = load_class($class);

      my @attached =
      map { $_->name }
      grep { $_->does('Attached') }
      $module->{params_class}->meta->get_all_attributes;

      my $params = $deploy->params;
      delete $params->{ $_ } for (@attached);

      my $merged_params = $module->{params_class}->new_with_options(%{ $params }, update => 1, argv => $self->extra_argv);

      my $obj = $module->{class}->new(params => $merged_params);

      my $deployer = $obj->get_deployer({
          access_key => $ENV{AWS_ACCESS_KEY_ID},
          secret_key => $ENV{AWS_SECRET_ACCESS_KEY},
          account    => $ENV{CPSD_AWS_ACCOUNT},
          comments   => $self->comments,
        },'CCfnX::CloudFormationDeployer', 'CCfnX::PersistentDeployment');

      if ($self->no_version_control) {
        $deployer->reset_stack_version;
      }
      else {
        # Will not let execution continue if version control doesn't find this
        # update to be safe
        $deployer->assert_stack_version_ok;
      }

      $deployer->redeploy;
      
    } elsif ($self->mode eq 'deployment_engine') {

      my $module = load_class($self->deployment);
      my $obj = $module->{class}->new(params => $module->{params_class}->new_with_options(argv => $self->extra_argv));

      my $deployer = $obj->get_deployer({
          account    => $ENV{CPSD_AWS_ACCOUNT},
          comments   => $self->comments,
        },'CCfnX::DeploymentEngine');

      $deployer->redeploy;
    }
  }

}

1;
