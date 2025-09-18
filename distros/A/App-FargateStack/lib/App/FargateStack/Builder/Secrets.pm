package App::FargateStack::Builder::Secrets;

use strict;
use warnings;

use App::FargateStack::Builder::Utils qw(log_die);
use App::FargateStack::Constants;
use App::SecretsManager;
use Carp;
use Data::Dumper;
use English qw(-no_match_vars);
use File::Basename qw(basename);

use Role::Tiny;

########################################################################
sub add_secrets {
########################################################################
  my ( $self, $task ) = @_;

  return
    if !$task->{secrets};

  require App::SecretsManager;

  my $secrets_manager = App::SecretsManager->new( $self->get_global_options );

  my @secrets;

  foreach my $secret ( @{ $task->{secrets} } ) {
    my ( $path, $env_name, $secret_arn );

    if ( !$self->get_cache || !ref $secret ) {
      ($secret) = ref $secret ? keys %{$secret} : $secret;

      ( $path, $env_name ) = split /:/xsm, $secret;

      my $secret_name = basename($path);
      $env_name = uc( defined $env_name ? $env_name : $secret_name );

      $secret_arn = $secrets_manager->find_secret_arn($path);

      log_die( $self, 'Secret not found in Secrets Manager: %s (env var: %s)', $path, $env_name )
        if !$secret_arn;
    }
    else {
      ( $secret, $secret_arn ) = %{$secret};
      ( $path, $env_name ) = split /:/xsm, $secret;
    }

    log_die( $self, 'secret value must be path:env-name, not %s, example: /mysql/password:DB_PASSWORD', $secret )
      if !$env_name || !$path;

    push @secrets, { name => $env_name, valueFrom => $secret_arn };
  }

  $self->set_secrets( \@secrets );  # adding new secrets should
                                    # trigger updating policy
  return \@secrets;
}

########################################################################
sub add_secrets_policy {
########################################################################
  my ( $self, $secrets ) = @_;

  return if !$secrets || !@{$secrets};

  my @secret_arns = map { $_->{valueFrom} } @{$secrets};

  return {
    'Effect'   => 'Allow',
    'Action'   => 'secretsmanager:GetSecretValue',
    'Resource' => \@secret_arns,
  };
}

1;
