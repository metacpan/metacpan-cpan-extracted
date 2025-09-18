package App::FargateStack::Builder::Utils;

use strict;
use warnings;

BEGIN {
  use Log::Log4perl;
  # this register ths package as a wrapper class helps resolve
  # callstack issue when covering Log4perl methods.
  Log::Log4perl->wrapper_register(__PACKAGE__);
}

use Carp;
use Data::Dumper;
use Date::Parse qw(str2time);
use English qw(no_match_vars);
use JSON;
use List::Util qw(any none);
use Scalar::Util qw(blessed reftype refaddr looks_like_number);
use Term::ANSIColor;
use Time::Piece;
use Time::HiRes qw(time);
use Text::Diff;

use JSON;

use Role::Tiny;
use parent qw(Exporter Class::Accessor::Fast);

__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_accessors(qw(_var_pool));

our @EXPORT = qw(
  ToCamelCase
  choose
  common_args
  confirm
  display_diffs
  dmp
  elapsed_time
  jmespath_mapping
  log_die
  normalize_name
  normalize_time_range
  normalize_timestamp
  toCamelCase
  slurp_file
  write_json_file
  fetch_acm
  fetch_cloudtrail
  fetch_application_autoscaling
  fetch_ecr
  fetch_ec2
  fetch_ecs
  fetch_ecr
  fetch_elbv2
  fetch_events
  fetch_efs
  fetch_iam
  fetch_logs
  fetch_secrets
  fetch_sts
  fetch_route53
  fetch_cli_api
  fetch_wafv2
);

########################################################################
sub fetch_application_autoscaling { return shift->fetch_cli_api( 'Application-Autoscaling', @_ ); }
sub fetch_acm                     { return shift->fetch_cli_api( 'ACM',                     @_ ); }
sub fetch_cloudtrail              { return shift->fetch_cli_api( 'CloudTrail',              @_ ); }
sub fetch_iam                     { return shift->fetch_cli_api( 'IAM',                     @_ ); }
sub fetch_logs                    { return shift->fetch_cli_api( 'Logs',                    @_ ); }
sub fetch_efs                     { return shift->fetch_cli_api( 'EFS',                     @_ ); }
sub fetch_ecs                     { return shift->fetch_cli_api( 'ECS',                     @_ ); }
sub fetch_ec2                     { return shift->fetch_cli_api( 'EC2',                     @_ ); }
sub fetch_ecr                     { return shift->fetch_cli_api( 'ECR',                     @_ ); }
sub fetch_events                  { return shift->fetch_cli_api( 'Events',                  @_ ); }
sub fetch_sts                     { return shift->fetch_cli_api( 'STS',                     @_ ); }
sub fetch_secrets                 { return shift->fetch_cli_api( 'Secrets',                 @_ ); }
sub fetch_elbv2                   { return shift->fetch_cli_api( 'ElbV2',                   @_ ); }
sub fetch_route53                 { return shift->fetch_cli_api( 'Route53',                 @_ ); }
sub fetch_wafv2                   { return shift->fetch_cli_api( 'WafV2',                   @_ ); }
########################################################################
sub fetch_cli_api {
########################################################################
  my ( $self, $api, %options ) = @_;

  my $class = $self->get( lc $api );

  return $class
    if $class && !keys %options;

  if ( !$class ) {
    my $normalized_name = $api;
    $normalized_name =~ s/[\-]//xsm;

    my $class_path = sprintf 'App/%s.pm', $normalized_name;

    require $class_path;

    my $class_name = sprintf 'App::%s', $normalized_name;

    $self->set( lc $api, $class_name->new( _service_name => lc $api, %{ $self->get_global_options }, %options ) );

    $class = $self->get( lc $api );
  }

  foreach ( keys %options ) {
    $class->set( $_, $options{$_} );
  }

  return $class;
}

########################################################################
sub maybe_color {
########################################################################
  my ( $self, $color, $text ) = @_;

  return $text
    if !$self->get_color;

  return colored( $text, $color );
}

########################################################################
sub create_default {
########################################################################
  my ( $self, $what, @args ) = @_;

  require App::FargateStack::Constants;

  croak "no default for $what\n"
    if !exists $App::FargateStack::Constants::DEFAULT_NAMES{$what};

  my $default = $App::FargateStack::Constants::DEFAULT_NAMES{$what};

  return ref $default ? $default->( $self, @args ) : $default;
}

########################################################################
sub confirm {
########################################################################
  my ( $prompt, @args ) = @_;

  print sprintf "$prompt [y/N] ", @args;

  chomp( my $answer = <STDIN> );

  return $answer =~ /^y(es)?$/xsmi;
}

########################################################################
sub common_args {
########################################################################
  my ( $self, @args ) = @_;

  my $config = $self->get_config;

  my $var_pool = {
    config => $config,
    cache  => $self->get_cache,
    dryrun => $self->get_dryrun,
    # these just avoid a bunch of hash digging
    tasks           => $config->{tasks},
    cluster         => $config->{cluster},
    security_groups => $config->{security_groups},
    route53         => $config->{route53},
    alb             => $config->{alb},
    app             => $config->{app},
    subnets         => $config->{subnets},
    role            => $config->{role},
    events_role     => $config->{events_role},
  };

  $self->set__var_pool($var_pool);

  return $var_pool
    if !@args;

  my @invalid_args = grep { !exists $var_pool->{$_} } @args;

  croak sprintf "invalid argument(s): %s\n", join q{,}, @invalid_args
    if @invalid_args;

  return @{$var_pool}{@args};
}

########################################################################
sub display_diffs {
########################################################################
  my ( $self, $old, $new, $options ) = @_;

  my $json = JSON->new->canonical->pretty->allow_blessed->convert_blessed;

  my $old_str = $json->encode($old);
  my $new_str = $json->encode($new);

  # normalize line endings + ensure trailing newline (helps diff output)
  for my $str ( $old_str, $new_str ) {
    $str =~ s/\r\n/\n/xsmg;
    next if $str =~ /\n\z/xsm;
    $str .= "\n";
  }

  my $style = ( $options && ref $options ) ? ( $options->{style} // 'Table' ) : 'Table';
  my $diffs = diff( \$old_str, \$new_str, { STYLE => $style } ) // q{};

  return $diffs
    if !$options || !ref $options;

  return q{} if !length $diffs;

  my $log_level = $options->{log_level} // 'error';
  my $title     = $options->{title} //= 'objects differ:';

  $self->get_logger->$log_level( sprintf "\t%s",   $title );
  $self->get_logger->$log_level( sprintf "\n\t%s", $diffs );

  return $diffs;
}

########################################################################
sub ToCamelCase { goto &_toCamelCase; }
sub toCamelCase { return _toCamelCase( $_[0], $_[1], 1 ); }
########################################################################
sub _toCamelCase {
########################################################################
  my ( $snake_case, $want_hash, $lc_first ) = @_;

  $want_hash //= wantarray ? 0 : 1;

  my @CamelCase = map {
    ( $want_hash ? $_ : (), join q{}, map {ucfirst} split /_/xsm )
  } @{$snake_case};

  return $want_hash ? {@CamelCase} : @CamelCase
    if !$lc_first;

  return map {lcfirst} @CamelCase
    if !$want_hash;

  my %camelCase = @CamelCase;

  %camelCase = map { $_ => lcfirst $camelCase{$_} } keys %camelCase;

  return \%camelCase;
}

########################################################################
sub jmespath_mapping {
########################################################################
  my ( $prefix, $elems, $ucfirst ) = @_;
  $ucfirst //= 0;

  my $hash_list = reftype($elems) eq 'HASH' ? $elems : $ucfirst ? ToCamelCase($elems) : toCamelCase($elems);

  my $list = sprintf '%s.%s', $prefix, encode_json $hash_list;

  $list =~ s/"//gxsm;

  return $list;
}

########################################################################
sub elapsed_time {
########################################################################
  my ($start_time) = @_;

  return q{-}
    if !$start_time;

  # Extract timestamp and offset
  my ( $date, $time, $sign, $h_offset, $m_offset ) = $start_time =~ m{
    ^(\d{4}-\d{2}-\d{2})         # date
    T(\d{2}:\d{2}:\d{2})         # time
    \.\d+                        # fractional seconds
    ([+-])(\d{2}):(\d{2})$       # offset
}x;

  # Parse local time (as in the string, which is relative to its own offset)
  my $tp = Time::Piece->strptime( "$date $time", '%Y-%m-%d %H:%M:%S' );

  # Calculate total offset in seconds
  my $offset_sec = ( $h_offset * 3600 + $m_offset * 60 ) * ( $sign eq '+' ? 1 : -1 );

  # Convert to UTC epoch (add offset to local time to get UTC)
  my $epoch_utc = $tp->epoch - $offset_sec;

  # Get current UTC time
  my $now = time;

  # Elapsed time in seconds
  my $elapsed = int( $now - $epoch_utc );

  # Break into minutes and seconds
  my $minutes = int( $elapsed / 60 );
  my $seconds = $elapsed % 60;

  return sprintf '%d:%02d', $minutes, $seconds;
}

########################################################################
sub choose (&) { return $_[0]->(); }
########################################################################

########################################################################
sub dmp { return print {*STDERR} Dumper( [@_] ); }
########################################################################

########################################################################
sub _inc {
########################################################################
  my ( $what, $self, $key, $value ) = @_;

  my $resources = $self->get($what) // {};

  if ( ref $value && reftype($value) eq 'ARRAY' ) {
    ($value) = @{$value};
    $resources->{$key} //= [];
    push @{ $resources->{$key} }, $value;
  }
  else {
    $resources->{$key} = $value;
  }

  $self->set( $what, $resources );

  return $resources;
}

########################################################################
sub inc_existing_resources {
########################################################################
  return _inc( 'existing_resources', @_ );
}

########################################################################
sub inc_required_resources {
########################################################################
  return _inc( 'required_resources', @_ );
}

########################################################################
sub write_json_file {
########################################################################
  my ( $self, $file, $obj ) = @_;

  open my $fh, '>', $file
    or croak "could not open $file for writing\n";

  my $json = JSON->new->pretty->encode($obj);

  print {$fh} $json;

  close $fh;

  return $json;
}

########################################################################
sub slurp_file {
########################################################################
  my ( $file, $json ) = @_;

  local $RS = undef;

  open my $fh, '<', $file
    or croak "could not open $file\n";

  my $content = <$fh>;

  close $fh;

  return $json ? decode_json($content) : $content;
}

########################################################################
sub section_break { return shift->get_logger->info( q{-} x 80 ) }
########################################################################

########################################################################
sub normalize_name {
########################################################################
  my ( $self, $name ) = @_;

  return join q{}, map {ucfirst} split /[_-]+/xsm, $name;
}

########################################################################
sub abbrev {
########################################################################
  my ( $text, $len, $offset ) = @_;
  $offset //= 0;
  $text   //= q{};

  return sprintf '%s...', substr $text, $offset, $len;
}

########################################################################
sub is_service_running {
########################################################################
  my ( $self, $task_name ) = @_;

  my ( $config, $cluster ) = $self->common_args(qw(config cluster));
  my $cluster_name = $cluster->{name};

  my $ecs = $self->fetch_ecs;

  my $services = $ecs->list_services( $cluster_name, 'serviceArns' );

  croak sprintf "ERROR: could not list services for: [%s]\n%s", $cluster_name, $ecs->get_error
    if !$services;

  return
    if none {/\/$task_name/xsm} @{$services};

  my $status = $ecs->describe_services(
    cluster_name => $cluster_name,
    service_name => $task_name,
    query        => 'services[0].runningCount'
  );

  croak sprintf "ERROR: could not describe services for: [%s/%s]\n%s", $cluster_name, $task_name, $ecs->get_error
    if !defined $status;

  return $status;
}

########################################################################
sub _log {
########################################################################
  my ( $logger, $level, @args ) = @_;

  # If first arg looks like a sprintf format string AND we have more args, call sprintf
  if ( @args > 1 && $args[0] =~ /%/xsm ) {
    return $logger->$level( sprintf shift(@args), @args );
  }
  else {
    return $logger->$level(@args);
  }
}

sub log_info  { return _log( shift->get_logger, 'info',  @_ ) }
sub log_debug { return _log( shift->get_logger, 'debug', @_ ) }
sub log_warn  { return _log( shift->get_logger, 'warn',  @_ ) }
sub log_error { return _log( shift->get_logger, 'error', @_ ) }
sub log_die   { _log( shift->get_logger, 'error', @_ ); die q{}; }
sub log_trace { return _log( shift->get_logger, 'trace', @_ ) }
sub log_fatal { return _log( shift->get_logger, 'fatal', @_ ) }

########################################################################
sub normalize_timestamp {
########################################################################
  my ($ts) = @_;

  return
    if !$ts;

  # Already epoch?
  return int $ts        if $ts =~ /^\d{10}$/xsm;  # seconds
  return int $ts / 1000 if $ts =~ /^\d{13}$/xsm;  # millis

  my $s = "$ts";

  # Common cleanups:
  $s =~ s/,//xsmg;                                # "Aug 12, 2025, 4:55:04 PM" -> "Aug 12 2025 4:55:04 PM"
  $s =~ s/Z$/+0000/xsm;                           # ISO8601Z -> explicit offset
  $s =~ s/([+\-]\d\d):(\d\d)$/$1$2/xsm;           # "+05:30" -> "+0530"
  $s =~ s/[.]\d+(?=(?:Z|[+\-]\d\d:?\d\d)$)//xsm;  # strip fractional seconds if present

  # Some services append " UTC" or similar—strip trailing timezone words
  $s =~ s/\s+UTC$//xsmi;

  my $epoch = str2time($s);

  die "unrecognized timestamp: [$ts]"
    if !defined $epoch;

  return int $epoch;
}

use Readonly;

Readonly::Scalar our $SEC_PER_MIN  => 60;
Readonly::Scalar our $SEC_PER_HOUR => 60 * $SEC_PER_MIN;
Readonly::Scalar our $SEC_PER_DAY  => 24 * $SEC_PER_HOUR;

########################################################################
sub normalize_time_range {
########################################################################
  my ( $start, $end ) = @_;

  return
    if !$start;

  my $now = time;

  my $start_epoch = _to_epoch( $start, $now );
  my $end_epoch   = defined $end ? _to_epoch( $end, $now ) : undef;

  croak 'start is in the future' if $start_epoch > $now;
  croak 'end is in the future'   if defined $end_epoch && $end_epoch > $now;
  croak 'start > end'            if defined $end_epoch && $start_epoch > $end_epoch;

  return ( $start_epoch * 1000, defined $end_epoch ? $end_epoch * 1000 : undef );
}

########################################################################
sub _to_epoch {
########################################################################
  my ( $value, $now ) = @_;

  # Duration syntax (e.g. 5d, 30m, 2h)
  if ( $value =~ /^(\d+)([dmh])$/xsmi ) {
    my ( $n, $unit ) = ( $1, lc $2 );
    croak 'duration cannot be zero' if $n == 0;

    my %span = (
      d => $SEC_PER_DAY,
      h => $SEC_PER_HOUR,
      m => $SEC_PER_MIN,
    );

    return $now - $n * $span{$unit};
  }

  # Date string ‑ let Date::Parse do the heavy lifting
  my $epoch = str2time($value);

  croak "unrecognized date format: [$value]"
    if !defined $epoch;

  return $epoch;
}

1;

__END__

=pod

=head1 NAME

App::FargateStack::Builder::Utils

=head1 SYNOPSIS

 # can be used as a role with Role::Tiny or you can import methods

 with 'App::FargateStack::Builder::Utils';

 use App::FargateStack::Builder::Utils qw(choose log_die);

=head1 METHODS AND SUBROUTINES

=head2 choose

A clever little helper that makes your code look awesome. Instead of this:

 my $foo;

 if ( $bar ) {
   $foo = 'biz';
 }
 else {
   $foo = 'baz';
 }

 my $foo = choose {
   return 'biz'
     if $bar;
 
   return 'baz';
 }

The example above would probably be handled by a ternary, but imagine
more complex logic and you'll see why the assignment and declaration
sometimes get separated.  Since I hate to do that...C<choose> was born.

=head2 normalize_timestamp

=head2 fetch_*

Use the C<fetch_*> methods to retrieve an instance of one of the AWS
API classes. The fetch method caches class instances and instantiates
them if necessary by providing common arguments (like profile).

 my $ecs = $self->fetch_ecs;

=head2 normalize_time_range

  my ($from_ms, $to_ms) = normalize_time_range($start, $end);

Normalizes a human-friendly time range into Unix epoch timestamps in
**milliseconds**.

Given a required C<$start> and an optional C<$end>, this routine parses
each value into epoch seconds (using L<Date::Parse/str2time> for absolute
dates, or a compact “duration” syntax), validates the range, and returns
a two-element list: C<(start_ms, end_ms_or_undef)>.

Returns an empty list if C<$start> is false/undefined (useful for
“no time filter” cases).

=head3 Arguments

=over 4

=item C<$start> (required)

Either:

=over 4

=item * A relative duration: C</^\d+[dmh]$/i>

Examples: C<"5m"> (5 minutes), C<"2h"> (2 hours), C<"7d"> (7 days).  
Zero durations (e.g., C<"0m">) are rejected.

=item * An absolute date/time string parsed by C<str2time>.

Examples: C<"2025-08-12 08:00">, C<"2025-08-12T08:00:00Z">, RFC-822 style,
etc. If no timezone is present, parsing uses the local timezone.

=back

=item C<$end> (optional)

Same accepted formats as C<$start>. If omitted, the end of the range is
left undefined.

=back

=head3 Behavior

=over 4

=item * A single “now” is captured at the start of the call, so when both
C<$start> and C<$end> are durations (e.g., C<"15m"> and C<"5m">) they are
evaluated relative to the same instant.

=item * Validation:

=over 4

=item * C<start is in the future> if C<$start> resolves after “now”.

=item * C<end is in the future> if C<$end> resolves after “now”.

=item * C<start > end> if both are defined and C<$start> resolves after C<$end>.

=item * C<duration cannot be zero> for C<0d>, C<0h>, or C<0m>.

=item * C<unrecognized date format: [VALUE]> if C<str2time> cannot parse.

=back

=back

=head3 Returns

A two-element list in **milliseconds since the Unix epoch**:

  ( $start_ms, $end_ms_or_undef )

B<List context is expected.> In scalar context, Perl will return the last
element of the list (which may be C<undef>); don’t rely on that.

=head3 Examples

  # Last 15 minutes, open-ended end:
  my ($from, $to) = normalize_time_range('15m');         # $to is undef

  # Absolute window (local timezone if none given):
  my ($from, $to) = normalize_time_range('2025-08-12 00:00',
                                         '2025-08-12 06:00');

  # Mixed: from 2 hours ago to 30 minutes ago:
  my ($from, $to) = normalize_time_range('2h', '30m');

=head3 Notes

=over 4

=item * The return values are in milliseconds. Some AWS APIs expect seconds;
divide by 1000 if needed.

=item * Duration units supported are days (C<d>), hours (C<h>), and minutes
(C<m>). Seconds/weeks are not accepted.

=item * Absolute parsing is delegated to L<Date::Parse/str2time>; pass a
timezone (e.g., trailing C<Z>) to avoid local-TZ assumptions.

=back

=pod

=head3 jmespath_mapping

  my $expr = jmespath_mapping($prefix, $elems, $ucfirst);

Builds a JMESPath object-projection expression by combining a prefix
(e.g., C<'tasks[]'>) with a field mapping rendered in JMESPath syntax,
such as C<{TaskArn:taskArn,StartedAt:startedAt}>. Quotes are stripped
from the JSON representation to form valid JMESPath.

=head4 Arguments

=over 4

=item * C<$prefix> (Str)

A JMESPath prefix to project over, e.g., C<'tasks[]'> or C<'events[]'>.

=item * C<$elems> (HashRef|ArrayRef)

Either a hashref mapping output keys to source field names, or a list
of source field names. When a list/arrayref is provided, keys are
auto-generated via camel-casing utilities (see C<$ucfirst> below).

Examples:

  # HashRef form (used as-is):
  { TaskArn => 'taskArn', StartedAt => 'startedAt' }

  # ArrayRef form (auto-mapped):
  [ 'taskArn', 'startedAt', 'stoppedAt' ]

=item * C<$ucfirst> (Bool, optional; default 0)

Controls how output keys are generated when C<$elems> is not a hashref.

- If false (default), keys use lower camel case via C<toCamelCase()>.
- If true, keys use upper camel case via C<ToCamelCase()>.

When C<$elems> is a hashref, this flag is ignored.

=back

=head4 Returns

(Str) A JMESPath expression of the form:

  "$prefix.{Key1:field1,Key2:field2,...}"

For example:

  jmespath_mapping('tasks[]', [ 'taskArn', 'startedAt' ], 1)
    => 'tasks[].{TaskArn:taskArn,StartedAt:startedAt}'

  jmespath_mapping('events[]', { Id => 'eventID', Time => 'eventTime' }, 0)
    => 'events[].{Id:eventID,Time:eventTime}'

=head4 Notes

- When C<$elems> is a hashref, it is used directly as the key->field map.
- When C<$elems> is a list/arrayref, the keys are derived from each field
  name using C<toCamelCase()> or C<ToCamelCase()> depending on C<$ucfirst>.
- The need to handle both camel case styles exists because AWS services
  and JMESPath queries are not consistent in field naming conventions.
  Some AWS APIs return structures with lower camel case keys
  (e.g., C<taskArn>), while others or UI tools expect upper camel case
  (e.g., C<TaskArn>). This helper accommodates both without requiring
  the caller to manually reformat keys.
- Internally, the method JSON-encodes the map and then removes double
  quotes to yield valid JMESPath object projection syntax.

=head4 See Also

L<JMESPath|https://jmespath.org/> specification for object projections.

=head1 AUTHOR

Rob Lauer - <rlauer@treasurersbriefcase.com>

=head1 SEE ALSO

L<Role::Tiny>

=cut
