package App::FargateStack::Builder::IAM;

use strict;
use warnings;

use Carp;
use Data::Dumper;
use Data::Compare;
use English qw(-no_match_vars);

use App::FargateStack::Constants;
use App::FargateStack::Builder::Utils qw(choose log_die);
use Text::Diff;
use JSON;

use Role::Tiny;

########################################################################
sub build_iam_role {
########################################################################
  my ($self) = @_;

  my ( $config, $tasks, $dryrun ) = $self->common_args(qw(config tasks dryrun));

  my $iam = $self->fetch_iam;

  ######################################################################
  # create role
  ######################################################################
  my $role = $config->{role} // {};
  $config->{role} = $role;

  $self->log_trace( sub { return Dumper( [ role => $role ] ) } );

  my ( $role_name, $role_arn ) = $self->create_fargate_role();

  my $policy_name = $role->{policy_name} // $self->create_default( 'policy-name', 'ecs' );
  @{$role}{qw(name arn policy_name)} = ( $role_name, $role_arn, $policy_name );

  ######################################################################
  # create policy - see if policy needs to be created or updated
  ######################################################################
  $self->create_policy( $iam, 'ecs' );

  ######################################################################
  # create task role
  ######################################################################
  my $task_role = $config->{task_role} // {};
  $config->{task_role} = $task_role;

  $self->log_trace( sub { return Dumper( [ task_role => $task_role ] ) } );

  my ( $task_role_name, $task_role_arn ) = $self->create_fargate_task_role();

  my $task_policy_name = $task_role->{policy_name} // $self->create_default( 'policy-name', 'task' );
  @{$task_role}{qw(name arn policy_name)} = ( $task_role_name, $task_role_arn, $task_policy_name );

  ######################################################################
  # create task policy
  ######################################################################
  $self->create_policy( $iam, 'task' );

  return;
}

########################################################################
sub create_policy {
########################################################################
  my ( $self, $iam, $type ) = @_;

  my ( $config, $dryrun ) = $self->common_args(qw(config dryrun));

  my $role = $type eq 'ecs' ? $config->{role} : $config->{task_role};

  my ( $policy_name, $role_name ) = @{$role}{qw(policy_name name)};

  ######################################################################
  # create policy - see if policy needs to be created or updated
  ######################################################################
  # if we turned caching off OR we don't have an ARN yet, check to see
  # if the policy exists

  my $policy = $iam->get_role_policy( $role_name, $policy_name );

  $iam->check_result(
    message => 'ERROR: could not get role policy: [%s] for role [%s]',
    params  => [ $policy_name, $role_name ],
    regexp  => qr/cannot\sbe\sfound/xsmi
  );

  $self->log_trace(
    sub {
      return Dumper(
        [ policy => $policy,
          role   => $role
        ]
      );
    }
  );

  my $role_policy = choose {
    return $self->create_fargate_policy
      if $type eq 'ecs';

    return $self->create_fargate_task_policy;
  };

  my $policy_exists = $FALSE;

  if ($policy) {
    $policy_exists = Compare( $policy, $role_policy ) ? 1 : -1;
  }

  $self->log_trace(
    sub {
      return Dumper(
        [ existing_policy => $policy,
          new_policy      => $role_policy,
          role            => $role,
          policy_exists   => $policy_exists,
        ]
      );
    }
  );

  if ( $policy_exists && $policy_exists != -1 ) {
    $self->log_info( 'iam: policy: [%s] exists...%s', $policy_name, 'skipping' );
    $self->inc_existing_resources( 'iam:role-policy' => [$policy_name] );
    return;
  }
  elsif ( $policy_exists == -1 ) {
    my $title = sprintf 'iam: role policy [%s] differs', $policy_name;

    $self->display_diffs( $policy, $role_policy, { title => $title } );
    $self->log_warn( 'iam: policy: [%s] will be replaced...%s', $policy_name, $dryrun );
  }
  else {
    $self->log_warn( 'iam: policy: [%s] will be created...%s', $policy_name, $dryrun );
  }

  $self->inc_required_resources( 'iam:policy' => [$policy_name] );

  return
    if $dryrun;

  # -- policy exists but differs
  if ( $policy_exists == -1 ) {
    $self->log_warn( 'iam: deleting policy [%s] for role [%s]...', $policy_name, $role_name );
    $iam->delete_role_policy( $role_name, $policy_name );
  }

  $self->log_trace( sub { return Dumper( [ 'iam:policy' => $role_policy ] ); } );

  $self->log_warn( 'iam: creating policy [%s] for role [%s]...', $policy_name, $role_name );

  $iam->put_role_policy( $role_name, $policy_name, $role_policy );

  $iam->check_result(
    { message => "ERROR: could not create policy %s for %s\n%s",
      params  => [ $role_name, $policy_name, $iam->get_error ]
    }
  );

  return;
}

########################################################################
sub create_fargate_policy {
########################################################################
  my ($self) = @_;

  my $config = $self->get_config;

  my @statement;

  my $role_policy = {
    Version   => $IAM_POLICY_VERSION,
    Statement => \@statement,
  };

  push @statement, $self->add_ecr_policy();

  push @statement, $self->add_efs_policy();  # force rebuild of policy

  push @statement, $self->add_log_group_policy();

  if ( my $secrets = $self->get_secrets ) {
    push @statement, $self->add_secrets_policy($secrets);
  }

  return $role_policy;
}

########################################################################
sub create_fargate_task_policy {
########################################################################
  my ($self) = @_;

  my $config = $self->get_config;

  my @statement;

  my $role_task_policy = {
    Version   => $IAM_POLICY_VERSION,
    Statement => \@statement,
  };

  if ( $config->{bucket} ) {
    push @statement, $self->add_bucket_policy;
  }

  if ( $config->{queue} ) {
    push @statement, $self->add_queue_policy();
  }

  if ( my $secrets = $self->get_secrets ) {
    push @statement, $self->add_secrets_policy($secrets);
  }

  return $role_task_policy;
}

########################################################################
sub create_fargate_role { return shift->create_role( @_, 'ecs' ); }
########################################################################
sub create_fargate_task_role { return shift->create_role( @_, 'task' ); }
########################################################################

########################################################################
sub create_role {
########################################################################
  my ( $self, $type ) = @_;

  my $config = $self->get_config;

  my $dryrun = $self->get_dryrun;

  my $iam = $self->fetch_iam;

  my $service_domain = $AWS_SERVICE_DOMAINS{$type};

  log_die( $self, 'iam: invalid task type: %s', $type )
    if !$service_domain;

  my $trust_policy = {
    Version   => $IAM_POLICY_VERSION,
    Statement => [
      { Effect    => 'Allow',
        Principal => { Service => $service_domain },
        Action    => 'sts:AssumeRole'
      }
    ]
  };

  my $role_config = choose {
    if ( $type eq 'events' ) {
      $config->{events_role} //= {};
      return $config->{events_role};
    }
    elsif ( $type eq 'ecs' ) {
      $config->{role} //= {};
      return $config->{role};
    }
    elsif ( $type eq 'task' ) {
      $config->{task_role} //= {};
      return $config->{task_role};

    }
  };

  my $role_name = $role_config->{name} // $self->create_default( 'role-name', $type );

  my $role = choose {
    return { Role => { Arn => $role_config->{arn} } }
      if $role_config->{arn};

    return $iam->role_exists($role_name);
  };

  $self->log_trace( sub { return Dumper( [ role => $role ] ) } );

  if ( $role->{Role}->{Arn} ) {
    $self->log_info( 'iam: role: [%s] exists...%s', $role_name, $self->get_cache || 'skipping' );

    $self->inc_existing_resources( 'iam:role' => [ $role->{Role}->{Arn} ] );

    return ( $role_name, $role->{Role}->{Arn} );
  }

  $self->inc_required_resources(
    'iam:role' => [
      sub {
        my ($dryrun) = @_;
        return $dryrun ? "arn:???/$role_name" : $role_config->{arn};
      }
    ]
  );

  $self->log_warn( 'iam: role: [%s] will be created...%s', $role_name, $self->get_dryrun );

  my $role_arn;

  if ( !$dryrun ) {
    $role_arn = $iam->create_role( $role_name, $trust_policy );

    $self->log_trace( sub { return Dumper( [ 'iam: policy' => $trust_policy ] ); } );

    log_die( $self, "ERROR: could not create role: %s\n%s", $role_name, $iam->get_error )
      if $iam->get_error;
  }

  return ( $role_name, $role_arn );
}

1;
