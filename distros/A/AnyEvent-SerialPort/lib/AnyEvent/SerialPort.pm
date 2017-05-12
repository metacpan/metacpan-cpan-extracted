use strict;
use warnings;
package AnyEvent::SerialPort;
{
  $AnyEvent::SerialPort::VERSION = '1.130171';
}

use base 'AnyEvent::Handle';

use constant {
  DEBUG => $ENV{ANYEVENT_SERIALPORT_DEBUG},
};

use Carp qw/croak carp/;
use Device::SerialPort qw/:PARAM :STAT 0.07/;
use Fcntl;
use Symbol qw(gensym);

# ABSTRACT: AnyEvent::Handle subclass for serial ports


sub new {
  my $pkg = shift;
  my %p = @_;
  croak "Parameter serial_port is required" unless (exists $p{serial_port});

  # allow just a device name - to use defaults or array reference with
  # device and settings
  my $dev = delete $p{serial_port};
  my @settings;
  if (ref $dev) {
    @settings = @$dev;
    $dev = shift @settings;
  }

  my $fh = gensym();
  my $s = tie *$fh, 'Device::SerialPort', $dev or
    croak "Could not tie serial port, $dev, to file handle: $!";

  foreach my $setting ([ baudrate => 9600 ],
                       [ databits => 8 ],
                       [ parity => 'none' ],
                       [ stopbits => 1 ],
                       [ datatype => 'raw' ],
                       @settings
                      ) {
    my ($setter, @v) = @$setting;
    $s->$setter(@v);
  }
  $s->write_settings();
  sysopen($fh, $dev, O_RDWR|O_NOCTTY|O_NDELAY) or
    croak "sysopen of '$dev' failed: $!";
  $fh->autoflush(1);
  my $self = $pkg->SUPER::new(fh => $fh, %p);
  $self->{serial_port} = $s;
  $self;
}


sub serial_port {
  shift->{serial_port}
}

1;

__END__
=pod

=head1 NAME

AnyEvent::SerialPort - AnyEvent::Handle subclass for serial ports

=head1 VERSION

version 1.130171

=head1 SYNOPSIS

  use AnyEvent;
  use AnyEvent::SerialPort;

  my $cv = AnyEvent->condvar;

  my $hdl;
  $hdl = AnyEvent::SerialPort->new(
           serial_port => '/dev/ttyUSB0',
           # other AnyEvent::Handle arguments here
         );

  # or to use something other than 9600 8n1 raw
  $hdl = AnyEvent::SerialPort->new
          (
           serial_port =>
             [ '/dev/ttyUSB0',
               [ baudrate => 4800 ],
               # other [ "Device::SerialPort setter name" => \@arguments ] here
             ],
           # other AnyEvent::Handle arguments here
         );

  # obtain the Device::SerialPort object
  my $port = $hdl->serial_port;

=head1 DESCRIPTION

This module is a subclass of AnyEvent::Handle for serial ports.

B<IMPORTANT:> This is a new API and is still subject to change.  Feedback
and suggestions would be very welcome.

=head1 METHODS

=head2 new(%parameters)

Constructs an AnyEvent::SerialPort object based on the given
parameters.  The permitted parameters are those of the
AnyEvent::Handle super class constructor (except C<connect> and
C<fh> which would not make sense) and a C<serial_port> parameter.
The value of the serial port parameter may be either:

=over

=item * the full path name of the serial device, or

=item * a list reference containing the full path name of the serial
device and zero or more list references each containing a
Device::SerialPort method name and arguments to be executed on the
wrapped Device::SerialPort object.

=back

By default, the following setter methods are called on the underlying
Device::SerialPort object:

=over

=item baudrate(9600),

=item databits(8),

=item parity('none'),

=item stopbits(1), and

=item datatype('raw')

=back

The second form of the C<serial_port> parameter value described above
can be used to override these settings and apply additional setters.

See the L</"SYNOPSIS"> for examples.

=head2 serial_port()

Return the wrapped Device::SerialPort object.

=head1 AUTHOR

Mark Hindess <soft-cpan@temporalanomaly.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Mark Hindess.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

