package App::FargateStack::AutoscalingConfig;

use strict;
use warnings;

use App::FargateStack::Constants;
use App::FargateStack::Builder::Utils qw(dmp choose);

use Data::Dumper;
use English qw(no_match_vars);
use List::Util qw(none uniq);

__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_accessors(
  qw(
    config
    cpu
    max_capacity
    metric
    min_capacity
    policy_arn
    policy_name
    requests
    scale_in_cooldown
    scale_out_cooldown
    scheduled_actions
    task_name
  )
);

use parent qw(Class::Accessor::Fast);

########################################################################
sub new {
########################################################################
  my ( $class, @args ) = @_;

  my $options = ref $args[0] ? $args[0] : {@args};

  die 'usage: App::FargateStack::AutoscalingConfig->new(config => autoscaling-config)'
    if !$options->{config};

  my $self = $class->SUPER::new($options);

  foreach (qw(cpu requests scale_in_cooldown scale_out_cooldown policy_name)) {
    next if !defined $self->get($_);

    $self->update( $_ => $self->get($_) );
  }

  $self->parse_metric();

  if ( $self->get_cpu || $self->get_requests ) {
    $self->parse_cooldown();

    $self->parse_scaling_capacity();
  }

  $self->parse_scheduled_actions();

  $self->sanity_check();

  return $self;
}

########################################################################
sub sanity_check {
########################################################################
  my ($self) = @_;

  die 'autoscaling: cpu & requests are mutually exclusive'
    if $self->get_cpu && $self->get_requests;

  return;
}

########################################################################
sub update {
########################################################################
  my ( $self, $key, $value ) = @_;

  $self->get_config->{$key} = $value;

  return $self->set( $key, $value );
}

########################################################################
sub has_scheduled_action {
########################################################################
  my ($self) = @_;

  return exists $self->get_config->{scheduled};
}

########################################################################
sub parse_scheduled_actions {
########################################################################
  my ($self) = @_;

  return
    if !$self->has_scheduled_action;

  my $scheduled = $self->get_config->{scheduled};

  my %scheduled_actions;

  foreach my $scheduled_action_name ( keys %{$scheduled} ) {
    $scheduled_actions{$scheduled_action_name} = $self->_parse_scheduled_action( $scheduled->{$scheduled_action_name} );
  }

  $self->set_scheduled_actions( \%scheduled_actions );

  return $self;
}

########################################################################
sub parse_cooldown {
########################################################################
  my ($self) = @_;

  return
    if !$self->get_cpu && !$self->get_requests;

  my $config = $self->get_config;

  my $scale_out_cooldown = $self->get_scale_out_cooldown // $config->{scale_out_cooldown};
  my $scale_in_cooldown  = $self->get_scale_in_cooldown  // $config->{scale_in_cooldown};

  $scale_out_cooldown ||= $DEFAULT_AUTOSCALING_SCALE_OUT_COOLDOWN;
  $scale_in_cooldown  ||= $DEFAULT_AUTOSCALING_SCALE_IN_COOLDOWN;

  $self->update( scale_out_cooldown => int $scale_out_cooldown );
  $self->update( scale_in_cooldown  => int $scale_in_cooldown );

  return $self;
}

########################################################################
sub parse_scaling_capacity {
########################################################################
  my ($self) = @_;

  return
    if !$self->get_cpu && !$self->get_requests;

  my $config = $self->get_config;

  my $min_capacity = $self->get_min_capacity // $config->{min_capacity};
  my $max_capacity = $self->get_max_capacity // $config->{max_capacity};

  $min_capacity ||= $DEFAULT_AUTOSCALING_MIN_CAPACITY;
  $max_capacity ||= $DEFAULT_AUTOSCALING_MAX_CAPACITY;

  die sprintf 'autoscaling: min_capacity [%s] must be less than max_capacity [%s]', $min_capacity, $max_capacity
    if $min_capacity > $max_capacity;

  $self->update( min_capacity => int $min_capacity );
  $self->update( max_capacity => int $max_capacity );

  return $self;
}

########################################################################
sub get_metric_value {
########################################################################
  my ($self) = @_;

  return $self->get( $self->get_metric );
}

########################################################################
sub parse_metric {
########################################################################
  my ($self) = @_;

  my $config = $self->get_config;

  my $metric = $self->get_metric;

  if ( $metric && $metric =~ /^(cpu|requests)[: \-,](\d+)$/xsm ) {
    $metric = $1;
    $config->{$1} = $2;
  }
  elsif ( defined $self->get_cpu ) {
    $config->{cpu} = $self->get_cpu;
  }
  elsif ( defined $self->get_requests ) {
    $config->{requests} = $self->get_requests;
  }

  my @metric = choose {
    return ( 'cpu', int $config->{cpu} )
      if defined $config->{cpu};

    return ( 'requests', int $config->{requests} )
      if defined $config->{requests};

    # scheduled only?
    return ( $config->{scheduled}, 0 )
      if defined $config->{scheduled};

    return;
  };

  die 'autoscaling: autoscaling type must be one of "cpu", "requests" or "scheduled"'
    if !@metric;

  return  # scheduled
    if !$metric[1];

  $self->set_metric( $metric[0] );

  $self->update( $metric[0] => $metric[1] );

  return $self;
}

=pod

=head2 parse_scheduled_action

my $action_hash = $self->parse_scheduled_action( $scheduled_action_hash );

This is a private helper subroutine that acts as the primary parser and validator
for the user-defined schedule configuration. It takes a single, user-configured
schedule hash (e.g., the business_hours block) and translates it into a
complex data structure containing the two distinct, API-ready "ScaleOut" and
"ScaleIn" actions required by AWS.

The subroutine's main responsibilities are:

=over 4

=item *

Parsing: It parses the user-friendly start_time, end_time, days,
min_capacity, and max_capacity values. It supports flexible delimiters
for capacity pairs and both textual and numeric day representations.

=item *

Validation: It performs a series of critical, upfront validation checks.
If any part of the configuration is missing, malformed, or logically
inconsistent (e.g., a scale-in capacity is larger than a scale-out capacity),
the subroutine will abort the entire process with a clear, descriptive error
message.

=item *

Transformation: It transforms the validated user input into two separate,
syntactically correct AWS cron expressions (cron(...)) for the scale-out and
scale-in events.

=item *

Structuring: It builds and returns a nested hash that precisely mirrors
the data structure needed for the put-scheduled-action API calls, separating
the ScaleOut and ScaleIn actions, each with their own Schedule string and
Action hash containing the corresponding capacity limits.

=back

=head3 Arguments

=over 4

=item * C<$scheduled_action>

A hash reference corresponding to a single named schedule from the user's YAML
configuration. It is expected to contain the following keys:

=over 8

=item * C<start_time> (e.g., "09:00")

=item * C<end_time> (e.g., "17:00")

=item * C<days> (e.g., "MON-FRI", "2-6")

=item * C<min_capacity> (e.g., "2/1", "2-1")

=item * C<max_capacity> (e.g., "4/1", "4-1")

=back

=back

=head3 Returns

A hash reference containing two keys, C<ScaleOut> and C<ScaleIn>. Each of these
keys contains another hash with the fully-formed C<Action> and C<Schedule>
sub-hashes required for the final API calls.

=cut

########################################################################
sub _parse_scheduled_action {
########################################################################
  my ( $self, $scheduled_action ) = @_;

  my ( $start_time, $end_time, $days ) = @{$scheduled_action}{qw(start_time end_time days)};

  die 'autoscaling: you must include start_time, end_time, and days for a scheduled action'
    if !$start_time || !$end_time || !$days;

  my (@start_times) = split /:/xsm, $start_time;

  my (@end_times) = split /:/xsm, $end_time;

  die sprintf 'autoscaling: invalid start time: [%s]', $start_time
    if $start_times[0] < 0 || $start_times[0] > 59;

  die sprintf 'autoscaling: invalid start time: [%s]', $start_time
    if $start_times[1] < 0 || $start_times[1] > 23;

  die sprintf 'autoscaling: invalid end time: [%s]', $end_time
    if $start_times[0] < 0 || $start_times[0] > 59;

  die sprintf 'autoscaling: invalid end time: [%s]', $end_time
    if $start_times[1] < 0 || $start_times[1] > 23;

  my @days_parsed = split /[\/\-: ,]/xsmi, $days;

  if ( @days_parsed == 1 ) {
    push @days_parsed, @days_parsed;
  }

  my %day_names = qw(SUN 1 MON 2 TUE 3 WED 4 THU 5 FRI 6 SAT 7);
  my %day_nums  = reverse %day_names;

  foreach my $day (@days_parsed) {
    if ( $day =~ /^\d$/xsmi ) {
      $day =~ s/^[1-7]$/$day_nums{$day}/xsm;
    }

    die sprintf 'autoscaling: invalid day: [%s]', $day
      if none { $day eq $_ } keys %day_names;
  }

  die sprintf 'autoscaling: invalid day range [%s] - [%s]', @days_parsed
    if $day_names{ $days_parsed[0] } > $day_names{ $days_parsed[1] };

  my ( $min_capacity, $max_capacity ) = @{$scheduled_action}{qw(min_capacity max_capacity)};

  die 'autoscaling: both min_capacity and max_capacity must be provided'
    if !$max_capacity || !$min_capacity;

  my @min_capacities = split /[: ,\/\-]/xsm, $min_capacity;

  my @max_capacities = split /[: ,\/\-]/xsm, $max_capacity;

  die 'autoscaling: min_capacity must be a tuple (ex: 2/1)'
    if @min_capacities != 2;

  die 'autoscaling: scale in min capacity should be <= scale out min capacity'
    if $min_capacities[0] < $min_capacities[1];

  die 'autoscaling: max_capacity must be a tuple (ex: 2/1)'
    if @max_capacities != 2;

  die 'autoscaling: scale in max capacity should be <= scale out max capacity'
    if $max_capacities[0] < $max_capacities[1];

  $days_parsed[0] = $day_names{ $days_parsed[0] };
  $days_parsed[1] = $day_names{ $days_parsed[1] };

  my $action = {
    ScaleOut => {
      Action => {
        MinCapacity => int $min_capacities[0],
        MaxCapacity => int $max_capacities[0],
      },
      Schedule => sprintf 'cron(%02d %02d ? * %s *)',
      @start_times,
      join q{-},
      uniq @days_parsed,
    },
    ScaleIn => {
      Action => {
        MinCapacity => int $min_capacities[1],
        MaxCapacity => int $max_capacities[1],
      },
      Schedule => sprintf 'cron(%02d %02d ? * %s *)',
      @end_times,
      join q{-},
      uniq @days_parsed,
    }
  };

  return $action;
}

1;
