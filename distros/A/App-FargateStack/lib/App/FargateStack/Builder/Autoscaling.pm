package App::FargateStack::Builder::Autoscaling;

use strict;
use warnings;

use Carp;
use CLI::Simple::Constants qw(:booleans);
use Data::Dumper;
use English qw(-no_match_vars);
use List::Util qw(none any uniq pairs max);
use JSON;

use App::FargateStack::AutoscalingConfig;
use App::FargateStack::Constants;
use App::FargateStack::Builder::Utils qw(log_die dmp choose);

use Role::Tiny;

########################################################################
sub build_autoscaling {
########################################################################
  my ($self) = @_;

  my ( $config, $tasks ) = $self->common_args(qw(config tasks));

  foreach my $task_name ( keys %{$tasks} ) {
    # autoscaling only applies to http & daemon tasks
    next if $tasks->{$task_name} =~ /^(?:task|scheduled)$/xsm;

    next
      if !exists $tasks->{$task_name}->{autoscaling};

    $self->_build_autoscaling($task_name);
  }

  return $SUCCESS;
}

########################################################################
sub _build_autoscaling {
########################################################################
  my ( $self, $task_name ) = @_;

  my $dryrun = $self->get_dryrun;

  my $task = $self->get_config->{tasks}->{$task_name};

  my $app_autoscaling = $self->fetch_application_autoscaling;

  my $policy_name = $self->create_default( 'autoscaling-policy-name', $task_name );

  my $autoscaling_config
    = eval { return App::FargateStack::AutoscalingConfig->new( config => $task->{autoscaling}, policy_name => $policy_name ); };

  log_die( $self, $EVAL_ERROR )
    if !$autoscaling_config || $EVAL_ERROR;

  my $resource_id = $self->_resource_id($task_name);

  ######################################################################
  # scheduled actions
  ######################################################################
  if ( $autoscaling_config->has_scheduled_action ) {
    $self->build_scheduled_actions(
      task               => $task,
      resource_id        => $resource_id,
      app_autoscaling    => $app_autoscaling,
      autoscaling_config => $autoscaling_config,
    );
  }

  my $scaling_policy = $app_autoscaling->describe_scaling_policies(
    service_namespace => 'ecs',
    policy_names      => $policy_name,
    query             => 'ScalingPolicies',
  );

  $app_autoscaling->check_result( message => 'ERROR: could not describe scaling policies for: [%s]', $resource_id );
  $scaling_policy = $scaling_policy->[0];

  return
    if !$autoscaling_config->get_cpu && !$autoscaling_config->get_requests;

  my $policy_configuration = $self->create_policy_configuration( $task_name, $autoscaling_config );

  if ( !$scaling_policy ) {
    $self->log_warn( 'autoscaling: policy: [%s] does not exist...will be created...%s', $policy_name, $dryrun );

    $self->inc_required_resources(
      'autoscaling:scaling-policy' => sub {
        my ($dryrun) = @_;

        return $dryrun ? 'arn:???' : $autoscaling_config->get_policy_arn;
      }
    );

    if ( !$dryrun ) {
      my $arn = $self->create_autoscaling_policy(
        app_autoscaling      => $app_autoscaling,
        resource_id          => $resource_id,
        min_capacity         => $autoscaling_config->get_min_capacity,
        max_capacity         => $autoscaling_config->get_max_capacity,
        policy_name          => $policy_name,
        policy_configuration => $policy_configuration,
      );

      $autoscaling_config->update( policy_arn => $arn );
    }

    return $TRUE;
  }

  my $current_policy = $scaling_policy->{TargetTrackingScalingPolicyConfiguration};

  my $diffs = $self->display_diffs( $policy_configuration, $current_policy );

  if ($diffs) {
    $self->log_error( "autoscaling: scaling policy: [%s] has changed:\n%s\n", $policy_name, $diffs );

    log_die( $self, 'autoscaling: aborting update...use --force to force update' )
      if !$self->get_force;

    $self->log_warn( 'autoscaling: scaling policy: [%s] will be updated...%s', $policy_name, $dryrun );

    if ( !$dryrun ) {
      my $arn = $self->create_autoscaling_policy(
        app_autoscaling      => $app_autoscaling,
        resource_id          => $resource_id,
        min_capacity         => $autoscaling_config->get_min_capacity,
        max_capacity         => $autoscaling_config->get_max_capacity,
        policy_name          => $policy_name,
        policy_configuration => $policy_configuration,
      );

      $autoscaling_config->update( policy_arn => $arn );  # the arn should not change, but why not?
    }
  }
  else {
    $self->log_info( 'autoscaling: scaling policy: [%s] has not changed...skipping', $policy_name );
    $self->inc_existing_resources( autoscaling => $autoscaling_config->get_policy_arn );
  }

  return $TRUE;
}

########################################################################
sub _resource_id {
########################################################################
  my ( $self, $task_name ) = @_;

  return sprintf 'service/%s/%s', $self->get_config->{cluster}->{name}, $task_name;
}

########################################################################
sub create_policy_configuration {
########################################################################
  my ( $self, $task_name, $autoscaling_config ) = @_;

  my $scale_in_cooldown  = $autoscaling_config->get_scale_in_cooldown;
  my $scale_out_cooldown = $autoscaling_config->get_scale_out_cooldown;

  my $metric       = $autoscaling_config->get_metric;
  my $metric_value = $autoscaling_config->get_metric_value;

  my $predefined_metric_type = {
    cpu      => 'ECSServiceAverageCPUUtilization',
    requests => 'ALBRequestCountPerTarget',
  }->{$metric};

  my $resource_label = $metric eq 'requests' ? $self->create_resource_label($task_name) : q{};

  my $predefined_metric_specficiation = {
    PredefinedMetricType => $predefined_metric_type,
    $resource_label ? ( ResourceLabel => $resource_label ) : ()
  };

  my $policy_configuration = {
    TargetValue                   => $metric_value,
    PredefinedMetricSpecification => $predefined_metric_specficiation,
    ScaleOutCooldown              => $scale_out_cooldown,
    ScaleInCooldown               => $scale_in_cooldown,
  };

  $self->log_debug(
    sub {
      return Dumper(
        [ policy_configuration => $policy_configuration,
          metric               => $metric,
        ]
      );
    }
  );

  return $policy_configuration;
}

########################################################################
sub create_resource_label {
########################################################################
  my ( $self, $task_name ) = @_;

  my $config = $self->get_config;

  my $task = $config->{tasks}->{$task_name};

  my $target_arn = $task->{target_group_arn};

  my ($tg_part) = $target_arn =~ /(targetgroup\/.*)$/xsm;

  my $alb_arn = $config->{alb}->{arn};
  my ($alb_part) = $alb_arn =~ /loadbalancer\/(.*)$/xsm;

  return sprintf '%s/%s', $alb_part, $tg_part;
}

########################################################################
sub create_autoscaling_policy {
########################################################################
  my ( $self, %args ) = @_;

  my ( $resource_id, $min_capacity, $max_capacity, $policy_name, $policy_configuration, $app_autoscaling )
    = @args{qw(resource_id min_capacity max_capacity policy_name policy_configuration app_autoscaling)};

  my $query = sprintf 'ScalableTargets[?ResourceId == `%s`]|[0]', $resource_id;

  my $scalable_targets = $app_autoscaling->describe_scalable_targets( service_namespace => 'ecs', query => $query );
  $app_autoscaling->check_result( message => 'ERROR: could not describe scalable targets for: [%s]', $resource_id );

  if ( !$scalable_targets ) {

    $app_autoscaling->register_scalable_target(
      service_namespace  => 'ecs',
      scalable_dimension => 'ecs:service:DesiredCount',
      resource_id        => $resource_id,
      min_capacity       => $min_capacity,
      max_capacity       => $max_capacity,
    );

    $app_autoscaling->check_result( message => 'ERROR: could not register scalable target for: [%s]', $resource_id );
  }

  my $scaling_policy = $app_autoscaling->put_scaling_policy(
    policy_name          => $policy_name,
    service_namespace    => 'ecs',
    scalable_dimension   => 'ecs:service:DesiredCount',
    resource_id          => $resource_id,
    policy_type          => 'TargetTrackingScaling',
    policy_configuration => encode_json($policy_configuration),
  );

  $app_autoscaling->check_result( message => 'ERROR: could not create scaling policy target for: [%s]', $resource_id );

  return $scaling_policy->{PolicyARN};
}

########################################################################
sub build_scheduled_actions {
########################################################################
  my ( $self, %args ) = @_;

  my ( $task, $resource_id, $app_autoscaling, $autoscaling_config )
    = @args{qw(task resource_id app_autoscaling autoscaling_config)};

  my $dryrun = $self->get_dryrun;

  my $config = $self->get_config;

  my $parsed_actions = $autoscaling_config->get_scheduled_actions;

  ######################################################################
  # configured actions, could be new or existing
  ######################################################################
  my @actions = keys %{$parsed_actions};

  ######################################################################
  # fetch existing scheduled actions
  ######################################################################
  my $schedules = $app_autoscaling->describe_scheduled_actions( service_namespace => 'ecs' );
  $app_autoscaling->check_result( message => 'ERROR: could not describe scheduled actions' );

  my $scheduled_actions = { map { ( $_->{ScheduledActionName} => $_ ) } @{ $schedules->{ScheduledActions} // [] } };

  my @scheduled_action_names = keys %{$scheduled_actions};

  ######################################################################
  # collect new scheduled actions...
  ######################################################################
  my %put_scheduled_actions;

  foreach my $action_name (@actions) {
    my $action = $parsed_actions->{$action_name};

    if ( none { $_ =~ /$action_name/xsm } @scheduled_action_names ) {
      $self->log_warn( 'autoscaling: schedule action: [%s] does not exist...will be created...%s', $action_name, $dryrun );

      $self->inc_required_resources( 'autoscaling:scheduled-action' => $action_name );

      $self->log_debug( sub { return Dumper( [ action => $action ] ) } );
      $put_scheduled_actions{$action_name} = $action;
      next;
    }

    my @existing_actions = grep { $_ =~ /$action_name/xsm } @scheduled_action_names;

    foreach (@existing_actions) {
      my $target_action = $scheduled_actions->{$_};

      my $min_capacity = $target_action->{ScalableTargetAction}->{MinCapacity};
      my $max_capacity = $target_action->{ScalableTargetAction}->{MaxCapacity};
      my $schedule     = $target_action->{Schedule};

      my $scale_type = $target_action->{ScheduledActionName} =~ /\-in\-/xsm ? 'ScaleIn' : 'ScaleOut';

      if ( $schedule eq $action->{$scale_type}->{Schedule}
        && $min_capacity == $action->{$scale_type}->{Action}->{MinCapacity}
        && $max_capacity == $action->{$scale_type}->{Action}->{MaxCapacity} ) {

        $self->log_info( 'autoscaling: scheduled action: [%s] for [%s] has not changed...skipping', $action_name, $scale_type );
        $self->inc_existing_resources(
          'autoscaling:scheduled' => [
            join "\n",
            sprintf '%s min_capacity:%s max_capacity: %s', $target_action->{Schedule},
            $target_action->{ScalableTargetAction}->{MinCapacity},
            $target_action->{ScalableTargetAction}->{MaxCapacity}

          ]
        );

      }
      else {
        $self->log_warn( 'autoscaling: scheduled action: [%s] for [%s] has changed...will be updated...%s',
          $action_name, $scale_type, $dryrun );
        $self->inc_required_resources( 'autoscaling:scheduled-action' => $action_name );
        $put_scheduled_actions{$action_name} = $action;
      }
    }
  }

  ######################################################################
  # Sanity check the top-level metric based capacities and scheduled actions min/max capacities
  ######################################################################
  if ( !$autoscaling_config->get_cpu && !$autoscaling_config->get_requests ) {
    ####################################################################
    # Rule: 1 If no metric scaling action exists, min/max should be equal
    ####################################################################
    my $error_msg = <<'END_OF_ERROR_MESSAGE';
ERROR: Configuration for schedule '%s' is inconsistent.
It defines a min_capacity (%d) that is different from its max_capacity (%d)
for its 'in' period, but no metric-based scaling policy (cpu or requests) has been defined.
Without a metric policy, the service can only scale to the minimum capacity and will never reach the maximum.
To resolve this, please set min_capacity and max_capacity to the same value for a fixed-capacity schedule.
END_OF_ERROR_MESSAGE

    foreach my $p ( pairs %put_scheduled_actions ) {
      if ( $p->[1]->{ScaleOut}->{Action}->{MinCapacity} != $p->[1]->{ScaleOut}->{Action}->{MaxCapacity} ) {
        $self->log_die(
          $error_msg, $p->[0],
          $p->[1]->{ScaleOut}->{Action}->{MinCapacity},
          $p->[1]->{ScaleOut}->{Action}->{MaxCapacity}
        );
      }

      if ( $p->[1]->{ScaleIn}->{Action}->{MinCapacity} != $p->[1]->{ScaleIn}->{Action}->{MaxCapacity} ) {
        $self->log_die(
          $error_msg, $p->[0],
          $p->[1]->{ScaleIn}->{Action}->{MinCapacity},
          $p->[1]->{ScaleIn}->{Action}->{MaxCapacity}
        );
      }
    }

    # presumbably existing schedules are sane...but we will check anyway
    foreach (@scheduled_action_names) {
      my $min_capacity = $scheduled_actions->{$_}->{ScalableTargetAction}{MinCapacity};
      my $max_capacity = $scheduled_actions->{$_}->{ScalableTargetAction}{MaxCapacity};

      log_die( $self, $error_msg, $min_capacity, $max_capacity )
        if $min_capacity != $max_capacity;
    }
  }
  else {
    ####################################################################
    # Rule 2: top-level max_capacity >= scheduled action max capacity
    ####################################################################
    my $error_msg = <<'END_OF_ERROR_MESSAGE';
ERROR: Configuration for a scheduled action is inconsistent.
It defines a max_capacity (%d) that is greater than the top-level max_capacity (%d).
In App::FargateStack, the top-level 'max_capacity' is the absolute ceiling for the service at all times.
To resolve this, please set the top-level 'max_capacity' to the highest value your service should ever scale to (%d or greater).
END_OF_ERROR_MESSAGE

    my $min_capacity = $autoscaling_config->get_min_capacity;
    my $max_capacity = $autoscaling_config->get_max_capacity;

    # new action max takes precendent over existing action max capacity
    my $max_scheduled_capacity;

    foreach ( uniq @scheduled_action_names, keys %put_scheduled_actions ) {
      $max_scheduled_capacity
        = max exists $put_scheduled_actions{$_}
        ? $put_scheduled_actions{$_}{ScaleOut}{Action}{MaxCapacity}
        : $scheduled_actions->{$_}->{ScalableTargetAction}{MaxCapacity};
    }

    if ( $max_capacity < $max_scheduled_capacity ) {
      $self->log_die( $error_msg, $max_scheduled_capacity, $max_capacity, $max_scheduled_capacity );
    }
  }

  if ( !$dryrun ) {
    foreach my $p ( pairs %put_scheduled_actions ) {
      my ( $action_name, $action ) = @{$p};

      $self->put_scheduled_action(
        name        => $action_name . '-out',
        resource_id => $resource_id,
        action      => $action->{ScaleOut}->{Action},
        schedule    => $action->{ScaleOut}->{Schedule},
      );

      $self->put_scheduled_action(
        name        => $action_name . '-in',
        resource_id => $resource_id,
        action      => $action->{ScaleIn}->{Action},
        schedule    => $action->{ScaleIn}->{Schedule},
      );
    }
  }

  return;
}

=pod
 aws application-autoscaling put-scheduled-action \
    --service-namespace ecs \
    --resource-id service/app-fargatestack-website-cluster/apache \
    --scalable-dimension ecs:service:DesiredCount \
    --schedule 'cron(0 18 ? *  MON-FRI *)' \
    --scheduled-action-name foo \
    --scalable-target-action '{"MinCapacity":1, "MaxCapacity":2}'

=cut

########################################################################
sub put_scheduled_action {
########################################################################
  my ( $self, %args ) = @_;

  my ( $action_name, $resource_id, $schedule, $action ) = @args{qw(name resource_id schedule action)};

  my $app_autoscaling = $self->fetch_application_autoscaling;

  my $result = $app_autoscaling->put_scheduled_action(
    resource_id            => $resource_id,
    schedule               => $schedule,
    scalable_target_action => encode_json($action),
    name                   => $self->create_default( 'scheduled-action-name', $action_name ),
  );

  $app_autoscaling->check_result( message => 'ERROR: could not put scheduled event: [%s]', $action_name );

  return $result;
}

1;
