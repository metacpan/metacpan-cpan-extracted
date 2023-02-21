package Acme::Hospital::Bed;

use 5.006;
use strict;
use warnings;
our $VERSION = '0.04';

sub new {
	my ($package, %args) = @_;
	$args{total_num_of_rooms} ||= 20;
	$args{lifes} ||= 3;
	$args{rooms} ||= [];
	$args{max_length_of_stay} ||= $args{total_num_of_rooms}*2;
	my $self = bless \%args, $package;
	unless ($self->{names}) {
		$self->{names} = [
			qw/rob robert ben tom dean dennis ruby roxy jane michelle larry liane leanne anne axel/
		];
	}
	unless ($self->{phrases}) {
		$self->{phrases} = [
			[
				"Hello, I am fine.",
				"I still have my mind.",
			],
			[
				"Hello, I am still fine.",
				"I still have my mind."
			],
			[
				"Hello, I am also fine.",
				"I still have my mind."
			],
			[
				"Hello, I think I'm still fine.",
				"I still have my mind."
			],
			[
				"Hello, I think you think I'm fine.",
				"I still have my mind."
			],
			[
				"Hello, am I still fine.",
				"Where is my mind?",
			],
			[
				"Hello, do you still think I'm fine.",
				"Where is my mind?",
			],
			[
				"Hello, I don't feel so fine.",
				"Where is my mind?",
			],
			[
				"Hello, This is not fine.",
				"Where is my mind?",
			],
			[
				"Hello, I'm not fine.",
				"Where is my mind?",
			]
		];
	}
	return $self;
}

sub start { 
	my $self = shift;
	unless (ref $self) {
		$self = __PACKAGE__->new;
	}
	$self->next_patient; 
}

sub available_rooms {
	return $_[0]->{total_num_of_rooms} - scalar @{$_[0]->{rooms}};
}

sub next_patient {
	$_[0]->check_patients_out;
	my $available = $_[0]->available_rooms;
	if ($available == 0) {
		say('You won this time.');
		exit;
	}
	my %patient = $_[0]->_generate_patient();
	my @phrases = @{ $_[0]->{phrases}->[$patient{level}] };
	my $phrase = $phrases[int(rand(@phrases))];
	say(sprintf 'You have %s available rooms', $_[0]->available_rooms);
	say( sprintf('The next patients name is: %s. The patient will stay for: %s days.', $patient{name}, $patient{length}));
	say($phrase);
	my $ans = _wait_answer();
	if ($ans eq 'y') {
		$patient{level} < 6 ? do {
			$_[0]->_lose_a_life();
		} : do {
			push @{$_[0]->{rooms}}, \%patient;
		};
	} elsif ($patient{level} > 5) {
		$_[0]->_lose_a_life();
	}
	$_[0]->next_patient() unless $_[1];
}

sub check_patients_out {
	my $i = 0;
	for (@{$_[0]->{rooms}}) {
		$_->{length}--;
		if ($_->{length} == 0) {
			splice @{$_[0]->{rooms}}, $i, 1; 
			say('Patient checked out: ' . $_->{name});
		}
		$i++;
	}
}

sub _lose_a_life {
	if ($_[0]->{lifes}-- == 0) {
		say('GAME OVER!');
		exit;
	}
	say(sprintf 'You lose a life, %s lifes remaining.', $_[0]->{lifes});
}

sub _wait_answer {
	say('Should they go to hospital? (y/n) ');
	my $answer = <STDIN>;
	chomp $answer;
	if ($answer !~ m/y|n/) {
		return _wait_answer();
	}
	return $answer;
}

sub _generate_patient {
	my @names = @{$_[0]->{names}};
	return (
		name => sprintf('%s %s', map { $names[int(rand(@names))] } 0 .. 1),
		level => int(rand(10)),
		length => int(rand($_[0]->{max_length_of_stay})) || 1
	);
}

sub say {
	print $_[0] . "\n";
}

1;

__END__

=head1 NAME

Acme::Hospital::Bed - The great new Acme::Hospital::Bed!

=head1 VERSION

Version 0.04

=cut

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

	use Acme::Hospital::Bed;

	Acme::Hospital::Bed->start;

	...

	Acme::Hospital::Bed->new(
		total_num_of_beds => 30,
		lifes => 5,
		names => [qw/tom richard joy/],
		phrases => [
			[
				"Hello, I am fine.",
				"I still have my mind after episode 1.",
			],
			[
				"Hello, I am still fine.",
				"I still have my mind after episode 2."
			],
			[
				"Hello, I am also fine.",
				"I still have my mind after episode 3."
			],
			[
				"Hello, I think I'm still fine.",
				"I still have my mind after watching and travelling through the world wide corruption."
			],
			[
				"Hello, I think you think I'm fine.",
				"I still have my mind after visiting my truest disbelievers."
			],
			[
				"Hello, am I still fine.",
				"I will then make my own judgement?",
			],
			[
				"Hello, do you still think I'm fine.",
				"Good luck?",
			],
			[
				"Hello, I don't feel so fine.",
				"Where is my mind?",
			],
			[
				"Hello, This is not fine.",
				"Where is my mind?",
			],
			[
				"Are you being dishonest?",
			]
		]
	)->start;

=head1 DESCRIPTION

Acme::Hospital::Bed is a simple command line Q/A game. 

The basic gameplay is the following:

A patient is generated with a random 'illness' level of 1 to 10 and a phrase that is associated to this level.

The player then decides y(yes) or n(no) to check the patient into a hospital bed.

If they guess correctly then the patient will be allocated a bed for the specified time, else the player will lose a life.

A correct guess is when the player decides yes and the patients level is greater than 5.

An incorrect guess is when the player decides yes and the patients level is lower than 5 or when the player decides no and the patients level is greater than 5.

During each turn, all rooms are deducted 1 nights stay. If a room reaches 0 then the patient is checked out and that room becomes available again.

=head1 METHODS

=head2 new

To instantiate a new Acme::Hospital::Bed object.

	Acme::Hospital::Bed->new(
		total_num_of_beds => 30,
		lifes => 5,
		names => [qw/tom richard harry/],
		phrases => [
			[
				'Level 1 phrase'
			],
			[...],
			[...],
			[...],
			[...],
			[...],
			[...],
			[...],
			[...],
			[
				'Level 10 phrase'
			]
		]	
	)

=head3 total_num_of_beds

Configure the total number of beds needed to win the game. The default is 20.

=head3 lifes

Configure the total number of lifes the player is allowed. The default is 3.

=head3 names

Configure the list of names used to generate patients. This is expected as an ArrayRef. 

=head3 phrases

Configure the list of phrases for each 'health' level. This is expected as an ArrayRefs of ArraysRefs(aoa); 

=head2 start

This method can be used to Start the game. You can either call this directly or after new.

	Acme::Hospital::Bed->start;
	
	Acme::Hospital::Bed->new(%options)->start;

=head2 next_patient

This method can also be used to start the game. If passed a true param it will return after the first itteration else it will loop untill the game is finished.
	
	Acme::Hospital::Bed->new(%options)->next_patient();	
	...
	Acme::Hospital::Bed->new(%options)->next_patient(1);	

=head2 available_rooms

This method will return the number of available rooms left for the current game.

	$ahb->available_rooms;

=head2 check_patients_out

This method will itterate the current rooms arrayref, deducting the length of stay by 1 day and will remove (check out) any patients that have reached 0.

	$ahb->check_patients_out

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-acme-hospital-bed at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Acme-Hospital-Bed>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Acme::Hospital::Bed

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Acme-Hospital-Bed>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Acme-Hospital-Bed>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Acme-Hospital-Bed>

=item * Search CPAN

L<https://metacpan.org/release/Acme-Hospital-Bed>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2020 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of Acme::Hospital::Bed
