package Chandra::Game::Tetris::Blocks;

use Object::Proto::Sugar;

use strict;
use warnings;

use Chandra::Game::Tetris::Blocks::IBlock;
use Chandra::Game::Tetris::Blocks::OBlock;
use Chandra::Game::Tetris::Blocks::TBlock;
use Chandra::Game::Tetris::Blocks::SBlock;
use Chandra::Game::Tetris::Blocks::ZBlock;
use Chandra::Game::Tetris::Blocks::LBlock;
use Chandra::Game::Tetris::Blocks::JBlock;

has random_block => (
	builder => 'build_random_block'
);

has current => (
	isa => Object,
	trigger => 'set_next_block'
);

has next => (
	isa => Object,
	lazy => 1,
	builder => 'build_next_block'
);

sub build_random_block {
	my @pieces = (
		new Chandra::Game::Tetris::Blocks::IBlock,
		new Chandra::Game::Tetris::Blocks::OBlock,
		new Chandra::Game::Tetris::Blocks::TBlock,
		new Chandra::Game::Tetris::Blocks::SBlock,
		new Chandra::Game::Tetris::Blocks::ZBlock,
		new Chandra::Game::Tetris::Blocks::LBlock,
		new Chandra::Game::Tetris::Blocks::JBlock,
	);
	return sub {
		return Object::Proto::clone($pieces[int(rand(scalar @pieces))]);
	};
}

sub build_next_block {
	$_[0]->random_block->();
}

sub set_next_block {
	$_[0]->next($_[0]->random_block->());
}

1;
