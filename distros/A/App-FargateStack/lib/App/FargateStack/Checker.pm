package App::FargateStack::Checker;

use strict;
use warnings;

use App::FargateStack::Builder::Utils qw(choose);
use Carp;
use Carp::Always;
use CLI::Simple::Constants qw(:booleans %LOG_LEVELS);
use Data::Dumper;
use English qw(-no_match_vars);
use Getopt::Long qw(GetOptions);
use List::Util qw(any none uniq);
use Text::ASCIITable::EasyTable;
use Sub::Util qw(subname);

use parent qw(CLI::Simple);

__PACKAGE__->use_log4perl( log_level => 'info' );

caller or __PACKAGE__->main();

########################################################################
sub check_fargate_env {
########################################################################
  my ($self) = @_;

  my @rows;

  push @rows, check( $self, \&check_credentials );
  push @rows, check( $self, \&check_service_linked_roles );
  push @rows, check( $self, \&check_vpc_and_subnets );
  push @rows, check( $self, \&check_egress );
  push @rows, check( $self, \&check_ecs_permissions );
  push @rows, check( $self, \&check_elbv2_permissions );
  push @rows, check( $self, \&check_logs_permissions );
  push @rows, check( $self, \&check_ecr_access );
  push @rows, check( $self, \&check_events_permissions );
  push @rows, check( $self, \&check_passrole );

  if ( $self->get_dns )     { push @rows, check_route53($self); }
  if ( $self->get_https )   { push @rows, check_acm($self); }
  if ( $self->get_secrets ) { push @rows, check_secrets_hint($self); }

  my $exit = render_table( $self, \@rows );

  my ( $caps, $m ) = summarize_capabilities( \@rows );
  # Temporary debug to stderr
  my %sets = (
    'HTTP services' =>
      [ 'Credentials', 'VPC/Subnets', 'Egress', 'ECS perms', 'ELBv2 perms', 'CloudWatch Logs perms', 'iam:PassRole' ],
    'HTTPS service' =>
      [ 'Credentials', 'VPC/Subnets', 'Egress', 'ECS perms', 'ELBv2 perms', 'CloudWatch Logs perms', 'iam:PassRole', 'ACM' ],
    'Scheduled tasks' =>
      [ 'Credentials', 'VPC/Subnets', 'Egress', 'ECS perms', 'Events perms', 'CloudWatch Logs perms', 'iam:PassRole' ],
    'One-shot tasks'  => [ 'Credentials', 'VPC/Subnets', 'Egress', 'ECS perms', 'CloudWatch Logs perms', 'iam:PassRole' ],
    'Daemon services' => [ 'Credentials', 'VPC/Subnets', 'Egress', 'ECS perms', 'CloudWatch Logs perms', 'iam:PassRole' ],
  );

  foreach my $cap ( sort keys %sets ) {
    my @missing = grep { !exists $m->{$_} } @{ $sets{$cap} };
    if (@missing) {
      print {*STDERR} sprintf "capability[%s] missing checks: %s\n", $cap, join q{, }, @missing;
    }
  }

  render_capabilities( $caps, $self->get_account, $self->get_region );

  return $exit;
}

########################################################################
sub check {
########################################################################
  my ( $self, $sub ) = @_;

  my ( undef, $name ) = split /_/xsm, subname($sub);

  $self->get_logger->info( sprintf 'checking %s...', $name );

  return $sub->($self);
}

my %clients;

########################################################################
sub new_client {
########################################################################
  my ( $class, @args ) = @_;

  return $clients{$class}
    if $clients{$class};

  my $class_path = $class;

  my $options = choose {
    return {@args}
      if !ref $args[0];

    return {
      profile   => $args[0]->get_profile,
      region    => $args[0]->get_region,
      log_level => $args[0]->get_log_level,
      logger    => $args[0]->get_logger,
    };
  };

  $class_path =~ s/::/\//gxsm;

  require "$class_path.pm";

  return $clients{$class} = $class->new($options);
}

########################################################################
sub try_aws {
########################################################################
  my ($code_ref) = @_;

  my $err;

  my $out = eval { return ( $code_ref->() ); } or do {
    $err = $EVAL_ERROR || 'unknown error';
  };

  return ( !!$out, $out, $err );
}

########################################################################
sub render_table {
########################################################################
  my ( $self, $rows ) = @_;

  my $title = sprintf 'Fargate environment preflight (profile: [%s] region: [%s], Route53 profile: [%s])',
    $self->get_profile, $self->get_region, $self->get_route53_profile;

  my $exit_code = 0;

  foreach my $r ( @{$rows} ) {
    if ( $r->{Status} eq 'FAIL' ) {
      $exit_code = 2;
    }
    if ( $r->{Status} eq 'WARN' && $exit_code == 0 ) {
      $exit_code = 1;
    }
  }

  print {*STDOUT} easy_table(
    table_options => { headingText => $title },
    columns       => [qw(Check Status Detail)],
    data          => $rows,
  );

  return $exit_code;
}

########################################################################
sub row_ok   { return { Check => $_[0], Status => 'PASS', Detail => $_[1] // q{} }; }
sub row_warn { return { Check => $_[0], Status => 'WARN', Detail => $_[1] // q{} }; }
sub row_fail { return { Check => $_[0], Status => 'FAIL', Detail => $_[1] // q{} }; }
########################################################################

########################################################################
sub check_events_permissions {
########################################################################
  my ($opt) = @_;

  my $events = new_client( 'App::Events', $opt );

  # Read-only probe; no mutation. Either of these is fine:
  # list-event-buses  => broad, minimal perms
  # list-rules        => stricter, proves rule visibility
  my ( $ok, $buses, $err ) = try_aws( sub { $events->command( 'list-event-buses' => [ '--query' => 'EventBuses[].Name' ] ) } );

  if ( !$ok ) {
    return row_fail( 'Events perms', 'Cannot list event buses' );
  }

  return row_ok( 'Events perms', 'Describe OK' );
}

########################################################################
sub check_credentials {
########################################################################
  my ($opt) = @_;

  my $sts = new_client( 'App::STS', $opt );

  my ( $ok, $out, $err ) = try_aws( sub { $sts->get_caller_identity() } );

  if ( !$ok || !$out ) {
    return row_fail( 'Credentials', 'Cannot call STS GetCallerIdentity' );
  }

  my $acct = $out->{Account} || q{};
  my $arn  = $out->{Arn}     || q{};

  $opt->set_account($acct);

  if ( !$acct ) {
    return row_fail( 'Credentials', 'Missing account in STS response' );
  }

  return row_ok( 'Credentials', "Account $acct, Principal $arn" );
}

########################################################################
sub check_service_linked_roles {
########################################################################
  my ($opt) = @_;

  my $iam = new_client( 'App::IAM', $opt );

  my @required = ('AWSServiceRoleForECS');                   # core ECS control plane
  my @advisory = ('AWSServiceRoleForElasticLoadBalancing');  # only if you use ALB/NLB

  # If you intend to use service autoscaling, include this:
  if ( $opt->{check_scaling} ) {
    push @advisory, 'AWSServiceRoleForApplicationAutoScaling_ECSService';
  }

  my @missing_req;
  my @missing_adv;

  foreach my $r (@required) {
    my ($ok) = try_aws( sub { $iam->command( 'get-role' => [ '--role-name' => $r ] ) } );
    if ( !$ok ) {
      push @missing_req, $r;
    }
  }

  foreach my $r (@advisory) {
    my ($ok) = try_aws( sub { $iam->command( 'get-role' => [ '--role-name' => $r ] ) } );
    if ( !$ok ) {
      push @missing_adv, $r;
    }
  }

  if ( @missing_req && @missing_adv ) {
    return row_warn( 'Service-linked roles',
      'Missing required: ' . join( ', ', @missing_req ) . ' ; advisory missing: ' . join( ', ', @missing_adv ) );
  }

  if (@missing_req) {
    return row_warn( 'Service-linked roles', 'Missing required: ' . join ', ', @missing_req );
  }

  if (@missing_adv) {
    return row_warn( 'Service-linked roles', 'Advisory missing: ' . join ', ', @missing_adv );
  }

  return row_ok( 'Service-linked roles', 'Present or auto-creatable' );
}

########################################################################
sub check_vpc_and_subnets {
########################################################################
  my ($opt) = @_;

  my $ec2 = new_client( 'App::EC2', $opt );

  my ( $ok_vpc, $vpcs, $err_vpc ) = try_aws(
    sub {
      $ec2->command( 'describe-vpcs' => [ '--query' => 'Vpcs[].VpcId' ] );
    }
  );

  if ( !$ok_vpc || !$vpcs || !@{$vpcs} ) {
    return row_fail( 'VPC/Subnets', 'No VPCs accessible in this region' );
  }

  my ( $ok_sub, $subs, $err_sub ) = try_aws(
    sub {
      $ec2->command( 'describe-subnets' => [ '--query' => 'Subnets[].AvailabilityZone' ] );
    }
  );

  if ( !$ok_sub || !$subs || !@{$subs} ) {
    return row_fail( 'VPC/Subnets', 'No subnets found' );
  }

  my %az       = map { $_ => 1 } @{$subs};
  my $az_count = scalar keys %az;

  if ( $az_count < 2 ) {
    return row_fail( 'VPC/Subnets', 'Need at least two subnets across different AZs' );
  }

  return row_ok( 'VPC/Subnets', sprintf 'OK (%d AZs)', $az_count );
}

########################################################################
sub check_egress {
########################################################################
  my ( $opt, $need_secrets ) = @_;

  my $ec2 = new_client( 'App::EC2', $opt );

  my ( $ok_nat, $nat, $err_nat ) = try_aws(
    sub {
      $ec2->command(
        'describe-nat-gateways' => [ '--filter', 'Name=state,Values=available', '--query', 'NatGateways[].NatGatewayId' ] );
    }
  );

  my ( $ok_ep, $eps, $err_ep ) = try_aws(
    sub {
      $ec2->command( 'describe-vpc-endpoints' => [ '--query', 'VpcEndpoints[].ServiceName' ] );
    }
  );

  my $has_nat = $ok_nat && $nat && @{$nat};
  my $has_eps = $ok_ep  && $eps;

  if ( !$has_nat && !$has_eps ) {
    return row_fail( 'Egress', 'Private subnets need NAT or VPC endpoints (ECR, Logs, Secrets)' );
  }

  my %need = (
    'com.amazonaws.%s.ecr.api' => 1,
    'com.amazonaws.%s.ecr.dkr' => 1,
    'com.amazonaws.%s.logs'    => 1,
  );

  if ($need_secrets) {
    $need{'com.amazonaws.%s.secretsmanager'} = 1;
  }

  if ($has_eps) {
    my %have = map { $_ => 1 } @{$eps};
    my @missing;
    foreach my $tmpl ( keys %need ) {
      my $svc = sprintf $tmpl, ( $opt->{region} || 'us-east-1' );
      if ( !$have{$svc} ) {
        push @missing, $svc;
      }
    }
    if ( @missing && !$has_nat ) {
      return row_fail( 'Egress', 'Missing VPC endpoints: ' . join q{, }, @missing );
    }
    if ( @missing && $has_nat ) {
      return row_ok( 'Egress', 'Using NAT; missing optional endpoints: ' . join q{, }, @missing );
    }
  }

  return row_ok( 'Egress', $has_nat ? 'NAT available' : 'Required endpoints present' );
}

########################################################################
sub check_ecs_permissions {
########################################################################
  my ($opt) = @_;

  my $ecs = new_client( 'App::ECS', $opt );

  my ( $ok1, $clusters, $err1 ) = try_aws( sub { $ecs->command( 'list-clusters' => [ '--query' => 'clusterArns[]' ] ) } );
  my ( $ok2, $tds,      $err2 ) = try_aws( sub { $ecs->command( 'list-task-definitions' => [ '--max-results' => '1' ] ) } );

  if ( !$ok1 || !$ok2 ) {
    return row_fail( 'ECS perms', 'Missing list/describe permissions' );
  }

  return row_ok( 'ECS perms', 'List/Describe OK (create/update assumed during deploy)' );
}

########################################################################
sub check_elbv2_permissions {
########################################################################
  my ($opt) = @_;

  my $elbv2 = new_client( 'App::ElbV2', $opt );

  my ( $ok, $lbs, $err )
    = try_aws( sub { $elbv2->command( 'describe-load-balancers' => [ '--query' => 'LoadBalancers[].LoadBalancerArn' ] ) } );

  if ( !$ok ) {
    return row_fail( 'ELBv2 perms', 'Cannot describe load balancers' );
  }

  return row_ok( 'ELBv2 perms', 'Describe OK' );
}

########################################################################
sub check_logs_permissions {
########################################################################
  my ($opt) = @_;

  my $logs = new_client( 'App::Logs', $opt );

  my ( $ok, $lgs, $err ) = try_aws( sub { $logs->command( 'describe-log-groups' => [ '--limit' => '1' ] ) } );

  if ( !$ok ) {
    return row_fail( 'CloudWatch Logs perms', 'Cannot describe log groups' );
  }

  return row_ok( 'CloudWatch Logs perms', 'Describe OK' );
}

########################################################################
sub check_route53 {
########################################################################
  my ($self) = @_;

  my %options = (
    profile   => $self->get_route53_profile,
    region    => $self->get_region,
    log_level => $self->get_log_level,
  );

  my $r53 = new_client( 'App::Route53' => %options );

  my ( $ok, $hzs, $err ) = try_aws( sub { $r53->command( 'list-hosted-zones' => [ '--query' => 'HostedZones[].Id' ] ) } );

  if ( !$ok ) {
    return row_fail( 'Route 53', 'Cannot list hosted zones' );
  }

  return row_ok( 'Route 53' => 'List OK' );
}

########################################################################
sub check_acm {
########################################################################
  my ($opt) = @_;

  my $acm = new_client( 'App::ACM', $opt );

  my ( $ok, $certs, $err )
    = try_aws( sub { $acm->command( 'list-certificates' => [ '--query' => 'CertificateSummaryList[].CertificateArn' ] ) } );

  if ( !$ok ) {
    return row_fail( 'ACM', 'Cannot list certificates in region' );
  }

  return row_ok( ACM => 'List OK' );
}

########################################################################
sub check_ecr_access {
########################################################################
  my ($opt) = @_;

  my $ecr = new_client( 'App::ECR', $opt );

  my ( $ok, $repos, $err ) = try_aws( sub { $ecr->command( 'describe-repositories' => [ '--max-results' => '1' ] ) } );

  if ( !$ok ) {
    return row_warn( 'ECR', 'Cannot describe repositories; image validation may fail' );
  }

  return row_ok( 'ECR', 'Describe OK' );
}

########################################################################
sub check_secrets_hint {
########################################################################
  my ($opt) = @_;

  # The deployer does not need GetSecretValue; tasks use task role.
  # We only check control-plane reachability here.
  my $ec2 = new_client( 'App::EC2', $opt );

  my ( $ok_ep, $eps, $err_ep ) = try_aws(
    sub {
      $ec2->command( 'describe-vpc-endpoints' => [ '--query', 'VpcEndpoints[].ServiceName' ] );
    }
  );

  if ( !$ok_ep ) {
    return row_warn( 'Secrets Manager', 'Could not confirm VPC endpoints for Secrets Manager' );
  }

  my %have = map { $_ => 1 } @{ $eps || [] };
  my $svc  = sprintf 'com.amazonaws.%s.secretsmanager', ( $opt->{region} || 'us-east-1' );

  if ( !$have{$svc} ) {
    return row_warn( 'Secrets Manager', 'Missing VPC endpoint for Secrets Manager or rely on NAT' );
  }

  return row_ok( 'Secrets Manager', 'Endpoint present' );
}
########################################################################
sub check_passrole {
########################################################################
  my ($opt) = @_;
  my $role_names = $opt->get_role_names;

  # role_names: arrayref of the exact role names your framework will create,
  # e.g., [ 'FargateStack/my-svc/TaskExecutionRole', 'FargateStack/my-svc/TaskRole',
  #         'FargateStack/my-svc/EventsInvokeRole' ]

  my $sts = new_client( 'App::STS', $opt );
  my $iam = new_client( 'App::IAM', $opt );

  my $id         = $sts->get_caller_identity();
  my $acct       = $id->{Account} || q{};
  my $caller_arn = $id->{Arn}     || q{};

  if ( !$acct || !$caller_arn ) {
    return row_fail( 'iam:PassRole', 'Cannot resolve caller identity' );
  }

  my $policy_source_arn = _principal_to_policy_source_arn( $caller_arn, $acct );
  if ( !$policy_source_arn ) {
    return row_fail( 'iam:PassRole', 'Cannot derive policy-source ARN for simulation' );
  }

  my $role_arns = _role_arns_from_names( $acct, $role_names || [] );
  if ( !$role_arns || !@{$role_arns} ) {
    return row_warn( 'iam:PassRole', 'No target roles specified; skipping simulation' );
  }

  my @services = qw(ecs-tasks.amazonaws.com events.amazonaws.com);

  my %decisions_by_service;

  foreach my $svc (@services) {
    my $result = eval { _simulate_passrole_once( $iam, $policy_source_arn, $role_arns, $svc ) };
    if ( $EVAL_ERROR || !$result ) {
      # If org blocks simulation, warn rather than fail
      return row_warn( 'iam:PassRole', 'Simulation not permitted; verify PassRole manually' );
    }

    # result is an arrayref of EvalDecision strings: allowed | explicitDeny | implicitDeny
    my @dec = @{ $result || [] };
    $decisions_by_service{$svc} = \@dec;
  }

  # Aggregate decisions: any explicitDeny -> FAIL
  # otherwise any implicitDeny -> WARN
  # otherwise all allowed -> PASS
  my $detail = q{};
  my $status = 'PASS';

  foreach my $svc (@services) {
    my $dec         = $decisions_by_service{$svc} || [];
    my $svc_summary = sprintf '%s: %s', $svc, ( join q{,}, @{$dec} );

    if ( grep { $_ eq 'explicitDeny' } @{$dec} ) {
      $status = 'FAIL';
    }
    elsif ( $status ne 'FAIL' && grep { $_ eq 'implicitDeny' } @{$dec} ) {
      $status = 'WARN';
    }

    $detail .= $svc_summary . q{ };
  }

  $detail =~ s/\s+\z//;

  if ( $status eq 'FAIL' ) { return row_fail( 'iam:PassRole', $detail ); }
  if ( $status eq 'WARN' ) { return row_warn( 'iam:PassRole', $detail ); }
  return row_ok( 'iam:PassRole', $detail || 'allowed' );
}

########################################################################
sub _principal_to_policy_source_arn {
########################################################################
  my ( $sts_arn, $account_id ) = @_;

  # Examples:
  # arn:aws:sts::123456789012:assumed-role/DeployerRole/SESSION -> arn:aws:iam::123456789012:role/DeployerRole
  # arn:aws:iam::123456789012:user/someuser                     -> arn:aws:iam::123456789012:user/someuser

  return q{} if !$sts_arn || !$account_id;

  if ( $sts_arn =~ m{\A arn:aws:sts::\Q$account_id\E:assumed-role/([^/]+)/}xsm ) {
    my $role = $1;
    return sprintf 'arn:aws:iam::%s:role/%s', $account_id, $role;
  }

  if ( $sts_arn =~ m{\A arn:aws:iam::\Q$account_id\E:(user|role)/}xsm ) {
    return $sts_arn;
  }

  # Fallback: try to coerce to iam::role if it looks like an sts assumed role
  return $sts_arn;
}

########################################################################
sub _role_arns_from_names {
########################################################################
  my ( $account_id, $role_names ) = @_;

  $role_names ||= [];
  my @arns;

  foreach my $name ( @{$role_names} ) {
    next if !$name;
    push @arns, sprintf 'arn:aws:iam::%s:role/%s', $account_id, $name;
  }

  return \@arns;
}

########################################################################
sub _simulate_passrole_once {
########################################################################
  my ( $iam, $policy_source_arn, $resource_arns, $passed_to_service ) = @_;

  # Build CLI JSON for --context-entries
  my $context_json = sprintf
    q|[{"ContextKeyName":"iam:PassedToService","ContextKeyValues":["%s"],"ContextKeyType":"string"}]|,
    $passed_to_service;

  # Ask for just the decision list
  return $iam->command(
    'simulate-principal-policy' => [
      '--policy-source-arn' => $policy_source_arn,
      '--action-names'      => 'iam:PassRole',
      '--resource-arns'     => @{$resource_arns},
      '--context-entries'   => $context_json,
      '--query'             => 'EvaluationResults[].EvalDecision',
      '--output'            => 'json',
    ]
  );
}

########################################################################
sub _gate {
########################################################################
  my ( $need, $caps ) = @_;

  my $result = 'YES';

  foreach ( @{$need} ) {
    next        if $caps->{$_} =~ /PASS/xsm;
    return 'NO' if $caps->{$_} eq 'FAIL';

    $result = 'MAYBE';
  }

  return $result;
}

########################################################################
sub summarize_capabilities {
########################################################################
  my ($rows) = @_;

  my $m = { map { ( $_->{Check} => $_->{Status} ) } @{$rows} };

  my @default_needs = ( 'Credentials', 'VPC/Subnets', 'Egress', 'ECS perms', 'CloudWatch Logs perms', 'iam:PassRole' );
  my @need_http     = ( @default_needs, 'ELBv2 perms' );
  my @need_https    = ( @need_http,     'ACM' );
  my @need_sched    = ( @default_needs, 'Events perms' );
  my @need_oneshot  = @default_needs;
  my @need_daemon   = @default_needs;

  my %caps = (
    'HTTP services'   => _gate( \@need_http,    $m ),
    'HTTPS service'   => _gate( \@need_https,   $m ),
    'Scheduled tasks' => _gate( \@need_sched,   $m ),
    'One-shot tasks'  => _gate( \@need_oneshot, $m ),
    'Daemon services' => _gate( \@need_daemon,  $m ),
  );

  return ( \%caps, $m );
}

########################################################################
sub render_capabilities {
########################################################################
  my ( $caps, $account, $region ) = @_;

  my $title = sprintf "Capabilities Summary\nAccount [%s] Region: [%s]", $account, $region;

  my @data;

  foreach my $k ( sort keys %{$caps} ) {
    push @data, { 'Service Type' => $k, 'Available' => $caps->{$k} };
  }

  print easy_table(
    table_options => { headingText => $title },
    columns       => [ 'Service Type', 'Available' ],
    data          => \@data

  );

  return;
}

########################################################################
sub init {
########################################################################
  my ($self) = @_;

  $self->set_route53_profile($self->get_dns_profile // $self->get_profile);

  return;
}

########################################################################
sub main {
########################################################################

  my %default_options = (
    profile   => $ENV{AWS_PROFILE} || q{default},
    region    => $ENV{AWS_REGION}  || q{us-east-1},
    log_level => 'info',
    dns       => $TRUE,
    secrets   => $TRUE,
    https     => $TRUE,
  );

  my @option_specs = qw(
    profile=s
    region=s
    https!
    help|h
    dns!
    secrets!
    dns-profile=s
    log_level=s
  );

  my %commands = ( default => \&check_fargate_env );

  my $cli = App::FargateStack::Checker->new(
    commands        => \%commands,
    default_options => \%default_options,
    option_specs    => \@option_specs,
    extra_options   => [qw(account global_options role_names route53_profile)],
  );

  my @expected_roles = (
    # Execution role and task role your builder will create
    'FargateStack/my-svc/TaskExecutionRole',
    'FargateStack/my-svc/TaskRole',
    'FargateStack/my-svc/EventsInvokeRole',
  );

  $cli->set_role_names( \@expected_roles );

  $cli->set_global_options(
    { profile => $cli->get_profile,
      region  => $cli->get_region
    }
  );

  return $cli->run();
}

1;

__END__

=pod

=head1 NAME

app-FargateStack-env.pl - Preflight checker for ECS Fargate environments

=head1 USAGE

  app-FargateStack-env.pl [options]

=head1 DESCRIPTION

Runs read-only checks against the target AWS account and region to verify
that common ECS Fargate deployment scenarios are feasible. Produces an
ASCII table with PASS/WARN/FAIL rows and a capabilities summary for:

  - HTTP services
  - HTTPS service
  - Scheduled tasks
  - One-shot tasks
  - Daemon services

No resources are created or modified. Intended as a fast “can I deploy here?”
probe for humans and CI.

=head2 Options

=over 4

=item B<--profile> I<STR>

AWS config/credentials profile to use. Defaults to C<$ENV{AWS_PROFILE}> or the
SDK’s default behavior if unset.

=item B<--region> I<STR>

AWS region to target (e.g. C<us-east-1>). Defaults to C<$ENV{AWS_REGION}> if set.

=item B<--dns> | B<--no-dns>

Enable or disable Route 53 checks. Default: B<enabled>.
Use B<--no-dns> (or B<--nodns>) to skip DNS checks.

=item B<--dns-profile> I<STR>

Alternate AWS profile for Route 53 lookups. Useful when DNS is managed in a
separate account. Falls back to C<--profile> if not provided.

=item B<--https> | B<--no-https>

Enable or disable ACM certificate checks (same region as the load balancer).
Default: B<disabled>. Turn on if you plan to deploy HTTPS.

=item B<--secrets> | B<--no-secrets>

Enable or disable Secrets Manager reachability checks. Default: B<disabled>.
When enabled, the checker verifies control-plane reachability (e.g., VPC
endpoint present or NAT available). It does not validate individual
C<GetSecretValue> permissions for task roles.

=back

=head1 OUTPUT

The main table includes rows like:

  Credentials
  Service-linked roles
  VPC/Subnets
  Egress
  ECS perms
  ELBv2 perms
  CloudWatch Logs perms
  ECR
  Events perms
  iam:PassRole
  Route 53
  ACM
  Secrets Manager

Each row has a Status of B<PASS>, B<WARN>, or B<FAIL> and a Detail string.
Typical examples:

  - Egress: PASS with NAT present; missing VPC endpoints are called out as optional.
  - Events perms: PASS when EventBridge APIs are readable (e.g., list-event-buses).
  - iam:PassRole: PASS when simulation allows passing target roles to
    C<ecs-tasks.amazonaws.com> and C<events.amazonaws.com>.

=head2 CAPABILITIES SUMMARY

After the table, a summary lists readiness for common Fargate scenarios:

  YES   = all required checks PASS
  MAYBE = at least one required check WARN (no FAILs)
  NO    = at least one required check FAIL or a required check is missing

The gates for each capability are:

  HTTP services    : Credentials, VPC/Subnets, Egress, ECS perms,
                     ELBv2 perms, CloudWatch Logs perms, iam:PassRole
  HTTPS service    : HTTP services + ACM
  Scheduled tasks  : Credentials, VPC/Subnets, Egress, ECS perms,
                     Events perms, CloudWatch Logs perms, iam:PassRole
  One-shot tasks   : Credentials, VPC/Subnets, Egress, ECS perms,
                     CloudWatch Logs perms, iam:PassRole
  Daemon services  : Credentials, VPC/Subnets, Egress, ECS perms,
                     CloudWatch Logs perms, iam:PassRole

=head2 EXIT STATUS

  0  All checks PASS
  1  One or more checks WARN (no FAILs)
  2  One or more checks FAIL

These exit codes are designed for CI gating.

=head2 NOTES

=over 4

=item * Read-only

The checker performs only C<Describe*/List*> calls and IAM simulation where
available. It does not create, update, or delete resources.

=item * Service-linked roles (SLRs)

The checker reports on SLRs relevant to ECS/ELB. EventBridge does not have a
single generic “AWSServiceRoleForEvents”; feature-specific SLRs are outside the
default scope.

=item * Egress semantics

For private subnets, NAT is sufficient for pulling images and writing logs.
VPC endpoints for ECR (api+dkr) and Logs are recommended in restricted/air-gapped
environments; missing endpoints are reported as optional when NAT is present.

=item * iam:PassRole simulation

When role names are known or derivable, the checker simulates C<iam:PassRole>
for each target role against C<ecs-tasks.amazonaws.com> and
C<events.amazonaws.com>. If role names are not available, the tool may WARN and
capabilities depending on PassRole may degrade to MAYBE.

=item * Separate DNS account

If Route 53 is managed in another account, use C<--dns-profile>. The header will
display the active “Route53 profile” for clarity.

=back

=head1 EXAMPLES

Minimal, default profile/region:

  app-FargateStack-env.pl

Explicit profile/region:

  app-FargateStack-env.pl --profile sandbox --region us-east-1

Skip DNS checks entirely:

  app-FargateStack-env.pl --no-dns

Use a separate Route 53 account, and enable HTTPS + Secrets checks:

  app-FargateStack-env.pl --profile sandbox --region us-east-1 \
    --dns-profile prod --https --secrets

=head1 SEE ALSO

ECS, Fargate, ELBv2, EventBridge, Route 53, ACM, CloudWatch Logs, ECR.

=cut
