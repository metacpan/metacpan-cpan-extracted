package Chandra::Game::Tetris::Blocks::ZBlock;

use strict;
use warnings;
use Object::Proto::Sugar;

with 'Chandra::Game::Tetris::Blocks::Role';

sub _build_name { 'zblock' }

sub _build_id { 5 }

sub _build_cells {
	return [
		[1, 1, 0, 0],
		[0, 1, 1, 0],
		[0, 0, 0, 0],
		[0, 0, 0, 0],
	];
}

1;
