package Chandra::Game::Tetris::Blocks::LBlock;

use strict;
use warnings;
use Object::Proto::Sugar;

with 'Chandra::Game::Tetris::Blocks::Role';

sub _build_name { 'lblock' }

sub _build_id { 6 }

sub _build_cells {
	return [
		[0, 1, 0, 0],
		[0, 1, 0, 0],
		[0, 1, 1, 0],
		[0, 0, 0, 0],
	];
}

1;
