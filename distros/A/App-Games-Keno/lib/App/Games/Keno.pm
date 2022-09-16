package App::Games::Keno;
use Moose;
use Types::Standard qw(Int ArrayRef HashRef Bool);
use Carp            qw(croak carp);
use List::Compare   qw (get_intersection);
use List::Util      qw(any uniq);
use Scalar::Util    qw(looks_like_number);

# ABSTRACT: Plays Keno

=head1 NAME 
  
App::Games::Keno
  
=head1 SYNOPSIS
 
This package plays a game of Keno.  The number range is 1 to 80 and the payout amounts are for 1 to 10 spots.
 
Sample code to play 1000 draws with 5 spots.  The spots are chosen for you.

 use App::Games::Keno;

 my $first_game = App::Games::Keno->new( num_spots => 5, draws => 1000 );
 $first_game->PlayKeno;
 say "You won \$"
   . $first_game->winnings . " on "
   . $first_game->draws
   . " draws.";

This is how you choose your own spots.  

 my $second_game = App::Games::Keno->new(
   spots => [ 45, 33, 12, 20, 75 ],
   draws => 1000
 );
 $second_game->PlayKeno;
 say "You won \$"
   . $second_game->winnings . " on "
   . $second_game->draws
   . " draws.";

Several verbosity levels exist, use theme like this:

 my $third_game = App::Games::Keno->new(
   spots => [ 45, 33, 12, 20, 75 ],
   draws => 1000,
   verbose => 1
 );
 
Verbose level 0 is the default and prints nothing.  
Verbose level 1 prints the amount won on winning draws.  
Verbose level 2 prints evrything from verbose level 1 and the 
numbers drawn on each draw and the numbers that matched.

=cut

sub BUILD {
	my $self = shift;

	croak "Didn't get the number of draws you want"
	  if ( !defined $self->draws );
	croak "Spots or Number of spots (not both)"
	  if ( defined $self->spots && defined $self->num_spots );
	croak "Need spots or number of spots"
	  if ( !defined $self->spots && !defined $self->num_spots );

	if ( !defined $self->verbose ) { $self->verbose(0); }
	if ( $self->verbose < 0 || $self->verbose > 2 ) {
		warn "'" . $self->verbose . "' is not a valid verbose level, using '0'";
		$self->verbose(0);
	}

	if ( defined $self->spots ) {
		if ( any { !looks_like_number($_) } @{ $self->spots } ) {
			croak "One of the spots you chose doesn't look like a number.";
		}
		if ( any { $_ < 1 || $_ > 80 } @{ $self->spots } ) {
			croak "You chose a spot that is out of the 1 to 80 range";
		}
		if ( scalar @{ $self->spots } != uniq @{ $self->spots } ) {
			croak "You appear to have chosen two or more of the same spots";
		}
		if ( scalar @{ $self->spots } < 1 ) {
			croak "You must choose at least one spot";
		}
		if ( my $too_many_spots = scalar @{ $self->spots } > 10 ) {
			croak "Too many spots.  You must choose between 1 and 10 spots";
		}
		$self->num_spots( scalar @{ $self->spots } );
	}
	elsif ( $self->num_spots >= 1 && $self->num_spots <= 10 ) {
		$self->spots( get_random_set( $self->num_spots ) );
	}
	else {
		croak "You must ask for between 1 and 10 spots.";
	}

	if ( !defined $self->verbose ) {
		$self->verbose(0);
	}

	return;
}

has 'draws' => (
	is  => 'rw',
	isa => Int,
);

has 'winnings' => (
	is      => 'rw',
	isa     => Int,
	default => 0
);

has 'num_won_draws' => (
	is      => 'rw',
	isa     => Int,
	default => 0
);

has 'num_spots' => (
	is  => 'rw',
	isa => Int,
);

has 'spots' => (
	is  => 'rw',
	isa => ArrayRef,
);

has 'verbose' => (
	is      => 'rw',
	isa     => Int,
	default => 0
);

has 'payout_table' => (
	is      => 'ro',
	isa     => HashRef,
	default => sub {
		return {
			'1' => {
				'1' => 2
			},
			'2' => {
				'2' => 11
			},
			'3' => {
				'2' => 2,
				'3' => 27
			},
			'4' => {
				'2' => 1,
				'3' => 5,
				'4' => 75
			},
			'5' => {
				'3' => 2,
				'4' => 18,
				'5' => 420
			},
			'6' => {
				'3' => 1,
				'4' => 8,
				'5' => 50,
				'6' => 1100,
			},
			'7' => {
				'3' => 1,
				'4' => 3,
				'5' => 17,
				'6' => 100,
				'7' => 4500
			},
			'8' => {
				'4' => 2,
				'5' => 12,
				'6' => 50,
				'7' => 750,
				'8' => 10_000
			},
			'9' => {
				'4' => 1,
				'5' => 6,
				'6' => 25,
				'7' => 150,
				'8' => 3000,
				'9' => 30_000,
			},
			'10' => {
				'0'  => 5,
				'5'  => 2,
				'6'  => 15,
				'7'  => 40,
				'8'  => 450,
				'9'  => 4250,
				'10' => 100_000
			}
		};
	}
);

sub PlayKeno {
	my $self          = shift;
	my $num_won_draws = 0;
	if ( $self->verbose > 0 ) {
		print "You are playing "
		  . $self->draws
		  . " draws with "
		  . scalar @{ $self->spots }
		  . " spots:  "
		  . join( "  ", sort { $a <=> $b } @{ $self->spots } )
		  . "\n\n";
	}
	for ( 1 .. $self->draws ) {
		my $drawnNumbers   = get_random_set(20);
		my $list_compare   = List::Compare->new( $self->spots, $drawnNumbers );
		my @matchedNumbers = $list_compare->get_intersection;
		my $matches        = scalar @matchedNumbers;
		my $this_payout    = $self->get_payout($matches);
		if ( $matches > 6 && $matches == $self->num_spots ) {
			print
"You matched all $matches spots and won \$$this_payout on draw $_\n";
		}
		if ( $this_payout > 0 ) {
			$num_won_draws++;
		}
		my $winningsIn  = $self->winnings;
		my $winningsOut = $winningsIn + $this_payout;
		$self->winnings($winningsOut);

		if ( $self->verbose > 1 ) {
			print "** Draw $_:  ";
			print join( "  ", sort { $a <=> $b } @{$drawnNumbers} );
			if ( $matches > 0 ) {
				print "\nYou matched $matches numbers: ("
				  . join( "  ", sort { $a <=> $b } @matchedNumbers ) . ") ";

			}
			else {
				print "\nYou matched no numbers.";
			}
			if ( $this_payout == 0 ) {
				print " There is no payout for that.  You LOSE!!";
			}
			print "\n";
		}

		if ( $self->verbose > 0 && $this_payout > 0 ) {
			print
"You matched $matches numbers and won \$$this_payout on draw $_\n";
		}
	}
	if ( $self->verbose > 0 ) {
		print "\nYou won "
		  . commify($num_won_draws) . " of "
		  . commify( $self->draws )
		  . " draws.\n";
	}
	return;
}

sub get_random_set {
	my $count = shift;
	my @random_set;
	my %seen;

	for ( 1 .. $count ) {
		my $candidate = 1 + int rand(80);
		redo if $seen{$candidate}++;
		push @random_set, $candidate;
	}

	return \@random_set;
}

sub get_payout {
	my $self  = shift;
	my $match = shift;
	my $spot  = $self->num_spots;

	if ( exists( $self->payout_table->{$spot}{$match} ) ) {
		return $self->payout_table->{$spot}{$match};
	}
	else {
		return 0;
	}
}

sub commify {
	my $text = reverse $_[0];
	$text =~ s/(\d\d\d)(?=\d)(?!\d*\.)/$1,/g;
	return scalar reverse $text;
}

1;

