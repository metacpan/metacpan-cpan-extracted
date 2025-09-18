package App::Logs;

# ECS logging utilities for CloudWatch

use strict;
use warnings;

use App::FargateStack::Constants;
use Carp;
use Data::Dumper;
use List::Util qw(any);

use Role::Tiny::With;
with 'App::AWS';

use parent qw(App::Command);

__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_accessors(qw(log_group_name log_stream_name region profile));

########################################################################
sub describe_log_groups {
########################################################################
  my ( $self, $log_group_name, $query ) = @_;

  $log_group_name //= $self->get_log_group_name;

  return $self->command( 'describe-log-groups' =>
      [ $log_group_name ? ( '--log-group-name-prefix' => $log_group_name ) : (), $query ? ( '--query' => $query ) : () ] );
}

########################################################################
sub delete_log_group {
########################################################################
  my ( $self, $log_group_name, $query ) = @_;

  $log_group_name //= $self->get_log_group_name;

  return $self->command( 'delete-log-group' =>
      [ $log_group_name ? ( '--log-group-name' => $log_group_name ) : (), $query ? ( '--query' => $query ) : () ] );
}

########################################################################
sub log_group_exists {
########################################################################
  my ( $self, $log_group_name ) = @_;

  $log_group_name //= $self->get_log_group_name;

  # Check if log group exists already
  my $result = $self->describe_log_groups( $log_group_name, 'logGroups' );

  return
    if !$result || !@{$result};

  return $result->[0];
}

########################################################################
sub create_log_group {
########################################################################
  my ( $self, $log_group_name ) = @_;

  $log_group_name //= $self->get_log_group_name;

  my $log_group = $self->log_group_exists($log_group_name);

  return $log_group
    if $log_group;

  $self->command( 'create-log-group' => [ '--log-group-name' => $log_group_name, ] );

  croak sprintf "could not create log group %s\n%s", $log_group_name, $self->get_error
    if $self->get_error;

  return $self->log_group_exists($log_group_name);
}

########################################################################
sub get_log_events {
########################################################################
  my ( $self, $log_group, $log_stream, $query ) = @_;

  $log_stream //= $self->get_log_stream_name;
  $log_group  //= $self->get_log_group_name;

  return $self->command(
    'get-log-events' => [
      '--log-group-name' => $log_group,
      '--log-stream'     => $log_stream,
      $query ? ( '--query' => $query ) : ()
    ]
  );
}

########################################################################
sub get_next_log_events {
########################################################################
  my ( $self, $token ) = @_;

  my $log_stream = $self->get_log_stream_name;

  my $log_group = $self->get_log_group_name;

  croak "set log_stream_name and log_group_name first\n"
    if !$log_stream || !$log_group;

  croak "usage: get_next_log_events(token)\n"
    if !$token;

  return $self->command(
    'get-log-events' => [
      '--log-group-name' => $log_group,
      '--log-stream'     => $log_stream,
      '--next-token'     => $token,
    ]
  );
}

########################################################################
sub put_retention_policy {
########################################################################
  my ( $self, $log_group, $retention_days ) = @_;

  croak "ERROR: %s is not a valid retention period\n"
    if !any { $retention_days == $_ } @{$CLOUDWATCH_LOGS_RETENTION_DAYS};

  return $self->command(
    'put-retention-policy' => [
      '--log-group-name'    => $log_group,
      '--retention-in-days' => $retention_days,
    ]
  );
}

########################################################################
sub delete_retention_policy {
########################################################################
  my ( $self, $log_group ) = @_;

  return $self->command( 'delete-retention-policy' => [ '--log-group-name' => $log_group, ] );
}

1;
