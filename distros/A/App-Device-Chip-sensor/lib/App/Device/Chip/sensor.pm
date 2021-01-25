#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2020 -- leonerd@leonerd.org.uk

use v5.26;
use Object::Pad 0.19;

package App::Device::Chip::sensor 0.01;
class App::Device::Chip::sensor;

use Future::AsyncAwait;

use Device::Chip::Adapter;
use Future::IO 0.08; # ->alarm
use Getopt::Long qw( GetOptionsFromArray );

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

=cut

has $_ADAPTERDESC;
has @_CHIPTYPES;
has $_interval :reader = 10;

method OPTSPEC
{
   return (
      'b|blib' => sub { require blib; blib->import; },

      'i|interval=i' => \$_interval,
      'adapter|A=s'  => \$_ADAPTERDESC,
   );
}

=head1 PROVIDED METHODS

The following methods are provided on the base class, intended for subclasses
or applications to invoke.

=cut

=head2 parse_argv

   $app->parse_argv()
   $app->parse_argv( \@argv )

Provides a list of commandline arguments for parsing, either from a given
array reference or defaulting to the process C<@ARGV> if not supplied.

This uses L</OPTSPEC> to collect the defined arguments, whose references
should handle the results.

=cut

method parse_argv ( $argv = \@ARGV )
{
   my %optspec = $self->OPTSPEC;

   GetOptionsFromArray( $argv, %optspec ) or exit 1;

   while( @$argv ) {
      my $chiptype = shift @$argv;
      # TODO: parse chip constructor args/mount options
      push @_CHIPTYPES, $chiptype;
   }

   return $self;
}

=head2 adapter

   $adapter = $app->adapter;

A memoized lazy accessor for the application's configured
L<Device::Chip::Adapter> instance, taken from the C<--adapter> option.

=cut

has $_adapter;
method adapter
{
   return $_adapter //= Device::Chip::Adapter->new_from_description( $_ADAPTERDESC );
}

=head2 chips

   @chips = await $app->chips;

An asynchronous memoized lazy accessor for the list of L<Device::Chip>
instances, whose class names are taken from the remaining commandline
arguments after the options are parsed.

=cut

has $_chips; # arrayref
async method chips
{
   return @$_chips if $_chips;

   my $adapter = $self->adapter;

   foreach my $chiptype ( @_CHIPTYPES ) {
      my $class = "Device::Chip::$chiptype";

      require ( "$class.pm" ) =~ s(::)(/)gr;

      my $chip = $class->new;
      await $chip->mount( $adapter );

      await $chip->protocol->power(1);

      if( $chip->can( "initialize_sensors" ) ) {
         await $chip->initialize_sensors;
      }

      push @$_chips, $chip;
   }

   return @$_chips;
}

=head2 chips

   @sensors = await $app->sensors;

An asynchronous memoized lazy accessor for the list of L<Device::Chip::Sensor>
instances of each of the configured chips (from the L</chips> method).

=cut

has $_sensors; # arrayref
async method sensors
{
   return @$_sensors if $_sensors;

   @$_sensors = map { $_->list_sensors } await $self->chips;

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

async method run ()
{
   my @chips = await $self->chips;

   $SIG{INT} = $SIG{TERM} = sub { exit 1; };

   END {
      $chips[0] and $chips[0]->protocol->power(0)->get;
   }

   my @sensors = await $self->sensors;

   my $waittime = Time::HiRes::time();
   while(1) {
      # Read concurrently
      my $now = Time::HiRes::time();

      my @values = await Future->needs_all(
         map { $_->read } @sensors
      );

      $self->output_readings( $now, \@sensors, \@values );

      $waittime += $_interval;
      await Future::IO->alarm( $waittime );
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
L<Object::Pad> C<has> keyword:

   has $_title;
   has $_bgcol = "#cccccc";

   method OPTSPEC :override
   {
      return ( $self->SUPER::OPTSPEC,
         'title=s'            => \$_title,
         'background-color=s' => \$_bgcol,
      );
   }

=cut

=head2 after_sensors

   await $app->after_sensors( @sensors )

This method is invoked once on startup by the L</run> method, after it has
configured the chip adapter and chips and obtained their individual sensor
instances. The application may wish to perform one-time startup tasks in here,
such as creating database files with knowledge of the specific sensor data
types, or other such behaviours.

=cut

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
