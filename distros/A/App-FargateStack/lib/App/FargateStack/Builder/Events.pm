package App::FargateStack::Builder::Events;

use strict;
use warnings;

use App::FargateStack::Builder::Utils qw(log_die);
use App::FargateStack::Constants;
use Carp;
use Data::Compare;
use Data::Dumper;
use English qw(-no_match_vars);
use JSON;

use Role::Tiny;

########################################################################
sub build_events {
########################################################################
  my ($self) = @_;

  my ( $config, $dryrun, $cluster, $tasks ) = $self->common_args(qw(config dryrun cluster tasks));

  my @events = grep { $tasks->{$_}->{type} eq 'task' && $tasks->{$_}->{schedule} } keys %{$tasks};

  if ( !@events ) {
    $self->log_info('events: no events to build');
    return;
  }

  $self->log_info( 'events: [%d] event(s) to build', scalar @events );

  $self->log_info('events: constructing IAM role for events...');

  $self->build_events_iam_role(@events);  # task names

  foreach my $task_name (@events) {
    $self->log_info( 'events: building event for: [%s]', $task_name );

    my $task = $tasks->{$task_name};

    # ok to be undef, as App::Events will provide default
    my $event_bus_name = $task->{event_bus_name};

    my $event = $self->fetch_events;

    my $schedule = $task->{schedule};

    if ( !$schedule ) {
      $self->log_warn( 'events: no schedule for task: [%s]...skipping', $task_name );
      return;
    }

    $self->log_info( 'events: found a schedule...validating schedule: [%s]', $schedule );

    my $valid_schedule = $event->validate_schedule($schedule);

    croak sprintf "ERROR: invalid schedule expression: %s\nSee: %s", $schedule, $EVENT_SCHEDULER_TYPE_URL
      if !$valid_schedule;

    my $rule_name = sprintf '%s-schedule', $task_name;

    if ( $valid_schedule ne $schedule ) {
      $self->log_warn( sprintf 'events: [%s] schedule modified [%s] automatically for you...', $schedule, $valid_schedule );

      $task->{schedule} = $valid_schedule;
      $schedule = $valid_schedule;
    }

    $self->log_info( 'events: checking if rule [%s] exists or schedule [%s] changed', $rule_name, $schedule );

    my $exists = $event->rule_exists( $rule_name, $schedule );

    my $rule_exists = $exists ? q{} : 'does not ';

    my $schedule_changed = $exists == -1 ? q {} : 'not ';

    my $level = $rule_exists ? 'warn' : 'info';
    $level = $schedule_changed ? 'info' : 'error';
    $level = "log_$level";

    $self->$level( 'events: rule [%s] %sexists and schedule [%s] has %schanged',
      $rule_name, $rule_exists, $schedule, $schedule_changed );

    if ( $exists == -1 || $self->taskdef_has_changed($task_name) ) {
      if ( !$dryrun ) {
        $self->log_error( 'events: attempting to delete rule in case target does not exist [%s]...%s', $rule_name, $dryrun );

        my $result = $event->delete_rule($rule_name);
        $event->check_result(
          message => 'could not delete rule: [%s]',
          params  => [$rule_name],
          regexp  => qr/has\stargets/xmsi
        );
      }
    }

    my $action = !$exists ? 'created' : 'replaced';

    if ( !$exists || ( $exists == -1 || $self->taskdef_has_changed($task_name) ) ) {

      $self->inc_required_resources( 'events:rule' => [$rule_name] );
      $self->get_logger->warn( sprintf 'events: [%s] rule will be %s...%s', $rule_name, $action, $dryrun );

      $self->log_warn( sprintf 'events: [%s] rule will be %s...%s', $rule_name, $action, $dryrun );

      if ( !$dryrun ) {
        $event->put_rule( rule_name => $rule_name, schedule => $schedule, state => $TRUE );
        $event->check_result( message => 'ERROR: could not create rule [%s]', $rule_name );
      }

      $self->get_logger->warn( sprintf 'events: [%s] rule %s successfully', $rule_name, $action );
    }
    else {
      $self->get_logger->info( sprintf 'events: rule [%s] exists...skipping', $rule_name );
      $self->inc_existing_resources( 'events:rule' => $rule_name );
    }

    $self->create_event_target($task_name);
  }

  return;
}

########################################################################
sub create_event_target {
########################################################################
  my ( $self, $task_name ) = @_;

  my ( $config, $dryrun, $tasks ) = $self->common_args(qw(config dryrun tasks));

  my $region = $self->get_region;

  my $account = $self->get_account;

  my $task = $tasks->{$task_name};

  my $events_role = $config->{events_role};

  my $task_definition_arn = $task->{arn} // $EMPTY;

  my @subnets = sort @{ $self->get_subnets->{private} // $self->get_subnets->{public} };

  my $security_group = $config->{security_groups}->{fargate}->{group_id};

  my $tags = $self->build_run_tags( $task_name => $task );

  my $target = [
    { Id            => $self->create_default( 'rule-id', $task_name ),
      Arn           => $config->{cluster}->{arn},
      RoleArn       => $events_role->{arn},
      EcsParameters => {
        Tags                 => $tags,
        TaskDefinitionArn    => $task_definition_arn,
        TaskCount            => 1,
        LaunchType           => 'FARGATE',
        Group                => 'schedule:' . $task_name,
        EnableECSManagedTags => JSON::true,
        EnableExecuteCommand => JSON::false,
        PropagateTags        => 'TASK_DEFINITION',
        NetworkConfiguration => {
          awsvpcConfiguration => {
            Subnets        => [ $subnets[0] ],
            SecurityGroups => [$security_group],
            AssignPublicIp => 'DISABLED'
          }
        }
      }
    }
  ];

  my $rule_name = $self->create_default( 'rule-name', $task_name );

  my $event = $self->fetch_events;

  my $current_target = $event->target_exists($rule_name);

  my $replace_target = $current_target ? $TRUE : $FALSE;

  # compare $target vs $current_target
  if ( $current_target && !Compare( $target->[0], $current_target ) ) {

    $self->display_diffs( $current_target, $target->[0], { style => 'Table', title => 'rule target differs' } );
    $replace_target = $TRUE;
  }

  $self->log_trace(
    sub {
      return Dumper(
        [ current_target      => $current_target,
          target              => $target,
          task_definition_arn => $task_definition_arn,
          replace_target      => $replace_target,
        ]
      );
    }
  );

  my $ecs_parameters = $current_target->{EcsParameters} // {};

  my $current_task_definition_arn = $ecs_parameters->{TaskDefinitionArn} // $EMPTY;

  if ( !$replace_target && $current_task_definition_arn && $current_task_definition_arn eq $task_definition_arn ) {
    $self->log_info( sprintf 'events: [%s] target exists...skipping', $task_name );
    $self->inc_existing_resources( 'events:target' => [$task_name] );

    return;
  }
  elsif ( $current_task_definition_arn && $current_task_definition_arn eq $task_definition_arn ) {
    $replace_target = -1;

    $self->log_warn( sprintf 'events: [%s] task ARNs differ [%s] <=> [%s]',
      $task_name, $current_task_definition_arn, $task_definition_arn );
  }

  my $action = $current_target ? 'replaced' : 'created';

  $self->log_warn( sprintf 'events: target [%s] will be %s...%s', $task_name, $action, $dryrun );

  $self->inc_required_resources( 'events:target' => [$task_name] );

  return
    if $dryrun;

  if ($current_target) {
    $self->log_warn( 'events: deleting target for rule [%s]...', $rule_name );
    $event->remove_targets( $rule_name, $self->create_default( 'rule-id', $task_name ) );
  }

  $self->log_warn( 'events: creating target for rule [%s]...', $rule_name );

  my $result = $event->put_targets( $rule_name, $target );
  $event->check_result(
    message => 'ERROR: could not create target [%s] for rule [%s]',
    params  => [ to_json( $target, { pretty => $TRUE } ), $rule_name ]
  );

  return;
}

########################################################################
sub build_events_iam_role {
########################################################################
  my ($self) = @_;

  my ( $config, $dryrun ) = $self->common_args(qw(config dryrun));

  my $iam = $self->fetch_iam;

  my $role_config = $config->{events_role} // {};

  my ( $role_name, $role_arn ) = $self->create_events_role();

  my $policy_name = $self->create_default( 'policy-name', 'events' );
  @{$role_config}{qw(name arn policy_name)} = ( $role_name, $role_arn, $policy_name );

  my $policy = $iam->get_role_policy( $role_name, $policy_name );

  my @statement = $self->add_events_policy();

  my $role_policy = {
    Version   => $IAM_POLICY_VERSION,
    Statement => \@statement,
  };

  if ( $policy && Compare( $policy, $role_policy ) ) {
    $self->log_info( 'iam:role-policy: policy [%s] for [%s] exists...%s',
      $policy_name, $role_name, $self->get_cache || 'skipping' );

    $self->inc_existing_resources( 'iam:role-policy' => [$policy_name] );

    return;
  }

  if ($policy) {
    $self->display_diffs( $policy, $role_policy, { title => 'event policy has changed' } );
  }

  $self->log_warn(
    'iam:role-policy: policy [%s] will be %s for [%s]...%s',
    $policy_name, ( $policy ? 'updated' : 'created' ),
    $role_name, $dryrun
  );

  $self->inc_required_resources( 'iam:policy' => [$policy_name] );

  return
    if $dryrun;

  $iam->put_role_policy( $role_name, $policy_name, $role_policy );
  $iam->check_result(
    message => 'ERROR: could not %s policy [%s] for [%s]',
    params  => [ ( $policy ? 'update' : 'create' ), $policy_name, $role_name ]
  );

  $self->log_warn( 'iam:role-policy: policy [%s] %s successfully for [%s]...',
    $policy_name, ( $policy ? 'updated' : 'created' ), $role_name );

  return;
}

########################################################################
sub update_rule_state {
########################################################################
  my ( $self, $state ) = @_;

  my ( $config, $tasks, $dryrun ) = $self->common_args(qw(config tasks dryrun));

  my ($task_name) = $self->get_args;

  my $err;

  if ( !$task_name ) {
    ( $task_name, $err ) = grep { defined $tasks->{$_}->{schedule} } keys %{$tasks};
  }

  croak sprintf "%s %s-scheduled-task task-name\n", $ENV{SCRIPT_NAME}, $state ? 'enable' : 'disable'
    if !$task_name || $err;

  my $rule_name = sprintf '%s-schedule', $task_name;

  require App::Events;

  my $event  = App::Events->new( $self->get_global_options );
  my $result = $event->describe_rule( $rule_name, '{state: State, schedule: ScheduleExpression}' );

  log_die( $self, "could not describe rule: [%s]\n%s", $rule_name, $event->get_error )
    if !$result;

  $self->log_warn( 'events: current state: [%s] for rule [%s]...will be updated do [%s]...%s',
    $result->{state}, $rule_name, ( $state ? 'ENABLED' : 'DISABLED' ), $dryrun );

  return
    if $dryrun;

  $result = $state ? $event->enable_rule($rule_name) : $event->disable_rule($rule_name);

  log_die( $self, "could not update rule: [%s]\n%s", $rule_name, $event->get_error )
    if !$result && $event->get_error;

  return;
}

########################################################################
sub create_events_role { return shift->create_role( @_, 'events' ); }
########################################################################

########################################################################
sub add_events_policy {
########################################################################
  my ($self) = @_;

  my @events = $self->has_events;

  my $region       = $self->get_region;
  my $account      = $self->get_account;
  my $cluster_name = $self->get_config->{cluster}->{name};

  my $role_arn = $self->get_config->{role}->{arn};

  my @policy_statement = (
    { Effect    => 'Allow',
      Action    => 'ecs:RunTask',
      Resource  => [ map { sprintf $TASK_DEFINITION_ARN_TEMPLATE, $region, $account, $_ } @events ],
      Condition => {
        ArnLike => {
          'ecs:cluster' => sprintf $CLUSTER_ARN_TEMPLATE,
          $region, $account, $cluster_name,
        }
      }
    },
    { Effect   => 'Allow',
      Action   => 'iam:PassRole',
      Resource => [$role_arn],
    },
    { 'Sid'      => 'TagLaunchedTasks',
      'Effect'   => 'Allow',
      'Action'   => 'ecs:TagResource',
      'Resource' => sprintf 'arn:aws:ecs:%s:%s:task/%s/*',
      $region, $account, $cluster_name,
    }
  );

  return @policy_statement;
}

########################################################################
sub has_events {
########################################################################
  my ($self) = @_;

  my ( $config, $tasks ) = $self->common_args(qw(config tasks));

  my ($schedule) = grep { $tasks->{$_}->{schedule} } keys %{$tasks};

  return $schedule;
}

########################################################################
sub fetch_events {
########################################################################
  my ($self) = @_;

  require App::Events;

  my $events = $self->get_events;

  return $events
    if $events;

  $events = App::Events->new( $self->get_global_options );

  $self->set_events($events);

  return $events;
}

########################################################################
sub build_run_tags {
########################################################################
  my ( $self, $task_name, $task ) = @_;

  my %tags = (
    %{ $task->{tags} // {} },  # user-specified tags
    'App::FargateStack:Schedule' => $task_name,
    'App::FargateStack:Type'     => 'cron',
  );

  my @tags = map { ( { Key => $_, Value => $tags{$_} } ) } sort keys %tags;
  return \@tags;
}

1;
