package Biblio::RFID::Reader::INET;
use warnings;
use strict;
use base 'IO::Socket::INET';

use IO::Socket::INET;
use Time::HiRes qw(ualarm);
use Data::Dump qw(dump);

my $debug = $ENV{DEBUG};

=head1 NAME

Biblio::RFID::Reader::INET - emulate serial port over TCP socket

=cut

sub write {
	my $self = shift;
	$self->_check_connected;
	warn ">> write ",dump(@_) if $debug;
	my $count = $self->SUPER::print(@_);
	$self->flush;
#warn "XX ",ref($self), " write response: $count ", dump(@_);
	return $count;
}

our $read_char_time = 1;
sub read_char_time { $read_char_time = $_[1] * 1_000 || 1_000_000 };
sub read_const_time {};

sub read(*\$$;$) {
	my $self = shift;
	my $len = shift || die "no length?";

#warn "XX ",ref($self), " read $len timeout $read_char_time";
	my $buffer;
	eval {
		local $SIG{ALRM} = sub { die "read timeout" };

		#warn "## read_serial $len timeout $read_char_time\n";

		ualarm $read_char_time;
		$len = $self->SUPER::read( $buffer, $len );
		ualarm 0;
	};
	if ( $@ ) {
		warn "ERROR: $@";
		$len = 0;
	}

	$self->_check_connected;

	warn "<< read $len ",dump($buffer) if $debug;
	return ( $len, $buffer );
}

sub _check_connected {
	my $self = shift;
	return if $self->connected;

	warn "LOST TCP Connection";
	exit 1;
}

1;
__END__

=head1 SEE ALSO

L<Biblio::RFID::Reader::Serial>

