package Chandra::Game::Tetris::Blocks::IBlock;

use strict;
use warnings;
use Object::Proto::Sugar;

with 'Chandra::Game::Tetris::Blocks::Role';

sub _build_name { 'iblock' }

sub _build_id { 1 }

sub _build_cells {
	return [
		[0, 0, 0, 0],
		[1, 1, 1, 1],
		[0, 0, 0, 0],
		[0, 0, 0, 0],
	];
}

1;
