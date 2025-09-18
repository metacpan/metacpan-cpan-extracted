package App::FargateStack::Autoscaling;

use strict;
use warnings;

use App::FargateStack::AutoscalingConfig;
use App::FargateStack::Constants;
use App::FargateStack::Builder::Utils qw(dmp choose confirm);
use Carp;
use CLI::Simple::Constants qw(:booleans);
use List::Util qw(none);

use Data::Dumper;
use English qw(no_match_vars);

use Role::Tiny;

########################################################################
sub cmd_delete_scheduled_action {
########################################################################
  my ($self) = @_;

  my @all_scheduled_actions = $self->get_scheduled_action_names;

  croak "ERROR: there are no scheduled actions in your configuration\n"
    if !@all_scheduled_actions;

  my ($scheduled_action) = $self->get_args;

  croak "ERROR: usage: delete-scheduled-action scheduled-action-name\n"
    if !$scheduled_action && @all_scheduled_actions != 1;

  $scheduled_action = $all_scheduled_actions[0];

  croak sprintf "ERROR: no scheduled action: %s in configuration\n", $scheduled_action
    if none { $scheduled_action eq $_ } $self->get_scheduled_action_names;

  my $config = $self->get_config;

  my $app_autoscaling = $self->fetch_application_autoscaling;

  foreach my $task ( keys %{ $config->{tasks} } ) {
    next if !exists $config->{tasks}->{$task}->{autoscaling};
    next if !exists $config->{tasks}->{$task}->{autoscaling}->{scheduled}->{$scheduled_action};

    my $resource_id = $self->_resource_id($task);

    if ( !$self->get_force ) {
      if ( !confirm( 'Are you sure you want to deleted scheduled action "%s"', $scheduled_action ) ) {
        print {*STDOUT} "Aborting...\n";
        return $SUCCESS;
      }
    }

    foreach (qw(in out)) {
      my $scheduled_action_name = $self->create_default( 'scheduled-action-name', $scheduled_action . qw{-} . $_ );
      $app_autoscaling->delete_scheduled_action(
        service_namespace     => 'ecs',
        scheduled_action_name => $scheduled_action_name,
        resource_id           => $resource_id,
        scalable_dimension    => 'ecs:service:DesiredCount',
      );

      $app_autoscaling->check_result( message => 'ERROR: could not delete scheduled action: [%s]', $scheduled_action_name );
    }

    delete $config->{tasks}->{$task}->{autoscaling}->{scheduled}->{$scheduled_action};

    if ( !keys %{ $config->{tasks}->{$task}->{autoscaling}->{scheduled} } ) {
      delete $config->{tasks}->{$task}->{autoscaling}->{scheduled};
    }
  }

  $self->update_config;

  return $SUCCESS;
}

########################################################################
sub cmd_delete_autoscaling_policy {
########################################################################
  my ($self) = @_;

  my ( $config, $tasks ) = $self->common_args(qw(config tasks));

  my ($task_name) = $self->get_default_service_name;

  croak sprintf "usage: delete-autoscaling-policy task-name\n"
    if !$task_name;

  my $app_autoscaling = $self->fetch_application_autoscaling;

  croak sprintf "ERROR: no scaling policy defined for: [%s]\n", $task_name
    if !exists $config->{tasks}->{$task_name}->{autoscaling}->{policy_name};

  my $resource_id = $self->_resource_id($task_name);
  my $policy_name = $config->{tasks}->{$task_name}->{autoscaling}->{policy_name};

  if ( !$self->get_force ) {
    if ( !confirm( 'Are you sure you want to delete scaling policy: [%s]', $policy_name ) ) {
      print {*STDOUT} "Aborting...\n";
      return $SUCCESS;
    }
  }

  $app_autoscaling->delete_scaling_policy(
    resource_id        => $resource_id,
    policy_name        => $policy_name,
    scalable_dimension => 'ecs:service:DesiredCount',
    service_namespace  => 'ecs',
  );

  $app_autoscaling->check_result(
    { message => 'ERROR: could not delete scaling policy: [%s]',
      params  => [$policy_name],
      regexp  => qr/no\sscaling\spolicy\sfound/xsmi
    }
  );

  foreach (qw(policy_arn policy_name cpu requests scale_in_cooldown scale_out_cooldown max_capacity min_capacity)) {
    delete $config->{tasks}->{$task_name}->{autoscaling}->{$_};
  }

  if ( !keys %{ $config->{tasks}->{$task_name}->{autoscaling} } ) {
    delete $config->{tasks}->{$task_name}->{autoscaling};
  }

  $self->update_config;

  return $SUCCESS;
}

########################################################################
sub _get_autoscaling_task_name {
########################################################################
  my ( $self, $tasks ) = @_;

  my (@args) = $self->get_args;

  my $possible_task_name = shift @args;

  return ( $possible_task_name, @args )
    if $tasks->{$possible_task_name};

  my ( $task_name, $err ) = grep { $tasks->{$_}->{type} =~ /^(daemon|https?)$/xsm } keys %{$tasks};

  croak "ERROR: You need to select which task to apply autoscaling to\n"
    if $err;

  return ( $task_name, $possible_task_name, @args );
}

########################################################################
sub cmd_add_scheduled_action {
########################################################################
  my ($self) = @_;

  my $tasks = $self->get_config->{tasks};

  my ( $task_name, @args ) = $self->_get_autoscaling_task_name($tasks);

  croak
    "usage: add-scheduled-action [task] name start-time end-time days min-capacity max-capacity (ex: 00:18 00:02 MON-FRI 2/1 2/2)\n"
    if @args != 6;

  my $schedule_name = shift @args;

  my $scheduled = $tasks->{$task_name}->{autoscaling}->{scheduled} // {};

  # plan will verify these values
  $scheduled->{$schedule_name} = {
    start_time   => $args[0],
    end_time     => $args[1],
    days         => $args[2],
    min_capacity => $args[3],
    max_capacity => $args[4],
  };

  my $autoscaling_config = App::FargateStack::AutoscalingConfig->new(
    config    => $tasks->{$task_name}->{autoscaling},
    task_name => $task_name
  );

  $self->update_config;

  print {*STDOUT} sprintf "Scheduled action: [%s] added to your configuration. Run plan to verify the configuration.\n",
    $schedule_name;

  return $SUCCESS;
}

########################################################################
sub cmd_add_scaling_policy {
########################################################################
  my ($self) = @_;

  my $tasks = $self->get_config->{tasks};

  my ( $task_name, @args ) = $self->_get_autoscaling_task_name($tasks);

  croak
    "usage: add-scaling-policy [task] cpu|requests metric-value [min_capacity max_capacity [scale_out_cooldown scale_in_cooldown]]\n"
    if !( @args == 2 || @args == 4 || @args == 6 ) || $args[0] !~ /^(?:cpu|requests)$/xsm;

  my $autoscaling_config = App::FargateStack::AutoscalingConfig->new(
    config             => $tasks->{$task_name}->{autoscaling},
    task_name          => $task_name,
    metric             => sprintf( '%s:%s', @args[ 0, 1 ] ),
    min_capacity       => $args[2],
    max_capacity       => $args[3],
    scale_out_cooldown => $args[4],
    scale_in_cooldown  => $args[5],
    policy_name        => $self->create_default( 'autoscaling-policy-name', $task_name ),
  );

  print {*STDOUT} sprintf "Scaling policy: [%s] added to your configuration. Run plan to verify the configuration.\n",
    $autoscaling_config->get_policy_name;

  $self->update_config;

  return $SUCCESS;
}

1;
