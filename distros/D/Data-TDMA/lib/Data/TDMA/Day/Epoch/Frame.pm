package Data::TDMA::Day::Epoch::Frame;

use Data::TDMA::Day::Epoch::Frame::Slot;
use Data::TDMA::Constants qw{ :all };

use warnings;
use strict;

use vars qw{ $augment };

sub new {
	shift;
	my ($zeroh) = (@_);
	my $frame_start = $zeroh;
	my $slots = [ 
		$zeroh,
		[ ],
	];
	
	my $this_frame = $zeroh;
	
	foreach my $slot_num (1 .. $SLOTS_PER_FRAME) {
		my $slot = Data::TDMA::Day::Epoch::Frame::Slot->new(
			$this_frame,
			$slot_num,
			# no payload
		);
		# Put the slot into the frame
		push @{ $slots->[1] }, $slot;
		
		# Increment the time for the next slot
		$this_frame += $SECONDS_PER_SLOT;
	}
	
	return $slots;
}

sub get_time  { my $self = shift; return $self->[0] }
sub get_slots { my $self = shift; return $self->[1] }
sub get_start { my $self = shift; return $self->[1]->[$_[0]]->get_time() }
sub get_end   { my $self = shift; return $self->[1]->[$_[-1]]->get_time() }

1;

=head1 NAME

Data::TDMA::Day::Epoch::Frame

=head1 ABSTRACT

TDMA::Day::Epoch::Frame provides frame component, which epochs are broken into.
Each frame contains 1536 slots, which are the basic data component of a TDMA
communications system.

=head1 USAGE

	# Just provide the time the frame started.
	my $tdma_frame = TDMA::Day::Epoch::Frame->new( $time );
	
=head1 AUTHOR

	Alex J. Avriette
	alex@cpan.org
