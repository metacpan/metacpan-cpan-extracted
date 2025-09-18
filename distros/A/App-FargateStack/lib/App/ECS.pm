package App::ECS;

use strict;
use warnings;

use App::FargateStack::Constants;
use App::FargateStack::Builder::Utils qw(choose);

use Carp;
use Data::Dumper;
use File::Temp qw(tempfile);
use JSON;
use Scalar::Util qw(reftype);
use List::Util qw(pairs);

use parent qw(App::Command);

use Role::Tiny::With;
with 'App::AWS';

__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_accessors(
  qw(
    cluster_name
    ec2
    listener_arn
    log_group
    profile
    region
    security_group
    service_name
    subnet_ids
  )
);

########################################################################
sub cluster_exists {
########################################################################
  my ( $self, $cluster_name ) = @_;

  $cluster_name //= $self->get_cluster_name;

  my $clusters = $self->command(
    'describe-clusters' => [
      '--clusters' => $cluster_name,
      '--query'    => 'clusters[?status == `ACTIVE`]',
    ]
  );

  return
    if !@{$clusters};

  return $clusters->[0]->{clusterArn};
}

########################################################################
sub create_cluster {
########################################################################
  my ( $self, $name ) = @_;

  $name //= $self->get_cluster_name;

  return $self->command( 'create-cluster' => [ '--cluster-name' => $name, ] );
}

########################################################################
sub delete_service {
########################################################################
  my ( $self, $cluster_name, $service_name ) = @_;

  $cluster_name //= $self->get_cluster_name;

  croak "usage: delete_service(cluster-name, service-name)\n"
    if !$cluster_name || !$service_name;

  return $self->command(
    'delete-service' => [
      '--cluster' => $cluster_name,
      '--service' => $service_name,
      '--force',
    ]
  );
}

########################################################################
sub describe_services {
########################################################################
  my ( $self, %args ) = @_;

  my ( $cluster_name, $service_name, $query ) = @args{qw(cluster_name service_name query)};

  croak "usage: describe_services(cluster-name, service-name, [query])\n"
    if !$cluster_name || !$service_name;

  return $self->command(
    'describe-services' => [
      '--services' => $service_name,
      '--cluster'  => $cluster_name,
      $query ? ( '--query' => $query ) : ()
    ]
  );
}

########################################################################
sub list_tasks {
########################################################################
  my ( $self, @args ) = @_;

  my ( $cluster_name, $query, $desired_status ) = choose {
    return @args
      if !ref $args[0];

    return @{ $args[0] }{qw(cluster_name query desired_status)};
  };

  croak "usage: list_tasks(cluster-name)\n"
    if !$cluster_name;

  return $self->command(
    'list-tasks' => [
      '--cluster' => $cluster_name,
      $query          ? ( '--query'          => $query )          : (),
      $desired_status ? ( '--desired-status' => $desired_status ) : (),
    ]
  );

}

########################################################################
sub stop_task {
########################################################################
  my ( $self, $cluster_name, $task_arn, $query ) = @_;

  croak "usage: stop_task(cluster-name, task-arn)\n"
    if !$cluster_name;

  return $self->command(
    'stop-task' => [
      '--cluster' => $cluster_name,
      '--task'    => $task_arn,
      $query ? ( '--query' => $query ) : ()
    ]
  );
}

########################################################################
sub describe_tasks {
########################################################################
  my ( $self, $cluster_name, $task_arn, $query ) = @_;

  croak "usage: describe_tasks(cluster-name, task-arn, [query])\n"
    if !$cluster_name || !$task_arn;

  return $self->command(
    'describe-tasks' => [
      '--tasks'   => ref $task_arn ? @{$task_arn} : $task_arn,
      '--cluster' => $cluster_name,
      $query ? ( '--query' => $query ) : ()
    ]
  );
}

########################################################################
sub describe_task_definition {
########################################################################
  my ( $self, $task, $query ) = @_;

  croak "usage: describe_task_definition(task, [query])\n"
    if !$task;

  return $self->command(
    'describe-task-definition' => [
      '--task-definition' => $task,
      $query ? ( '--query' => $query ) : ()
    ]
  );
}

########################################################################
sub describe_clusters {
########################################################################
  my ( $self, $cluster_name, $query ) = @_;

  $cluster_name //= $self->get_cluster_name;

  return $self->command( 'describe-clusters' => [ '--clusters' => $cluster_name, ] );
}

########################################################################
sub register_task_definition {
########################################################################
  my ( $self, $task_definition ) = @_;

  croak "usage: register_task_definition(task-definition-file)\n"
    if !$task_definition || !-s $task_definition;

  my $result
    = $self->command( 'register-task-definition' => [ '--no-cli-pager', '--cli-input-json' => "file://$task_definition", ] );

  return $result;
}

########################################################################
sub run_task {
########################################################################
  my ( $self, %args ) = @_;

  foreach (qw(network_configuration subnets security_groups)) {
    next if !ref $args{$_};
    $args{$_} = encode_json( $args{$_} );
  }

  return $self->command(
    'run-task' => [
      '--cluster'               => $args{cluster},
      '--task-definition'       => $args{task_definition},
      '--network-configuration' => $args{network_configuration},
      '--launch-type'           => 'FARGATE',
    ]
  );
}

########################################################################
sub wait_tasks_stopped {
########################################################################
  my ( $self, $cluster_name, $task_arn ) = @_;

  return $self->command(
    'wait' => [
      'tasks-stopped',
      '--cluster' => $cluster_name,
      '--tasks'   => $task_arn,
    ]
  );
}

########################################################################
sub list_services {
########################################################################
  my ( $self, $cluster_name, $query ) = @_;

  $cluster_name //= $self->get_cluster_name;

  return $self->command(
    'list-services' => [
      '--cluster' => $cluster_name,
      $query ? ( '--query' => $query ) : ()
    ]
  );
}

########################################################################
sub delete_cluster {
########################################################################
  my ( $self, $cluster_name ) = @_;

  return $self->command( 'delete-cluster' => [ '--cluster' => $cluster_name ] );
}

########################################################################
sub list_task_definitions {
########################################################################
  my ( $self, $family_prefix, $query ) = @_;

  return $self->command( 'list-task-definitions' =>
      [ $family_prefix ? ( '--family-prefix' => $family_prefix ) : (), $query ? ( '--query' => $query ) : () ] );

}

########################################################################
sub deregister_task_definition {
########################################################################
  my ( $self, $task_definition, $query ) = @_;

  croak "usage: deregister_task_definition(task-definition, [query])\n"
    if !$task_definition;

  return $self->command(
    'deregister-task-definition' => [ '--task-definition' => $task_definition, $query ? ( '--query' => $query ) : () ] );
}

########################################################################
sub delete_task_definitions {
########################################################################
  my ( $self, $task_definitions ) = @_;

  croak "usage: delete_task_definitions(task-definitions, [options])\n"
    if !$task_definitions;

  if ( !ref $task_definitions ) {
    $task_definitions = [$task_definitions];
  }

  my @task_definition_list = @{$task_definitions};

  # - ECS requires dregistratrion before deletion
  foreach my $def (@task_definition_list) {
    my $result = $self->deregister_task_definition($def);

    croak sprintf "ERROR: could not deregister: [%s]\n%s", $def, $self->get_error
      if !$result;
  }

  while ( my @batch = splice @task_definition_list, 0, 10 ) {
    my $list = join q{,}, @batch;

    my $result = $self->command( 'delete-task-definitions' => [ '--task-definitions' => $list ] );

    croak sprintf "ERROR: could not delete task definitions: [%s]\n%s", $list, $self->get_error
      if !$result;
  }

  return;
}

########################################################################
sub create_service {
########################################################################
  my ( $self, %args ) = @_;

  my ( $service_name, $cluster_name, $task_definition, $desired_count, $public_ip )
    = @args{qw(service_name cluster_name task_definition desired_count public_ip)};

  $cluster_name  //= $self->get_cluster_name;
  $desired_count //= 1;

  my ( $subnets, $security_groups ) = @args{qw(subnets security_groups)};

  croak "subnets is required and must be an array\n"
    if !$subnets || reftype($subnets) ne 'ARRAY';

  croak "security_groups is required and must be an array\n"
    if !$security_groups || reftype($security_groups) ne 'ARRAY';

  croak "no security groups defined\n"
    if !@{$security_groups};

  croak "service-name is required\n"
    if !$service_name;

  my $network_configuration = {
    awsvpcConfiguration => {
      subnets        => $subnets,
      securityGroups => $security_groups,
      assignPublicIp => $public_ip ? 'ENABLED' : 'DISABLED',
    }
  };

  my ( $target_group_arn, $container_name, $container_port ) = @args{qw(target_group_arn container_name container_port)};

  $container_port //= $DEFAULT_PORT;

  my $load_balancers;

  if ($target_group_arn) {
    $load_balancers = [
      { targetGroupArn => $target_group_arn,
        containerName  => $container_name,
        containerPort  => $container_port,
      }
    ];
  }

  return $self->command(
    'create-service' => [
      '--cluster'               => $cluster_name,
      '--service-name'          => $service_name,
      '--task-definition'       => $task_definition,
      '--desired-count'         => $desired_count,
      '--launch-type'           => 'FARGATE',
      '--network-configuration' => encode_json($network_configuration),
      $load_balancers ? ( '--load-balancers' => encode_json($load_balancers) ) : (),
    ]
  );
}

########################################################################
sub update_service {
########################################################################
  my ( $self, %args ) = @_;

  my ( $cluster_name, $service_name, $task_definition, $force, $desired_count, $query )
    = @args{qw(cluster_name service_name task_definition force desired_count query)};

  $cluster_name //= $self->get_cluster_name;
  $service_name //= $self->get_service_name;

  return $self->command(
    'update-service' => [
      '--cluster' => $cluster_name,
      '--service' => $service_name,
      $query                 ? ( '--query' => $query )                     : (),
      defined $desired_count ? ( '--desired-count' => $desired_count )     : (),
      ($task_definition)     ? ( '--task-definition' => $task_definition ) : (),
      $force                 ? '--force-new-deployment'                    : (),
    ]
  );
}

########################################################################
sub tag_resource {
########################################################################
  my ( $self, $arn, @tags ) = @_;

  my $tag_string = join q{}, map { sprintf 'Key=%s,Value=%s', @{$_} } pairs @tags;

  return $self->command(
    'add-tags',
    [ '--tags'         => $tag_string,
      '--resoure-arns' => $arn,
    ]
  );
}

1;
