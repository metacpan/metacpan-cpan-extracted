package Acme::Hospital::Bed;

use 5.006;
use strict;
use warnings;
use feature qw/say/;
our $VERSION = '0.01';

sub new {
	my ($package, %args) = @_;
	$args{total_num_of_rooms} ||= 20;
	$args{lifes} ||= 3;
	$args{rooms} ||= {};
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
	return $self->next_patient;
}

sub available_rooms {
	return $_[0]->{total_num_of_rooms} - keys %{$_[0]->{rooms}};
}

sub generate_random_name {
	my @names = @{$_[0]->{names}};
	return sprintf '%s %s', map { $names[int(rand($#names))] } 0 .. 1;
}

sub next_patient {
	my $patient = int(rand(10));
	my $name = $_[0]->generate_random_name;
	my @phrases = @{ $_[0]->{phrases}->[$patient] };
	my $phrase = $phrases[int(rand($#phrases))];
	say sprintf 'You have %s available rooms', $_[0]->available_rooms;
	say 'The next patients name is: ' . $name;
	say $phrase;
	my $ans = wait_answer();
	if ($ans eq 'y') {
		$patient < 6 ? do {
			$_[0]->lose_a_life();
		} : do {
			$_[0]->{rooms}->{keys %{$_[0]->{rooms}}} = $name;
		};
	} elsif ($patient > 5) {
		$_[0]->lose_a_life();
	}
	$_[0]->next_patient();
}

sub lose_a_life {
	if ($_[0]->{lifes}-- == 0) {
		say 'GAME OVER!';
		exit;
	}
	say sprintf 'You lose a life, %s lifes remaining.', $_[0]->{lifes};
}

sub wait_answer {
	say 'Should they go to hospital? (y/n) ';
	my $answer = <STDIN>;
	chomp $answer;
	if ($answer !~ m/y|n/) {
		return wait_answer();
	}
	return $answer;
}

1;

__END__

=head1 NAME

Acme::Hospital::Bed - The great new Acme::Hospital::Bed!

=head1 VERSION

Version 0.01

=cut

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

	use Acme::Hospital::Bed;

	Acme::Hospital::Bed->new();

	...

	Acme::Hospital::Bed->new(
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
	);

=head1 AUTHOR

LNATION, C<< <thisusedtobeanemail at gmail.com> >>

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
