package App::Events;

use strict;
use warnings;

use App::FargateStack::Constants;
use Carp;
use Data::Dumper;
use English qw(-no_match_vars);
use File::Temp qw(tempfile);
use JSON;
use List::Util qw(none any);
use Scalar::Util qw(reftype);

use Role::Tiny::With;
with 'App::AWS';

use parent qw(App::Command);

__PACKAGE__->follow_best_practice();
__PACKAGE__->mk_accessors(qw(profile region event_bus_name unlink));

use Readonly;

Readonly::Scalar our $DEFAULT_EVENT_BUS_NAME => 'default';

########################################################################
sub new {
########################################################################
  my ( $class, @args ) = @_;

  my $self = $class->SUPER::new(@args);

  if ( !$self->get_event_bus_name ) {
    $self->set_event_bus_name($DEFAULT_EVENT_BUS_NAME);
  }

  return $self;
}

########################################################################
sub describe_rule {
########################################################################
  my ( $self, $rule_name, $query ) = @_;

  return $self->command(
    'describe-rule' => [
      '--name' => $rule_name,
      $query ? ( '--query' => $query ) : ()
    ]
  );
}

########################################################################
sub remove_targets {
########################################################################
  my ( $self, $rule_name, $id ) = @_;

  return $self->command(
    'remove-targets' => [
      '--rule'           => $rule_name,
      '--ids'            => $id,
      '--event-bus-name' => $self->get_event_bus_name,
    ]
  );
  return;
}

########################################################################
sub list_targets_by_rule {
########################################################################
  my ( $self, $rule_name, $query ) = @_;

  return $self->command(
    'list-targets-by-rule' => [
      '--rule'           => $rule_name,
      '--event-bus-name' => $self->get_event_bus_name,
      $query ? ( '--query' => $query ) : (),
    ]
  );

  return;
}

########################################################################
#  0 => does not exist
#  1 => exists and schedule has not changed
# -1 => exists and schedule has changed
########################################################################
sub rule_exists {
########################################################################
  my ( $self, $rule_name, $schedule ) = @_;

  my $event_bus_name = $self->get_event_bus_name;

  my $result = $self->command(
    'list-rules' => [
      '--query' => sprintf "Rules[?Name == `%s` && EventBusName == `%s`]",
      $rule_name, $event_bus_name
    ]
  );

  $self->check_result(
    message => 'ERROR: could not execute list-rules for: %s',
    params  => [$rule_name],
    regexp  => qr/does\s+not\s+exists/xsmi
  );

  my ($rule) = @{ $result || [] };

  return $FALSE
    if !$rule || !$schedule;

  return $schedule ? $schedule eq $rule->{ScheduleExpression} ? 1 : -1 : 0;
}

########################################################################
sub enable_rule {
########################################################################
  my ( $self, $rule_name ) = @_;

  return $self->command(
    'enable-rule' => [
      '--name'           => $rule_name,
      '--event-bus-name' => $self->get_event_bus_name,
    ]
  );
}

########################################################################
sub disable_rule {
########################################################################
  my ( $self, $rule_name ) = @_;

  return $self->command(
    'disable-rule' => [
      '--name'           => $rule_name,
      '--event-bus-name' => $self->get_event_bus_name,
    ]
  );
}

########################################################################
sub delete_rule {
########################################################################
  my ( $self, $rule_name ) = @_;

  return $self->command(
    'delete-rule' => [
      '--name'           => $rule_name,
      '--event-bus-name' => $self->get_event_bus_name
    ]
  );

}

########################################################################
sub put_rule {
########################################################################
  my ( $self, %args ) = @_;

  my ( $rule_name, $schedule, $state, $event_pattern ) = @args{qw(rule_name schedule state event_pattern)};

  return $self->command(
    'put-rule' => [
      '--name'           => $rule_name,
      '--event-bus-name' => $self->get_event_bus_name,
      $schedule      ? ( '--schedule'      => $schedule )                       : (),
      $event_pattern ? ( '--event-pattern' => $event_pattern )                  : (),
      $state         ? ( '--state'         => $state ? 'ENABLED' : 'DISABLED' ) : (),
    ]
  );

}

########################################################################
sub target_exists {
########################################################################
  my ( $self, $rule_name ) = @_;

  my $result = $self->command(
    'list-targets-by-rule' => [
      '--event-bus-name' => $self->get_event_bus_name,
      '--rule'           => $rule_name,
      '--query'          => 'Targets',
    ]
  );

  $self->check_result(
    message => 'ERROR: could not list targets for %s',
    params  => [$rule_name],
    regexp  => qr/does\s+not\s+exist/xsmi
  );

  return reftype($result) ? $result->[0] : $result;
}

########################################################################
sub put_targets {
########################################################################
  my ( $self, $rule, $target ) = @_;

  my ( $fh, $tmpfile ) = tempfile(
    'rule-XXXXX',
    UNLINK => $self->get_unlink,
    SUFFIX => '.json'
  );

  my $json = JSON->new->pretty->encode($target);

  print {$fh} $json;

  close $fh;

  return $self->command(
    'put-targets' => [
      '--rule'           => $rule,
      '--targets'        => "file://$tmpfile",
      '--event-bus-name' => $self->get_event_bus_name
    ]
  );
}

########################################################################
sub validate_schedule {
########################################################################
  my ( $self, $schedule ) = @_;

  my ( $type, $args ) = ( $schedule =~ /^(cron|at|rate)[(]([^)].+)[)]$/xsm );

  return $FALSE
    if !$type || !$args;

  my %validators = (
    rate => sub {
      my ($args) = @_;

      my ( $value, $unit ) = split /\s+/xsm, $args;

      return $FALSE
        if !$value || !$unit;

      return $TRUE
        if $unit eq 'minutes'
        && $value > 0
        && $value <= 59;

      return $TRUE
        if $unit eq 'hours'
        && $value > 0
        && $value <= 59;

      return $TRUE
        if $unit eq 'days' && $value > 0;

      return $FALSE;
    },
    cron => sub {
      my ($args) = @_;

      my @cron = split /\s+/xsm, $args;

      return $FALSE
        if 6 != @cron;

      my ( $min, $hour, $dom, $month, $dow, $year ) = @cron;

      # AWS stupid cron format - both dom and dow cannot be '*', but
      # allow in our config
      if ( $dow eq q{*} && $dom eq q{*} ) {
        $dow = q{?};
      }

      if ( _validate_min($min)
        && _validate_hour($hour)
        && _validate_day($dom)
        && _validate_month($month)
        && _validate_dow($dow)
        && _validate_year($year) ) {
        return sprintf 'cron(%s %s %s %s %s %s)', $min, $hour, $dom, $month, $dow, $year;
      }

      return $FALSE;
    },
    at => sub {
      my ($args) = @_;

      my ( $this_month, $today, $this_year ) = (localtime)[ 3, 4, 5 ];
      $this_month++;
      $this_year += 1900;

      my ( $year, $month, $day, $hour, $min, $sec ) = ( $args =~ /^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})$/xsm );

      return $FALSE
        if $year < $this_year;

      return $FALSE
        if $month < 1 || $month > 12;

      return $FALSE
        if $day < 1 || $day > 31;

      return $FALSE
        if $hour < 0 || $hour > 23;

      return $FALSE
        if $min < 0 || $min > 59;

      return $FALSE
        if $sec < 0 || $sec > 59;

      return $FALSE
        if $year == $this_year && $month < $this_month;

      return $FALSE
        if $year == $this_year && $month == $this_month && $day < $today;

      # let's not get carried away with checking hour,
      # min, seconds in the past...if someone does
      # that it should blow up in there face...

      return $TRUE;
    },
  );

  return $validators{$type}->($args);
}

########################################################################
sub _validate_range {
########################################################################
  my ( $expr, $min, $max ) = @_;

  return $TRUE
    if $expr !~ /[\-]/xsm;

  return $FALSE
    if !$expr;

  # Handle simple range: "start-end"
  return $TRUE if $expr =~ /^(\d+)-(\d+)$/xsm && $1 >= $min && $2 <= $max && $1 <= $2;

  # Handle step: "*/n"
  return $TRUE if $expr =~ m{^\*/(\d+)$}xsm && $1 > 0;

  # Handle range with step: "m-n/x"
  return $TRUE
    if $expr =~ m{^(\d+)-(\d+)/(\d+)$}xsm
    && $1 >= $min
    && $2 <= $max
    && $1 <= $2
    && $3 > 0;

  return $FALSE;
}

########################################################################
sub _validate_min {
########################################################################
  my ($min) = @_;

  return $TRUE if $min eq q{*};

  if ( $min =~ /^\d+$/xsm ) {
    return $TRUE if $min >= 0 && $min <= 59;
    return $FALSE;
  }

  if ( $min =~ /,/xsm ) {
    foreach my $m ( split /,/xsm, $min ) {
      return $FALSE if $m !~ /^\d+$/xsm || $m < 0 || $m > 59;
    }
    return $TRUE;
  }

  return $TRUE if _validate_range( $min, 0, 59 );

  return $FALSE;
}

########################################################################
sub _validate_hour {
########################################################################
  my ($hour) = @_;

  return $TRUE if $hour eq q{*};

  if ( $hour =~ /^\d+$/xsm ) {
    return $TRUE if $hour >= 0 && $hour <= 23;
    return $FALSE;
  }

  if ( $hour =~ /,/xsm ) {
    foreach my $h ( split /,/xsm, $hour ) {
      return $FALSE if $h !~ /^\d+$/xsm || $h < 0 || $h > 23;
    }
    return $TRUE;
  }

  return $TRUE if _validate_range( $hour, 0, 23 );

  return $FALSE;
}

########################################################################
sub _validate_day {
########################################################################
  my ($day) = @_;

  return $TRUE if $day eq q{*};

  if ( $day =~ /^\d+$/xsm ) {
    return $TRUE if $day >= 1 && $day <= 31;
    return $FALSE;
  }

  if ( $day =~ /,/xsm ) {
    foreach my $d ( split /,/xsm, $day ) {
      return $FALSE if $d !~ /^\d+$/xsm || $d < 1 || $d > 31;
    }
    return $TRUE;
  }

  return $TRUE if _validate_range( $day, 1, 31 );

  return $FALSE;
}

########################################################################
sub _validate_month {
########################################################################
  my ($month) = @_;

  return $TRUE if $month eq q{*};

  my @valid_names = qw(JAN FEB MAR APR MAY JUN JUL AUG SEP OCT NOV DEC);
  my @valid_nums  = ( 1 .. 12 );

  return $TRUE if any { $month eq $_ } @valid_names, @valid_nums;

  if ( $month =~ /,/xsm ) {
    foreach my $m ( split /,/xsm, $month ) {
      return $FALSE if none { $m eq $_ } @valid_names, @valid_nums;
    }
    return $TRUE;
  }

  return $TRUE if _validate_range( $month, 1, 12 );

  return $FALSE;
}

########################################################################
sub _validate_year {
########################################################################
  my ($year) = @_;

  return $TRUE if $year eq q{*};

  my $this_year = (localtime)[5] + 1900;

  return $TRUE if $year =~ /^\d+$/xsm && $year >= $this_year;

  if ( $year =~ /,/xsm ) {
    foreach my $y ( split /,/xsm, $year ) {
      return $FALSE if $y !~ /^\d+$/xsm || $y < $this_year;
    }
    return $TRUE;
  }

  if ( $year =~ /^(\d+)-(\d+)$/xsm ) {
    my ( $start, $end ) = ( $1, $2 );
    return $TRUE if $start >= $this_year && $start <= $end;
  }

  return $FALSE;
}

########################################################################
sub _validate_dow {
########################################################################
  my ($day) = @_;

  return $TRUE if $day eq q{*};

  # allow numeric values 1..7 and short day names
  my @valid_names = qw(SUN MON TUE WED THU FRI SAT);
  my @valid_nums  = ( 1 .. 7 );

  # simple name or number
  return $TRUE if any { $day eq $_ } @valid_names, @valid_nums;

  # comma-separated values (e.g., "1,MON,3")
  if ( $day =~ /,/xsm ) {
    foreach my $d ( split /,/xsm, $day ) {
      return $FALSE if none { $d eq $_ } @valid_names, @valid_nums;
    }
    return $TRUE;
  }

  # numeric range
  return $TRUE if _validate_range( $day, 1, 7 );

  # named range (e.g., MON-FRI)
  return $TRUE if $day =~ /^(${\join '|', @valid_names})-(${\join '|', @valid_names})$/xsm;

  return $FALSE;
}

1;
