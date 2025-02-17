#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2020-2024 -- leonerd@leonerd.org.uk

use v5.26;
use warnings;
use Object::Pad 0.800;

class App::Device::Chip::sensor 0.07;

use Carp;

use Feature::Compat::Defer;
use Feature::Compat::Try;
use Future::AsyncAwait;
use Sublike::Extended;

use Device::Chip::Adapter;
use Device::Chip::Sensor 0.19; # ->type
use Future::IO 0.08; # ->alarm
use Getopt::Long qw( GetOptionsFromArray );
use List::Util 1.29 qw( max pairgrep );
use Scalar::Util qw( refaddr );

=head1 NAME

C<App::Device::Chip::sensor> - Base class to build C<Device::Chip::Sensor>-based applications on

=head1 SYNOPSIS

   #!/usr/bin/perl
   use v5.26;

   use Object::Pad;
   use Future::AsyncAwait;

   class App extends App::Device::Chip::sensor
   {
      method output_readings ( $now, $sensors, $values )
      {
         print "At time $now, we have some sensor values...\n";
      }
   }

   await App->new->parse_argv->run;

=head1 DESCRIPTION

This module provides a base class to assist in writing applications that
process data periodically from one or more L<Device::Chip>-based sensors, via
the L<Device::Chip::Sensor> interface. A typical program using this module
would derive a subclass from it, provide the remaining methods as necessary,
and eventually call the L</run> method to start the application.

=cut

=head1 COMMANDLINE OPTIONS

The following commandline options are recognised by the base class and may be
used in addition to any defined by the actual application logic.

=over 4

=item * --blib, -b

Uses the L<blib> module to add additional paths into C<@INC> to search for
more Perl modules. May be useful when testing chip drivers under development
without needing to install them.

=item * --interval, -i TIME

Specifies the time, in seconds, between every round of collecting sensor
readings and invoking the L</output_readings> method.

Defaults to 10 seconds.

=item * --adapter, -A STR

Adapter configuration string to pass to L<Device::Chip::Adapter/new_from_description>
to construct the chip adapter used for communication with the actual chip
hardware.

=item * --filter, -F STR

Specifies the kind of filtering to apply to gauge values. See L</FILTERING>
for more detail.

=item * --mid3, -m

Enable "middle-of-3" filtering of gauge values, to reduce sensor noise from
unreliable sensors. This is equivalent to setting C<-F mid3>.

=item * --best-effort, -B

Enables best-effort mode, which causes failures of sensor readings to be
ignored, reporting C<undef> instead. In this mode, the C<on_sensor_fail>
method may be invoked for failures; it can further refine what the behaviour
should be.

=back

=cut

field @_CHIPCONFIGS;
method _chipconfigs { @_CHIPCONFIGS }  # for unit testing

field $_interval :mutator = 10;

field $_best_effort :mutator;

field $_filter :mutator;

method OPTSPEC
{
   return (
      'b|blib' => sub { require blib; blib->import; },

      'i|interval=i' => \$_interval,

      'F|filter=s' => \$_filter,

      'm|mid3' => sub { $_filter = "mid3" },

      'B|best-effort' => \$_best_effort,
   );
}

=head1 PROVIDED METHODS

The following methods are provided on the base class, intended for subclasses
or applications to invoke.

=cut

=head2 parse_argv

   $app->parse_argv();
   $app->parse_argv( \@argv );

Provides a list of commandline arguments for parsing, either from a given
array reference or defaulting to the process C<@ARGV> if not supplied.

This uses L</OPTSPEC> to collect the defined arguments, whose references
should handle the results.

=cut

method parse_argv ( $argv = \@ARGV )
{
   my %optspec = $self->OPTSPEC;

   @_CHIPCONFIGS = ();

   my $ADAPTERDESC; my $adapter;

   GetOptionsFromArray( $argv, %optspec,
      'adapter|A=s' => sub {
         $ADAPTERDESC = $_[1];
         undef $adapter;
      },
      '<>' => sub {
         my ( $chiptype, $opts ) = split m/:/, $_[0], 2;

         $adapter //= Device::Chip::Adapter->new_from_description( $ADAPTERDESC );

         my %config = (
            type    => $chiptype,
            adapter => $adapter,
         );

         while( length $opts ) {
            if( $opts =~ s/^-C:(.*?)=(.*)(?:$|,)// ) {
               $config{config}{$1} = $2;
            }
            elsif( $opts =~ s/^-M:(.*?)=(.*)(?:$|,)// ) {
               $config{mountopts}{$1} = $2;
            }
            else {
               croak "Unable to parse chip configuration options '$opts' for $chiptype'";
            }
         }

         $self->add_chip( %config );
      },
   ) or exit 1;

   return $self;
}

=head2 add_chip

   $app->add_chip( %config );

I<Since version 0.05.>

Adds a new chip to the stored configuration, as if it had been given as a
commandline argument. Takes the following named arguments:

=over 4

=item type => STR

Required string that gives the name of the chip class.

=item adapter => Device::Chip::Adapter

Required L<Device::Chip::Adapter> instance.

=item mountopts => HASH

Optional HASH reference containing extra mount parameters.

=item config => HASH

Optional HASH reference containing extra chip configuration to set up using
the C<configure> method once mounted.

=back

=cut

extended method add_chip ( :$type, :$adapter, %config )
{
   push @_CHIPCONFIGS, {
      type    => $type,
      adapter => $adapter,
      pairgrep { defined $b } %config{qw( mountopts config )}
   };
}

=head2 chips

   @chips = await $app->chips;

An asynchronous memoized lazy accessor for the list of L<Device::Chip>
instances, whose class names are taken from the remaining commandline
arguments after the options are parsed.

=cut

field $_chips; # arrayref
async method chips
{
   return @$_chips if $_chips;

   foreach my $chipconfig ( @_CHIPCONFIGS ) {
      my $chiptype = $chipconfig->{type};
      my $adapter  = $chipconfig->{adapter};

      my $class = "Device::Chip::$chiptype";

      require ( "$class.pm" ) =~ s(::)(/)gr;

      my $chip = $class->new;

      my %mountopts;
      %mountopts = $chipconfig->{mountopts}->%* if $chipconfig->{mountopts};

      await $chip->mount( $adapter, %mountopts );

      if( $chipconfig->{config} ) {
         await $chip->change_config( $chipconfig->{config}->%* );
      }

      await $chip->protocol->power(1);

      if( $chip->can( "initialize_sensors" ) ) {
         await $chip->initialize_sensors;
      }

      push @$_chips, $chip;
   }

   return @$_chips;
}

=head2 sensors

   @sensors = await $app->sensors;

An asynchronous memoized lazy accessor for the list of L<Device::Chip::Sensor>
instances of each of the configured chips (from the L</chips> method).

=cut

field $_sensors; # arrayref

field $_chipname_width;
field $_sensorname_width;

sub _chipname ( $chip ) { return ( ref $chip ) =~ s/^Device::Chip:://r }

async method sensors
{
   return @$_sensors if $_sensors;

   @$_sensors = map { $_->list_sensors } await $self->chips;

   $_chipname_width   = max map { length _chipname $_ } @$_chips;
   $_sensorname_width = max map { length $_->name } @$_sensors;

   await $self->after_sensors( @$_sensors );

   return @$_sensors;
}

async method after_sensors ( @sensors ) { }

=head2 run

   await $app->run;

An asynchronous method which performs the actual run loop of the sensor
application. This implements the main application logic, of regular collection
of values from all of the sensor instances and reporting them to the
L</output_readings> method.

In normal circumstances the L<Future> instance returned by this method would
remain pending for the lifetime of the program, and not complete. For an
application that has nothing else to perform concurrently it can simply
C<await> this future to run the logic. If it has other logic to perform as
well it could combine this with other futures using a C<< Future->needs_all >>
or similar techniques.

=cut

field %filters_by_sensor;

async method run ()
{
   my @chips = await $self->chips;

   $SIG{INT} = $SIG{TERM} = sub { exit 1; };

   defer {
      try {
         $chips[0] and $chips[0]->protocol->power(0)->get;
      }
      catch ($e) {
         warn "Failed to turn off power while shutting down: $e";
      }
   }

   my @sensors = await $self->sensors;

   my $waittime = Time::HiRes::time();
   while(1) {
      # Read concurrently
      my $now = Time::HiRes::time();

      my @values = await Future->needs_all(
         map {
            my $sensor = $_;
            my $f = $sensor->read;
            $f = $f->then(
               async sub ($reading) {
                  $self->on_sensor_ok( $sensor );
                  return $reading;
               },
               async sub ($failure, @) {
                  $self->on_sensor_fail( $sensor, $failure );
                  return undef;
               },
            ) if $_best_effort;
            $f;
         } @sensors
      );

      foreach my $idx ( 0 .. $#sensors ) {
         my $sensor = $sensors[$idx];

         my $filter = $filters_by_sensor{ refaddr $sensor } //= $self->make_filter_for_sensor( $sensor );

         $values[$idx] = $filter->filter( $values[$idx] );
      }

      $self->output_readings( $now, \@sensors, \@values );

      $waittime += $_interval;
      await Future::IO->alarm( $waittime );
   }
}

method make_filter_for_sensor ( $sensor )
{
   # We only filter gauges currently
   return App::Device::Chip::sensor::Filter::Null->new if $sensor->type ne "gauge";

   if( !length $_filter or $_filter eq "null" ) {
      return App::Device::Chip::sensor::Filter::Null->new;
   }
   elsif( $_filter =~ m/^mid(\d+)$/ ) {
      return App::Device::Chip::sensor::Filter::MidN->new( n => $1 );
   }
   elsif( $_filter =~ m/^ravg(\d+)$/ ) {
      return App::Device::Chip::sensor::Filter::Ravg->new( alpha => 2 ** -$1 );
   }
   else {
      die "Unrecognised filter name $_filter";
   }
}

=head2 print_readings

   $app->print_readings( $sensors, $values );

Prints the sensor names and current readings in a human-readable format to the
currently-selected output handle (usually C<STDOUT>).

=cut

method _format_reading ( $sensor, $value )
{
   return undef if !defined $value;

   # Take account of extra precision required due to filtering
   my $filter = $filters_by_sensor{ refaddr $sensor };
   my $extra_digits = $filter ? $filter->extra_digits : 0;
   return sprintf "%.*f", $sensor->precision + $extra_digits, $value;
}

method print_readings ( $sensors, $values )
{
   foreach my $i ( 0 .. $#$sensors ) {
      my $sensor = $sensors->[$i];
      my $value  = $values->[$i];

      my $chip = $sensor->chip;
      my $chipname = _chipname $chip;

      my $units = $sensor->units;
      $units = " $units" if defined $units;

      my $valuestr;
      if( !defined $value ) {
         $valuestr = "<undef>";
      }
      elsif( $sensor->type eq "gauge" ) {
         $valuestr = sprintf "%s%s", $self->_format_reading( $sensor, $value ), $units // "";
      }
      else {
         $valuestr = sprintf "%s%s/sec", $self->_format_reading( $sensor, $value / $self->interval ), $units // "";
      }

      printf "% *s/% *s: %s\n",
         $_chipname_width, $chipname, $_sensorname_width, $sensor->name, $valuestr;
   }
}

=head1 REQUIRED METHODS

This base class itself is incomplete, requiring the following methods to be
provided by an implementing subclass to contain the actual application logic.

=cut

=head2 output_readings

   $app->output_readings( $now, $sensors, $values );

This method is invoked regularly by the L</run> method, to provide the
application with the latest round of sensor readings. It is passed the current
UNIX epoch timestamp as C<$now>, an array reference containing the individual
L<Device::Chip::Sensor> instances as C<$sensors>, and a congruent array
reference containing the most recent readings taken from them, as plain
numbers.

The application should put the bulk of its processing logic in here, for
example writing the values to some sort of file or database, displaying them
in some form, or whatever else the application is supposed to do.

=cut

=head1 OVERRIDABLE METHODS

The base class provides the following methods, but it is expected that
applications may wish to override them to customise the logic contained in
them.

If using L<Object::Pad> to do so, don't forget to provide the C<:override>
method attribute.

=cut

=head2 OPTSPEC

   %optspec = $app->OPTSPEC;

This method is invoked by the L</parse_argv> method to construct a definition
of the commandline options understood by the program. These are returned in a
key/value list to be processed by L<Getopt::Long>. If the application wishes
to parse additional arguments it should override this method, call the
superclass version, and append any extra argument specifications it requires.

As this is invoked as a regular instance method, a convenient way to store the
parsed values is to pass references to instance slot variables created by the
L<Object::Pad> C<field> keyword:

   field $_title;
   field $_bgcol = "#cccccc";

   method OPTSPEC :override
   {
      return ( $self->SUPER::OPTSPEC,
         'title=s'            => \$_title,
         'background-color=s' => \$_bgcol,
      );
   }

=cut

=head2 after_sensors

   await $app->after_sensors( @sensors );

This method is invoked once on startup by the L</run> method, after it has
configured the chip adapter and chips and obtained their individual sensor
instances. The application may wish to perform one-time startup tasks in here,
such as creating database files with knowledge of the specific sensor data
types, or other such behaviours.

=cut

=head2 on_sensor_ok

   $app->on_sensor_ok( $sensor );

This method is invoked in C<--best-effort> mode after a successful reading
from sensor; typically this is used to clear a failure state.

The default implementation does nothing.

=cut

method on_sensor_ok ( $sensor ) { }

=head2 on_sensor_fail

   $app->on_sensor_fail( $sensor, $failure );

This method is invoked in C<--best-effort> mode after a failure of the given
sensor. The caught exception is passed as C<$failure>.

The default implementation prints this as a warning using the core C<warn()>
function.

=cut

method on_sensor_fail ( $sensor, $failure )
{
   my $sensorname = $sensor->name;
   my $chipname   = ref ( $sensor->chip );

   warn "Unable to read ${sensorname} of ${chipname}: $failure";
}

=head1 FILTERING

The C<--filter> setting accepts the following filter names

=cut

=head2 null

No filtering is applied. Each sensor reading is reported as it stands.

=cut

class App::Device::Chip::sensor::Filter::Null
{
   use constant extra_digits => 0;

   method filter ( $value ) { return $value }
}

=head2 midI<n>

The most recent I<n> values are sorted, and the middle of these is reported.
To be well-behaved, I<n> should be an odd number. (C<mid3>, C<mid5>, C<mid7>,
etc...)

=cut

class App::Device::Chip::sensor::Filter::MidN
{
   use List::Util 1.29 qw( all );

   field $n :param;
   field @readings;

   use constant extra_digits => 0;

   method filter ( $value )
   {
      # Accumulate the past 3 readings
      push @readings, $value;
      shift @readings while @readings > $n;

      # Take the middle of the 3
      return $value unless @readings == $n and all { defined } @readings;

      my @sorted = sort { $a <=> $b } @readings;
      return $sorted[($n-1) / 2];
   }
}

=head2 ravgI<n>

Recursive average with weighting of C<2 ** -n>.

=cut

class App::Device::Chip::sensor::Filter::Ravg
{
   field $alpha :param;
   field $prev;

   use constant extra_digits => 2;

   method filter ( $value )
   {
      return $prev = $value if !defined $prev;
      return $prev = $prev + $alpha * ( $value - $prev );
   }
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
