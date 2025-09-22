package App::FargateStack::Init;

use strict;
use warnings;

use App::FargateStack::Constants;
use App::FargateStack::Builder::Utils qw(jmespath_mapping toCamelCase log_die dmp);

use Carp;
use Data::Dumper;
use English qw(no_match_vars);
use File::Basename qw(basename);
use List::Util qw(any none);
use Scalar::Util qw(reftype);
use YAML qw(LoadFile);

use Role::Tiny;

our $VERSION = '1.0.47';

########################################################################
sub init {
########################################################################
  my ($self) = @_;

  if ( $self->get_version ) {
    $self->set__command('version');
    return $TRUE;
  }

  my $command = $self->command;

  if ( $self->get_config ) {
    $self->set_config_name( $self->get_config );
  }

  if ( $self->get_history ) {
    $self->fetch_option_defaults;
  }

  my $cmd_spec = $self->commands->{$command};

  my $cmd_options = reftype($cmd_spec) eq 'ARRAY' ? $cmd_spec->[2] // {} : {};

  my ( $skip_init, $skip_config ) = @{$cmd_options}{qw(skip_init skip_config)};

  my $config = $skip_config ? {} : $self->_init_config;

  $self->set_config($config);

  $self->_init_defaults($config);

  return
    if $skip_init;

  my $dryrun = $self->get_dryrun;
  $self->set_dryrun( $dryrun ? '(dryrun)' : $EMPTY );

  log_die( $self, 'ERROR: when applying changes --no-update is not allowed' )
    if !$dryrun && !$self->get_update && $command eq 'apply';

  $self->section_break;

  $self->log_info( '%s %s (c) Copyright 2025 TBC Development Group, LLC', ref $self, $VERSION );
  $self->section_break;

  $self->_init_account;

  my $vpc_id = $config->{vpc_id};

  my $ec2 = $self->_init_ec2( $vpc_id, %{ $self->get_global_options } );

  if ( !$vpc_id ) {
    $vpc_id = $ec2->get_vpc_id;
    $config->{vpc_id} = $vpc_id;
  }

  $config->{subnets} = $ec2->get_subnets;

  $self->fetch_ecs->set_ec2($ec2);

  my $elb = $self->fetch_elbv2( vpc_id => $vpc_id, ec2 => $ec2 );

  # this will determine if we have an http service defined, configure
  # the ALB if it is not set explicitly and check on required parameters
  $self->_init_tasks();

  $self->_init_route53();

  $self->get_logger->trace( sub { return Dumper( [ config => $config ] ); } );

  $self->show_config;

  # only install die handler for apply - this makes sure we record any
  # provisioned resources
  if ( $self->command =~ /^(?:apply|destroy|delete-)$/xsmi ) {
    $SIG{__DIE__} = sub {
      my $msg = shift;

      if ($EXCEPTIONS_BEING_CAUGHT) {  # eval
        warn $msg;
        return;
      }

      # if config exists...we have removed last_updated and id
      if ( $config && $config->{config_name} ) {
        warn sprintf "Unclean shutdown - writing config file to [%s]\n", $config->{config_name};
        eval { YAML::DumpFile( $config->{config_name}, $config ); }
      }

      die $msg;
    };
  }

  return $TRUE;
}

########################################################################
sub _init_ec2 {
########################################################################
  my ($self) = @_;

  my $config = $self->get_config;

  my $subnets = $config->{subnets};

  my %options = (
    vpc_id => $config->{vpc_id},
    ( $self->get_cache && $subnets ) ? ( subnets => $subnets ) : (),
    %{ $self->get_global_options },
  );

  $self->log_trace( sub { return Dumper( [ options => \%options ] ); } );

  if ( $subnets && $self->get_cache ) {
    $self->log_debug( 'init-ec2: reading subnets from config...%s', $self->get_cache );
  }
  else {
    $self->log_debug('init-ec2: configuring VPC and subnets...');
  }

  my $ec2 = $self->fetch_ec2(%options);

  $subnets = $ec2->get_subnets;

  $self->log_trace( sub { return Dumper( [ subnets => $subnets ] ) } );

  $self->set_subnets($subnets);

  # make sure we have at least 2 subnets
  foreach (qw(private public)) {
    my $subnets = $subnets->{$_};
    $self->log_debug( 'init-ec2: %d %s subnets detected.', scalar( @{$subnets} ), $_ );
    next if $subnets && @{$subnets} > 1;

    log_die( $self, 'ERROR: you must specify at least 2 %s subnets', $_ );
  }

  $config->{vpc_id} = $ec2->get_vpc_id;

  # if we find subnets in the config...always validate in case they
  # got changed...
  if ($subnets) {
    $self->log_info('init-ec2: validating subnets...');
    $ec2->validate_subnets($subnets);  # this will croak if any are not invalid
  }
  else {
    my $subnets = $ec2->get_subnets;
    $self->set_subnets($subnets);
    $config->{subnets} = $subnets;
  }

  $self->log_debug( sub { return Dumper( [ subnets => $subnets ] ) } );

  return $ec2;
}

########################################################################
sub _init_config {
########################################################################
  my ($self) = @_;

  my $config_file = $self->get_config_name // $ENV{FARGATE_STACK_CONFIG} // 'fargate-stack.yml';

  croak sprintf "ERROR: %s not found or is unreadable\n", $config_file
    if !-s $config_file || !-r $config_file;

  my $config = LoadFile($config_file);

  $config->{config_name} = $config_file;

  $self->set_config($config);

  return $config;
}

########################################################################
sub _init_tasks {
########################################################################
  my ($self) = @_;

  my $config = $self->get_config;

  my $tasks = $config->{tasks};

  ######################################################################
  # check: must have at least 1 task defined
  ######################################################################
  log_die( $self, "ERROR: no tasks defined in config\n" )
    if !$tasks;

  ######################################################################
  # check: can only have 1 http service
  ######################################################################
  my ( $http_service, $error )
    = grep { $tasks->{$_}->{type} && $tasks->{$_}->{type} =~ /^http/xsm } keys %{$tasks};

  log_die( $self, 'ERROR: only one http service is permitted' )
    if $error;

  $self->set_http($http_service);

  ######################################################################
  # check: if http service defined must have 2 private subnets
  ######################################################################
  if ($http_service) {

    # check to make sure we have private subnets, we're not going to
    # allow placing tasks in public subnets for HTTP services
    if ( !$config->{subnets}->{private} || !@{ $config->{subnets}->{private} } ) {

      my $err_msg = <<'END_OF_ERROR';
ERROR: With a load balancer configured, tasks must run in private
subnets. Provide at least two private subnets in different AZs, or
remove the load balancer from this service.
END_OF_ERROR
      log_die( $self, $err_msg );
    }

    $self->configure_alb();

    log_die( $self, "ERROR: when provisioning an http task, domain is required\n" )
      if !$config->{domain};
  }

  ######################################################################
  # check: must have a valid image defined for each task
  ######################################################################
  my @images = map { $tasks->{$_}->{image} // () } keys %{$tasks};

  if ( @images != scalar keys %{$tasks} ) {
    $self->log_error( 'ERROR: every task must have an image. You have %d task but only %d images',
      scalar(@images), scalar keys %{$tasks} );
  }

  if ( $self->get_cache ) {
    $self->log_info( 'init-tasks: skipping images validation...%s', $self->get_cache );
    return;
  }

  $self->log_info('init-tasks: validating images...');

  my $ecr = $self->fetch_ecr();

  $ecr->validate_images(@images);

  return;
}

########################################################################
sub _init_account {
########################################################################
  my ($self) = @_;

  my $config = $self->get_config;

  if ( $config->{account} && $self->get_cache ) {
    $self->log_info( 'init-account: reading account value from config...%s', $self->get_cache );
    $self->set_account( $config->{account} );
    return;
  }

  my $sts = $self->fetch_sts();

  $self->log_info('init-account: determining AWS account value...');

  my $result = $sts->get_caller_identity;
  $sts->check_result( message => 'ERROR: could not determine account for profile:[%s]', $self->get_profile );

  $config->{account} = $result->{Account};
  $self->log_info( 'init-account: AWS account: [%s]...', $config->{account} );

  $self->set_account( $config->{account} );

  return;
}

########################################################################
sub default_region {
########################################################################
  my ( $self, $region ) = @_;

  $region //= $self->get_region // $ENV{AWS_DEFAULT_REGION} // 'us-east-1';
  $self->set_region($region);

  return $region;
}

########################################################################
sub _init_defaults {
########################################################################
  my ( $self, $config ) = @_;

  my $last_updated = delete $config->{last_updated};
  delete $config->{id};

  $config->{region} = $self->default_region( $config->{region} );

  my $profile        = $self->get_profile;
  my $profile_source = 'command line';

  if ( !$profile && $config->{profile} ) {
    $profile        = $config->{profile};
    $profile_source = 'config';
  }
  elsif ( !$profile && $ENV{AWS_PROFILE} ) {
    $profile        = $ENV{AWS_PROFILE};
    $profile_source = 'environment';
  }

  if ( !$profile ) {
    $profile        = 'default';
    $profile_source = 'default';
  }

  $self->set_profile($profile);
  $config->{profile} = $profile;

  $self->set_profile_source($profile_source);

  my %global_options = (
    profile   => $self->get_profile,
    region    => $self->get_region,
    logger    => $self->get_logger,
    log_level => $self->get_log_level,
    unlink    => $self->get_unlink,
  );

  $self->set_global_options( \%global_options );

  my $cache = $self->get_cache;
  $self->set_cache( $cache && $last_updated ? '(cached)' : $EMPTY );

  return;
}

########################################################################
sub _init_route53 {
########################################################################
  my ($self) = @_;

  my $command = $self->command;

  my @route53_commands = qw(apply plan list-zones delete-http-service);

  return
    if none { $command eq $_ } @route53_commands;

  my $config = $self->get_config;

  $self->log_trace( sub { return Dumper( [ alb => $config->{alb}, $self->get_http ] ) } );

  my ( $route53_config, $domain ) = @{$config}{qw(route53 domain)};

  if ( !$route53_config ) {
    $route53_config = {};
    $config->{route53} = $route53_config;
  }

  if ( $self->get_route53_profile ) {
    $route53_config->{profile} = $self->get_route53_profile;
  }
  elsif ( $self->get_dns_profile ) {
    $route53_config->{profile} = $self->get_route53_profile;
  }
  else {
    $route53_config->{profile} //= $self->get_profile;
  }

  my ( $zone_id, $profile ) = @{$route53_config}{qw(zone_id profile)};

  $self->log_debug(
    sub {
      return Dumper(
        [ route53_profile => $profile,
          cli             => $self->get_route53_profile
        ]
      );
    }
  );

  my $route53 = $self->fetch_route53(
    hosted_zone_id => $zone_id,
    elb            => $self->get_elbv2,
    profile        => $profile,
  );

  return
    if !$self->get_http && $command =~ /apply|plan|list-zones/xsm;

  my $alb_type = $config->{alb}->{type};

  if ( !$zone_id ) {
    my $zone_type = $self->is_https ? 'public' : 'private';

    $self->log_warn( 'init-route53: zone_id is required when creating a task of type: [%s]',
      $self->is_https ? 'https' : 'http' );

    $self->log_warn( 'init-route53: ...attempting to find a [%s] hosted zone', $zone_type );

    my $hosted_zone = $route53->find_hosted_zone( $domain, $zone_type );
    $self->benchmark('route53');

    log_die( $self, 'init-route53: ERROR: no hosted zone of type [%s] found in this account for domain: [%s]',
      $zone_type, $domain )
      if !$hosted_zone || !@{$hosted_zone};

    $zone_id = basename( $hosted_zone->[0]->{Id} );
    $route53_config->{zone_id} = $zone_id;

    return;
  }

  return
    if $self->get_cache;

  $self->log_info( 'init-route53: validating hosted zone id: [%s]...', $zone_id );

  my $zone = eval { return $route53->validate_hosted_zone( zone_id => $zone_id, domain => $domain, alb_type => $alb_type, ); };

  my $err = $EVAL_ERROR;

  if ( $zone && !$err ) {
    $self->log_info( 'init-route53: hosted zone id: [%s/%s]', $zone->{Id}, $zone->{Name} );
    return;
  }

  # output a helpful table of hosted zones for this domain
  $self->log_warn( "\n" . $self->display_hosted_zones($domain) );

  ($err) = split /\n/, $err;

  log_die( $self, $err );

  return;
}

1;
