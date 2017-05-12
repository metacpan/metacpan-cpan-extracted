package Biblio::RFID::Reader::Serial;

use warnings;
use strict;

use Device::SerialPort qw(:STAT);
use Data::Dump qw(dump);

=head1 NAME

Biblio::RFID::Reader::Serial - base class for serial RFID readers

=head1 METHODS

=head2 new

Open serial port (if needed) and init reader

=cut

sub new {
	my $class = shift;
	my $self = {@_};
	bless $self, $class;

	$self->port && return $self;
}


=head2 port

Tries to open usb serial ports C</dev/ttyUSB*>

  my $serial_obj = $self->port;

To try just one device use C<RFID_DEVICE=/dev/ttyUSB1> enviroment variable

=cut

our $serial_device;

sub port {
	my $self = shift;

	return $self->{port} if defined $self->{port};

	my $settings = $self->serial_settings;
	my @devices  = $ENV{RFID_DEVICE} ? ( $ENV{RFID_DEVICE} ) : glob '/dev/ttyUSB*';
	warn "# port devices ",dump(@devices);

	foreach my $device ( @devices ) {

		next if $serial_device->{$device};

		if ( my $port = Device::SerialPort->new($device) ) {

			foreach my $opt ( qw/handshake baudrate databits parity stopbits/ ) {
				$port->$opt( $settings->{$opt} );
			}

			$self->{port} = $port;

			warn "# probe by init $device ",ref($self);
			if ( $self->init ) {
				warn "init OK ", ref($self), " $device settings ",dump $settings;
				$serial_device->{$device} = $port;
				last;
			} else {
				$self->{port} = 0;
			}
		}
	}

	warn "# serial_device ",dump($serial_device);

	return $self->{port};
}

1
__END__

=head1 SEE ALSO

L<Biblio::RFID::Reader::3M810>

L<Biblio::RFID::Reader::CPRM01>

L<Biblio::RFID::Reader::API>

