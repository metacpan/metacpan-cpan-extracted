package Data::TDMA::Day::Epoch::Frame::Slot;

# this whole business may not be necessary.
use vars qw{ $augment };

use warnings;
use strict;

sub new {
	shift; # package
	my ($zeroh, $slot_number, $payload) = (@_);
	
	# a payload; normally I'd use sub { ... }, but this is faster for
	# generic TDMA object creation
	$payload = '' unless defined $payload;
	
	my $stuff = [ 
		$zeroh,
		$slot_number,
		$payload,
	];
	
	bless $stuff, __PACKAGE__;
}

sub get_time    { my $self = shift; return $self->[0] }
sub get_serial  { my $self = shift; return $self->[1] }
sub get_payload { my $self = shift; return $self->[2] }

1;

=head1 NAME

Data::TDMA::Day::Epoch::Frame::Slot

=head1 ABSTRACT

The TDMA slot is the most basic component of the network. It is roughly
7 miliseconds long.

=head1 USAGE

	my $tdma_slot = Data::TDMA::Day::Epoch::Frame::Slot->new(); # no arguments

=head3 A pinch of reality

The amount of data you can fit into it depends upon your line speed, and how
fast you can feed your data into your data structures. There's no reason you
couldn't transmit a two gigabyte tiff in every slot, but you would need both
the processor power necessary to serialize that object, as well as the line 
speed will have to be in excess of three terabytes a second.

In practice, the size of a slot is governed by the protocol, and is often
on the order of a hundred or a few hundred bits. Room is left for checksum
information, generally. There are also two additional pieces, which are
valuable to cryptographers: jitter and propagation. Jitter is "dead time"
used at the beginning of a slot, and propagation is more "dead time" used
at the end of a slot. So if we have a hundred bits of bandwidth per slot,
we may choose to vary our jitter and propagation values so that somebody
listening is unable to tell when the messages begin and end.

Because this is constant for the protocol, this data is set in the Constants
package.

Your object is a blessed array ref, but with the Constants package, you can
add to it just about anything perl can create.


=head1 AUTHOR

	Jane A. Avriette
	jane@cpan.org
