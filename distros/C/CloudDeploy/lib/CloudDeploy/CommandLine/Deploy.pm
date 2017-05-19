package CloudDeploy::CommandLine::Deploy {
  use MooseX::App;  
  use CloudDeploy::Utils;
  use Moose::Util::TypeConstraints qw/enum/;

  parameter deploy_class => (is => 'ro', isa => 'Str', required => 1);
  option comments => (is => 'ro', isa => 'Str|Undef', documentation => "Comments to include with deployment");

  sub run {
    my ($self) = @_;

    my $module = load_class($self->deploy_class);
    my $obj = $module->{class}->new(params => $module->{params_class}->new_with_options(argv => $self->extra_argv));

    if ($obj->isa('CCfnX::MakeAMIBase')){
      die "Please make AMIs with imager";
    }

    # New deployment engine vs cfn deployer
    my $deployer;
    $deployer = $obj->get_deployer({
        access_key => $ENV{AWS_ACCESS_KEY_ID},
        secret_key => $ENV{AWS_SECRET_ACCESS_KEY},
        account    => $ENV{CPSD_AWS_ACCOUNT},
        comments   => $self->comments,
      },'CCfnX::CloudFormationDeployer', 'CCfnX::PersistentDeployment');

    $deployer->deploy;
  }
}

1;

