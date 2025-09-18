package App::FargateStack::Builder::Service;

use strict;
use warnings;

use Carp;
use Data::Dumper;
use English qw(-no_match_vars);
use List::Util qw(any);

use App::FargateStack::Constants;

use Role::Tiny;

########################################################################
sub build_service {
########################################################################
  my ( $self, $service_name, $desired_count ) = @_;

  my ( $config, $dryrun, $tasks, $cluster ) = $self->common_args(qw(config dryrun tasks cluster));

  my $ecs = $self->fetch_ecs;

  my $task = $tasks->{$service_name};

  my @vpc_subnets = $self->get_service_subnets( $task->{type} );

  my @services = @{ $ecs->list_services( $cluster->{name}, 'serviceArns' ) || [] };

  my @desired_services = $service_name ? ($service_name) : keys %{$tasks};

  $self->log_warn( 'service: creating %d service(s) [%s]', scalar(@desired_services), join q{,}, @desired_services );

  my $public_ip = $FALSE;

  foreach my $task_name (@desired_services) {

    my $task = $tasks->{$task_name};

    if ( any { $_ eq $task_name } @services ) {
      $self->get_logger->info( sprintf 'service: [%s] already exists...skipping', $task_name );
      next;
    }

    $self->get_logger->info( sprintf 'service: creating service: [%s] with [%s] task(s) in subnets: [%s]...%s',
      $task_name, $desired_count, ( join q{,}, @vpc_subnets ), $dryrun );

    if ( !$dryrun ) {
      my $result = $ecs->create_service(
        service_name    => $task_name,
        container_name  => $task_name,
        cluster_name    => $config->{cluster}->{name},
        task_definition => $task_name,
        desired_count   => $desired_count,
        subnets         => \@vpc_subnets,
        public_ip       => $public_ip,
        security_groups => [ $config->{security_groups}->{fargate}->{group_id} ],
        $self->get_http         ? ( target_group_arn => $task->{target_group_arn} )   : (),
        $task->{container_port} ? ( container_port   => 0 + $task->{container_port} ) : (),
      );

      $self->log_debug( sub { return Dumper( [ result => $result ] ); } );

      $ecs->check_result( { message => 'ERROR: could not create service: [%s], desired count: [%s]' },
        $task_name, $desired_count );
    }
  }

  return;
}

########################################################################
# Best Practice: if we have are an HTTP service we should put the task in the same
# AZs as the ALB
########################################################################
sub get_service_subnets {
########################################################################
  my ( $self, $type ) = @_;

  my ( $config, $alb ) = $self->common_args(qw(config alb));

  my $alb_arn = defined $alb && $alb->{arn};

  if ( $alb_arn && $type =~ /^https?/xsm ) {
    $self->get_logger->warn('service: service will be placed in the same AZs as load balancer.');
    return $self->get_task_subnets($alb_arn);
  }

  # this is for tasks and services other than HTTP or HTTPS
  my $subnets = $self->get_subnets->{private};

  if ( !$subnets || !@{$subnets} ) {
    if ( $subnets = $self->get_subnets->{public} ) {
      $self->get_logger->warn('service: no private subnets! Using public subnets is not recommended.');
    }
    else {
      croak sprintf "no subnets in %s found\n", $config->{vpc_id};
    }
  }

  return @{$subnets}[ 0, 1 ];
}

########################################################################
sub get_task_subnets {
########################################################################
  my ( $self, $alb_arn ) = @_;

  # fetch ALB AZs
  my $elb = $self->fetch_elbv2;

  my $az_names = $elb->describe_load_balancers(
    arn   => $alb_arn,
    query => 'LoadBalancers[].AvailabilityZones[].ZoneName',
  );

  $elb->check_result( message => 'ERROR: could not describe load balancer: [%s]', $alb_arn );

  # fetch AZs of private subnets
  my $ec2 = $self->fetch_ec2;

  my $private_subnets = $self->get_config->{subnets}->{private} // [];

  # we should not be able to get here...since we check this on startup
  if ( !$private_subnets || !@{$private_subnets} ) {
    $self->log_error('ERROR: no private subnets available.');
    $self->log_errror('App::FargateStack does not support placing tasks in a public subnets for HTTP services.');
    exit 1;
  }

  my $result = $ec2->describe_subnets(
    { subnets => $private_subnets,
      query   => 'Subnets[].{az_name:AvailabilityZone,subnet_id:SubnetId}'
    }
  );

  $ec2->check_result( message => 'ERROR: could not describe subnets: [%s]', join q{,}, @{$private_subnets} );

  $self->log_debug( sub { return Dumper( [ subnet => $result ] ) } );

  my %subnets_by_zone = map { $_->{az_name} => $_->{subnet_id} } @{$result};

  $self->log_debug( sub { return Dumper( [ subnets_by_zone => \%subnets_by_zone ] ) } );

  # Best practice: pick subnets whose AZs match the ALB's AZs, preserve order
  my @selected = grep {defined} @subnets_by_zone{ @{$az_names} };

  return @selected;
}

1;
