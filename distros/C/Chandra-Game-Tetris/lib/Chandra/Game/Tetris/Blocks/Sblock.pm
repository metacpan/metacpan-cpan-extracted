package Chandra::Game::Tetris::Blocks::SBlock;

use strict;
use warnings;
use Object::Proto::Sugar;

with 'Chandra::Game::Tetris::Blocks::Role';

sub _build_name { 'sblock' }

sub _build_id { 4 }

sub _build_cells {
	return [
		[0, 1, 1, 0],
		[1, 1, 0, 0],
		[0, 0, 0, 0],
		[0, 0, 0, 0],
	];
}

1;
