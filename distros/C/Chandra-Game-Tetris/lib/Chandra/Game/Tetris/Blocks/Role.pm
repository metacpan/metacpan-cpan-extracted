package Chandra::Game::Tetris::Blocks::Role;

use strict;
use warnings;
use Object::Proto::Sugar -role;
use Chandra::Element;

has name => (
	is => 'ro',
	isa => Str,
	builder => 1,
);

has id => (
	is => 'ro',
	isa => Int,
	builder => 1,
);

has cells => (
	is => 'rw',
	isa => ArrayRef,
	builder => 1
);

has [qw/row col/] => (
	is => 'rw',
	isa => Int
);

sub render {
	my ($self) = @_;

	my $table = Chandra::Element->new({
		tag => 'table',
		class => 'tetris-block tetris-block-' . $self->name,
	});

	my $cells = $self->cells;

	for my $row (@{$cells}) {
		my $tr = $table->add_child({ tag => 'tr', class => 'tetris-block-row' });
		for my $cell (@{$row}) {
			my $class = $cell
				? 'tetris-cell filled block-' . $self->id
				: 'tetris-cell empty';
			$tr->add_child({
				tag => 'td',
				class => $class,
				children => [{ tag => 'div' }],
			});
		}
	}

	return $table;
}

1;
