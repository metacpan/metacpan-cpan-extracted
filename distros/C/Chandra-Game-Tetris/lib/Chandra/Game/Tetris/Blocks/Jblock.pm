package Chandra::Game::Tetris::Blocks::JBlock;

use strict;
use warnings;
use Object::Proto::Sugar;

with 'Chandra::Game::Tetris::Blocks::Role';

sub _build_name { 'jblock' }

sub _build_id { 7 }

sub _build_cells {
	return [
		[0, 0, 1, 0],
		[0, 0, 1, 0],
		[0, 1, 1, 0],
		[0, 0, 0, 0],
	];
}

1;
