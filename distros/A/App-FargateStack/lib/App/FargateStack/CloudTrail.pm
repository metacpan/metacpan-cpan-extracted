package App::FargateStack::CloudTrail;

use strict;
use warnings;

use App::FargateStack::Builder::Utils qw(normalize_time_range dmp jmespath_mapping normalize_timestamp choose);
use Carp;
use CLI::Simple::Constants qw(:booleans);
use Data::Dumper;
use Date::Parse qw(str2time);
use English qw(no_match_vars);
use List::Util qw(any none);
use File::Basename qw(basename);
use Text::ASCIITable::EasyTable;
use Text::Wrap;

$Text::Wrap::columns = 72;

use Role::Tiny;

########################################################################
sub cmd_cloudtrail_events {
########################################################################
  my ($self) = @_;

  my ( $config, $cluster ) = $self->common_args(qw(config cluster));

  my $cluster_name = $cluster->{name};
  my ( undef, $task_name, $start_time, $end_time ) = $self->get_args;

  die sprintf "usage: %s show cloudtrail-events task-name start-time [end-time]\n", $ENV{SCRIPT_NAME}
    if !$task_name || !$start_time;

  die "ERROR: show cloudtrail-events is for stacks with at least 1 scheduled event\n"
    if !$self->has_events;

  # may support multiple groups and/or multiple roles in the future
  my $group_names //= [ 'schedule:' . $task_name ];
  $group_names = ref($group_names) ? $group_names : [$group_names];

  my $role_names //= [ $config->{events_role}->{name} ];
  $role_names = ref($role_names) ? $role_names : [$role_names];

  my $ct = $self->fetch_cloudtrail;

  ($start_time) = normalize_time_range($start_time);

  die sprintf "ERROR: invalid start-time: %s\n",
    if !$start_time;

  # get CloudTrail events, filter on role
  my $events = $ct->lookup_events(
    start_time => int $start_time / 1000,
    attributes => { EventName => 'RunTask' }
  );

  $ct->check_result( message => 'ERROR: could not lookup events in CloudTrail' );

  die sprintf "ERROR: no events for: [%s] found, start-time: %s\n", $task_name, scalar localtime $start_time
    if !$events || !@{$events};

  my %status;

  foreach my $e ( @{$events} ) {
    $e = $e->{CloudTrailEvent};
    next if !$e;

    my $userName = $e->{userIdentity}->{sessionContext}->{sessionIssuer}->{userName};
    next if !$userName || none { $_ eq $userName } @{$role_names};

    $status{ $e->{eventID} } = {
      eventTime    => normalize_timestamp( $e->{eventTime} ),
      errorMessage => $e->{errorMessage},
      errorCode    => $e->{errorCode},
      taskArn      => $e->{responseElements}->{tasks}->[0]->{taskArn}
    };
  }

  die sprintf "ERROR: no events match this role: [%s]\n", join q{,}, @{$role_names}
    if !keys %status;

  my @arns = map { $status{$_}->{taskArn} // () } keys %status;

  $self->_decorate_status( \@arns, \%status, $cluster_name );

  my $data = $self->_build_event_data( \%status );

  my $output = choose {
    return JSON->new->pretty->encode($data)
      if $self->get_output eq 'json';

    return easy_table(
      columns       => [qw(EventTime ErrorCode ErrorMessage StartTime StopTime LastStatus Task)],
      data          => $data,
      table_options => { headingText => sprintf "CloudTrail/ECS Events\nRoles: %s", join q{,}, @{$role_names} }
    );
  };

  print {*STDOUT} $output;

  return;
}

########################################################################
sub _build_event_data {
########################################################################
  my ( $self, $status ) = @_;

  my @eventIds = sort { $status->{$a}->{eventTime} <=> $status->{$b}->{eventTime} } keys %{$status};

  my @data;

  foreach my $e (@eventIds) {
    my $row = $status->{$e};
    next if !$row->{errorMessage} && !$row->{taskDefinitionArn};

    push @data,
      {
      EventTime    => scalar( localtime( $status->{$e}->{eventTime} ) ),
      StartTime    => $row->{startedAt}  // q{},
      StopTime     => $row->{stoppedAt}  // q{},
      LastStatus   => $row->{lastStatus} // q{},
      Task         => $row->{taskDefinitionArn} ? basename( $row->{taskDefinitionArn} ) : q{},
      ErrorCode    => $row->{errorCode},
      ErrorMessage => wrap( q{}, q{}, $row->{errorMessage} ),
      };
  }
  return \@data;
}

########################################################################
sub _decorate_status {
########################################################################
  my ( $self, $arns, $status, $cluster_name ) = @_;

  my $query = jmespath_mapping( 'tasks[]' => [qw(taskArn startedAt stoppedAt lastStatus taskDefinitionArn)] );

  my $ecs = $self->fetch_ecs;

  my @arn_list = @{$arns};

  my @task_list;

  # AWS describe-tasks limits tasks to 100
  while ( my @arns = splice @arn_list, 0, 99 ) {
    push @task_list, @{ $ecs->describe_tasks( $cluster_name, \@arns, $query ) };
  }

  my %tasks = map { ( $_->{taskArn} => $_ ) } @task_list;

  foreach my $e ( keys %{$status} ) {
    my $arn = $status->{$e}->{taskArn};
    next if !$arn;

    $status->{$e}->{stoppedAt}         = $tasks{$arn}->{stoppedAt};
    $status->{$e}->{startedAt}         = $tasks{$arn}->{startedAt};
    $status->{$e}->{lastStatus}        = $tasks{$arn}->{lastStatus};
    $status->{$e}->{taskDefinitionArn} = $tasks{$arn}->{taskDefinitionArn};
  }

  return $status;
}

1;
