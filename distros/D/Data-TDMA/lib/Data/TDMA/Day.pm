package Data::TDMA::Day;

use warnings;
use strict;

use Data::TDMA;
use Data::TDMA::Day::Epoch;
use Data::TDMA::Constants qw{ :all };

use Time::HiRes qw{ time };

use Carp qw{ carp cluck confess };

# Mess with this at your peril... or advantage.
use constant SECONDS_PER_DAY => 86400;

sub new {
=cut

We're cleaning up input here

=cut

	shift; 
	my ($zeroh, $omegah); # we'll need these later.

	confess "You will need to pass a hash to the constructor."
		if ref $_[0] ne 'HASH';

	confess "One at a time, bro"
		if $_[1];

	# Surely we have named args per the docs? All of this
	# gymnastics is so that we can accept {} or named
	# params without throwing a -w warning.
	if (
		grep { 'zeroh'  } @$_[0] and 
		grep { 'omegah' } @$_[0]
	) {
		my $args = $_[0];
		($zeroh, $omegah) = @$args{ qw{ zeroh omegah } };
		# zero hour, "omega" or "final" second - thank tipler.
	}

=cut

This section here is where the "day" object are assembled

=cut

	if ($zeroh and $omegah) {
		Data::TDMA::Constants->_init();
		my $enum   = Data::TDMA::Day::Epoch::delta_to_epochs( $zeroh, $omegah );
	  return _day_build( $zeroh, $omegah, $enum );
	}
	else { # we just got {} or nonsense
		Data::TDMA::Constants->_init();
		my $estart = time();
		my $efins  = $estart + $Data::TDMA::Constants::SECONDS_PER_DAY;
		my $enum   = Data::TDMA::Day::Epoch::delta_to_epochs( $estart, $efins );
	  return _day_build( $estart, $efins, $enum );
	}

	cluck "OOPS, logic failed at the Day Hatchery!";
}

sub _day_build {
	# Now Mammy's already been here afore and seen the hurt in
	# the unwanted days so they all got important names like
	# "zeroh" and "omegah".

	my ($zeroh, $omegah, $enum) = @_;

	my @epochs;

	# think a little
	for (my $e = 1; $e < $enum; push @epochs, Data::TDMA::Day::Epoch->new( $zeroh, $e++ ) ) { }

	my $day = bless [ 
		$zeroh,      # And we should be able to ask $day the beginning of
		$omegah,     # the first epoch and the end of the last epoch
		[ @epochs ], # but we provide them for convenience
	], __PACKAGE__;

	# And here we give it back to the user.
	return $day;
}

sub get_start        { return shift->[0] } # so you can "hack" the clock
sub get_finish       { return shift->[1] }
sub get_epochs       { return shift->[2] }

# $n is the epoch number you're looking for
sub get_epoch        { my ($s, $n) = (@_); return $s->[2]->[$n] }

# we can't get time arbitrarily without knowing which epoch, right? so we
# first have to use a method to figure out which epoch we want, and then
# which slice from there, and so on. So this method seems obvious, but
# is more sinister.
sub get_time {
	carp "Data::TDMA::Epoch::get_time() is more appropriate here.";
	undef;
}

1;

=head1 NAME

Data::TDMA::Day

=head1 ABSTRACT

Data::TDMA::Day provides the basis for the TDMA communications protocol. Each day
in a TDMA link is composed of 112.5 I<epochs>.

=head1 USAGE

	my $tdma_day = Data::TDMA::Day->new(); # no arguments

Your new day will actually have 113 I<epochs> in it, as opposed to giving you 
112.5, which is more "correct," but far less practical. At the intersection 
of one day and the next, you're going to have to figure out how to make that
switch.

It is advised that you create a Day, and begin filling it with data that can
then be pushed on the wire. If you know what time it is, your day object can
tell you which epoch you're in, that epoch can tell you which frame it's 
supposed to be sending, and that frame is going to know which slot you should
be reading (or stuffing on the wire). But normally, we'd just send entire
frames.

When your epochs have data that ought to be sent out, you can pack them
however you like by defining a I<serialize> function in TDMA::Constants.

This might look something like this:

	my $i = 0; # just an iterator
	my $epoch = $tdma_day->get_epoch( $epoch_number); 

	foreach my $frame ($epoch->get_frames()) {
		# Note that some TDMA implementations, like Link 16, have a limited
		# amount of bandwidth available.
		$_->set_payload("$i++") for @{ $frame->get_slots() }
	}

	$sock->send( $epoch->serialize() );


=head1 AUTHOR

	Jane A. Avriette
	jane@cpan.org
