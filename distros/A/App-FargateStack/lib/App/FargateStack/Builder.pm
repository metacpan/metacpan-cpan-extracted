package App::FargateStack::Builder;

use strict;
use warnings;

use App::FargateStack::Constants;
use App::FargateStack::Builder::Utils qw(log_die confirm dmp);

use CLI::Simple::Constants qw(:booleans);
use Carp;
use Data::Dumper;
use Digest::MD5 qw(md5_hex);
use English qw(-no_match_vars);
use File::Temp qw(tempfile);
use List::Util qw(pairs any none uniq);
use Scalar::Util qw(reftype);
use Text::ASCIITable::EasyTable;
use YAML qw(DumpFile);
use Term::ANSIColor;

use Role::Tiny;

########################################################################
sub build {
########################################################################
  my ($self) = @_;

  $self->benchmark;

  my ( $config, $dryrun, $tasks ) = $self->common_args(qw(config dryrun tasks));

  my $domain = $config->{domain};

  my $subnets = $self->get_subnets();

  $self->section_break;

  if ( !$self->get_force && !$dryrun ) {
    if ( !confirm('You are about to apply changes and possibly create or update resources. Proceed?') ) {
      $self->log_die('Aborting...');
    }
  }

  $self->log_info( 'Beginning %s phase...', $dryrun ? 'plan' : 'apply' );
  $self->section_break;

  # -- log groups --
  $self->build_log_group;
  $self->benchmark('log-groups');
  $self->section_break;

  # -- task definitions --
  $self->create_taskdef_files;
  $self->section_break;

  # -- certificate --
  if ( $domain && $self->has_https_service ) {
    $self->build_certificate;
    $self->benchmark('certificate');
    $self->section_break;
  }

  # -- queue --
  if ( $config->{queue} && $config->{queue}->{name} ) {
    $self->build_queue;
    $self->benchmark('queue');
    $self->section_break;
  }

  # -- bucket --
  if ( $config->{bucket} && $config->{bucket}->{name} ) {
    $self->build_bucket;
    $self->benchmark('bucket');
    $self->section_break;
  }

  ## -- iam --
  $self->build_iam_role;
  $self->benchmark('iam');
  $self->section_break;

  ## -- cluster --
  $self->build_fargate_cluster;
  $self->benchmark('cluster');
  $self->section_break;

  ## -- security group --
  $self->build_security_group;
  $self->benchmark('security-group');
  $self->section_break;

  # -- task definitions --
  foreach my $task_name ( keys %{$tasks} ) {
    $self->register_task_definition($task_name);
    $self->benchmark( 'register-task-definition:' . $task_name );
    $self->section_break;
  }

  # -- EFS ingress
  foreach my $task_name ( keys %{$tasks} ) {
    next if !exists $tasks->{$task_name}->{efs} || !$tasks->{$task_name}->{efs}->{authorize_ingress};
    my $efs_config = $tasks->{$task_name}->{efs};
    my $efs_id     = $efs_config->{id};

    if ( !$self->is_efs_ingress_authorized($efs_config) ) {
      $self->log_warn( 'efs: authorizing task: [%s] ingress to EFS: [%s]...%s', $task_name, $efs_id, $dryrun );

      $self->authorize_efs_ingress( $config->{security_groups}->{fargate}->{group_id}, $efs_config );
    }
    else {
      $self->log_info( 'efs: ingress for [%s] to [%s]...already authorized...skipping', $task_name, $efs_id );
    }

    $self->benchmark('efs-ingress');
    $self->section_break;
  }

  ## -- events --
  if ( $self->has_events ) {
    $self->build_events;
    $self->benchmark('events');
    $self->section_break;
  }

  ## -- http service --
  if ( $self->get_http() ) {
    $self->build_http_service;
    $self->benchmark('http-service');
    $self->section_break;
  }

  ## -- autoscaling
  if ( $self->get_http() ) {
    $self->build_autoscaling();
    $self->benchmark('autoscaling');
    $self->section_break;
  }

  # -- route53 (create alias)
  if ( $self->get_http ) {
    $self->create_alias();
    $self->benchmark('route53');
    $self->section_break;
  }

  # -- WAF
  if ( $self->get_http() ) {
    $self->build_waf();
    $self->benchmark('waf');
  }

  # -- finished --
  $self->log_info( 'builder: build completed in %ds', $self->benchmark('elapsed_time') );

  $self->log_info( 'builder: %d resources will be created.', scalar keys %{ $self->get_required_resources // {} } // 0 );

  $self->log_info( 'builder: %d resources already exist', scalar keys %{ $self->get_existing_resources // {} } // 0 );

  $self->section_break;

  ## -- benchmarks --
  my @benchmarks;
  foreach my $p ( pairs $self->dump_benchmarks() ) {
    push @benchmarks, { Resource => $p->[0], Time => $p->[1] };
  }

  my $table = easy_table(
    columns       => [qw(Resource Time)],
    data          => \@benchmarks,
    table_options => { headingText => 'Benchmarks' },
  );

  $self->log_info("\n$table");

  # -- resources --
  foreach my $p ( pairs Required => $self->get_required_resources, Existing => $self->get_existing_resources ) {

    my $data      = [];
    my $resources = $p->[1];

    foreach my $k ( sort keys %{$resources} ) {
      my $value = resolve_resource_value( $resources->{$k} // $EMPTY, $self->get_dryrun );
      $value = sprintf '%s', join( "\n", @{$value} ) // $EMPTY;

      push @{$data}, { Resource => $k, Value => $value };
    }

    if ( @{$data} ) {
      my $table = easy_table(
        columns       => [qw(Resource Value)],
        data          => $data,
        table_options => { headingText => $p->[0] . ' Resources' }
      );

      my $level = $p->[0] eq 'Required' ? 'warn' : 'info';

      $self->get_logger->$level("\n$table");
    }
    else {
      $self->log_warn( 'builder: no %s resources', lc $p->[0] );
    }
  }

  $self->update_config;

  return;
}

# resolves the resource value from the hash of resources
# TBD: better documentation of this method
########################################################################
sub resolve_resource_value {
########################################################################
  my ( $value, $dryrun ) = @_;

  return [$value]
    if !ref $value;

  if ( reftype($value) eq 'ARRAY' ) {
    my @values;

    foreach my $v ( @{$value} ) {
      if ( ref $v && reftype($v) eq 'CODE' ) {
        push @values, $v->($dryrun);
      }
      else {
        push @values, $v;
      }
    }
    return \@values;
  }
  else {
    return [ $value->($dryrun) ];
  }
}

########################################################################
sub get_scheduled_action_names {
########################################################################
  my ($self) = @_;

  my $config = $self->get_config;
  my @scheduled_action_names;

  foreach ( keys %{ $config->{tasks} } ) {
    next if !exists $config->{tasks}->{$_}->{autoscaling};
    next if !exists $config->{tasks}->{$_}->{autoscaling}->{scheduled};
    push @scheduled_action_names, keys %{ $config->{tasks}->{$_}->{autoscaling}->{scheduled} };
  }

  return @scheduled_action_names;
}

########################################################################
sub update_config_id {
########################################################################
  my ($self) = @_;

  $Data::Dumper::Sortkeys = $TRUE;

  my $config = $self->get_config;

  delete $config->{id};
  delete $config->{last_updated};

  my $md5_hex = md5_hex( Dumper( $self->get_config ) );

  $config->{id} = $md5_hex;

  $config->{last_updated} = scalar localtime;

  return $config;
}

########################################################################
sub update_config {
########################################################################
  my ($self) = @_;

  $self->log_warn( 'builder: config file %s %s be updated', $self->get_config_name, $self->get_update ? 'will' : 'will not' );

  return
    if !$self->get_update;

  my ( $fh, $filename ) = tempfile( 'fargate-stack-XXXX', SUFFIX => '.yml' );

  my $config = $self->update_config_id();

  DumpFile( $filename, $config );

  my $config_name = $self->get_config_name;

  rename $config_name, "${config_name}.bak";

  rename $filename, $config_name;

  return;
}

########################################################################
sub configure_alb {
########################################################################
  my ($self) = @_;

  my $config = $self->get_config;

  my $is_secure = $self->has_https_service;

  # default ALB type is private with a listener on port 80
  my $alb_config = $config->{alb} // {};
  $alb_config->{type} //= $is_secure ? 'public' : 'private';
  $alb_config->{port} //= $is_secure ? '443'    : '80';

  # if it was already defined as public w/o a port, then 443 and
  # redirect 80 -> 443
  if ( $alb_config->{type} eq 'public' && !$alb_config->{port} ) {
    $alb_config->{port} = '443';
    if ( !defined $alb_config->{redirect_80} ) {
      $alb_config->{redirect_80} = $TRUE;
    }
  }

  croak "invalid alb type, must be 'public' or 'private'\n"
    if $alb_config->{type} !~ /^public|private$/xsm;

  $config->{alb} = $alb_config;

  return;
}

########################################################################
sub remove_listener_rules {
########################################################################
  my ( $self, $alb_arn ) = @_;

  my ( $config, $dryrun ) = $self->common_args(qw(config dryrun));

  my $elb = $self->get_elbv2;

  my $domain = $config->{domain};

  my $listeners = $elb->describe_listeners( $alb_arn, 'Listeners' );

  foreach my $listener ( @{$listeners} ) {
    my $rules = $elb->describe_rules( $listener->{ListenerArn}, 'Rules' );

    foreach my $rule ( @{$rules} ) {
      my $action     = $rule->{Actions}->[0];
      my $conditions = $rule->{Conditions}->[0] || [];

      next
        if !$conditions;
      next
        if !$conditions->{Field};
      next
        if $conditions->{Field} ne 'host-header';
      next
        if $conditions->{Values}->[0] ne $domain;

      $self->log_warn( 'removing App::FargateStack provisioned listener rule type: [%s] for port: [%s]...%s',
        $action->{Type}, $listener->{Port}, $dryrun );

      if ( !$dryrun ) {
        $elb->delete_rule( $rule->{RuleArn} );
      }

      last;
    }
  }

  return;
}

=pod

For multi-task configuration files we cannot delete these resources:

 - role, policy
 - log group
 - Fargate security group
 - cluster

For http services we can delete

 - ALB if it is was provisioned by App::FargateStack
 - ALB security group
 - Alias record
 - target group

For scheduled task we can delete

 - rule 
 - rule target

If only 1 task in the configuration file, we can delete the entire stack.

The task ARN will be deleted to indicate that the task resources were
removed.

=cut

########################################################################
# type = task|scheduled|daemon|https?
########################################################################
sub delete_task_resources {
########################################################################
  my ( $self, $task_name, $type ) = @_;

  my ( $config, $tasks, $dryrun, $security_groups, $cluster )
    = $self->common_args(qw(config tasks dryrun security_groups cluster));

  my @active_tasks = grep { $tasks->{$_}->{arn} } keys %{$tasks};

  my $num_tasks = scalar @active_tasks;

  $config->{cluster} //= {};
  $cluster->{name}   //= $self->create_default('cluster-name');

  if ( !$self->get_force ) {
    return $SUCCESS
      if !confirm( sprintf 'Are you sure you want to delete the %s (%s) task?', $task_name, $type );
  }

  # check to see if service is running before removing resources
  my $task_type = $tasks->{$task_name}->{type};

  if ( $task_type =~ /^(?:https?|daemon)$/xsm ) {
    $self->log_trace( sub { return Dumper( [ cluster => $cluster ] ); } );

    log_die( $self, 'ERROR: service [%s] is still running...stop service first.', $task_name )
      if $self->is_service_running($task_name);
  }

  if ( !$dryrun ) {
    $self->log_error('WARNING: "dryrun" mode not enabled...resources will be removed!');
  }

  my $confirm_all = $self->get_confirm_all;

  ######################################################################
  # -- delete log group
  ######################################################################
  if ( $num_tasks == 1 ) {
    $self->_delete_log_group( $confirm_all, $task_name );
  }

  ######################################################################
  # -- delete roles & policies
  ######################################################################
  if ( $num_tasks == 1 ) {
    $self->_delete_roles( $confirm_all, $task_name, $type );
  }

  ######################################################################
  # -- delete scheduled task
  ######################################################################
  if ( $type eq 'scheduled' ) {
    $self->_delete_scheduled_task( $confirm_all, $task_name );
  }

  ######################################################################
  # -- delete task definitions
  ######################################################################
  $self->_delete_task_definitions( $confirm_all, $task_name );

  ######################################################################
  # -- delete service
  ######################################################################

  if ( $type =~ /^(?:daemon|https?)$/xsm ) {
    ####################################################################
    # -- remove alias record
    ####################################################################
    if ( $type ne 'daemon' ) {
      $self->_delete_alias_record($confirm_all);
    }

    $self->_delete_service( $confirm_all, $task_name, $type );
  }

  ######################################################################
  # -- delete http(s)
  ######################################################################
  if ( $type =~ /^(?:https?)$/xsm ) {
    $self->_delete_http( $confirm_all, $task_name );
  }

  ####################################################################
  # -- remove target group
  ####################################################################
  $self->_delete_target_group( $confirm_all, $task_name );

  ######################################################################
  # -- delete security group
  ######################################################################
  if ( $num_tasks == 1 ) {
    $self->_delete_security_group( $confirm_all, $task_name );
  }

  ######################################################################
  # -- delete cluster
  ######################################################################
  if ( $num_tasks == 1 ) {
    $self->_delete_cluster( $confirm_all, $task_name );
  }

  ######################################################################
  # -- iam role (resource changes may require new policy)
  ######################################################################
  if ( $num_tasks != 1 ) {
    $self->log_warn('iam: looking to see if we need to update role...');
    $self->build_iam_role();
  }

  ######################################################################
  # NOTE: Skeletons of deleted tasks are left in the confguration file
  # for single task config and for multi-task configs. --purge-config
  # will allow purging of tasks in multi-task configs only...
  ######################################################################
  if ( $self->get_purge_config ) {
    delete $tasks->{$task_name};
  }

  if ( !$dryrun ) {
    delete $config->{id};
    delete $config->{last_updated};

    $self->update_config;
    $self->log_info(
      'builder: A skeleton configuration remains that will allow you to recreate the stack. Run "app-FargateStack plan" to rehydrate your configuration.'
    );
  }

  return $SUCCESS;
}

########################################################################
sub _delete_cluster {
########################################################################
  my ( $self, $confirm_all, $service_name, $type ) = @_;

  my ( $config, $dryrun, $tasks, $cluster ) = $self->common_args(qw(config dryrun tasks cluster));

  my $cluster_name = $cluster->{name};
  my $confirmed    = $confirm_all ? confirm( 'cluster: delete cluster: [%s]', $cluster_name ) : $TRUE;

  if ($confirmed) {
    my $ecs = $self->fetch_ecs;

    $self->log_warn( 'cluster: [%s] will be deleted...%s', $cluster_name, $dryrun );

    if ( !$dryrun ) {
      my $result = $ecs->delete_cluster($cluster_name);
      $ecs->check_result(
        message => 'ERROR: could not delete cluster: [%s]',
        params  => [$cluster_name],
        regexp  => qr/nosuchentity/xmsi,
        warn    => $TRUE,
      );

      $self->log_warn( 'cluster: [%s] deleted successfully...status: [%s]', $cluster_name, $result->{cluster}->{status} );

      delete $config->{cluster};
    }
  }
  else {
    $self->log_warn( 'cluster: deletion skipped...%s', $dryrun );
  }
  return;
}

########################################################################
sub _delete_alias_record {
########################################################################
  my ( $self, $confirm_all, $service_name, $type ) = @_;

  my ( $config, $dryrun, $tasks, $alb ) = $self->common_args(qw(config dryrun tasks alb));
  my $domain = $config->{domain};

  return  # belt & suspenders...we should never get here
    if !$domain;

  my $confirmed = $confirm_all ? confirm( 'route53: delete alias record for: [%s]', $domain ) : $TRUE;

  if ($confirmed) {
    $self->log_warn( 'route53: alias record for: [%s] will be deleted...%s', $domain, $dryrun );

    if ( !$dryrun ) {
      $self->remove_alias_record( $alb->{arn} );
    }
  }
  else {
    $self->log_warn( 'route53: alias record deletion skipped...%s', $dryrun );
  }

  return;
}

########################################################################
sub _delete_service {
########################################################################
  my ( $self, $confirm_all, $service_name, $type ) = @_;

  my ( $config, $dryrun, $tasks ) = $self->common_args(qw(config dryrun tasks));

  my $confirmed = $confirm_all ? confirm( 'service: delete %s service?', $type ) : $TRUE;

  if ($confirmed) {

    $self->log_warn( 'service: [%s] will be deleted...%s', $service_name, $dryrun );

    if ( !$dryrun ) {
      my $ecs = $self->fetch_ecs;

      $ecs->delete_service( $config->{cluster}->{name}, $service_name );

      $ecs->check_result(
        message => 'ERROR: could not delete ECS service: [%s]',
        params  => [$service_name],
        regexp  => qr/notfound/xsmi,
        warn    => $TRUE,
      );
    }
  }
  else {
    $self->log_warn( 'service: deletion skipped...%s', $dryrun );
  }

  return;
}

########################################################################
sub _delete_task_definitions {
########################################################################
  my ( $self, $confirm_all, $task_name ) = @_;

  my ( $config, $dryrun, $tasks ) = $self->common_args(qw(config dryrun tasks));

  my $confirmed = $confirm_all ? confirm( 'task: delete all task definitions for: [%s]', $task_name ) : $TRUE;

  if ($confirmed) {
    my $ecs = $self->fetch_ecs;

    my $task_definitions = $ecs->list_task_definitions( $task_name, 'taskDefinitionArns' );
    $self->log_warn( 'task: definitions for: [%s] will be deleted...%s', $task_name, $dryrun );

    if ( !$dryrun ) {
      if ( $task_definitions && @{$task_definitions} ) {
        $ecs->delete_task_definitions($task_definitions);
        $ecs->check_result( message => 'ERROR: could not delete task definitions' );
      }

      $task_definitions = $ecs->list_task_definitions( $task_name, 'taskDefinitionArns' );
      $ecs->check_result( message => 'ERROR: could not list task definitions' );

      # this should happen...delete_task_definitions() will croak if a
      # task definition cannot be deregistered and deleted
      croak "ERROR: could not delete all task definitions\n"
        if @{$task_definitions};

      delete $tasks->{$task_name}->{arn};
    }
  }
  else {
    $self->log_warn( 'task: definition deletion skipped...%s', $dryrun );
  }

  return;
}

########################################################################
sub _delete_scheduled_task {
########################################################################
  my ( $self, $confirm_all, $task_name, $type ) = @_;

  my ( $config, $dryrun, $tasks ) = $self->common_args(qw(config dryrun tasks));

  ######################################################################
  # -- delete schedule task
  ######################################################################
  my $confirmed = $confirm_all ? confirm( 'Delete scheduled task: [%s]', $task_name ) : $TRUE;

  if ($confirmed) {
    # -- delete target event
    my $events = $self->fetch_events;

    my $rule_name = $self->create_default( 'rule-name', $task_name );
    my $rule_id   = $self->create_default( 'rule-id',   $task_name );

    $self->log_warn( 'scheduled task: [%s] will be deleted...%s', $task_name, $dryrun );

    ####################################################################
    # -- remove target
    ####################################################################
    if ( !$dryrun ) {
      $self->log_warn( 'scheduled task: deleting target for rule: [%s:%s]', $rule_name, $rule_id );
      $events->remove_targets( $rule_name, $rule_id );
      $events->check_result(
        message => 'ERROR: could not remove target for rule: [%s], id: [%s]',
        params  => [ $rule_name, $rule_id ],
        regexp  => qr/notfound/xsmi
      );

      ####################################################################
      # -- delete rule
      ####################################################################
      $self->log_warn( 'scheduled task: deleting rule: [%s]', $rule_name );
      $events->delete_rule($rule_name);
      $events->check_result( message => 'ERROR: could not remove rule: [%s]', params => [$rule_name] );

      $self->log_warn( 'schedule task: scheduled task: [%s] successfully deleted...', $task_name );
    }
  }
  else {
    $self->log_warn( 'event deletion skipped...%s', $dryrun );
  }

  return;
}

########################################################################
sub _delete_roles {
########################################################################
  my ( $self, $confirm_all, $task_name, $type ) = @_;

  my ( $config, $dryrun ) = $self->common_args(qw(config dryrun));

  my $confirmed = $confirm_all ? confirm( 'iam: delete roles & policies for task: [%s]?', $task_name ) : $TRUE;

  ######################################################################
  # -- delete roles & policies
  ######################################################################
  if ($confirmed) {

    my $iam = $self->fetch_iam();

    my @roles = ( 'role', $type eq 'scheduled' ? 'events_role' : () );

    foreach my $r (@roles) {
      my $role = $config->{$r};
      my ( $role_arn, $role_name, $policy_name ) = @{$role}{qw(arn name policy_name)};

      if ( !defined $role_name && !defined $role_arn ) {
        $self->log_warn('iam: role not defined in configuration...skipping deletion');
        delete $role->{arn};
        next;
      }

      ####################################################################
      # -- delete role policy
      ####################################################################
      $self->log_warn( 'iam: role: [%s] and policy: [%s] will be deleted...%s', $role_name, $policy_name, $dryrun );

      if ( !$dryrun ) {
        $iam->delete_role_policy( $role_name, $policy_name );
        $iam->check_result(
          message => 'ERROR: could not delete role policy: [%s]',
          params  => [$policy_name],
          regexp  => qr/nosuchentity/xsmi
        );

        delete $role->{policy_name};

        ####################################################################
        # -- delete role
        ####################################################################
        $iam->delete_role($role_name);
        $iam->check_result(
          message => 'ERROR: could not delete role: [%s]',
          params  => [$role_name],
          regexp  => qr/nosuchentity/xsmi
        );

        delete $role->{name};
        delete $role->{arn};
      }
    }
  }
  else {
    $self->log_warn( 'iam: role & policy deletion skipped...%s', $dryrun );
  }

  return;
}

########################################################################
sub _delete_log_group {
########################################################################
  my ( $self, $confirm_all, $task_name ) = @_;

  my ( $config, $dryrun, $tasks ) = $self->common_args(qw(config dryrun tasks));

  my ( $log_group, $log_group_arn ) = @{ $config->{log_group} }{qw(name arn)};

  if ( !$log_group && !$log_group_arn ) {
    $self->log_warn('logs: log group not defined in configuration file...skipping deletion');
    return;
  }

  my $confirmed = $confirm_all ? confirm( 'logs: delete log group: [%s]?', $log_group ) : $TRUE;

  if ( !$confirmed ) {
    $self->log_warn('log: log group deletion skipped...');
    return;
  }

  my $logs = $self->fetch_logs();
  if ( !$log_group ) {
    $log_group = ( split /:/xsm, $log_group_arn )[-1];
  }

  $self->log_warn( 'logs: log group: [%s] will be deleted...%s', $log_group, $dryrun );

  return
    if $dryrun;

  $logs->delete_log_group($log_group);

  $logs->check_result(
    message => 'ERROR: could not delete log group: %s',
    params  => [$log_group],
    regexp  => qr/notfound/xsmi
  );

  delete $config->{log_group};

  return;
}

########################################################################
sub _delete_security_group {
########################################################################
  my ( $self, $confirm_all, $task_name ) = @_;

  my ( $config, $dryrun, $security_groups, $tasks ) = $self->common_args(qw(config dryrun security_groups tasks));

  my $ec2 = $self->fetch_ec2;

  my $efs_config = $tasks->{$task_name}->{efs};

  my $sg_id = $security_groups->{fargate}->{group_id};

  if ( !$sg_id ) {
    $self->log_warn('ec2: no security group defined in configuration...skipping deletion');
    return;
  }

  my $confirmed = $confirm_all ? confirm( 'ec2: delete security_group: [%s]?', $sg_id ) : $TRUE;

  if ($confirmed) {
    if ( $efs_config && $efs_config->{authorize_ingress} ) {
      $self->log_warn( q{ec2: fargate task's ingress to EFS will be revoked...%s}, $dryrun );

      if ( !$dryrun ) {
        $self->revoke_efs_ingress( $sg_id, $efs_config->{id} );
      }
    }

    $self->log_warn( 'ec2: security group: [%s] will be deleted...%s', $sg_id, $dryrun );

    if ( !$dryrun ) {

      while ($TRUE) {
        $ec2->delete_security_group($sg_id);

        $ec2->check_result(
          message => 'ERROR: could not delete security_group: %s',
          params  => [$sg_id],
          regexp  => qr/notfound|invalid|dependency/xsmi
        );

        last if !$ec2->get_error || $ec2->get_error !~ /dependency/xsmi;

        sleep 2;

        $self->log_info('ec2: waiting for ENI to release security group...');
      }

      delete $security_groups->{fargate};
    }

  }
  else {
    $self->log_warn( 'ec2: security group deletion skipped...%s', $dryrun );
  }

  return;
}

########################################################################
sub _delete_target_group {
########################################################################
  my ( $self, $confirm_all, $task_name ) = @_;

  my ( $tasks, $dryrun ) = $self->common_args(qw(tasks dryrun));

  my $elbv2 = $self->fetch_elbv2;

  my $target_group_arn = $tasks->{$task_name}->{target_group_arn};

  if ( !$target_group_arn ) {
    $self->log_warn('elbv2: no target group defined in configuration...skipping target group deletion');
    return $FALSE;
  }

  my $confirmed = $confirm_all ? confirm( 'elbv2: delete target group for task: [%s]', $task_name ) : $TRUE;

  if ($confirmed) {
    $self->log_warn( 'elbv2: target group for task: [%s] will be removed...%s', $task_name, $dryrun );

    if ( !$dryrun ) {
      $elbv2->delete_target_group($target_group_arn);
      $elbv2->check_result( message => 'ERROR: could not delete target group: [%s]', params => [$target_group_arn] );

      delete $tasks->{$task_name}->{target_group_arn};
      delete $tasks->{$task_name}->{target_group_name};
    }
  }
  else {
    $self->log_warn( 'elbv2: target group deletion skipped...%s', $dryrun );
  }

  return;
}

########################################################################
sub _delete_http {
########################################################################
  my ( $self, $confirm_all, $task_name ) = @_;

  my ( $config, $tasks, $dryrun, $security_groups ) = $self->common_args(qw(config tasks dryrun security_groups));

  my $alb_sg = $security_groups->{alb}->{group_id};

  my $alb_arn = $config->{alb}->{arn};

  if ( !$alb_arn ) {
    $self->log_warn('elbv2: no ALB  in config...skipping ALB teardown');
    return $FALSE;
  }

  my $target_group_arn = $tasks->{$task_name}->{target_group_arn};

  if ( !$target_group_arn ) {
    $self->log_warn('elbv2: no target group in config...skipping ALB teardown');
    return $FALSE;
  }

  my $type = $tasks->{$task_name}->{type};

  my $confirmed = $confirm_all ? confirm( 'elbv2: delete %s service?', $type ) : $TRUE;

  if ( !$confirmed ) {
    $self->log_warn( 'elbv2: skipping deletion of %s service', $task_name );

    return;
  }

  ####################################################################
  # -- remove ALB if it was provisioned by App::FargateStack
  ####################################################################

  if ( !$self->alb_exists($alb_arn) ) {
    delete $config->{alb}->{arn};
    $self->log_warn( 'elbv2: ALB: [%s] does not exists...skipping deletion', $alb_arn );

    return;
  }

  my $is_our_alb = $self->is_our_alb( $alb_arn, $target_group_arn );

  if ( !$is_our_alb ) {
    $self->log_warn('elbv2: ALB was not provisioned by App::FargateStack...only deleting listerner rules.');

    my $confirmed = $confirm_all ? confirm( 'elbv2: delete listener rules on ALB: [%s]?', $alb_arn ) : $TRUE;

    if ($confirmed) {
      $self->log_warn( 'elbv2: listener rules for ALB: [%s] will be deleted...%s', $alb_arn, $dryrun );
      $self->remove_listener_rules($alb_arn);
    }
    else {
      $self->log_warn('elbv2: skipping deletion of listener rules');
    }

    return;
  }

  $confirmed = $confirm_all ? confirm( 'elbv2: delete ALB: [%s]?', $alb_arn ) : $TRUE;

  if ($confirmed) {
    $self->log_warn( 'elbv2: ALB: [%s] and its listener rules will be deleted...%s', $alb_arn, $dryrun );

    if ( !$dryrun ) {
      my $ec2   = $self->fetch_ec2;
      my $elbv2 = $self->fetch_elbv2;

      $elbv2->delete_load_balancer($alb_arn);
      $elbv2->check_result( message => 'could not delete load balancer: [%s]', params => [$alb_arn] );

      if ( $self->wait_for_alb_delete() ) {
        $self->log_warn( 'elbv2: successfully deleted ALB: [%s]', $alb_arn );

        delete $config->{alb}->{arn};
      }
      else {
        log_die( $self, 'elbv2: deletion of ALB: [%s] may have failed or has not completed yet.', $alb_arn );
      }

      ####################################################################
      # -- remove security group
      ####################################################################
      $self->log_warn( 'elbv2: security group for ALB on task: [%s] will be removed...%s', $task_name, $dryrun );
      $ec2->revoke_security_group_ingress(
        group_id     => $config->{security_groups}->{fargate}->{group_id},
        source_group => $alb_sg,
        port         => $config->{alb}->{port},
        protocol     => 'tcp',
      );

      my $err = 'dependency';

      while ( $err =~ /dependency/xsmi ) {
        $ec2->delete_security_group($alb_sg);
        sleep 2;
        $err = $ec2->get_error;
      }

      $ec2->check_result(
        message => 'ERROR: could not delete security group: [%s]',
        params  => [$alb_sg],
        regexp  => qr/notfound/xsmi
      );

      delete $security_groups->{alb};
    }
  }
  else {
    $self->log_warn('elbv2: skipping deletion of ALB');
  }

  return;
}

########################################################################
sub alb_exists {
########################################################################
  my ( $self, $alb_arn ) = @_;

  return
    if !$alb_arn;

  my $elbv2 = $self->fetch_elbv2;
  $elbv2->describe_load_balancer($alb_arn);

  return $elbv2->get_error =~ /notfound/xsmi ? $FALSE : $TRUE;
}

########################################################################
sub wait_for_alb_delete {
########################################################################
  my ($self) = @_;

  my $alb_arn = $self->get_config->{alb}->{arn};

  my $tries = $DEFAULT_ALB_MAX_TRIES;

  my $elbv2 = $self->fetch_elbv2;

  while ( $tries-- > 0 ) {
    my $result = $elbv2->describe_load_balancer($alb_arn);

    $self->log_debug( Dumper( [ result => $result ] ) );

    return $TRUE if !$result && $elbv2->get_error =~ /notfound/xsmi;
    sleep $DEFAULT_ALB_POLL_SLEEP_TIME;
  }

  return $FALSE;
}

########################################################################
sub is_our_alb {
########################################################################
  my ( $self, $alb_arn, $tg_arn ) = @_;

  my $elb = $self->get_elbv2;

  croak "usage: is_our_alb(alb-arn, target-group-arn)\n"
    if !$alb_arn || !$tg_arn;

  my $tags = $elb->describe_tags( $alb_arn, 'TagDescriptions[].Tags[]' );

  my ($ours) = grep { $_->{Key} eq 'CreatedBy' && $_->{Value} eq 'FargateStack' } @{$tags};

  return $TRUE
    if $ours;

  # get listener rules and see if our ALB is default by finding
  # default and seeing if its target group (if any) is our target
  # group...
  my $result = $elb->describe_listeners( $alb_arn, 'Listeners[0]' );
  $elb->check_result( message => 'ERROR: could not describe listeners for: [%s]', $alb_arn );
  my $listener_arn = $result->{ListenerArn};

  $result = $elb->describe_rules( $result->{ListenerArn}, 'Rules[]' );
  $elb->check_result( message => 'ERROR: could not describe rule for listener: [%s]', $listener_arn );

  my ($default) = grep { $_->{IsDefault} } @{$result};

  my $default_tg_arn = $default->{Actions}->[0]->{TargetGroupArn};

  return $default_tg_arn && $default_tg_arn eq $tg_arn;
}

########################################################################
sub remove_alias_record {
########################################################################
  my ( $self, $alb_arn ) = @_;

  my $config = $self->get_config;

  my $elb = $self->fetch_elbv2;

  my $domain = $config->{domain};

  my $route53 = $self->fetch_route53;

  my $zone_id = $config->{route53}->{zone_id};

  my $query = sprintf 'ResourceRecordSets[?Name == `%s.`]', $domain;

  my $resource_record_set = $route53->list_resource_record_sets( $zone_id, $query );
  $route53->check_result(
    message => 'ERROR: could not list resource record sets in zone: [%s]',
    params  => [$zone_id],
    regexp  =>
  );

  if ( !@{$resource_record_set} ) {
    $self->log_warn( 'route53: alias record for: [%s]not found...skipping deletion', $domain );
    return;
  }

  my $change_batch = {
    ChangeBatch => {
      Changes => [
        { Action            => 'DELETE',
          ResourceRecordSet => $resource_record_set->[0],
        }
      ]
    }
  };

  $route53->change_resource_record_sets( $zone_id, $change_batch );
  $route53->check_result(
    message => 'ERROR: could not delete alias record for domain: [%s]',
    params  => [$domain],
    regexp  => qr/not\sfound/xsmi,
    warn    => $TRUE,
  );

  return;
}

########################################################################
sub get_efs_sgs {
########################################################################
  my ( $self, $efs_config ) = @_;

  my $ec2 = $self->get_ec2;

  my $efs    = $self->fetch_efs();
  my $efs_id = $efs_config->{id};

  my $eni_list = $efs->describe_mount_targets( $efs_id, 'MountTargets[].NetworkInterfaceId' );
  $efs->check_result( message => 'ERROR: could not describe mount targets for: [%s]', $efs_id );

  my $sgs = $ec2->describe_network_interfaces( $eni_list, 'NetworkInterfaces[].Groups[].GroupId' );
  $ec2->check_result( message => 'ERROR: could not describe network interfaces for: [%s]', join q{,}, @{$eni_list} );

  $efs_config->{security_groups} = [ uniq @{$sgs} ];

  return $efs_config->{security_groups};
}

########################################################################
sub is_efs_ingress_authorized {
########################################################################
  my ( $self, $efs_config ) = @_;

  my $fargate_sg = $self->get_config->{security_groups}->{fargate}->{group_id};
  my $efs_sgs    = $efs_config->{security_groups};

  my $ec2 = $self->fetch_ec2;

  my $filters = sprintf 'Name=group-id,Values=%s', join q{,}, @{$efs_sgs};
  my $query = sprintf 'SecurityGroupRules[?IsEgress == `false` && ReferencedGroupInfo.GroupId == `%s`]|[0]', $fargate_sg;

  my $ingress_rules = $ec2->describe_security_group_rules(
    filters => $filters,
    query   => $query
  );

  $ec2->check_result( message => 'ERROR: could not describe security group rules', join q{,}, @{$efs_sgs} );

  return
    if !$ingress_rules;

  return $ingress_rules->{FromPort} == $DEFAULT_EFS_PORT && $ingress_rules->{ToPort} == $DEFAULT_EFS_PORT;
}

########################################################################
sub authorize_efs_ingress {
########################################################################
  my ( $self, $task_sg, $efs_config ) = @_;

  my $dryrun = $self->get_dryrun;

  my $efs_sgs = $efs_config->{security_groups} // $self->get_efs_sgs($efs_config);

  dmp efs_config => $efs_config;

  my $ec2 = $self->fetch_ec2;

  return
    if $dryrun;

  foreach my $efs_sg ( @{$efs_sgs} ) {
    $ec2->authorize_security_group_ingress(
      'group_id'     => $efs_sg,
      'protocol'     => 'tcp',
      'port'         => $DEFAULT_EFS_PORT,
      'source_group' => $task_sg,
    );

    last
      if !$ec2->check_result(
      { message => 'ERROR: could not authorize ingress for: [%s] to EFS: [%s]',
        params  => [ $task_sg, $efs_sg ],
        regexp  => qr/already\sexists/xsmi
      }
      );  # assume if one ingress rule exists on the sg, all exist?
  }

  return;
}

########################################################################
sub revoke_efs_ingress {
########################################################################
  my ( $self, $task_sg, $efs_id ) = @_;

  my @efs_sgs = $self->get_efs_sgs($efs_id);

  my $ec2 = $self->get_ec2;

  foreach my $efs_sg (@efs_sgs) {
    my $result = $ec2->revoke_security_group_ingress(
      '--group-id'     => $efs_sg,
      '--protocol'     => 'tcp',
      '--port'         => $DEFAULT_EFS_PORT,
      '--source-group' => $task_sg,
    );

    next if $result || $ec2->get_error =~ /notfound/xsmi;

    croak sprintf "ERROR: could not revoke security group ingress for: [%s]\n%s", $efs_sg, $ec2->get_error;
  }

  return;
}

1;
