package Chandra::Game::Tetris::Blocks::OBlock;

use strict;
use warnings;
use Object::Proto::Sugar;

with 'Chandra::Game::Tetris::Blocks::Role';

sub _build_name { 'oblock' }

sub _build_id { 2 }

sub _build_cells {
	return [
		[0, 0, 0, 0],
		[0, 1, 1, 0],
		[0, 1, 1, 0],
		[0, 0, 0, 0],
	];
}

1;
