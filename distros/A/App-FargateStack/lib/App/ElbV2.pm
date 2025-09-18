package App::ElbV2;

use strict;
use warnings;

use App::EC2;
use Carp;
use Data::Dumper;
use List::Util qw(first any);
use JSON;

use Role::Tiny::With;
with 'App::AWS';

use parent 'App::Command';

__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_accessors(
  qw(
    alb
    certificate_arn
    ec2
    name
    profile
    region
    security_groups
    subnets
    tags
    vpc_id
    _alb_cache
  )
);

########################################################################
sub add_listener_certificate {
########################################################################
  my ( $self, $listener_arn, $certificate_arn ) = @_;

  return $self->command(
    'add-listener-certificates' => [
      '--listener-arn' => $listener_arn,
      '--certificates' => "CertificateArn=$certificate_arn",
    ]
  );
}

########################################################################
sub modify_listener_certificate {
########################################################################
  my ( $self, $listener_arn, $certificate_arn, $default_action ) = @_;

  if ( !$default_action ) {
    my $response = $self->command( 'describe-listeners' => [ '--listener-arns' => $listener_arn ] );

    my ($listener) = ref $response eq 'HASH' ? @{ $response->{Listeners} || [] } : ();

    if ( $listener && $listener->{DefaultActions} ) {
      $default_action = $listener->{DefaultActions};
    }
    else {
      die "Unable to retrieve existing default actions for listener $listener_arn\n";
    }
  }

  return $self->command(
    'modify-listener' => [
      '--listener-arn'    => $listener_arn,
      '--certificates'    => "CertificateArn=$certificate_arn",
      '--default-actions' => encode_json($default_action),
    ]
  );
}

########################################################################
sub list_certificates {
########################################################################
  my ( $self, $listener_arn ) = @_;

  my $query = 'Certificates[].CertificateArn';

  return $self->command(
    'describe-listener-certificates' => [
      '--listener-arn' => $listener_arn,
      '--query'        => $query,
    ]
  );
}

########################################################################
sub create_load_balancer {
########################################################################
  my ( $self, %args ) = @_;

  my ( $lb_name, $type, $scheme, $subnets, $security_groups, $tags ) = @args{qw(name type scheme subnets security_groups tags)};

  $type    //= 'application';
  $scheme  //= 'internet-facing';
  $lb_name //= $self->get_name;

  croak "ERROR: subnets must be an array ref\n"
    if !$subnets || !ref $subnets;

  croak "ERROR: security_groups must be an array ref\n"
    if !$security_groups || !ref $security_groups;

  return $self->command(
    'create-load-balancer' => [
      '--name'            => $lb_name,
      '--type'            => $type,
      '--scheme'          => $scheme,
      '--subnets'         => @{$subnets},
      '--security-groups' => @{$security_groups},
      $tags ? ( '--tags' => $self->format_tags($tags) ) : ()
    ]
  );
}

########################################################################
sub describe_listeners {
########################################################################
  my ( $self, $alb_arn, $query ) = @_;

  croak "no ALB arn\n"
    if !$alb_arn;

  return $self->command(
    'describe-listeners' => [
      '--load-balancer-arn' => $alb_arn,
      $query ? ( '--query' => $query ) : (),
    ]
  );
}

########################################################################
sub describe_rules {
########################################################################
  my ( $self, $listener_arn, $query ) = @_;

  croak "no listener arn\n"
    if !$listener_arn;

  return $self->command(
    'describe-rules' => [
      '--listener-arn' => $listener_arn,
      $query ? ( '--query' => $query ) : (),
    ]
  );
}

########################################################################
sub describe_load_balancers {
########################################################################
  my ( $self, %args ) = @_;

  my ( $query, $arn ) = @args{qw(query arn)};
  $query //= q{};
  $arn   //= q{};

  my $alb_cache = $self->get__alb_cache // {};
  my $cache_key = sprintf '%s|%s', $arn, $query;

  return $alb_cache->{$cache_key}
    if $alb_cache->{$cache_key} && !$args{no_cache};

  my $result = $self->command(
    'describe-load-balancers' => [ $arn ? ( '--load-balancer-arns' => $arn ) : (), $query ? ( '--query' => $query ) : (), ] );

  $alb_cache->{$cache_key} = $result;
  $self->set__alb_cache($alb_cache);

  return $result;
}

########################################################################
sub delete_load_balancer {
########################################################################
  my ( $self, $alb_arn, $query ) = @_;

  my $result
    = $self->command( 'delete-load-balancer' => [ '--load-balancer-arn' => $alb_arn, $query ? ( '--query' => $query ) : (), ] );

  return $result;
}

########################################################################
sub delete_target_group {
########################################################################
  my ( $self, $target_group_arn, $query ) = @_;

  return $self->command(
    'delete-target-group' => [ '--target-group-arn' => $target_group_arn, $query ? ( '--query' => $query ) : (), ] );
}

########################################################################
sub delete_rule {
########################################################################
  my ( $self, $rule_arn, $query ) = @_;

  return $self->command( 'delete-rule' => [ '--rule-arn' => $rule_arn, $query ? ( '--query' => $query ) : (), ] );
}

########################################################################
sub set_security_groups {
########################################################################
  my ( $self, $arn, @security_groups ) = @_;

  return $self->command(
    'set-security-groups' => [
      '--load-balancer-arn' => $arn,
      '--security-groups'   => join( q{ }, @security_groups ),
    ]
  );

}

########################################################################
sub describe_load_balancer {
########################################################################
  my ( $self, $arn, $query, @filters ) = @_;

  return $self->command(
    'describe-load-balancers' => [
      '--load-balancer-arn' => $arn,
      $query ? ( '--query' => $query ) : (),
      map { ( '--filters' => $_ ) } @filters
    ]
  );
}

########################################################################
sub describe_tags {
########################################################################
  my ( $self, $arn, $query ) = @_;

  return $self->command(
    'describe-tags' => [
      '--resource-arns' => $arn,
      $query ? ( '--query' => $query ) : (),
    ]
  );
}

########################################################################
sub find_public_alb {
########################################################################
  my ($self) = @_;

  return $self->_find_alb_of_type('internet-facing');
}

########################################################################
sub find_alb {
########################################################################
  my ( $self, $type ) = @_;

  return $type eq 'private' ? $self->find_private_alb : $self->find_public_alb;
}

########################################################################
sub find_private_alb {
########################################################################
  my ($self) = @_;

  return $self->_find_alb_of_type('internal');
}

########################################################################
sub _find_alb_of_type {
########################################################################
  my ( $self, $type, $no_error ) = @_;

  croak "usage: find_alb(internal|internet-facing)\n"
    if !$type || $type !~ /internal|internet\-facing/xsm;

  my $ec2 = $self->get_ec2;

  my $vpc_id = $ec2->get_vpc_id;

  croak "no vpc_id found\n"
    if !$vpc_id;

  my $query = sprintf 'LoadBalancers[?Scheme == `%s` && VpcId == `%s`]', $type, $vpc_id;

  my $albs = $self->describe_load_balancers( query => $query );

  $self->get_logger->debug( Dumper( [ albs => $albs ] ) );

  croak "ERROR: No ALBs of type: $type\n"
    if !$no_error && !$albs || !@{$albs};

  croak sprintf "ERROR: More than one ALBs of type: $type\n%s\n", join "\n", map { $_->{LoadBalancerName} } @{$albs}
    if !$no_error && @{$albs} > 1;

  my $alb = $albs->[0];

  $self->set_alb($alb);

  $self->get_logger->debug( sub { return Dumper( [ alb => $alb ] ) } );

  return ( $alb->{LoadBalancerArn}, $alb->{SecurityGroups}->[0] );
}

########################################################################
sub get_listener_by_port {
########################################################################
  my ( $self, $alb_arn, $port ) = @_;

  my $query = sprintf 'Listeners[?Port == `%s`]', $port;

  my $result = $self->command(
    'describe-listeners' => [
      '--load-balancer' => $alb_arn,
      '--query',        => $query,
    ]
  );

  return @{$result};
}

########################################################################
sub create_rule {
########################################################################
  my ( $self, %args ) = @_;

  my ( $listener_arn, $priority, $conditions, $default_action ) = @args{qw(listener_arn priority conditions default_action)};

  return $self->command(
    'create-rule' => [
      '--listener-arn' => $listener_arn,
      '--priority'     => $priority,
      '--conditions'   => $conditions,
      '--actions'      => $default_action,
    ]
  );
}

########################################################################
sub validate_alb {
########################################################################
  my ( $self, %args ) = @_;

  my ( $alb_arn, $scheme ) = @args{qw(arn scheme)};

  croak "usage: validate_alb(alb-arn, [ vpc-id ])\n"
    if !$alb_arn;

  my $query = sprintf 'LoadBalancers[?LoadBalancerArn == `%s` && Scheme == `%s`]', $alb_arn, $scheme;

  my $albs = $self->describe_load_balancers( query => $query );

  croak "ERROR: unable to find ALB: %s\n%s", $alb_arn, $self->get_error
    if !$albs;

  return $albs;
}

########################################################################
sub find_alb_subnets {
########################################################################
  my ( $self, $alb_arn ) = @_;

  my $query = sprintf "LoadBalancers[?LoadBalancerArn == `%s`] | [0].AvailabilityZones[].SubnetId", $alb_arn;

  my @cmd = qw(aws elbv2 describe-load-balancers);

  push @cmd,
    '--profile' => $self->profile,
    '--query'   => $query;

  my $result = $self->execute(@cmd);

  return $result ? decode_json($result) : $result;
}

########################################################################
sub target_group_exists {
########################################################################
  my ( $self, $target_group_name ) = @_;

  my $query = sprintf "TargetGroups[?TargetGroupName == `%s`]|[0]", $target_group_name;

  my @cmd = qw(aws elbv2 describe-target-groups);

  push @cmd,
    (
    '--query'   => $query,
    '--profile' => $self->profile,
    );

  my $result = $self->execute(@cmd);

  return $result ? decode_json($result) : $result;
}

########################################################################
sub create_target_group {
########################################################################
  my ( $self, %args ) = @_;

  my ( $port, $protocol, $name, $vpc_id, $target_type, $health_check )
    = @args{qw(port protocol name vpc_id target_type health_check)};

  $port        //= '80';
  $protocol    //= 'HTTP';
  $target_type //= 'ip';
  $vpc_id      //= $self->get_vpc_id;

  my $tags = $self->format_tags;

  my @health_check_options = _create_health_check_options($health_check);

  $self->get_logger->trace(
    sub {
      return Dumper(
        [ health_check         => $health_check,
          health_check_options => \@health_check_options
        ]
      );
    }
  );

  return $self->command(
    'create-target-group' => [
      '--name'        => $name,
      '--protocol'    => $protocol,
      '--port'        => $port,
      '--vpc-id'      => $vpc_id,
      '--target-type' => $target_type,
      $tags ? ( '--tags' => $tags ) : (),
      '--query' => 'TargetGroups[0].TargetGroupArn',
      @health_check_options,
    ]
  );
}

########################################################################
sub _create_health_check_options {
########################################################################
  my ($health_check) = @_;

  return
    if !$health_check || !keys %{$health_check};

  my @health_check_options;

  if ( $health_check && $health_check->{enabled} ) {
    push @health_check_options, '--health-check-enabled';

    my @args = qw(port interval_seconds timeout_seconds matcher);
    my @normalized_args;

    foreach ( @args, qw(healthy_threshold_count unhealthy_threshold_count) ) {
      my $k = $_;
      $k =~ s/_/-/gxsm;

      if ( !/threshold|matcher/xsm ) {
        $k = "health-check-$k";
      }

      my $value = /matcher/xsm ? "HttpCode=$health_check->{$_}" : $health_check->{$_};
      push @health_check_options, "--$k" => $value;
    }
  }
  else {
    push @health_check_options, '--no-health-check-enabled';
  }

  return @health_check_options;
}

########################################################################
sub create_listener {
########################################################################
  my ( $self, %args ) = @_;

  my ( $alb_arn, $tg_arn, $port, $default_actions, $certificate_arn, $query )
    = @args{qw(alb_arn target_group_arn port default_actions certificate_arn query)};

  $certificate_arn //= $self->get_certificate_arn;
  my $protocol = $certificate_arn ? 'HTTPS' : 'HTTP';

  croak "port is a required argument\n"
    if !$port;

  return $self->command(
    'create-listener' => [
      '--load-balancer-arn' => $alb_arn,
      '--protocol'          => $protocol,
      '--port'              => $port,
      $default_actions ? ( '--default-actions' => $default_actions )                              : (),
      $query           ? ( '--query'           => $query )                                        : (),
      $certificate_arn ? ( '--certificates'    => sprintf 'CertificateArn=%s', $certificate_arn ) : (),
    ]
  );
}

########################################################################
sub fetch_rules_by_domain {
########################################################################
  my ( $self, $domain, $listener_arn ) = @_;

  my $query = sprintf 'Rules[?Conditions[?Field == `host-header` && contains(Values,`%s`)]]', $domain;

  return $self->command(
    'describe-rules' => [
      '--listener-arn' => $listener_arn,
      '--query'        => $query
    ]
  );

}

########################################################################
sub fetch_rule_arns_by_domain {
########################################################################
  my ( $self, @args ) = @_;

  my $rules = $self->fetch_rules_by_domain(@args);

  return
    if !$rules || !@{$rules};

  return [ map { $_->{RuleArn} } @{$rules} ];
}

########################################################################
sub format_tags {
########################################################################
  my ( $self, $tags ) = @_;

  return
    if !$tags || !keys %{$tags};

  return join q{ }, map { sprintf 'Key=%s,Value=%s', $_, $tags->{$_} } keys %{$tags};
}

1;
