package Data::TDMA;

use Data::TDMA::Constants qw{ :all };
use Data::TDMA::Day;

use warnings;
use strict;

use Carp qw{ cluck croak carp confess };

# oh, this is completely fucked up
sub new {
	shift; # class
	
	my $d = shift;
	
	# Straight outta perlobj.
	croak "Data::TDMA objects start with a day. Provide one."
		unless (blessed($d)) and $d->isa( 'Data::TDMA::Day');
	
	return bless [ [ $d ] ], __PACKAGE__;

}

# And from there, they can use the $day objects to determine
# whatever they like. But here, we have no "sub-object" introspection.
sub get_days {
	my $self = shift;
	return $self->[0];
}

# We need to be able to take days off the end of the stack because
# we'll be running this in serial (add a day, it's at the front, not
# the back...
sub pop_day {
	my $self = shift;
	return pop @{ $self->[0] };
}

=cut

# XXX: arrr, more dragons here

# this is for out-of-sync which i don't know we want to
# support

# we don't need a "get slot" since it already has itself.
# remember also that they are special, and the time data
# they share about themselves is not what you expect.
sub time_to_epoch {
	my ($self, $day, $time) = (@_);
	
	my $time_increment = $stime;
	my $epoch_num;
	
	ENUM: while (1) {
		my $epoch_high = $time_increment + $SECONDS_PER_EPOCH;
		if ($time > $time_increment and $time < $epoch_high ) {
			$epoch_num = $epoch;
			last ENUM;
		}
		else {
			$time_increment += $epoch_size;
			$epoch++;
		}
	}
	return $day->get_epoch( $epoch_num );
}

=cut


# XXX: we need to reach into the epoch object to pull out a frame
# so we need to iterate the frame_num the ame way we do for
# $SECONDS_PER_FRAME.
sub time_to_frame {
	my ($self, $day, $time) = (@_);

	my $epoch = $self->time_to_epoch( $time );
		
	my $frame_num;
	
	# Let's find our frame.
	$frame_num  = 1; # this is the frame we start at

	# this is the highest point in the frame we're looking at, and frames are
	# made of slots...
	my $frame_high = $epoch->get_frames()->[-1]->get_end();
	
	# this is the lowest point in the frame we're looking at
	my $frame_low  = $epoch->get_frames()->[0]->get_start();
	
	# Increment the highest point we'll evaluate.
	FNUM: while (1) {
		$frame_high += $SECONDS_PER_FRAME;
		if ($frame_low >= $time and $frame_high < $time) {
			# we're in the right slot, return it
			$frame_num = $day->get_frame( $frame_num )->get_serial();
			last FNUM;
		}
		elsif ($frame_low < $frame_high and $frame_low < $time) {
			$frame_low += $SECONDS_PER_FRAME;
			$frame_num++;
		}
		# Sorry, we looked, and didn't find it.
		return undef
			if $frame_high > $time;
	}
	
	return $epoch->get_frame( $frame_num );
}

sub time_to_slot {
	# a day object, and a "time" indicating which slot should be pulled
	my ($self, $day, $time) = (@_);
	my $frame = $day->time_to_frame( $time );

	# Let's find our slot.
	my $slot_num  = 1; # this is the slot we start at

	# this is the highest point in the slot we're looking at
	my $slot_high = $frame->get_epoch() + $SECONDS_PER_SLOT;
	
	# this is the lowest point in the slot we're looking at
	my $slot_low  = $frame->get_epoch();

	SNUM: while (1) {
		# Increment the highest point we'll evaluate.
		$slot_high += $SECONDS_PER_SLOT;
		if ($slot_low >= $time and $slot_high < $time) {
			# we're in the right slot, return it
			$slot_num = $frame->get_slot( $slot_num )->get_serial();
			last SNUM;
		}
		elsif ($slot_low < $slot_high and $slot_low < $time) {
			$slot_low += $SECONDS_PER_SLOT;
			$slot_num++;
		}
		# Sorry, we looked, and didn't find it.
		return undef
			if $slot_high > $time;
	}
	
	
	# We've done all this work here calculating which slot number to
	# ask the frame for, rather than put the math in the Frame module
	# so we just ask the frame for that slot, rather than hand it a 
	# date, and say, find out which slot that is (which would be an
	# intense grep on a large array full of objects...)
	
	# And, returning the slot gets the payloa of that slot, not just
	# the time.
	return $frame->get_slot( $slot_num );
}

1;


=head1 NAME

Data::TDMA

=head1 ABSTRACT

A module to communicate TDMA with perl.

=head1 USAGE

See the sub-modules, 

	L<Data::TDMA::Constants>
	L<Data::TMDA::Day>
	L<Data::TDMA::Day::Epoch>
	L<Data::TDMA::Day::Epoch::Frame>
	L<Data::TDMA::Day::Epoch::Frame::Slot>

It may also be useful to view the various cryptograhic modules
which can be useful with this set of modules, as well as L<Time::HiRes>

=head1 TDMA in a Nutshell

The key to managing data sharing is the Time Division Multiple Access (TDMA)
process, a frequency-hopped, time-sequenced transmission scheme. As many as 
32 subscribers in each net are assigned time slots within a cycle (or "epoch") 
that is 12.8 minutes long. Each epoch is subdivided into 64 frames, each of 
which consists of 1,536 frames of 7.8125 milliseconds each. One of the 
participants maintains the "clock" to ensure fidelity. Up to 128 sub-nets 
can be formed simultaneously. 
	
 JTIDS-Link 16, US Navy Warfighter's Encyclopedia
 (see references)

=head1 TDMA in (a whole lot of) Detail

TDMA is the division of a day into multiple epochs, which are further
subdivided into frames, which are then subdivided again, into slots.

The basic formula is thus:

	1 TDMA Day   = 112.5 Epochs
	1 TDMA Epoch = 64 frames
	1 TDMA Frame = 1536 Slots
	1 TDMA Slot  = 0.0078125 seconds (1/128 second)

	# Thus, walking back up the hierarchy, we see that:
	
	1 TDMA Frame = 12 seconds
	1 TDMA Epoch = 12.8 minutes (768 seconds)
	1 TDMA Day   = 1440 minutes
	
	# It may also be helpful to know that
	
	1 TDMA Epoch = 98,304 slots

The basic unit of communication in the TDMA network is the slot. 
The amount of data that can be communicated in a slot (1/128 second)
of course varies from network to network. If we assume a transmit rate 
in the HF spectrum, we might be transmitting in the range of 9600bps 
(which is pretty typical, but for example's sake, we'll use an easier
number). If instead we transmit at 16,000 bits per second, that boils
down to:
	
	125 bits per slot
	192,000 bits per frame
	294,912,000 bits per epoch
	33,177,600,000 bits per day
	
	# Now, let's do the important math for digital communication
	
	~15 bytes per slot
	2,400 bytes per frame
	36,864,000 bytes per epoch
	4,147,200,000 bytes per day

So while on the surface, it seems that a relatively sedate rate of
communication (16kbit), over relatively mundane technology (HF radio),
it is still possible to transmit a large amount of data to a large
amount of people (since there is no limit to the number of receivers).

TDMA has a number of qualities that make it very useful. First, as long
as everyone in the "loop" has the correct time, everyone knows what data
they should be looking at. They can also correlate this with cryptology
and hop frequencies during transmission (or, tcp ports if you like, for 
a wire-based TDMA), making the protocol very difficult to listen in on,
and also very difficult to jam. 

Additional measures can be taken to make TDMA further robust or more
secure, but they are beyond the scope of this document. You may find
more at L<Data::TDMA::Constants>

TDMA however is generally not applied to on-wire technology, and is
instead broadcast over radio networks. Many assumptions could be made
about its application to on-wire technology, such as encryption and
evasion. Substantially more data can be communicated over e.g., 
gigabit ethernet. At this point, the processor and memory (and network
transit time) become the serious bottlenecks.

=head1 USAGE

Since our TDMA object is going to be full of days, we're going to give
you a way to pull out the day you want. There are a number of ways to
do this.

	# Your TDMA object should be viewed as a I<conversation> rather
	# than a transaction. It is an object that I<contains> transactions.
	# So its instantiation should begin with a fresh "Day" object.
	
	my $now    = time();
	my $today  = Data::TDMA::Day->new( $now, $now + 86400 );
	my $tdma   = Data::TDMA->new( $today );
	
	# From here, you can interrogate your $day objects. Hopefully
	# you don't have too many, because memory will get full. Fast.
	my $days = $tdma->get_days();

	# If you want to know what epoch was at a given time (because
	# knowing the given day is just about useless), you need to
	# feed this sub a $day object and a time.
	my $epoch = $tdma->time_to_epoch( $day, $time + $delta );
	
	# The same is true of course for the slot and frame:
	my $slot  = $tdma->time_to_slot( $day, $time + $delta );
	my $frame = $tdma->time_to_frame( $day, $time + $delta );

	# In essence, you could iterate over a set of days, finding
	# the particular frames or slots you wanted, but that's really
	# up to how you want to run your protocol.

=head1 REFERENCES

 http://en.wikipedia.org/wiki/Time_division_multiple_access
 http://stinet.dtic.mil/oai/oai?&verb=getRecord&metadataPrefix=html&identifier=ADA455715
 http://citeseer.ist.psu.edu/689165.html
 https://wrc.navair-rdte.navy.mil/warfighter_enc/weapons/SensElec/Sensors/link16.htm

=head1 BUGS

It would be very nice if the code understood how to fork as many times
as the user specified so that e.g., Apple's new eight-core machines could
use all eight cores to assemble their widget and then put it on the line.
Of course, that would be complex, and complexity is the arch-enemy of 
stability (or readability, even).

Link16 and its associated friends like JTIDS were compromised during a 
military intelligence leak with China involving an arms sale to Taiwan,
which was managed by Lockheed Martin MS2 in San Diego.

Link16 also suffered a major blow when planners in congress for military
expenditures failed to understand that Link16 was not just an obsolete
way to talk to F-16's and wouldn't work on F-22's. Indeed, Link-16, or
TDMA, as it is more properly known, can and will work on any network in 
which there is reliable transit (such as tcpip) or packetform protocol
that has internal checksums.

It is now being referred to as MIL-STD 6016 and STANAG 5516.

Be not confused. You hold in your hands cool software. And shame on
Lockheed. Really.

=head1 AUTHOR

	Jane A. Avriette
	jane@cpan.org
