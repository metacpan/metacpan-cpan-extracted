package Biblio::RFID::Reader::Serial;

use warnings;
use strict;

use Device::SerialPort qw(:STAT);
use Biblio::RFID::Reader::INET;
use Data::Dump qw(dump);

=head1 NAME

Biblio::RFID::Reader::Serial - base class for serial or serial over TCP RFID readers

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

Tries to open usb serial ports C</dev/ttyUSB*> and serial ports C</dev/ttyS*>

  my $serial_obj = $self->port;

To try just one device use C<RFID_DEVICE=/dev/ttyUSB1> environment variable

If you want to define serial connection over TCP socket, you have to export
enviroment variable C<RFID_TCP=hostname:port>.

=cut

our $serial_device;

sub port {
	my $self = shift;

	warn "## port ",dump( $self->{port} );

	return $self->{port} if defined $self->{port};

	if ( my $tcp = $ENV{RFID_TCP} ) {
		my $port = Biblio::RFID::Reader::INET->new(
			PeerAddr => $tcp,
			Proto    => 'tcp'
		);
		warn "## TCP $tcp ", ref($port);
		$self->{port} = $port;
		$self->init;
		return $port;
	}

	if ( my $listen = $ENV{RFID_LISTEN} ) {
		my $server = Biblio::RFID::Reader::INET->new(
			Proto     => 'tcp',
			LocalAddr => $listen,
			Listen    => SOMAXCONN,
			Reuse     => 1
		);
									  
		die "can't setup server $listen: $!" unless $server;

		warn "RFID: waiting for reader connection to $listen";

		my $port = $server->accept();
		$port->autoflush(1);

		warn "## LISTEN $listen ", ref($port);
		$self->{port} = $port;
		$self->init;

		return $port;

	}

	my $settings = $self->serial_settings;
	my @devices  = $ENV{RFID_DEVICE} ? ( $ENV{RFID_DEVICE} ) : glob '/dev/ttyUSB* /dev/ttyS*';
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

