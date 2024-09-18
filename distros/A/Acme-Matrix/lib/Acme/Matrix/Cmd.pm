package Acme::Matrix::Cmd;

use Rope::Cmd;
use Coerce::Types::Standard qw/Int Bool JSON/;
use Acme::Matrix;
use Ascii::Text;

colors (
	title => 'bright_green',
	abstract => 'green',
	options_title => 'bright_green',
	options => 'bright_green',
	options_description => 'green'
);

title(Ascii::Text->new(font => 'Boomer', align => 'center')->stringify('MATRIX', 1));

abstract('script for generating heavenly digital rain');

option delay => (
	type => Int,
	description => 'delay to render a line in ms',
	option_alias => 'd',
	value => 10
);

option spacing => (
	type => Int,
	description => 'spacing between characters',
	option_alias => 's',
	value => 2
);

option words => (
	type => JSON->by('decode'),
	coerce_type => 1,
	description => 'words to use in the matrix rain',
	option_alias => 'w'
);

option chars => (
	type => JSON->by('decode'),
	coerce_type => 1,
	description => 'chars to use in the matrix rain',
	option_alias => 'c'
);

sub callback {
	my ($self) = @_;

	my @words;
	if ($self->words){ 
		if ( ! ref $self->words->[0]) {
			for (@{$self->words}) {
				push @words, [split //, $_];
			}
		} else {
			push @words, @{$self->words};
		}
	}

	Acme::Matrix->start(
		delay => $self->delay,
		spacing => $self->spacing,
		(scalar @words ? (words => \@words) : ()),
		($self->chars ? (chars => $self->chars) : ())
	);
}

1;

