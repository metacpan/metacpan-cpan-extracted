package Chandra::Game::Tetris::Grid;

use strict;
use warnings;

use Object::Proto::Sugar;
use Chandra;

has width => (
	isa => Int,
	default => 10
);

has height => (
	isa => Int,
	default => 18
);

has grid => (
	isa => ArrayRef
);

sub BUILD {
	my ($self) = @_;
	$self->_init_grid;
}

sub is_valid {
	my ($self, $cells, $row, $col) = @_;
	my $grid   = $self->grid;
	my $height = $self->height;
	my $width  = $self->width;
	for my $r (0 .. $#$cells) {
		for my $c (0 .. $#{$cells->[$r]}) {
			next unless $cells->[$r][$c];
			my $gr = $row + $r;
			my $gc = $col + $c;
			return 0 if $gr >= $height;
			return 0 if $gc < 0 || $gc >= $width;
			next if $gr < 0;   
			return 0 if $grid->[$gr][$gc];
		}
	}
	return 1;
}

sub lock_block {
	my ($self, $cells, $row, $col, $color_id) = @_;
	my $grid   = $self->grid;
	my $height = $self->height;
	my $width  = $self->width;
	for my $r (0 .. $#$cells) {
		for my $c (0 .. $#{$cells->[$r]}) {
			next unless $cells->[$r][$c];
			my $gr = $row + $r;
			my $gc = $col + $c;
			next if $gr < 0 || $gr >= $height;
			next if $gc < 0 || $gc >= $width;
			$grid->[$gr][$gc] = $color_id;
		}
	}
}

sub clear_lines {
	my ($self) = @_;
	my $grid  = $self->grid;
	my $width = $self->width;
	my @kept;
	my $cleared = 0;
	for my $row (@$grid) {
		if ((grep { $_ } @$row) == $width) {
			$cleared++;
		} else {
			push @kept, $row;
		}
	}
	for (1 .. $cleared) {
		unshift @kept, [(0) x $width];
	}
	$self->grid(\@kept);
	return $cleared;
}

sub reset {
	my ($self) = @_;
	$self->_init_grid;
}

sub _init_grid {
	my ($self) = @_;
	my $width  = $self->width;
	my $height = $self->height;
	my @grid;
	for (1 .. $height) {
		push @grid, [(0) x $width];
	}
	$self->grid(\@grid);
}

1;
