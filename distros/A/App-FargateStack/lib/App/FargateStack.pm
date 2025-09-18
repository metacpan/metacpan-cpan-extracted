package App::FargateStack;

########################################################################
# Copyright (C) 2025, TBC Development Group, LLC All rights reserved.  #
# This is free software and may be modified or redistributed under the #
# same terms as Perl itself.                                           #
#                                                                      #
# Repository: https://github.com/rlauer6/App-Fargate                   #
########################################################################

use strict;
use warnings;

use App::FargateStack::Builder::Utils qw(jmespath_mapping toCamelCase dmp choose confirm);
use App::FargateStack::Constants;
use App::FargateStack::Pod;
use Carp;
use CLI::Simple;
use CLI::Simple::Constants qw(:booleans :chars %LOG_LEVELS);
use Cwd qw(realpath);
use Data::Dumper;
use Date::Parse qw(str2time);
use English qw(no_match_vars);
use File::Basename qw(basename fileparse);
use List::Util qw(none any);
use Log::Log4perl;
use Pod::Usage;
use Scalar::Util qw(reftype looks_like_number);
use Text::ASCIITable::EasyTable;
use Term::ANSIColor;
use YAML qw(LoadFile);

use Role::Tiny::With;

# command methods
with 'App::FargateStack::Init';
with 'App::FargateStack::Logs';
with 'App::FargateStack::Route53';
with 'App::FargateStack::CloudTrail';
with 'App::FargateStack::CreateStack';
with 'App::FargateStack::Autoscaling';

with 'App::Benchmark';

# builder methods
with 'App::FargateStack::Builder';
with 'App::FargateStack::Builder::Autoscaling';
with 'App::FargateStack::Builder::IAM';
with 'App::FargateStack::Builder::Certificate';
with 'App::FargateStack::Builder::Events';
with 'App::FargateStack::Builder::EFS';
with 'App::FargateStack::Builder::HTTPService';
with 'App::FargateStack::Builder::Cluster';
with 'App::FargateStack::Builder::LogGroup';
with 'App::FargateStack::Builder::SecurityGroup';
with 'App::FargateStack::Builder::Secrets';
with 'App::FargateStack::Builder::Service';
with 'App::FargateStack::Builder::S3Bucket';
with 'App::FargateStack::Builder::SQSQueue';
with 'App::FargateStack::Builder::TaskDefinition';
with 'App::FargateStack::Builder::Utils';
with 'App::FargateStack::Builder::WafV2';

our $VERSION = '1.0.43';

use parent qw(CLI::Simple);

__PACKAGE__->use_log4perl( config => $LOG4PERL_CONF );

caller or __PACKAGE__->main;

########################################################################
sub init_logger {
########################################################################
  my ($self) = @_;

  my $log4perl_conf = $self->get_log4perl_conf;

  if ( !$self->get_color ) {
    $log4perl_conf =~ s/ColoredLevels//xsm;

    if ( $self->get_log_level && $self->get_log_level =~ /debug|trace/xsm ) {
      $log4perl_conf =~ s/ConversionPattern(.*?)$/ConversionPattern = [%d] (%M:%L) %m%n/xsm;
    }
  }

  $self->set_log4perl_conf($log4perl_conf);

  return $self->SUPER::init_logger;
}

########################################################################
sub show_config {
########################################################################
  my ($self) = @_;

  my $config = $self->get_config;

  my $subnets = $self->get_subnets;

  my $dryrun = $self->command eq 'plan' ? '(dryrun)' : $self->get_dryrun;

  $self->section_break;

  $self->log_info( '           account: [%s]', $self->get_account );
  $self->log_info( '           profile: [%s]', $self->get_profile );
  $self->log_info( '    profile source: [%s]', $self->get_profile_source );
  $self->log_info( '            region: [%s]', $self->get_region );
  $self->section_break;

  $self->log_info( '   route53 profile: [%s]', $config->{route53}->{profile} // q{-} );
  $self->log_info( '   route53 zone_id: [%s]', $config->{route53}->{zone_id} // q{-} );
  $self->section_break;

  $self->log_info( '          app name: [%s]', $config->{app}->{name} );
  $self->log_info( '       app version: [%s]', $config->{app}->{version} // q{-} );
  $self->log_info( '     https service: [%s]', $self->get_http           // q{-} );
  $self->log_info( '  scheduled events: [%s]', $self->has_events ? 'yes' : 'no' );
  $self->section_break;

  $self->log_info( '    subnets in VPC: [%s]', $config->{vpc_id} );
  $self->log_info( '            public: [%s]', join q{,}, @{ $subnets->{public}  || [] } );
  $self->log_info( '           private: [%s]', join q{,}, @{ $subnets->{private} || [] } );
  $self->section_break;

  $self->log_info( '            config: [%s]', $self->get_config_name );
  $self->log_info( '         log level: [%s]', $self->get_log_level // 'info' );
  $self->log_info( '             cache: [%s]', $self->get_cache ? 'enabled' : 'disabled' );
  $self->log_warn( '     update config: [%s]', $self->get_update ? 'yes' : 'no' );
  $self->log_warn( '            dryrun: [%s]', $dryrun           ? 'yes' : 'no' );

  return;
}

########################################################################
sub check_service_name {
########################################################################
  my ( $self, $service_name, $return_on_missing ) = @_;

  my $tasks = $self->common_args('tasks');

  # if only 1 service in config, then let's stat that
  if ( !$service_name ) {
    my ( $default_service, $error ) = grep { $tasks->{$_}->{type} =~ /daemon|http/xsm } keys %{$tasks};

    return
      if !$default_service && $return_on_missing;

    die sprintf "usage: %s status task-name\n", $ENV{SCRIPT_NAME}
      if $error || !$default_service;

    $service_name = $default_service;
  }

  return $service_name;
}

########################################################################
sub cmd_state {
########################################################################
  my ( $self, @args ) = @_;

  my ($config_name) = $self->get_args;

  my $options = $self->fetch_option_defaults;

  my $defaults_file = '.fargatestack/defaults.json';

  if ($config_name) {
    my ( $name, $path, $ext ) = fileparse( $config_name, qr/[.][^.]+$/xsm );

    $path = realpath($path);

    my $fqp = sprintf '%s/%s%s', $path, $name, $ext || 'yml';

    die sprintf "ERROR: file not found: [%s]\n", $fqp
      if !-s $fqp;

    $options->{config} = $fqp;

    $self->write_json_file( $defaults_file, $options );
    $config_name = $name;
  }

  my $data = [
    { Profile       => $options->{profile},
      'DNS Profile' => $options->{route53_profile},
      'Max Events', => $options->{max_events},
      'Config'      => $options->{config},
      'Region'      => $options->{region},
    }
  ];

  my @columns = ( 'Profile', 'DNS Profile', 'Region', 'Config', 'Max Events' );

  print {*STDOUT} easy_table(
    table_options => { headingText => sprintf 'Current Defaults: %s', $config_name },
    columns       => \@columns,
    data          => $data,
  );

  return $SUCCESS;
}

########################################################################
sub cmd_show {
########################################################################
  my ( $self, @args ) = @_;

  my ($command) = $self->get_args;

  my %sub_commands = ( 'cloudtrail-events' => \&cmd_cloudtrail_events, );

  die sprintf "ERROR: not a valid command. Must be one of: \n\t%s\n", join "\n\t", keys %sub_commands
    if !$sub_commands{$command};

  return $sub_commands{$command}->($self);
}

########################################################################
sub cmd_service_status {
########################################################################
  my ( $self, @args ) = @_;

  my $service_name = $self->check_service_name( @args, $self->get_args );

  my ( $cluster, $tasks ) = $self->common_args(qw(cluster tasks));

  my $cluster_name = $cluster->{name};

  $self->verify_service($service_name);

  require Text::Wrap;
  Text::Wrap->import('wrap');

  {
    ## no critic
    no warnings 'once';
    $Text::Wrap::columns = 100;
  }

  my @elems = qw(running_count desired_count status pending_count events task_definition);

  my $query = jmespath_mapping 'services[0]' => \@elems;
  my $ecs   = $self->fetch_ecs;

  my $result = $ecs->describe_services(
    cluster_name => $cluster_name,
    service_name => $service_name,
    query        => $query,
  );

  log_die( $self, "ERROR: could not describe service [%s]\n%s", $service_name, $self->get_ecs->get_error )
    if !$result;

  my ( $running_count, $desired_count, $status, $pending_count, $events, $task_definition_arn )
    = @{$result}{@elems};

  $pending_count //= q{-};

  $status = $self->maybe_color( $status eq 'ACTIVE' ? 'bright_green' : 'bright_yellow' => $status );

  my $title = sprintf "Service:[%s]\n", $self->maybe_color( bright_white => $service_name );

  $title .= sprintf "Status:[%s] Running:[%s] Pending:[%s] Desired:[%s]\n",
    $status,
    $self->maybe_color( green        => $running_count ),
    $self->maybe_color( yellow       => $pending_count ),
    $self->maybe_color( bright_white => $desired_count );

  $title .= sprintf 'Task Definition: [%s]', $self->maybe_color( 'bright_white' => $task_definition_arn );

  my @events = grep {defined} @{ $result->{events} }[ 0 .. ( $self->get_max_events - 1 ) ];

  my @data = map { { 'Time' => $_->{createdAt}, Event => wrap( q{}, q{}, $_->{message} ) } } @events;

  print {*STDOUT} easy_table(
    table_options => { headingText => $title, allowANSI => $TRUE },
    data          => \@data,
    columns       => [qw(Time Event)],
  );

  $self->display_task_status($service_name);

  return $SUCCESS;
}

########################################################################
sub display_task_status {
########################################################################
  my ( $self, $service_name ) = @_;

  my $ecs = $self->fetch_ecs;

  my $cluster_name = $self->get_config->{cluster}->{name};

  my $task_arns = $ecs->list_tasks( $cluster_name, 'taskArns' );
  $ecs->check_result( message => 'ERROR: could not list tasks for cluster: [%s]', $cluster_name );

  return
    if !@{$task_arns};

  $task_arns = [ map { basename($_) } @{$task_arns} ];

  my $query
    = sprintf
    'tasks[?group == `service:%s`].{started_at:startedAt, task_definition_arn:taskDefinitionArn, last_status:lastStatus, image_digest:containers[0].imageDigest}',
    $service_name;

  my $service_tasks = $ecs->describe_tasks( $cluster_name, $task_arns, $query );
  $ecs->check_result( message => 'ERROR: Could not describe tasks: [%s]', join q{,}, @{$task_arns} );

  $self->log_debug( sub { return Dumper( [ service_tasks => $service_tasks ] ) } );

  my @data;

  foreach my $task ( @{$service_tasks} ) {
    my ( $image_digest, $task_definition_arn, $started_at, $last_status )
      = @{$task}{qw(image_digest task_definition_arn started_at last_status)};

    my $short_image_digest        = abbrev( $image_digest, 16 );
    my $short_task_definition_arn = ( split m{/}xsm, $task_definition_arn )[-1];

    my $latest_task_definition_arn = $self->get_latest_task_definition($service_name);

    my $latest_image_digest = $self->get_latest_image($service_name)->{imageDigest};

    $last_status = $self->maybe_color( $last_status eq 'RUNNING' ? 'green' : 'yellow' => $last_status );

    $self->log_debug(
      sub {
        return Dumper(
          [ task                => $task,
            latest_image_digest => $latest_image_digest
          ]
        );
      }
    );

    my $task_definition_status = choose {
      return $self->maybe_color( green => 'Current' )
        if $task_definition_arn eq $latest_task_definition_arn;

      return $self->maybe_color( red => ( split m{/}xsm, $latest_task_definition_arn )[-1] );
    };

    $image_digest //= q{};

    my $image_digest_status = choose {
      return $self->maybe_color( green => 'Current' )
        if $image_digest eq $latest_image_digest;

      return $self->maybe_color( red => abbrev( $latest_image_digest, 16 ) );
    };

    push @data,
      {
      'Started At'             => $started_at,
      'Status'                 => $last_status,
      'Task Definition'        => $short_task_definition_arn,
      'Task Definition Status' => $task_definition_status,
      'Image Digest'           => $short_image_digest,
      'Image Status'           => $image_digest_status,
      };
  }

  print {*STDOUT} "\n\n",
    easy_table(
    table_options => { headingText => 'Task Status', allowANSI => $TRUE },
    data          => \@data,
    columns       => [ 'Started At', 'Status', 'Task Definition', 'Task Definition Status', 'Image Digest', 'Image Status' ],
    );

  return;
}

########################################################################
sub get_default_task_name {
########################################################################
  my ( $self, $type, $filter ) = @_;

  my $tasks = $self->common_args('tasks');

  my ($task_name) = $self->get_args;

  return $task_name
    if $task_name;

  my @task_names = keys %{$tasks};

  return $task_names[0]
    if @task_names == 1;

  $type //= 'task';

  my @tasks = grep { $tasks->{$_}->{type} eq $type } keys %{$tasks};

  if ($filter) {
    @tasks = grep { defined $tasks->{$_}->{$filter} } @tasks;
  }

  # more than 1, error or we found just 1
  return $tasks[1] ? $EMPTY : $tasks[0];
}

########################################################################
sub cmd_run_task {
########################################################################
  my ($self) = @_;

  my ( $config, $tasks, $dryrun, $cluster, $security_groups )
    = $self->common_args(qw(config tasks dryrun cluster security_groups));

  my $task_name = $self->get_default_task_name('task');

  die sprintf "usage: %s run-task task-name\n", $ENV{SCRIPT_NAME}
    if !$task_name;

  my $task = $tasks->{$task_name};

  log_die( $self, "ERROR: no such task [%s] defined in config\n", $task_name )
    if !$task;

  log_die( $self, "ERROR: [%s] is not a task\n", $task_name )
    if $task->{type} ne 'task';

  my $subnet_id = $self->get_subnet_id;
  my $is_public = $FALSE;

  if ( !$subnet_id ) {
    my @subnets = @{ $self->get_subnets->{private} // [] };

    if ( !@subnets ) {
      $self->log_warn('run-task: using public subnets is not recommended...');
      @subnets = @{ $self->get_subnets->{public} // [] };
    }

    $subnet_id = $subnets[0];
  }
  elsif ( any { $subnet_id eq $_ } @{ $self->get_subnets->{public} // [] } ) {
    $self->log_error( 'run-task: subnet-id: [%s] is in a public subnet...consider running your jobs in a private subnet',
      $subnet_id );
    $is_public = $TRUE;
  }
  elsif ( none { $subnet_id eq $_ } @{ $self->get_subnets->{private} // [] } ) {
    log_die( $self, 'subnet: [%s] is not in a public or private subnet in this VPC.', $subnet_id );
  }

  my $network_configuration = {
    awsvpcConfiguration => {
      subnets        => [$subnet_id],
      securityGroups => [ $security_groups->{fargate}->{group_id} ],
      assignPublicIp => $is_public ? 'ENABLED' : 'DISABLED',
    }
  };

  # check for latest image...
  $self->check_latest_image($task_name);

  # this may be null if we are in dryrun mode and the config has not been updated
  my $cluster_name
    = $dryrun && !$cluster->{name}
    ? sprintf '%s-cluster', $config->{app}->{name}
    : $cluster->{name};

  $self->log_warn( 'run-task: cluster: [%s] launching task: [%s] in subnet: [%s]...%s',
    $cluster_name, $task_name, $subnet_id, $dryrun );

  $self->log_trace( sub { return Dumper( [ awsvpcConfiguration => $network_configuration ] ); } );

  return $SUCCESS
    if $dryrun;

  log_die( $self, 'run-task: cluster has not been created yet...run "apply" first' )
    if !$cluster_name;

  my $ecs = $self->fetch_ecs;

  my $result = $self->get_ecs->run_task(
    cluster               => $cluster->{name},
    task_definition       => $task_name,
    network_configuration => $network_configuration,
  );

  log_die( $self, "ERROR: could not run task [%s]\n%s\n", $task_name, $self->get_ecs->get_error )
    if !$result;

  my @failures = @{ $result->{failures} };

  log_die( $self, 'ERROR: task failed to launch: %s', Dumper( \@failures ) )
    if @failures;

  ($tasks) = @{ $result->{tasks} };

  my $task_arn = $tasks->{taskArn};

  my $should_wait = $self->get_wait ? '(waiting)' : $EMPTY;

  $self->log_warn( 'run-task: task [%s] launched. ARN: [%s]...%s', $task_name, $task_arn, $should_wait );

  my $poll_limit = $self->get_task_timeout / $DEFAULT_ECS_POLL_TIME;

  if ($should_wait) {
    my $poll_count = 0;

    while ( $poll_count++ < $poll_limit ) {

      my ( $status, $stopped_reason, $exit_code ) = $self->get_task_status( $cluster_name, $task_arn );

      $self->log_warn( 'run-task: task [%s] status: [%s], exit code:[%s], reason: [%s]',
        $task_name, map { $_ // q{-} } ( $status, $exit_code, $stopped_reason ) );

      last if $status eq 'STOPPED';

      sleep $DEFAULT_ECS_POLL_TIME;
    }

    my $log_group = $config->{log_group}->{name};

    # by convention our log groups are named after our app
    my $log_stream = sprintf '%s/%s/%s', $config->{app}->{name}, $task_name, ( split /\//xsm, $task_arn )[-1];

    require App::Logs;

    my $logs = App::Logs->new(
      %{ $self->get_global_options },
      log_group_name  => $log_group,
      log_stream_name => $log_stream
    );

    my $events = $logs->get_log_events();

    log_die( $self, "run-task: unable to get logs from log group: [%s], stream: [%s]\n%s",
      $log_group, $log_stream, $logs->get_error )
      if !$events;

    while ( $events && @{ $events->{events} } ) {

      foreach my $e ( @{ $events->{events} } ) {

        my ( $timestamp, $message ) = @{$e}{qw(timestamp message)};
        $timestamp = scalar localtime $timestamp / 1000;

        print {*STDOUT} sprintf "%s - %s\n", $timestamp, $message;
      }

      $events = $logs->get_next_log_events( $events->{nextForwardToken} );
    }
  }

  return $SUCCESS;
}

########################################################################
sub check_latest_image {
########################################################################
  my ( $self, $task_name ) = @_;

  my $tasks = $self->common_args('tasks');

  my $latest_image   = $self->get_latest_image($task_name);
  my $latest_digest  = $latest_image->{imageDigest};
  my $current_digest = $tasks->{$task_name}->{image_digest} // $EMPTY;

  if ( $current_digest && $current_digest ne $latest_digest ) {
    $self->log_error('run-task: You are not running the latest image!');
    $self->log_error( 'run-task: [%s] != [%s]', $latest_digest, $current_digest );
    $self->log_error('run-task: run "app-FargateStack register-task" to align the latest image with your task');

    log_die( $self, 'run-task: use --force to force service creation or align your task with new image' )
      if !$self->get_force;
  }

  return $TRUE;
}

########################################################################
sub get_task_status {
########################################################################
  my ( $self, $cluster_name, $task_arn ) = @_;

  my @elems = qw(last_status stopped_reason containers);

  my $query = jmespath_mapping 'tasks[0]' => \@elems;
  my $ecs   = $self->fetch_ecs;

  my $result = $ecs->describe_tasks( $cluster_name, $task_arn, $query );
  $ecs->check_result( message => 'ERROR: unable to describe task: [%s]', $task_arn );

  my ( $status, $stopped_reason, $containers ) = @{$result}{@elems};

  return ( $status, $stopped_reason, $containers->[0]->{exitCode} );
}

########################################################################
sub get_default_service_name {
########################################################################
  my ( $self, $skip_arg ) = @_;

  # skip retrieving the arg (used when we want to allow a count as the first arg)
  if ( !$skip_arg ) {
    my ($service_name) = $self->get_args;

    return $service_name
      if $service_name;
  }

  my $tasks = $self->get_config->{tasks};

  return grep { $tasks->{$_}->{type} =~ /^(https?|daemon)/xsm } keys %{$tasks};
}

########################################################################
sub cmd_deploy_service {
########################################################################
  my ($self) = @_;

  my ( $config, $tasks ) = $self->common_args(qw(config tasks));

  my ( $task_name, $desired_count ) = $self->get_args;

  if ( looks_like_number $task_name ) {
    $desired_count = $task_name;
    $task_name     = $EMPTY;
  }

  if ( !$task_name || !exists $tasks->{$task_name} ) {
    ( $task_name, my $err ) = $self->get_default_service_name($TRUE);  # skip arg

    if ( !$task_name || $err ) {
      $self->log_error( 'ERROR: no task-name or not a valid task-name: [%s]', $task_name // q{} );

      die sprintf "usage: %s deploy-service service-name\n", $ENV{SCRIPT_NAME};
    }
  }

  if ( !$desired_count || !looks_like_number $desired_count ) {
    $desired_count = $tasks->{$task_name}->{desired_count} // 1;
  }

  $self->log_info('service: checking to see if task and latest image are aligned...');

  $self->check_latest_image($task_name);

  return $self->build_service( $task_name, $desired_count );
}

########################################################################
sub check_task {
########################################################################
  my ( $self, $task_name, $warn ) = @_;

  my $level = $warn ? 'warn' : 'die';

  my $config = $self->get_config;

  return $TRUE
    if $task_name && $config->{tasks}->{$task_name};

  log_die( $self, 'ERROR:  no such task [%s] defined in config', $task_name )
    if $level eq 'die';

  $self->get_logger->warn( 'WARNING: no such task [%s] defined in config...trying anyway  ¯\_(ツ)_/¯', $task_name );

  return;
}

########################################################################
sub cmd_remove_service {
########################################################################
  my ($self) = @_;

  my ( $task_name, $err ) = $self->get_default_service_name();

  die "usage: %s remove-service task-name\n", $ENV{SCRIPT_NAME}
    if !$task_name || $err;

  my ( $config, $cluster, $dryrun ) = $self->common_args(qw(config cluster dryrun));

  my $cluster_name = $cluster->{name};

  $self->verify_service($task_name);

  $self->check_task( $task_name, 'warn' );

  $self->log_warn( 'remove-service: task [%s] will be deleted...%s', $task_name, $dryrun );

  return $SUCCESS
    if $dryrun;

  my $ecs = $self->fetch_ecs;

  my $result = $ecs->delete_service( $cluster->{name}, $task_name );
  $ecs->check_result( message => 'ERROR: could not stop service %s', $task_name );

  return $SUCCESS;
}

########################################################################
sub verify_service {
########################################################################
  my ( $self, $service_name ) = @_;

  my ( $cluster, $config ) = $self->common_args(qw(cluster config));

  my $cluster_name //= $cluster->{name};

  my $ecs = $self->fetch_ecs;

  my $services = $ecs->list_services( $cluster_name, 'serviceArns' );

  die sprintf "ERROR: could not list services for cluster: [%s]\n%s", $cluster_name, $ecs->get_error
    if !$services;

  die sprintf "ERROR: no services running in cluster: [%s]\n", $cluster_name
    if !@{$services};

  die sprintf "ERROR: service [%s] is not running in cluster: [%s]\n", $service_name, $cluster_name
    if none { $_ =~ /$service_name/xsm } @{$services};

  return;
}

########################################################################
sub get_task_image_digests {
########################################################################
  my ( $self, $task_name ) = @_;
  my $ecs = $self->fetch_ecs;

  my $cluster_name = $self->get_config->{cluster}->{name};

  my $task_arns = $ecs->list_tasks( $cluster_name, 'taskArns' );
  $ecs->check_result( message => 'ERROR: Could not list tasks for cluster: [%s]', $cluster_name );

  my $group = sprintf 'service:%s', $task_name;

  my $query = sprintf 'tasks[?group == `%s`].containers[].{imageDigest:imageDigest}[].imageDigest', $task_name;

  my $image_digests = $ecs->describe_tasks( $cluster_name, $task_arns, $query );
  $ecs->check_result( message => 'ERROR: could not describe tasks for task arns: [%s]', join q{,}, @{$task_arns} );

  return $image_digests;
}

########################################################################
sub get_latest_task_definition {
########################################################################
  my ( $self, $task_name ) = @_;

  my $tasks = $self->get_config->{tasks};

  my $task_definition_arn = $tasks->{$task_name};

  my $ecs = $self->fetch_ecs;

  my $task_definitions = $ecs->list_task_definitions( $task_name, 'taskDefinitionArns' );
  $ecs->check_result( message => 'ERROR: could list task definitions for [%s]', $task_name );

  my ($latest_task_definition) = sort {
    my ($num_a) = $a =~ /:(\d+)$/xsm;
    my ($num_b) = $b =~ /:(\d+)$/xsm;
    $num_b <=> $num_a
  } @{$task_definitions};

  my ($latest_task_definition_version) = $latest_task_definition =~ /(:\d+)$/xsm;
  my ($task_definition_version)        = $task_definition_arn    =~ /(:\d+)$/xsm;

  return $latest_task_definition,;
}

########################################################################
sub cmd_update_service {
########################################################################
  my ( $self, @args ) = @_;

  my $service_name = $self->check_service_name( @args, $self->get_args );

  my ($cluster) = $self->common_args(qw(cluster));

  my $cluster_name = $cluster->{name};

  $self->verify_service($service_name);

  my $ecs                 = $self->fetch_ecs;
  my $task_definition_arn = $self->get_latest_task_definition($service_name);

  my @elems = qw(status running_count desired_count pending_count task_definition);

  my $result = $ecs->update_service(
    cluster_name    => $cluster_name,
    service_name    => $service_name,
    task_definition => basename($task_definition_arn),
    query           => jmespath_mapping( service => \@elems ),
  );

  $ecs->check_result( message => 'ERROR: could not update service: [%s]', $service_name );

  $self->log_debug( sub { return Dumper( [ result => $result ] ) } );

  my @data = {
    'Status'        => $self->maybe_color( bright_white => $result->{status} ),
    'Running Count' => $self->maybe_color( green        => $result->{running_count} ),
    'Desired Count' => $self->maybe_color( bright_white => $result->{desired_count} ),
    'Pending Count' => $self->maybe_color( yellow       => $result->{pending_count} ),
  };

  print {*STDOUT} easy_table(
    table_options => {
      allowANSI   => $TRUE,
      headingText => sprintf "Service Status\nTask Definition: %s",
      $result->{task_definition}
    },
    data    => \@data,
    columns => [ 'Status', 'Running Count', 'Pending Count', 'Desired Count' ]
  );

  return;
}

########################################################################
sub update_task_count {
########################################################################
  my ( $self, $task_name, $desired_count ) = @_;

  my ( $config, $cluster ) = $self->common_args(qw(config cluster));

  my $cluster_name = $cluster->{name};

  $self->verify_service($task_name);

  my $ecs = $self->get_ecs;

  my $result = $ecs->update_service(
    cluster_name  => $cluster_name,
    desired_count => $desired_count,
    service_name  => $task_name,
  );

  log_die( $self, "ERROR: could not update service: [%s]\n%s", $task_name, $ecs->get_error )
    if !$result;

  return $result;
}

########################################################################
sub cmd_start_stop_service {
########################################################################
  my ($self) = @_;

  my ( $task_name, $count ) = $self->get_args;

  if ( looks_like_number $task_name ) {
    $count     = $task_name;
    $task_name = $EMPTY;
  }

  $task_name = $self->check_service_name($task_name);
  my $command = $self->command;

  if ( $command eq 'start-service' ) {
    $count ||= 1;
  }
  elsif ( $command eq 'update-service' ) {
  }
  else {
    $count = 0;
  }

  if ( !$task_name ) {
    if ( $count == 0 ) {
      die sprintf "usage: %s -c config-name stop-service task-name\n", $ENV{SCRIPT_NAME};
    }

    die sprintf "usage: %s -c config-name start-service task-name [count]\n", $ENV{SCRIPT_NAME};
  }

  my $result = $self->update_task_count( $task_name, $count );

  sleep 2;  # wait a few seconds for status to be updated

  return $self->cmd_service_status($task_name);
}

########################################################################
sub cmd_register_task_definition {
########################################################################
  my ($self) = @_;

  my ( $config, $tasks, $dryrun ) = $self->common_args(qw(config tasks dryrun));

  my $task_name = $self->get_default_task_name;

  my $action = $self->get_skip_register ? 'update-target' : 'register';

  log_die( $self, 'usage: %s %s task-name', $action, $ENV{SCRIPT_NAME} )
    if !$task_name;

  my $task_definition_file = sprintf 'taskdef-%s.json', $task_name;

  $self->check_task($task_name);

  log_die( $self, "ERROR: no task definition file found for %s\n", $task_name )
    if !-s $task_definition_file;

  my $task_definition_arn;

  my $ecs = $self->fetch_ecs;

  if ( !$self->get_skip_register ) {
    $self->log_warn( 'register: registering task definition for: [%s]...%s', $task_name, $dryrun );

    if ( !$dryrun ) {
      my $task_definition = $ecs->register_task_definition($task_definition_file);
      $ecs->check_result( message => 'ERROR: register: could not register [%s]\n%s', $task_definition_file );
      $self->log_trace( sub { return Dumper( [ task_definition => $task_definition ] ) } );

      $task_definition_arn = $task_definition->{taskDefinition}->{taskDefinitionArn};

      log_die( $self, 'register: no taskDefinitionArn found? %s', Dumper( [ task_definition => $task_definition ] ) )
        if !$task_definition_arn;

      $self->log_warn( 'register: registered...[%s]', $task_definition_arn );

      $tasks->{$task_name}->{arn} = $task_definition_arn;

      my $latest_image = $self->get_latest_image($task_name);

      $self->log_info( 'register: updating image digest: [%s]', $latest_image->{imageDigest} );
      $tasks->{$task_name}->{image_digest} = $latest_image->{imageDigest};

      $self->update_config;  # record new task definition arn
    }
  }

  ## - events -
  if ( $tasks->{$task_name}->{type} eq 'task' ) {
    require App::Events;

    my $event = $self->fetch_events;

    my $rule_name = sprintf '%s-schedule', $task_name;

    my $target = $event->list_targets_by_rule( $rule_name, 'Targets' );
    $self->check_result( message => 'ERROR: could not list targets for: [%s]', $rule_name );

    if ( $target && @{$target} ) {

      # we only need to update the config if we skipped
      # registration...this is to allow for updating an event target
      # with a new task definition manually
      if ( !$dryrun && $self->get_skip_register ) {
        $config->{tasks}->{$task_name}->{arn} = $task_definition_arn;
        $self->update_config;
      }

      $self->create_event_target($task_name);
    }
  }

  return $SUCCESS;
}

########################################################################
sub get_latest_image {
########################################################################
  my ( $self, $task_name ) = @_;

  my $tasks = $self->common_args('tasks');

  my $ecr = $self->fetch_ecr;

  my ($repo_name) = split /:/xsm, $tasks->{$task_name}->{image};

  my ($latest) = $ecr->get_latest_image($repo_name);

  return $latest;
}

########################################################################
sub cmd_explain {
########################################################################
  my ($self) = @_;

  my $config = $self->get_config;

  return $SUCCESS;
}

########################################################################
sub cmd_version {
########################################################################

  my $version_stmt = <<'END_OF_TEXT';
%s %s
Copyright 2025 (c) TBC Development Group, LLC.

License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.
END_OF_TEXT

  my $pgm = $ENV{SCRIPT_NAME} // $PROGRAM_NAME;

  print {*STDOUT} sprintf $version_stmt, $pgm, $VERSION;

  return $SUCCESS;
}

########################################################################
sub cmd_plan {
########################################################################
  my ( $self, @args ) = @_;

  $self->set_dryrun('(dryrun)');

  return $self->build(@args);
}

########################################################################
sub cmd_apply {
########################################################################
  my ( $self, @args ) = @_;

  $self->set_dryrun($EMPTY);

  return $self->build(@args);
}

########################################################################
sub cmd_update_target {
########################################################################
  my ( $self, @args ) = @_;

  $self->set_skip_register($TRUE);

  return $self->cmd_register_task_definition(@args);
}

########################################################################
sub cmd_stop_task {
########################################################################
  my ( $self, @args ) = @_;

  my ( $config, $tasks ) = $self->common_args(qw(config tasks));

  my ($task_id) = $self->get_args;

  my ($task_name) = $self->check_service_name( $task_id, $TRUE );

  if ($task_name) {
    $task_id = $tasks->{$task_name}->{arn};
  }

  my $ecs = $self->get_ecs;

  die sprintf "usage: %s stop-task task-name|task-id|task-arn\n", $ENV{SCRIPT_NAME}
    if none { length $task_id == $_ } ( 32, 36 );

  my $result = $ecs->stop_task( $config->{cluster}->{name}, $task_id );

  log_die( $self, "ERROR: could not stop task: [%s]\n%s", $task_id, $ecs->get_error )
    if !$result;

  return $SUCCESS;
}

########################################################################
sub cmd_list_tasks {
########################################################################
  my ( $self, @args ) = @_;

  my $config = $self->get_config;

  my ($desired_status) = map {uc} $self->get_args;
  $desired_status //= $EMPTY;

  my $cluster_name = $config->{cluster}->{name};

  my $ecs = $self->get_ecs;

  my $result = $ecs->list_tasks(
    { cluster_name   => $cluster_name,
      query          => 'taskArns',
      desired_status => $desired_status
    }
  );
  $ecs->check_result( message => 'ERROR: could not list tasks for cluster: [%s]', $cluster_name );

  if ( !@{$result} ) {
    print {*STDERR} sprintf "No tasks currently running in cluster: [%s]\n", $cluster_name;

    return $SUCCESS;
  }

  my $task_list = [ map { basename $_ } @{$result} ];

  require Text::Wrap;
  Text::Wrap->import('wrap');

  {
    ## no critic
    no warnings 'once';
    $Text::Wrap::columns = 100;
  }

  my @elems = qw(status task_definition_arn last_status started_at memory cpu attachments task_arn stopped_reason);

  my $query = jmespath_mapping 'tasks[]' => \@elems;

  $result = $ecs->describe_tasks( $cluster_name, $task_list, $query );

  croak sprintf "ERROR: could not list describe tasks: [%s]\n%s", $cluster_name, $ecs->get_error
    if !$result;

  my $title = sprintf 'Tasks (cluster: %s)', $cluster_name;

  my @data;

  foreach ( @{$result} ) {
    my ( $status, $last_status, $start_time, $memory, $cpu, $arn, $stopped_reason )
      = @{$_}{qw(status last_status started_at memory cpu task_arn stopped_reason)};

    $stopped_reason = wrap( q{}, q{}, $stopped_reason // q{} );

    my $task_name = basename( $_->{task_definition_arn} );
    $task_name =~ s/:\d+$//;

    $status //= $last_status;
    $status = $self->maybe_color( $status =~ /running/xsmi ? 'green' : 'red' => $status );

    push @data,
      {
      'Start Time'     => $start_time,
      Status           => $status // $last_status,
      Memory           => $memory,
      CPU              => $cpu,
      'Task Id'        => basename($arn),
      'Task Name'      => $task_name,
      'Elapsed Time'   => elapsed_time($start_time),
      'Stopped Reason' => $stopped_reason,
      };
  }

  print {*STDOUT} easy_table(
    table_options => { headingText => $title, allowANSI => $TRUE },
    data          => \@data,
    columns       => [
      'Task Name', 'Task Id', 'Status', 'Memory', 'CPU',
      ( $desired_status ne 'STOPPED' ) ? ( 'Start Time', 'Elapsed Time' ) : ('Stopped Reason')
    ],
  );

  return $SUCCESS;
}

########################################################################
sub cmd_enable_scheduled_task {
########################################################################
  my ($self) = @_;

  return $self->update_rule_state($TRUE);
}

########################################################################
sub cmd_disable_scheduled_task {
########################################################################
  my ( $self, @args ) = @_;

  return $self->update_rule_state($FALSE);
}

########################################################################
sub cmd_update_policy {
########################################################################
  my ( $self, @args ) = @_;

  $self->set_cache($FALSE);

  return $self->build(@args);
}

########################################################################
sub cmd_destroy {
########################################################################
  my ( $self, @args ) = @_;

  print {*STDERR} "TBD\n";

  return $SUCCESS;
}
########################################################################
sub cmd_ {
########################################################################
  my ( $self, @args ) = @_;

  print {*STDERR} "TBD\n";

  return $SUCCESS;
}

########################################################################
sub cmd_delete_schedule {
########################################################################
  my ($self) = @_;

  my $tasks = $self->get_config->{tasks};

  my $task_name = $self->get_default_task_name( 'task', 'schedule' );

  die sprintf "usage: %s delete-schedule task-name\n", $ENV{SCRIPT_NAME}
    if !$task_name;

  die sprintf "ERROR: %s is not a schedule task\n", $task_name
    if $tasks->{$task_name}->{type} ne 'task' || !$tasks->{$task_name}->{schedule};

  # $task_name must be a schedule because we filtered above
  if ( !$self->get_force && scalar keys %{$tasks} == 1 ) {

    print {*STDERR} <<"END_OF_ERROR";
This is the only task in your configuration.

If you want to stop the task from running, consider:
  * Running: disable-scheduled-task $task_name
    (This leaves the task in place but disables the EventBridge rule.)

If you're sure you want to delete this stack use the --force option.

Deletion aborted to prevent unintended removal of the entire stack.
END_OF_ERROR
    exit 1;
  }

  if ( !$self->get_force ) {
    log_die( $self, 'Aborting...' )
      if !confirm( sprintf 'Are you sure you want to delete the %s scheduled task', $task_name );
  }

  return $self->delete_task_resources( $task_name, 'scheduled' );
}

########################################################################
sub cmd_delete_task {
########################################################################
  my ($self) = @_;

  my $tasks = $self->get_config->{tasks};

  my $task_name = $self->get_default_task_name('task');

  die sprintf "usage: %s delete-task task-name\n", $ENV{SCRIPT_NAME}
    if !$task_name;

  die sprintf "ERROR: [%s] is a not a task\n", $task_name
    if $tasks->{$task_name}->{type} ne 'task';

  die sprintf "ERROR: [%s] is a scheduled task...use 'delete-schedule'\n", $task_name
    if $tasks->{$task_name}->{schedule};

  if ( !$self->get_force && scalar keys %{$tasks} == 1 ) {
    print {*STDERR} <<"END_OF_ERROR";
This is the only task in your configuration.

If you're finished with this task and want to remove all artifacts,
you can run:
  * destroy

Deletion aborted to prevent unintended removal of the entire stack.
END_OF_ERROR
    exit 1;
  }

  return $self->delete_task_resources( $task_name, 'task' );
}

########################################################################
sub cmd_delete_daemon {
########################################################################
  my ($self) = @_;

  my $tasks     = $self->get_config->{tasks};
  my $task_name = $self->get_default_task_name( 'task', 'daemon' );

  die "usage: $ENV{SCRIPT_NAME} delete-daemon task-name\n"
    if !$task_name;

  die sprintf "ERROR: [%s] is not a daemon\n", $task_name
    if $tasks->{$task_name}->{type} ne 'daemon';

  if ( scalar keys %{$tasks} == 1 ) {
    my $msg = <<'END_OF_ERROR';
This is the only task in your configuration.

You can stop the daemon from running with the "stop-service" command.
END_OF_ERROR
    print {*STDERR} colored( $msg, 'bright_red' );
  }

  return $self->delete_task_resources( $task_name, 'daemon' );
}

########################################################################
sub cmd_delete_http_service {
########################################################################
  my ($self) = @_;

  my $tasks = $self->get_config->{tasks};

  my ( $task_name, $err ) = $self->get_default_service_name();

  die "usage: $ENV{SCRIPT_NAME} delete-http task-name\n"
    if !$task_name || $err;

  die "ERROR: [$task_name] is not an http task"
    if !$tasks->{$task_name}->{type} =~ /^https?/xsm;

  if ( scalar keys %{$tasks} == 1 ) {
    my $msg = <<'END_OF_WARNING';
WARNING: This is the only task in your configuration.

 - You can stop the http service from running with the "stop-service" command.
 - You can delete only the service with the "delete-service" command.

END_OF_WARNING
    print {*STDERR} colored( $msg, 'bright_red' );
  }

  return $self->delete_task_resources( $task_name, $tasks->{$task_name}->{type} );
}

########################################################################
sub cmd_redeploy {
########################################################################
  my ( $self, @args ) = @_;

  my $cluster      = $self->common_args('cluster');
  my $cluster_name = $cluster->{name};

  my ( $service_name, $err ) = $self->get_default_service_name;

  die sprintf "usage: %s redeploy service-name\n", $ENV{SCRIPT_NAME}
    if !$service_name || $err;

  my $ecs = $self->get_ecs;

  my $result = $ecs->update_service(
    cluster_name => $cluster_name,
    service_name => $service_name,
    force        => $TRUE
  );

  log_die( $self, "ERROR: could not update service: [%s]\n%s", $service_name, $ecs->get_error )
    if !$result;

  $self->log_info( 'redeploy: successfully updated service: [%s]', $service_name );

  return $SUCCESS;
}

########################################################################
sub cmd_reset_history {
########################################################################
  my ( $self, @args ) = @_;

  $self->fetch_option_defaults($TRUE);

  return $SUCCESS;
}

########################################################################
sub fetch_option_defaults {
########################################################################
  my ( $self, $reset ) = @_;

  my $options = {};

  my $defaults_file = '.fargatestack/defaults.json';

  if ( -s $defaults_file ) {
    $options = slurp_file( $defaults_file, $TRUE );
  }
  else {
    mkdir '.fargatestack';
  }

  return $self->write_json_file( $defaults_file, {} )
    if $reset;

  $options->{profile}         = $self->get_profile     // $options->{profile};
  $options->{config}          = $self->get_config_name // $options->{config};
  $options->{region}          = $self->default_region( $options->{region} );
  $options->{route53_profile} = $self->get_route53_profile // $options->{route53_profile};
  $options->{max_events}      = $self->get_max_events      // $options->{max_events};

  $self->set_profile( $options->{profile} );
  $self->set_config_name( $options->{config} );
  $self->set_route53_profile( $options->{route53_profile} );
  $self->set_max_events( $options->{max_events} );

  $self->write_json_file( $defaults_file, $options );

  return $options;
}

########################################################################
sub build_section_paths {
########################################################################
  my @items = @_;  # list of strings like '1:Title'

  my %paths;
  my @stack;

  foreach my $line (@items) {
    next if $line !~ /^(\d+):(.*)$/xsm;

    my ( $level, $title ) = ( $1, $2 );
    $level = int $level;  # Normalize level

    # Adjust the stack to this level
    $#stack = $level - 2;               # level 1 means index 0, so -2 to truncate above
    $stack[ $level - 1 ] = $title;

    # Join the stack up to this level
    my $path = join '/', @stack[ 0 .. $level - 1 ];
    $paths{$title} = $path;
  }

  return %paths;
}

########################################################################
sub parse_pod_sections {
########################################################################
  my $pod = slurp_file( $INC{'App/FargateStack/Pod.pm'} );
  my @sections;

  while ( $pod =~ /=head(\d+)\s+(.*?)$/gxsm ) {
    push @sections, "$1:$2";
  }

  return build_section_paths(@sections);
}

########################################################################
sub help {
########################################################################
  my ($self) = @_;

  my $subject = lc join $SPACE, @ARGV;
  $subject =~ s/\s+$//xsm;

  my %pod_sections = parse_pod_sections();
  my $section;

  if ( $subject && $subject ne 'help' ) {
    my ( $pod_section, $err ) = grep {/^$subject/smi} keys %pod_sections;

    if ($pod_section) {
      $section = $pod_sections{$pod_section};
      $section =~ s/[?]/\\?/gxsm;
    }
  }

  if ( !$section ) {
    $section = $HELP_SUBJECTS{$subject} // $EMPTY;

    if ( $subject && !$section && $subject ne 'help' ) {
      my @possible_subjects = grep {/$subject/xsmi} keys %HELP_SUBJECTS;

      if ( @possible_subjects == 1 ) {
        $section = $HELP_SUBJECTS{ $possible_subjects[0] };
      }
      elsif (@possible_subjects) {
        print {*STDERR} sprintf "'%s' was not found in the help index.\n\nPossible matches:\n\t* %s\n",
          $subject,
          join "\n\t* ",
          @possible_subjects;
        exit 1;
      }
    }

    if ( $section && ref $section ) {
      $section = uc $section->[0];
    }
    elsif ($section) {  # a help subject alias
      my $reference = $HELP_SUBJECTS{$section};
      $section = uc $reference->[0];
    }
  }

  eval {
    require IO::Pager;
    IO::Pager::open( *STDOUT, '|-:utf8', 'Unbuffered' );
  };

  if ( $subject && !$section ) {
    if ( $subject ne 'help' ) {
      print {*STDERR} sprintf "'%s' is not a valid subject\n", $subject;
    }

    my @data;

    foreach my $keyword ( sort keys %HELP_SUBJECTS ) {
      my $description = $HELP_SUBJECTS{$keyword};
      if ( ref $description ) {
        $description = $description->[1];
      }
      push @data, { Keyword => $keyword, Description => $description };
    }

    my $table = easy_table(
      columns       => [qw(Keyword Description)],
      data          => \@data,
      table_options => { headingText => 'Help Subjects' },
    );

    print {*STDOUT} $table;

    exit $SUCCESS;
  }

  return pod2usage(
    -input   => $INC{'App/FargateStack/Pod.pm'},
    -exitval => 1,
    -verbose => 99,
    -width   => 80,
    $section ? ( -sections => $section // 'USAGE' ) : ()
  );
}

########################################################################
sub main {
########################################################################

  my @extra_options = qw(
    account
    alb
    config_name
    cloudtrail
    ec2
    ecs
    ecr
    efs
    elbv2
    events
    existing_resources
    http
    iam
    global_options
    logs
    log_groups
    logger
    profile_source
    required_resources
    route53
    sts
    secrets
    subnets
    taskdef_status
  );

  my @option_specs = qw(
    help|h
    config|c=s
    color!
    confirm-all!
    create-alb|C
    dryrun|d
    force|f
    history|H!
    log-level=s
    log-time!
    log-wait!
    log-poll-time=s
    max-events|m=i
    output=s
    profile|p=s
    purge_config
    region|r=s
    route53-profile|R=s
    skip-register|s
    subnet-id=s
    task-timeout|t
    update|u!
    unlink|U!
    cache!
    version|v
    wait|w!
  );

  my %default_options = (
    wait            => $TRUE,
    unlink          => $TRUE,
    color           => $TRUE,
    cache           => $TRUE,
    'log-time'      => $TRUE,
    'log-wait'      => $TRUE,
    'log-poll-time' => $DEFAULT_LOG_POLL_TIME,
    'task-timeout'  => $DEFAULT_ECS_POLL_LIMIT,
    history         => $TRUE,
    update          => $TRUE,
    'max-events'    => $DEFAULT_MAX_EVENTS,
    output          => 'text',
  );

  my %commands = (
    'add-scaling-policy'      => [ \&cmd_add_scaling_policy,   'error', { skip_init => $TRUE, skip_config => $FALSE } ],
    'add-scheduled-action'    => [ \&cmd_add_scheduled_action, 'error', { skip_init => $TRUE, skip_config => $FALSE } ],
    'create-stack'            => [ \&cmd_create_stack,         'error', { skip_init => $TRUE, skip_config => $TRUE } ],
    'delete-daemon'           => \&cmd_delete_daemon,
    'delete-http-service'     => \&cmd_delete_http_service,
    'delete-scaling-policy'   => [ \&cmd_delete_autoscaling_policy, 'error', { skip_init => $TRUE, skip_config => $FALSE } ],
    'delete-schedule'         => \&cmd_delete_schedule,
    'delete-scheduled-action' => [ \&cmd_delete_scheduled_action, 'error', { skip_init => $TRUE, skip_config => $FALSE } ],
    'delete-service'          => [ \&cmd_remove_service, 'info' ],
    'delete-task'             => \&cmd_delete_task,
    'deploy-service'          => [ \&cmd_deploy_service, 'info' ],
    'disable-scheduled-task'  => \&cmd_disable_scheduled_task,
    'enable-scheduled-task'   => \&cmd_enable_scheduled_task,
    'list-tasks'              => [ \&cmd_list_tasks, 'error' ],
    'list-zones'              => [ \&cmd_list_zones, 'error' ],
    'register-task'           => \&cmd_register_task_definition,
    'remove-service'          => [ \&cmd_remove_service, 'info' ],
    'reset-history'           => [ \&cmd_reset_history,  'info', { skip_init => $TRUE, skip_config => $TRUE } ],
    'run-task'                => \&cmd_run_task,
    'start-service'           => [ \&cmd_start_stop_service, 'info' ],
    'stop-service'            => [ \&cmd_start_stop_service, 'error' ],
    'stop-task'               => [ \&cmd_stop_task,          'error' ],
    'update-policy'           => \&cmd_update_policy,
    'update-service'          => [ \&cmd_update_service, 'error', { skip_init => $TRUE } ],
    'update-target'           => \&cmd_update_target,
    apply                     => \&cmd_apply,
    default                   => [ \&cmd_explain, 'error' ],
    destroy                   => \&cmd_destroy,
    help                      => [ \&help,     'error', { skip_init => $TRUE, skip_config => $TRUE } ],
    logs                      => [ \&cmd_logs, 'error' ],
    plan                      => \&cmd_plan,
    redeploy                  => \&cmd_redeploy,
    show                      => [ \&cmd_show,           'error', { skip_init => $TRUE, skip_config => $TRUE } ],
    state                     => [ \&cmd_state,          'error', { skip_init => $TRUE, skip_config => $TRUE } ],
    status                    => [ \&cmd_service_status, 'error' ],
    version                   => [ \&cmd_version,        'error', { skip_init => $TRUE, skip_config => $TRUE } ],
  );

  my $fargate_stack = App::FargateStack->new(
    commands        => \%commands,
    default_options => \%default_options,
    extra_options   => \@extra_options,
    option_specs    => \@option_specs,
    abbreviations   => $TRUE,
    error_handler   => sub {
      print {*STDERR} shift;
      return $FALSE;
    },
    alias => {
      options  => { 'dns-profile' => 'route53-profile' },
      commands => {
        'create-service'            => 'deploy-service',
        'delete-autoscaling-policy' => 'delete-scaling-policy',
      },
    },
  );

  $fargate_stack->run();

  return 0;
}

1;

__END__
