package App::FargateStack::Builder::TaskDefinition;

use strict;
use warnings;

use App::FargateStack::Constants;
use App::FargateStack::Builder::Utils qw(log_die choose);
use Carp;
use Data::Dumper;
use English qw(-no_match_vars);
use File::Basename qw(fileparse);
use Data::Compare;
use List::Util qw(uniq);
use JSON;
use Test::More;

use Role::Tiny;

########################################################################
sub register_task_definition {
########################################################################
  my ( $self, $task_name ) = @_;

  my ( $config, $tasks, $dryrun ) = $self->common_args(qw(config tasks dryrun));

  my $ecs = $self->get_ecs;

  my $family = $tasks->{$task_name}->{family};

  my @task_definitions = map { $_->[0] }
    sort { $a->[1] <=> $b->[1] }
    map { [ $_, /:(\d+)$/ ? $1 : 0 ] } @{ $ecs->list_task_definitions( $family, 'taskDefinitionArns' ) // [] };

  if ( $self->taskdef_has_changed($task_name) || !@task_definitions ) {
    my $taskdef = @task_definitions ? $task_definitions[-1] : "arn:???/$task_name";

    if ( $taskdef =~ /:(\d+)$/xsm ) {
      my $version = $1 + 1;

      $taskdef =~ s/\d+$/$version/xsm;
    }

    $self->inc_required_resources(
      task => [
        sub {
          my ($dryrun) = @_;

          return $taskdef
            if $taskdef !~ /[?]/xsm;

          return $dryrun ? $taskdef : $tasks->{$task_name}->{arn};
        }
      ]
    );

    my $task_definition = sprintf 'taskdef-%s.json', $task_name;

    $self->log_warn(
      'register-task-definition: task definition for [%s] changed or does is not registered...will be registered...%s',
      $task_name, $dryrun );

    if ( !$dryrun ) {
      $self->log_warn( 'register-task-definition: registering task definition [%s]...', $task_name );

      my $result = $ecs->register_task_definition($task_definition);

      log_die( $self, "ERROR: unable to register task definition: [%s]\n%s", $task_definition, $ecs->get_error )
        if !$result;

      $tasks->{$task_name}->{arn} = $result->{taskDefinition}->{taskDefinitionArn};

    }
  }
  else {
    $self->log_info( 'register-task-definition: task definition for: [%s] has not changed...skipping', $task_name );

    $tasks->{$task_name}->{arn} = $task_definitions[-1];

    $self->inc_existing_resources( task => [ $task_definitions[-1] ] );
  }

  if ( !$tasks->{$task_name}->{image_digest} ) {
    # update image digest in configuration
    my $latest_image  = $self->get_latest_image($task_name);
    my $latest_digest = $latest_image->{imageDigest};

    if ( !$latest_digest ) {
      $self->log_error('register-task-definition: unable to retrieve image digest...did you push it to ECR?');
    }
    else {
      $self->log_warn( 'register-task-definition: updating image digest in config: [%s]', $latest_digest );
    }

    $tasks->{$task_name}->{image_digest} = $latest_digest;
  }

  return;
}

########################################################################
sub taskdef_has_changed { goto &taskdef_status; }
########################################################################

########################################################################
sub taskdef_status {
########################################################################
  my ( $self, $task, $action ) = @_;

  $action //= 'status';

  my $taskdef = "taskdef-$task.json";

  my ( $name, $path, $ext ) = fileparse( $taskdef, qr/[.][^.]+$/xsm );

  return !$self->get_taskdef_status->{$task};
}

########################################################################
sub create_role_arn {
########################################################################
  my ( $self, $role_name ) = @_;

  return sprintf 'arn:aws:iam::%s:role/%s', $self->get_account, $role_name;
}

########################################################################
sub define_port_mapping {
########################################################################
  my ( $task, $type ) = @_;

  return
    if !$type || $type !~ /^http/xsm;

  # use port or specify container_port, host_port - pick your poison
  my $port           = $task->{port}           // $DEFAULT_PORT;
  my $container_port = $task->{container_port} // $DEFAULT_PORT;

  return [
    { protocol      => 'tcp',
      containerPort => 0 + $container_port,
      hostPort      => 0 + $port,
    }
  ];
}

########################################################################
sub define_task_size {
########################################################################
  my ( $task, $type ) = @_;

  my ( $cpu, $memory, $size ) = @{$task}{qw(cpu memory size)};

  return ( $cpu, $memory, $size )
    if defined $size && defined $cpu && defined $memory;

  if ( defined $cpu && defined $memory ) {
    ($size) = grep { $ECS_TASK_PROFILES{$_}->{cpu} eq $cpu && $ECS_TASK_PROFILES{$_}->{memory} eq $memory }
      keys %ECS_TASK_PROFILES;

    if ($size) {
      $task->{size} = $size;
    }

    return ( $cpu, $memory, $size );
  }

  my $logical_type = choose {
    return 'web'    if $type =~ /http/xsm;
    return 'daemon' if $type eq 'daemon';
    return 'job'    if $type eq 'task' && $task->{schedule};
    return 'task';
  };

  $size //= $ECS_TASK_PROFILE_TYPES{$logical_type};

  if ($size) {
    my $profile = $ECS_TASK_PROFILES{$size};

    croak sprintf "ERROR: unknown profile: [%s], valid profiles: [%s]\n", $size, join q{,}, keys %ECS_TASK_PROFILES
      if !$profile;

    $cpu    //= $profile->{cpu};
    $memory //= $profile->{memory};
  }

  return ( $cpu, $memory, $size );
}

########################################################################
sub create_taskdef_files {
########################################################################
  my ($self) = @_;

  my ( $config, $services ) = $self->common_args(qw(config tasks));

  foreach my $task_name ( keys %{$services} ) {
    my $task = $services->{$task_name};

    $task->{type} //= 'task';

    my $type = $task->{type};

    # -- port mappings --
    my $portMapping = define_port_mapping( $task, $type );

    if ($portMapping) {
      @{$task}{qw(container_port host_port)} = @{ $portMapping->[0] }{qw(containerPort hostPort)};
    }

    # -- log group/stream prefix --
    #
    # Note: the default log group name was set earlier...and task will
    # be updated when (and if) we create the log group...
    my $log_group = $config->{log_group}->{name};

    my $stream_prefix = $config->{app}->{name};

    # -- image name --
    my $image = $self->resolve_image_name( $task->{image} );

    # -- environment --
    my @environment
      = map { { name => $_, value => $task->{environment}->{$_} } } keys %{ $task->{environment} // {} };

    # -- task name/family  --
    my ( $name, $family ) = @{$task}{qw(name family)};
    $task->{name}   //= $task_name;
    $task->{family} //= $task_name;

    # -- task size --
    my ( $cpu, $memory, $size ) = define_task_size( $task, $type );
    $task->{size}   //= $size;
    $task->{memory} //= $memory // $DEFAULT_MEMORY_SIZE;
    $task->{cpu}    //= $cpu    // $DEFAULT_CPU_SIZE;

    # -- secrets (from App::Fargate::Builder::Secrets)
    my $secrets = $self->add_secrets($task) // [];

    # -- efs mounts --
    my ( $volumes, $mount_points ) = $self->add_volumes($task);

    my $role_name      = $config->{role}->{name}      // $self->create_default( 'role-name', 'ecs' );
    my $task_role_name = $config->{task_role}->{name} // $self->create_default( 'role-name', 'task' );

    # Note that we create the role ARNs rather than taking them from
    # the config. This is because we create the task definition before
    # we actually create the roles. The role ARN is determistic...so
    # why not?

    my $taskdef = {
      executionRoleArn     => $self->create_role_arn($role_name),
      taskRoleArn          => $self->create_role_arn($task_role_name),
      memory               => "$task->{memory}",
      containerDefinitions => [
        { logConfiguration => {
            options => {
              'awslogs-region'        => $config->{region},
              'awslogs-stream-prefix' => $stream_prefix,
              'awslogs-group'         => $log_group
            },
            logDriver => q{awslogs}
          },
          environment  => \@environment,
          secrets      => $secrets,
          portMappings => $portMapping // [],
          essential    => JSON::true,
          name         => $task->{name},
          $task->{command} ? ( command => [ $task->{command} ] ) : (),
          image       => $image,
          mountPoints => $mount_points // [],
        }
      ],
      cpu                     => "$task->{cpu}",
      requiresCompatibilities => [q{FARGATE}],
      networkMode             => q{awsvpc},
      family                  => $task->{family},
      volumes                 => $volumes // [],

    };

    $self->log_trace( sub { return Dumper( [ taskdef => $taskdef ] ); } );

    $self->write_taskdef( $task_name, $taskdef );
  }

  return $TRUE;
}

########################################################################
sub write_taskdef {
########################################################################
  my ( $self, $task_name, $taskdef ) = @_;

  my $config = $self->get_config;

  my $taskdef_file = sprintf 'taskdef-%s.json', $task_name;

  $self->compare_task_definition( $task_name, $taskdef, $taskdef_file );

  $self->log_info( 'task: [%s] saving task definition file...[%s]', $task_name, $taskdef_file );

  open my $fh, '>', $taskdef_file
    or croak "could not open $taskdef_file for writing\n";

  print {$fh} JSON->new->pretty->encode($taskdef);

  close $fh;

  return;
}

########################################################################
sub compare_task_definition {
########################################################################
  my ( $self, $task_name, $taskdef, $taskdef_file ) = @_;

  my $config = $self->get_config;

  my $ecs            = $self->get_ecs;
  my $task           = $config->{tasks}->{$task_name};
  my $taskdef_status = $self->get_taskdef_status // {};

  my $current_taskdef = $ecs->describe_task_definition( $task_name, 'taskDefinition' );

  if ( !$current_taskdef ) {
    $taskdef_status->{$task_name} = $FALSE;
    $self->set_taskdef_status($taskdef_status);
    return;
  }

  $config->{tasks}->{$task_name}->{arn} = $current_taskdef->{taskDefinitionArn};

  my $status = -s $taskdef_file ? $TRUE : $FALSE;

  if ( !$status ) {
    $self->log_warn( 'task: [%s] no task definition file [%s]...forces new task definition', $task_name, $taskdef_file );
  }

  foreach my $k ( keys %{$taskdef} ) {
    next if $k eq 'containerDefinitions';

    if ( ref( $current_taskdef->{$k} ) eq 'ARRAY' ) {
      next if array_compare( $taskdef->{$k}, $current_taskdef->{$k} );
    }
    else {
      next if Compare( $taskdef->{$k}, $current_taskdef->{$k} );
    }

    $self->log_warn( 'task: [%s] %s changed...forces new task definition', $task_name, $k );

    $self->log_trace(
      sub {
        return Dumper(
          [ taskdef      => $taskdef->{$k},
            "current_$k" => $current_taskdef->{$k},
            current      => $current_taskdef
          ]
        );
      }
    );

    $self->display_diffs( $taskdef->{$k}, $current_taskdef->{$k}, { title => sprintf '%s changes', $k } );

    $status = $FALSE;
  }

  my $containerDefinitions = $taskdef->{containerDefinitions}->[0];

  my @keys_to_check = (
    qw(
      mountPoints
      portMappings
      command
      environment
      image
      name
      secrets), keys %{$containerDefinitions}
  );

  foreach my $k ( uniq @keys_to_check ) {
    my $current_elem = $current_taskdef->{containerDefinitions}->[0]->{$k};
    if ( ref($current_elem) eq 'ARRAY' ) {
      next if array_compare( $current_elem, $containerDefinitions->{$k} );
    }
    else {
      next if Compare( $containerDefinitions->{$k}, $current_elem );
    }

    $self->log_warn( 'task: [%s] %s changed...forces new task definition', $task_name, $k );

    $self->display_diffs( $current_elem, $containerDefinitions->{$k}, { title => sprintf '%s changes', $k } );

    $status = $FALSE;
  }

  $taskdef_status->{$task_name} = $status;

  $self->set_taskdef_status($taskdef_status);

  return;
}

########################################################################
sub array_compare {
########################################################################
  my ( $array1, $array2 ) = @_;

  return $FALSE
    if $array1 && !$array2;

  return $FALSE
    if !$array1 && $array2;

  return $FALSE
    if @{$array1} != @{$array2};

  my $json = JSON->new->canonical;

  my $array1_sorted = join q{}, sort map { ref $_ ? $json->encode($_) : $_ } @{$array1};

  my $array2_sorted = join q{}, sort map { ref $_ ? $json->encode($_) : $_ } @{$array2};

  return $array1_sorted eq $array2_sorted;
}

1;
