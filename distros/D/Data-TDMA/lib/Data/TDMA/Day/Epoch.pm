package Data::TDMA::Day::Epoch;

use Data::TDMA::Day::Epoch::Frame;
use Data::TDMA::Constants qw{ :all };

use POSIX qw{ floor };

use warnings;
use strict;

use Carp qw{ confess cluck carp };

sub new {
	my ($class, $zeroh, $epoch_num) = (@_);
	Data::TDMA::Constants->_init();
	confess unless $zeroh and $EPOCHS_PER_DAY and $epoch_num;
	my $epoch_start = ( $zeroh / $EPOCHS_PER_DAY ) * $epoch_num;
	
	my $frames = bless [
		$zeroh,
		$epoch_start,
		
		# this is the real object here...
		[ 
			map Data::TDMA::Day::Epoch::Frame->new( 
				$zeroh, $epoch_start, $epoch_num, $_ 
			), 
			1 .. $FRAMES_PER_EPOCH 
		],
		
		sub { 1 },
		
	], $class;
	return $frames;
}

# gettrs
sub get_time   { my $self = shift; return $self->[1] }
sub get_frames { my $self = shift; return $self->[2] }

# some simple math
sub delta_to_epochs {
	my ($at, $ot) = (@_); # alpha, omega times
	my $delta = $ot - $at;

	carp "d: $delta o: $ot a: $at \n"
		if $TDMA_DEBUG;
	
	$delta = floor $delta;	
	
	my $num_epochs = $delta / $SECONDS_PER_EPOCH;
	
	$num_epochs = floor $num_epochs;
	
	# And this is how many epochs are in a given $delta of seconds
	# minus the spare change from Time::HiRes
	return $num_epochs;
}	

1;

=head1 NAME

Data::TDMA::Day::Epoch

=head1 ABSTRACT

Data::TDMA::Day::Epoch provides the individual slices each TDMA epoch is separated
into: 64 individual I<frames>.

=head1 USAGE

	my $tdma_epoch = Data::TDMA::Day::Epoch->new(); # no arguments
	
=head1 AUTHOR

	Jane A. Avriette
	jane@cpan.org
