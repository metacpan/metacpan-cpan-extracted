package App::FargateStack::Builder::HTTPService;

use strict;
use warnings;

use Data::Dumper;
use English qw(-no_match_vars);
use List::Util qw(none any);
use JSON;

use App::FargateStack::Constants;
use App::FargateStack::Builder::Utils qw(log_die);

use Role::Tiny;

########################################################################
sub build_http_service {
########################################################################
  my ($self) = @_;

  my ( $config, $dryrun, $security_groups ) = $self->common_args(qw(config dryrun security_groups));

  $self->create_alb();

  $self->benchmark('http-service:create-alb');

  my $fargate_sg = $security_groups->{fargate}->{group_id};
  my $alb_sg     = $security_groups->{alb}->{group_id};

  my $ec2 = $self->fetch_ec2;

  if ( $fargate_sg && $alb_sg && $ec2->is_sg_authorized( $fargate_sg, $alb_sg ) ) {
    $self->log_info( q{http-service: security-group-ingress: ALB's security group: [%s] already authorized...skipping},
      $alb_sg );
  }
  else {

    $self->log_warn(
      q{http-service: security-group-ingress: ALB's security group: [%s] will be authorized to Fargate's: [%s]...%s},
      $alb_sg // '???',
      $fargate_sg // '???', $dryrun
    );
  }

  if ( !$dryrun ) {
    $ec2->authorize_security_group_ingress( group_id => $fargate_sg, source_group => $alb_sg );
  }

  $self->create_target_group();
  $self->benchmark('http-service:create-target-group');

  $self->create_listeners();
  $self->benchmark('http-service:create-listeners');

  if ( $self->is_https ) {
    $self->attach_certificate();
  }

  return $TRUE;
}

########################################################################
sub attach_certificate {
########################################################################
  my ($self) = @_;

  my ( $config, $dryrun, $alb ) = $self->common_args(qw(config dryrun alb));

  my $domain = $config->{domain};

  my $alb_arn = $alb->{arn};

  my $elb = $self->fetch_elbv2;

  if ( !$alb_arn || $alb_arn =~ /[?]{3}/xsm ) {
    $self->log_warn('http-service: no ALB created yet, cannot attach certificate');
    return;
  }

  my $listener = $elb->describe_listeners( $alb_arn, 'Listeners[?Port == `443`]' );

  log_die( $self, 'ERROR: could not find a 443 listener for ALB: [%s]', $alb_arn )
    if !$listener || !@{$listener};

  my $listener_arn = $listener->[0]->{ListenerArn};

  my $certificates = $elb->list_certificates($listener_arn);

  log_die( $self, 'ERROR: could not list certificates for ALB: [%s]', $alb_arn )
    if !$certificates;

  $self->log_trace( sub { return Dumper( [ certificates => $certificates ] ); } );

  my $certificate_arn = $config->{certificate_arn};

  if ($certificate_arn) {
    if ( any { $_ eq $certificate_arn } @{$certificates} ) {
      $self->log_info( 'http-service: certificate for [%s] already attached to listener...skipping', $domain );
      return;
    }
  }

  $self->log_warn( 'http-service: certificate for [%s] will be added to listener...%s', $domain, $dryrun );

  return
    if $dryrun;

  log_die( $self, 'http-service: no certificate arn' )
    if !$certificate_arn;

  my $result = $elb->add_listener_certificate( $listener_arn, $certificate_arn );

  log_die( $self, "ERROR: could not add certificate [%s] to ALB [%s]\n%s", $certificate_arn, $alb_arn, $elb->get_error )
    if !$result;

  $self->log_warn( 'http-service: successfully added certificate for [%s] to ALB', $domain );

  return;
}

########################################################################
sub fetch_listeners_by_port {
########################################################################
  my ( $self, $alb_arn ) = @_;

  my $elb = $self->get_elbv2;

  my $listeners = $elb->describe_listeners( $alb_arn, q{Listeners} );

  return $listeners ? map { ( $_->{Port} => $_ ) } @{$listeners} : ();
}

########################################################################
sub create_listeners {
########################################################################
  my ($self) = @_;

  my ( $config, $dryrun ) = $self->common_args(qw(config dryrun));

  my $elb = $self->get_elbv2;

  my ( $alb_arn, $alb_type, $alb_port, $alb_redirect ) = @{ $config->{alb} }{qw(arn type port redirect_80)};

  if ( !defined $alb_redirect && $self->is_https ) {
    $config->{arn}->{redirect_80} = $alb_redirect = $TRUE;
  }

  if ( !$alb_arn ) {
    $self->log_info( 'http-service: deferring listener creation, no ALB yet...%s', $dryrun );
    return;
  }

  my $service = $config->{tasks}->{ $self->get_http };

  my $target_group_arn = $service->{target_group_arn};

  my %listeners_by_port = $self->fetch_listeners_by_port($alb_arn);

  my %default_actions = ( $alb_port => [ { Type => 'forward', 'TargetGroupArn' => $target_group_arn } ] );

  if ( $self->is_https && $alb_redirect ) {
    $default_actions{80} = [
      { Type           => 'redirect',
        RedirectConfig => {
          Protocol   => 'HTTPS',
          Port       => $alb_port,
          StatusCode => 'HTTP_301'
        }
      }
    ];
  }

  my $domain = $config->{domain};
  my @ports  = keys %default_actions;

  my $needs_cert = $self->has_https_service;

  foreach my $port (@ports) {
    $default_actions{$port} = encode_json( $default_actions{$port} );

    # create listener returns listener configuration (uses --query)
    if ( !$listeners_by_port{$port} ) {
      $self->log_warn( 'http-service: listener for port [%s] will be created...%s', $port, $dryrun );

      $self->inc_required_resources(
        listeners => [
          sub {
            my ($dryrun) = @_;

            return $dryrun ? 'arn:???' : $self->get_listeners_by_port( $alb_arn, $port );
          }
        ]
      );

      if ( !$dryrun ) {
        $listeners_by_port{$port} = $elb->create_listener(
          alb_arn         => $alb_arn,
          port            => $port,
          default_actions => $default_actions{$port},
          query           => 'Listeners[0]',
          $needs_cert ? ( certificate_arn => $config->{certificate_arn} ) : (),
        );

        $elb->check_result( message => 'ERROR: could not create listener for port: [%s]', $port );
      }
    }
    else {
      $self->log_info( 'http-service: listener for port [%s] exists...skipping', $port );
      $self->inc_existing_resources( listeners => [ $listeners_by_port{$port}->{ListenerArn} ] );

      # add certificate...https
      if ( $needs_cert && !$dryrun ) {
        $elb->add_listener_certificate( $listeners_by_port{$port}->{ListenerArn}, $config->{certificate_arn} );
      }
    }
  }

  foreach my $port (@ports) {

    my $listener = $listeners_by_port{$port};

    $self->log_debug(
      Dumper(
        [ listener => $listener,
          port     => $port
        ]
      )
    );

    my $rules = $elb->fetch_rules_by_domain( $domain, $listener->{ListenerArn} );

    $self->log_trace( sub { return Dumper( [ rules => $rules ] ); } );

    if ( $rules && @{$rules} ) {
      $self->log_info( 'http-service: listener rule for port: [%s] exists...skipping', $port );
      $self->inc_existing_resources( listener_rules => [ map { $_->{RuleArn} } @{$rules} ] );
      next;
    }

    $rules = $elb->describe_rules( $listener->{ListenerArn}, 'Rules' );

    # find next priority
    my @priorities
      = sort { $a <=> $b } map { $_->{Priority} } grep { $_->{Priority} =~ /^\d+$/xsm } @{$rules};

    my $priority = @priorities ? $priorities[-1] + 1 : 100;

    $self->log_warn( 'http-service: listener rule for [%s] on port: [%s] will be created...%s', $domain, $port, $dryrun );

    $self->inc_required_resources(
      listener_rules => [
        sub {
          my ($dryrun) = @_;

          return 'arn:???'
            if $dryrun;

          my $rules = $elb->fetch_rule_arns_by_domain( $domain, $listener->{ListenerArn} );

          return q{}
            if !$rules;

          return join q{, }, @{$rules};
        }
      ]
    );

    if ( !$dryrun ) {
      my $conditions = "Field=host-header,Values=$domain";

      $elb->create_rule(
        listener_arn   => $listener->{ListenerArn},
        priority       => $priority,
        conditions     => $conditions,
        default_action => $default_actions{$port}
      );
    }
  }

  return;
}

########################################################################
sub create_target_group {
########################################################################
  my ($self) = @_;

  my ( $config, $tasks, $dryrun ) = $self->common_args(qw(config tasks dryrun));

  my $elb = $self->fetch_elbv2;

  # we would not be here unless we have an HTTP service
  my $task_name = $self->get_http;
  my $task      = $tasks->{$task_name};

  $task->{target_group_name} //= $self->create_default('target-group-name');
  my $target_group_name = $task->{target_group_name};

  if ( my $target_group = $elb->target_group_exists($target_group_name) ) {
    $self->log_info( 'http-service: target group [%s] exists...skipping', $target_group_name );

    $task->{target_group_arn} = $target_group->{TargetGroupArn};

    $self->inc_existing_resources( target_group => $task->{target_group_arn} );
  }
  else {
    $self->log_warn( 'http-service: target group [%s] will be created...%s', $target_group_name, $dryrun );

    $self->inc_required_resources(
      target_group => sub {
        my ($dryrun) = @_;
        return $dryrun ? "arn:???/$target_group_name" : $task->{target_group_arn};
      }
    );

    my $health_check = $task->{health_check} // {};

    if ( !defined $task->{health_check} || $health_check->{enabled} ) {
      $health_check->{enabled} //= 'true';
      $health_check->{port}    //= $task->{container_port};
      $health_check->{path}    //= q{/};

      $health_check->{interval_seconds} //= $DEFAULT_HEALTH_CHECK_INTERVAL;
      $health_check->{timeout_seconds}  //= $DEFAULT_HEALTH_CHECK_TIMEOUT;
      $health_check->{healthy_threshold_count}   = $DEFAULT_HEALTH_HEALTHY_CHECK_THRESHOLD;
      $health_check->{unhealthy_threshold_count} = $DEFAULT_HEALTH_UNHEALTHY_CHECK_THRESHOLD;

      $health_check->{matcher} = '200';
    }
    else {
      log_die( $self, 'ERROR: health checks must be enabled' );
    }

    $task->{health_check} = $health_check;

    $self->log_debug( sub { return Dumper( [ health_check => $health_check ] ); } );

    if ( !$dryrun ) {

      $task->{target_group_arn} = $elb->create_target_group(
        name         => $target_group_name,
        health_check => $health_check,
      );

      $elb->check_result( message => 'ERROR: could not create target group:[%s]', params => [$target_group_name] );

      $self->log_info( "\tarn: %s", $task->{target_group_arn} );
    }
  }

  return;
}

########################################################################
sub is_https { goto &has_https_service; }
########################################################################
sub has_https_service {
########################################################################
  my ($self) = @_;

  my $services = $self->get_config->{tasks};

  my $http_service = $self->get_http;

  return
    if !$http_service;

  return $services->{$http_service}->{type} eq 'https';
}

########################################################################
sub create_alb {
########################################################################
  my ($self) = @_;

  my ( $config, $dryrun, $alb, $security_groups ) = $self->common_args(qw(config dryrun alb security_groups));

  if ( !$alb ) {
    $alb = $config->{alb} = {};
    $config->{alb} = $alb;
  }

  if ( !$security_groups ) {
    $security_groups = $config->{security_groups} = {};
    $config->{security_groups} = $security_groups;
  }

  my $elb = $self->fetch_elbv2();
  my $ec2 = $self->fetch_ec2;

  # if we have defined one in the config, verify
  if ( my $alb_arn = $alb->{arn} ) {

    my $alb_info = $elb->describe_load_balancer( $alb_arn, 'LoadBalancers[0]' );
    $elb->check_result( message => 'ERROR: could not describe load balancer: [%s]', $alb_arn );

    $self->set_alb($alb_info);

    my ( $alb_name, $alb_security_groups ) = @{$alb_info}{qw(LoadBalancerName SecurityGroups)};

    $self->log_trace( sub { return Dumper( [ alb => $alb_info ] ); } );

    $self->log_info( 'http-service: load balancer [%s] defined in config and verified...skipping', $alb_name );

    $self->inc_existing_resources( alb => $alb_arn );

    my $alb_sg = $security_groups->{alb}->{group_id};

    if ( !$alb_sg ) {
      $self->log_info('http-service: no ALB security group in configuration...looking...');

      # find the security group that allows 443 ingress

      my $query = 'SecurityGroupRules[?IsEgress == `false` && ToPort == `443`]';

      foreach my $group_id ( @{$alb_security_groups} ) {
        my $sg = $ec2->describe_security_group_rules( group_id => $group_id, $query );

        next if !@{$sg};

        $alb_sg = $sg->[0]->{GroupId};  # or $group_id
        last;
      }

      if ($alb_sg) {
        $self->log_warn( 'http-service: found a security group for ALB [%s] with 443 ingress, using [%s]',
          $alb_info->{LoadBalancerName}, $alb_sg );
      }
    }

    if ( !$alb_sg ) {
      $alb_sg = $alb_security_groups->[0];

      $self->log_warn( 'http-service: could not find a security group for ALB [%s] with 443 ingress, using [%s]',
        $alb_name, $alb_sg );
    }

    $security_groups->{alb}->{group_id}   = $alb_sg;
    $security_groups->{alb}->{group_name} = $ec2->find_security_group_name($alb_sg);

    $self->inc_existing_resources( security_groups => [$alb_sg] );

    return;
  }

  # --create-alb forces creation of a new ALB
  if ( !$self->get_create_alb && !$alb->{create} ) {
    my $alb_type = $alb->{type};

    $self->log_error( 'http-service: WARNING - no ALB ARN defined in configuration...looking for %s ALB', $alb_type );

    my ( $alb_arn, $security_group_id ) = eval { return $elb->find_alb($alb_type); };
    my $err = $EVAL_ERROR;

    if ( !$alb_arn || $err ) {
      if ( $err =~ /no\salbs/xsm ) {
        $self->log_error( 'http-service: no %s ALBs were found in this VPC...a new ALB will be created...%s',
          $alb_type, $dryrun );
      }
      elsif ( $err =~ /more\sthan\sone/xsm ) {
        $self->log_die(
          'http-service: more than 1 %s ALBs were found...add the ARN to your configuration file or use the --create-alb option.',
          $alb_type
        );
      }
      else {
        die "$err";
      }
    }

    $self->log_trace(
      sub {
        return Dumper(
          [ alb_arn        => $alb_arn,
            security_group => $security_group_id
          ]
        );
      }
    );

    my $security_group_name;
    my $is_valid_alb;

    if ($alb_arn) {
      $security_group_name = $ec2->find_security_group_name($security_group_id);

      $is_valid_alb = $elb->validate_alb(
        arn    => $alb_arn,
        scheme => $self->is_https ? 'internet-facing' : 'internal'
      );
    }

    if ( $alb_arn && $is_valid_alb ) {

      # set this for later
      $self->set_alb( $elb->get_alb );

      $self->log_error( 'http-service: Found an existing ALB (%s)...will be added to configuration.', $alb_arn );

      $security_groups->{alb}->{group_id} = $security_group_id;
      $security_groups->{alb}->{name}     = $security_group_name;

      $alb->{arn}  = $alb_arn;
      $alb->{name} = $self->get_alb->{LoadBalancerName};

      $self->inc_existing_resources( alb => $config->{alb}->{name} );

      # me may still need to attach Fargate's security group to this ALB
      # check to see if fargate's security group is already attached

      my $query = sprintf 'LoadBalancers[?LoadBalancerArn == `%s`]|[0].SecurityGroups', $alb_arn;

      my $alb_security_groups = $elb->describe_load_balancers( query => $query );

      my $fargate_sg = $security_groups->{fargate}->{group_id} // 'not-provisioned-yet';

      if ( none { $_ eq $fargate_sg } @{$alb_security_groups} ) {
        $self->log_warn( 'http-service: will add security group %s to load balancer...%s', $fargate_sg, $dryrun );

        if ( !$dryrun ) {
          $elb->set_security_groups( $alb_arn, @{$alb_security_groups}, $fargate_sg );
        }
      }
      else {
        $self->log_info( 'http-service: security group %s already attached...skipping', $fargate_sg );
      }

      return;
    }
  }

  # create an alb
  if ( $self->get_create_alb || $alb->{create} ) {
    $self->log_warn( 'http-service: ALB creation forced by configuration or option...will be created...%s', $dryrun );
  }
  else {
    $self->log_error(
      'http-service: no ALB defined in your configuration and no usable ALB found...an ALB will be created...%s', $dryrun );
  }

  my $alb_sg   = $self->create_alb_security_group;
  my $alb_type = $self->is_https ? 'public' : 'private';

  my $subnets = [ @{ $self->get_subnets->{$alb_type} }[ ( 0, 1 ) ] ];

  my $alb_name = $alb->{name} // $self->create_default('alb-name');
  $alb->{name} = $alb_name;

  $self->inc_required_resources(
    alb => sub {
      my ($dryrun) = @_;
      return $dryrun ? "arn:???/$alb_name" : $alb->{arn};
    }
  );

  if ( !$dryrun ) {

    my $alb_info = $elb->create_load_balancer(
      name            => $alb_name,
      subnets         => $subnets,
      scheme          => $alb_type eq 'public' ? 'internet-facing' : 'internal',
      security_groups => [$alb_sg],
      tags            => { CreatedBy => 'FargateStack' },
    );

    $elb->check_result( message => 'ERROR: could not create load balancer: [%s]', $alb_name );

    $alb->{arn} = $alb_info->{LoadBalancers}->[0]->{LoadBalancerArn};

    $self->set_alb($alb_info);
  }

  return;
}

########################################################################
sub create_alb_security_group {
########################################################################
  my ($self) = @_;

  my ( $config, $dryrun, $app, $security_groups ) = $self->common_args(qw(config dryrun app security_groups));

  $security_groups //= {};
  $config->{security_groups} = $security_groups;

  # create security groups
  my $ec2 = $self->fetch_ec2;

  my $sg_name = $self->create_default('alb-security-group-name');

  my $query  = sprintf 'SecurityGroups[?GroupName == `%s`].{group_id: GroupId}', $sg_name;
  my $result = $ec2->describe_security_group( $sg_name, $query );
  $ec2->check_result( message => 'ERROR: could not describe security group: [%s]', $sg_name );

  $self->log_debug( [ result => $result, error => $ec2->get_error ] );

  if ( !$result ) {
    $self->inc_required_resources( security_groups => [$sg_name] );
    $self->log_info( 'http-service: ALB security group [%s] will be created...%s', $sg_name, $dryrun );
  }
  else {
    $self->log_info( 'http-service: ALB security group [%s] exists...skipping', $sg_name );
  }

  my $sg = $result->{group_id};

  my @allow_ports = ( $config->{alb}->{port}, $config->{alb}->{redirect_80} ? 80 : () );

  if ( !$sg && !$dryrun ) {
    my $sg_description = sprintf 'allow in-bound port(s): [%s] to %s-alb', join( q{,}, @allow_ports ), $app->{name};

    $sg = $ec2->create_security_group( $sg_name, $sg_description );
    $ec2->check_result( message => 'ERROR: could not create security group: [%s]', $sg_name );

    $security_groups->{alb}->{group_id} = $sg;
    $security_groups->{alb}->{name}     = $sg_name;
  }
  else {
    $sg = 'sg-????';
  }

  $self->log_info( 'http-service: authorizing ingress for [%s] on port(s): [%s]...%s',
    $sg, join( q{, }, @allow_ports ), $dryrun );

  if ( !$dryrun ) {
    foreach my $port (@allow_ports) {
      $ec2->authorize_security_group_ingress(
        group_id => $sg,
        port     => $port,
        cidr     => '0.0.0.0/0',
      );
    }
  }

  return $sg;
}

########################################################################
sub create_alias {
########################################################################
  my ($self) = @_;

  my ( $config, $dryrun ) = $self->common_args(qw(config dryrun));

  my $domain = $config->{domain};

  my $zone_id = $config->{route53}->{zone_id};

  return
    if !$domain;

  my $route53 = $self->fetch_route53;

  my $alb_arn = $config->{alb}->{arn};
  my $elb     = $self->fetch_elbv2;
  my ( $alb_dns_name, $alb_zone_id );

  if ($alb_arn) {

    my $alb = $elb->describe_load_balancer( $alb_arn, 'LoadBalancers[0]' );

    ( $alb_dns_name, $alb_zone_id ) = @{$alb}{qw(DNSName CanonicalHostedZoneId)};

    my $result = $route53->find_alias_record(
      zone_id     => $zone_id,
      dns_name    => $alb_dns_name,
      domain_name => $domain
    );

    $route53->check_result( message => 'ERROR: could not determine if an alias record exists for: [%s]', $domain );

    if ( $result && @{$result} ) {
      $self->log_info( 'http-service: alias record for [%s] exists...skipping', $domain );
      return;
    }
  }

  $self->log_warn( 'route53: alias for [%s] will be created...%s', $domain, $dryrun );
  $self->inc_required_resources( route53 => $domain );

  return
    if $dryrun;

  log_die( $self, 'ERROR: ALB has not been created yet?' )
    if !$alb_dns_name || !$alb_zone_id;

  my $result = $route53->create_alias(
    elb          => $elb,
    domain       => $domain,
    zone_id      => $zone_id,
    alb_dns_name => $alb_dns_name,
    alb_zone_id  => $alb_zone_id,
  );

  $route53->check_result( message => 'ERROR: could not create alias record for [%s]', $domain );

  $self->log_warn( 'http-service: successfully create alias record for [%s]', $domain );

  return;
}

########################################################################
sub get_listeners_by_port {
########################################################################
  my ( $self, $alb_arn ) = @_;

  my $elb = $self->fetch_elbv2;

  my $listeners = $elb->describe_listeners( $alb_arn, 'Listeners' );
  $elb->check_result( message => 'ERROR: could not describe listeners for: [%s]', $alb_arn );

  return map { $_->{Port} => $_->{ListenerArn} } @{$listeners};
}

1;
