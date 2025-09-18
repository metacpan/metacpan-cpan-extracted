package App::FargateStack::Builder::LogGroup;

use strict;
use warnings;

use Carp;
use Data::Dumper;
use English qw(-no_match_vars);

use App::FargateStack::Constants;

use Role::Tiny;

########################################################################
sub build_log_group {
########################################################################
  my ($self) = @_;

  my ( $config, $tasks, $dryrun ) = $self->common_args(qw(config tasks dryrun));

  $config->{log_group} //= {};
  $config->{log_group}->{name} //= $self->create_default('log-group');

  my $logs = $self->fetch_logs;

  my $log_group = $logs->log_group_exists( $config->{log_group}->{name} );

  if ($log_group) {
    my ( $arn, $name, $retention_days ) = @{$log_group}{qw(logGroupArn logGroupName retentionInDays)};

    $config->{log_group}->{name} = $name;  # just in case

    $self->log_info( 'logs: [%s] exists...%s', $name, 'skipping' );

    $self->inc_existing_resources( log_group => $arn );

    if ( exists $config->{log_group}->{retention_days} && $config->{log_group}->{retention_days} ) {
      if ( $retention_days != $config->{log_group}->{retention_days} ) {
        $self->log_warn( 'logs: [%s] retention policy has changed...will be updated...%s', $name, $dryrun );
        $self->inc_required_resources( logs => sprintf 'update retention days to %s', $config->{log_group}->{retention_days} );
        if ( !$dryrun ) {
          $logs->put_retention_policy( $name, $config->{log_group}->{retention_days} );
        }
      }
    }
    else {
      $self->log_error('logs: missing log retention policy. Logs will be stored indefinitely!');

      if ($retention_days) {
        $self->log_error( 'logs: retention policy for [%s] will be deleted...%s', $name, $dryrun );
        $self->inc_required_resources( logs => sprintf 'delete retention policy' );
        if ( !$dryrun ) {
          $logs->delete_retention_policy($name);
        }
      }
    }

    return;
  }

  my $log_group_name = $config->{log_group}->{name};

  $self->log_warn( 'logs: [%s] will be created...%s', $log_group_name, $dryrun );

  $self->inc_required_resources(
    log_group => sub {
      my ($dryrun) = @_;
      return $dryrun ? 'arn:???:' . $log_group_name : $config->{log_group}->{arn};
    }
  );

  return
    if $dryrun;

  $self->log_warn( 'logs: creating [%s]...', $log_group_name );

  my $result = $logs->create_log_group($log_group_name);
  $logs->check_result( message => 'ERROR: could not create group: [%s]', $log_group_name );

  $config->{log_group}->{arn}  = $result->{logGroupArn};
  $config->{log_group}->{name} = ( split /:/xsm, $result->{logGroupArn} )[-1];

  my $retention_days = $config->{log_group}->{retention_days} //= $DEFAULT_LOG_RETENTION_DAYS;
  $config->{log_group}->{retention_days} = $retention_days;

  $self->log_warn( 'logs: setting log retention days to [%s] for [%s]', $retention_days, $log_group_name );
  $logs->put_retention_policy( $log_group_name, $retention_days );

  $logs->check_result( message => 'ERROR: could not set retention policy for: [%s]', $log_group_name );

  return $TRUE;
}

########################################################################
sub add_log_group_policy {
########################################################################
  my ($self) = @_;

  my $log_group = $self->get_config->{log_group} // {};

  my $arn = $log_group->{arn} // q{};

  return {
    Effect   => 'Allow',
    Action   => [qw(logs:CreateLogStream logs:PutLogEvents logs:CreateLogGroup)],
    Resource => [ $arn, $arn . ':log-stream:*' ],
  };
}

1;
