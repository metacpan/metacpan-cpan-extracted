package DDCCI;

use strict;
use warnings;
use XSLoader;
use Exporter 5.57 'import';
use Carp;

our $VERSION = '0.003';
our %EXPORT_TAGS = ( 'all' => [ qw() ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw(
	&list_vcp_names
	&get_vcp_name
	&get_vcp_addr
	&decode_edid
	&scan_devices
);

XSLoader::load('DDCCI', $VERSION);

sub list_vcp_names {

	my $ret = [];

	for my $i (0x00 .. 0xff) {
		my $n = _get_vcp_name($i);
		push @{$ret}, $n if ($n ne '???');
	}

	return $ret;
}

sub get_vcp_name {

	my ($vcp) = @_;

	return _get_vcp_name($vcp);
}

sub get_vcp_addr {

	my ($name) = @_;

	return _get_vcp_addr($name);
}

sub decode_edid {

	my ($edid) = @_;
	return undef if (!defined $edid || (length($edid) != 128));

	my @b = (
		unpack('@8C', $edid),
		unpack('@9C', $edid),
		unpack('@10S<', $edid),
		unpack('@12L', $edid),
		unpack('@20C', $edid)
	);
	return {
		id => sprintf(
			'%c%c%c%04X', 
    		(($b[0] >> 2) & 0x1f) - 1 + ord('A'),
		    (($b[0] & 0x03) << 3) + ($b[1] >> 5) - 1 + ord('A'),
		    ($b[1] & 0x1f) - 1 + ord('A'),
		    $b[2]
		),
		sn => sprintf('%lu', $b[3]),
		type => ($b[4] & 0x80) ? 'digital' : 'analog',
	};
}

sub scan_devices {

	my $ret = [];

	opendir(my $dh, '/dev') || croak "cannot open /dev";
	my @devs = reverse grep { /^i2c-\d+$/ && (-c '/dev/' . $_) } readdir $dh;
	closedir $dh;

	for my $i (0 .. scalar @devs - 1) {
		my $fn = '/dev/' . $devs[$i];
		(my $fd = _open_dev($fn)) || next;
		my $edid = _read_edid($fd);
		my $de = decode_edid($edid);
		if (defined $de) {
			push @{$ret}, {
				dev => $fn,
				id => $de->{'id'},
				sn => $de->{'sn'},
				type => $de->{'type'}
			};
		}
		_close_dev($fd);
	}

	return $ret;
}

sub new {
	my ($class, $dev) = @_;
    defined($dev) || croak "usage: $class\->new(\$dev)";

	my $self = { fd => _open_dev($dev) };

	if ($self->{'fd'} < 0) {
		croak "unable to open device $dev";
		return undef;
	}

    bless $self, $class;
	return $self;
}

sub DESTROY {
	my ($self) = @_;

	_close_dev($self->{'fd'}) unless ($self->{'fd'} < 0);
}

sub read_edid {
	my ($self) = @_;

	return _read_edid($self->{'fd'});
}

sub read_caps {
	my ($self) = @_;

	return _read_caps($self->{'fd'});
}

sub read_vcp {
	my ($self, $addr) = @_;

	return _read_vcp($self->{'fd'}, $addr);
}

sub write_vcp {
	my ($self, $addr, $value) = @_;

	return _write_vcp($self->{'fd'}, $addr, $value);
}

1;

__END__

=head1 NAME

DDCCI - Perl extension for control monitors via DDC/CI protocol

=head1 SYNOPSIS

	use DDCCI;

	# list the connected monitors
	my $monitors = scan_devices();
	for (@{$monitors}) {
		print "Found monitor at $_->{'dev'}: $_->{'id'} s/n $_->{'sn'}\n";
	}

	# create a new object, using first found monitor
	my $ddcci = DDCCI->new($monitors->[0]->{'dev'});

	# get monitor EDID and decode it
	my $edid = $ddcci->read_edid();
	my $decoded = decode_edid($edid);
	print "id: $decoded->{'id'}, s/n: $decoded->{'sn'}, type: $decoded->{'type'}\n";

	# get monitor capabilities (from the firmware)
	my $caps = $ddcci->read_caps();
	print "Monitor capabilities: $cap\n";

	# get brightness VCP address
	my $brt_addr = get_vcp_addr('brightness');	

	# get brightness
	my $brightness = $ddcci->read_vcp($brt_addr);
	print "Monitor brightness is: $brightness\n";

	# set brightness to 50%
	$ddcci->write_vcp($brt_addr, 50);

=head1 DESCRIPTION

DDC/CI (Display Data Channel Command Interface) standard specifies a means for a computer to send commands to its monitor, or to receive data from the monitor, as settings and sensors;
it works over a bidirectional link realized though the video interface cable. Specific commands to control monitors are defined in a Monitor Control Command Set (MCCS) standard.

This module allow to control the monitor via DDC/CI commands.

It may work on all compatible monitors connected via VGA, DVI and HDMI ports, where the video card, its drivers and the video cable support this function.

On Linux platform, manual or automated loading of the kernel module 'i2c-dev' may be required, depending on the platform and system configuration.

The current release of this module doesn't work under Windows (sorry guys!).

=head1 EXPORT

=head2 list_vcp_names()

Returns a ref to an array containing the list of all available VCP names.

=head2 get_vcp_name($vcp_addr)

Returns the VCP name corresponding to a given VCP register address.
The result is '???' if an unknown address is requested.

=head2 get_vcp_addr($vcp_name)

Returns the VCP register address corresponding to a given VCP register name (case insensitive).
The result is -1 if an unknown name is requested.

=head2 decode_edid($edid)

Returns a ref to an hash containing some details from the given EDID block.
Please give a look to the section L</LIMITATIONS>.
The result is I<undef> on error.

=head2 scan_devices()

Returns a ref to an array containing the list of the detected monitor; 
each array element is a ref to an hash describing B<dev> (device), B<id> (ID), B<sn> (serial number), B<type> (input type: analog/digital). 
The result is I<undef> on error.

=head2 new($dev)

Returns a new object associated to the monitor device provided; 
there are several methods that can be used to intact with the returned object (see L</OBJECT METHODS>).
The result is I<undef> on error.

=head1 OBJECT METHODS

=head2 read_edid()

Returns a binary string of exactly 128 bytes, containing the monitor EDID base block (raw format).
It may be interpreted using the L</decode_edid> function, but please give a look to the section L</LIMITATIONS>.
The result is I<undef> on error.

=head2 read_caps()

Returns the string returned by monitor firmware due to capabilities report request.
The result is I<undef> on error.

=head2 read_vcp(addr)

Returns the value stored in the VCP pointed by the given address.
The result is I<undef> on error.

=head2 write_vcp(addr, value)

Set the value of the VCP pointed by the given address, and returns the value on success.
The result is I<undef> on error.

=head1 LIMITATIONS

=over

=item *
the VCPs addresses for each monitor brand/model may differ from standards, depending also on firmware version and production date. 
Nothing is guaranteed to work in the same way everywhere, so some testing may be required.
Please refer to specific monitor technical manual.

=item *
at the current stage of development the EDID decoding is pretty crude;
a more useful function may be added at application level to replace the function supplied by this module.
Give a look at L</SEE ALSO> section.

=item *
reading the VCPs max valid value is not currently supported; on the other hand the max values defined in monitors firmware are often wrong or obsolete - so who cares?

=item *
some monitors may require an activation sequence to begin accepting DDC/CI commands (i.e. some Samsung monitors).
Please refer to specific monitor technical manual.

=back

=head1 SEE ALSO

=over

=item *
https://en.wikipedia.org/wiki/Display_Data_Channel

=item *
https://en.wikipedia.org/wiki/Extended_Display_Identification_Data

=back

=head1 SUPPORT

To get some help or report bugs you may try to contact the author.
Nevertheless, since this module is really simple, you might also try to correct the bugs for yourself, and then let me know the fixes.

=head1 AUTHOR

R.Scussat - DSP LABS Srl, E<lt>rscussat@dsplabs.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2019 R.Scussat - DSP LABS Srl

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
