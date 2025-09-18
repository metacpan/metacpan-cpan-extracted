package App::FargateStack::Logs;

use strict;
use warnings;

use App::FargateStack::Constants;
use App::FargateStack::Builder::Utils qw(log_die normalize_time_range);
use App::Logs;

use CLI::Simple::Constants qw(:booleans);

use Carp;
use Data::Dumper;
use English qw(no_match_vars);
use File::Basename qw(basename);
use Date::Parse qw(str2time);
use Term::ANSIColor;
use Text::ASCIITable::EasyTable;

use Role::Tiny;

########################################################################
sub cmd_logs {
########################################################################
  my ($self) = @_;

  my ( $config, $tasks ) = $self->common_args(qw(config tasks));
  my ( $task_name, $start, $end ) = $self->get_args;

  $task_name //= $self->get_default_task_name;

  $self->check_task($task_name);
  my $task = $tasks->{$task_name};

  my ( $start_time, $end_time ) = normalize_time_range( $start, $end );

  if ($start_time) {
    $start_time = int $start_time;

    if ($end_time) {
      $end_time = int $end_time;
    }
  }

  my $logs = $self->fetch_logs;

  my $log_group_name    = $config->{log_group}->{name};
  my $log_stream_prefix = sprintf '%s/%s', $config->{app}->{name}, $task_name;

  my %base_args = (
    '--log-group-name'         => $log_group_name,
    '--log-stream-name-prefix' => $log_stream_prefix,
    ( $start_time ? ( '--start-time' => $start_time ) : () ),
    ( $end_time   ? ( '--end-time'   => $end_time )   : () ),
  );

  my $events = $logs->command( 'filter-log-events' => [%base_args] );

  if ( !$events ) {
    croak sprintf "ERROR: could not get log events for log group: [%s], prefix: [%s]\n%s",
      $log_group_name, $log_stream_prefix, $logs->get_error;
  }

  my $log_events = $events->{events} // [];

  my $next_timestamp = $start_time // 0;

  if ( @{$log_events} ) {
    $self->show_log_events($events);
    $next_timestamp = ( sort map { $_->{timestamp} } @{$log_events} )[-1];
  }
  elsif ( !$self->get_log_wait ) {
    croak sprintf "ERROR: no log events found for [%s] with prefix [%s]", $log_group_name, $log_stream_prefix;
  }

  while ( $self->get_log_wait ) {
    sleep $self->get_log_poll_time;

    my @poll_args = (
      '--log-group-name'         => $log_group_name,
      '--log-stream-name-prefix' => $log_stream_prefix,
      '--start-time'             => $next_timestamp + 1,
    );

    $events = $logs->command( 'filter-log-events' => \@poll_args );

    if ( !$events ) {
      $self->log_warn( 'WARNING: failed to poll logs: %s', $logs->get_error );
      sleep $self->get_log_poll_time;
      next;
    }

    last if !$events;

    my $polled = $events->{events} // [];

    if ( @{$polled} ) {
      $self->show_log_events($events);
      $next_timestamp = ( sort map { $_->{timestamp} } @{$polled} )[-1];
    }
  }

  return $SUCCESS;
}

########################################################################
sub show_log_events {
########################################################################
  my ( $self, $events ) = @_;

  foreach my $e ( @{ $events->{events} } ) {
    my ( $timestamp, $message ) = @{$e}{qw(timestamp message)};
    $timestamp = $self->get_log_time ? scalar localtime $timestamp / 1000 : $EMPTY;

    print {*STDOUT} sprintf "%s - %s\n", $self->get_color ? colored( $timestamp, 'green' ) : $timestamp, $message;
  }

  return;
}

########################################################################
sub find_task_log_stream {
########################################################################
  my ( $self, $task_name ) = @_;

  my ( $config, $cluster ) = $self->common_args(qw(config cluster));

  my $cluster_name = $cluster->{name};

  my $ecs = $self->get_ecs;

  my $query = 'tasks[].{task_name: overrides.containerOverrides[0].name}[0].task_name';

  my $task_list = $ecs->list_tasks( $cluster_name, 'taskArns' );
  my $stream_name;

  foreach my $task_arn ( @{$task_list} ) {
    my $running_task_name = $ecs->describe_tasks( $cluster_name, $task_arn, $query );
    if ( $running_task_name eq $task_name ) {
      $stream_name = sprintf '%s/%s/%s', $config->{app}->{name}, $task_name, basename($task_arn);
      last;
    }
  }

  croak sprintf
    "ERROR: no log stream found for container [%s] -- the task may not be running or may not have started logging yet.\n",
    $task_name
    if !$stream_name;

  return $stream_name;
}

1;
