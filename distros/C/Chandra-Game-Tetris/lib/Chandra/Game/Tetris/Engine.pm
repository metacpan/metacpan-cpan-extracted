package Chandra::Game::Tetris::Engine;

use strict;
use warnings;

use Object::Proto::Sugar;
use Chandra::Game::Tetris::Grid;
use Chandra::Game::Tetris::Blocks;
use Chandra::Element;

has [qw/width height/] => (
	isa => Int,
	required => 1
);

has [qw/grid blocks/] => (
	isa => Object,
);

has [qw/score lines level/] => (
	isa => Int
);

sub BUILD {
	my ($self) = @_;
	$self->grid(
		new Chandra::Game::Tetris::Grid $self->width, $self->height
	);
	$self->blocks(
		new Chandra::Game::Tetris::Blocks
	);
}

sub play_tick {
	my ($self) = @_;
	my $current = $self->blocks->current;
	my $grid = $self->grid;
	my $new_row = $self->blocks->current->row + 1;
	if ($grid->is_valid($current->cells, $new_row, $current->col)) {
		$current->row($new_row);
		return {
			grid  => $self->render_grid,
			score => $self->score,
			lines => $self->lines,
			level => $self->level,
		};
	}
	return $self->_lock_and_spawn;
}

sub play_move {
	my ($self, $dir) = @_;
	my $current = $self->blocks->current;
	my $grid = $self->grid;
	if ($dir eq 'left') {
		my $nc = $current->col - 1;
		$current->col($nc)
			if $grid->is_valid($current->cells, $current->row, $nc);
	} elsif ($dir eq 'right') {
		my $nc = $current->col + 1;
		$current->col($nc)
			if $grid->is_valid($current->cells, $current->row, $nc);
	} elsif ($dir eq 'rotate') {
		my $rotated = rotate_cw($current->cells);
		if ($grid->is_valid($rotated, $current->row, $current->col)) {
			$current->cells($rotated);
		} else {
			for my $check (-1, 1, -2, 2) {
				my $cc = $current->col + $check;
				if ($grid->is_valid($rotated, $current->row, $cc)) {
					$current->cells($rotated);
					$current->col($cc);
					last;
				}
			}
		}
	} elsif ($dir eq 'down') {
		my $nr = $current->row + 1;
		if ($grid->is_valid($current->cells, $nr, $current->col)) {
			$current->row($nr);
		} else {
			return $self->_lock_and_spawn;
		}
	} elsif ($dir eq 'drop') {
		my $nr = $current->row;
		while ($grid->is_valid($current->cells, $nr + 1, $current->col)) {
			$nr++;
		}
		$current->row($nr);
		return $self->_lock_and_spawn;
	}
	return {
		grid  => $self->render_grid,
		score => $self->score,
		lines => $self->lines,
		level => $self->level,
	};
}

sub draw_view {
	my ($self) = @_;
	my $html = Chandra::Element->new({
		tag => "div",
		class => "wrapper"
	});
	my $title = Chandra::Element->new({
		tag => "div",
		children => [{
			tag   => "h1",
			class => "title",
			data  => "Tetris"
		}]
	});
	my $game_area = Chandra::Element->new({
		tag  => "div",
		class => "tetris-game-area",
		children => [
			{
				tag => "div",
				class => "tetris-game-area-left",
				children => [ $self->draw_grid() ]
			},
			{
				tag => "div",
				class => "tetris-game-area-right",
				children => [
					{
						tag => "div",
						class => "score-wrapper",
						children => [
							{ tag => "h2", data => "Score" },
							{ tag => "h3", id   => "score", data => "0" }
						]
					},
					{
						tag => "div",
						class => "lines-wrapper",
						children => [
							{ tag => "h2", data => "Lines" },
							{ tag => "h3", id   => "lines", data => "0" }
						]
					},
					{
						tag => "div",
						class => "next-block-wrapper",
						children => [
							{ tag => "h2", data => "Next" },
							{ tag => "div", id  => "next-block" }
						]
					},
					{
						tag => "div",
						class => "start-wrapper",
						children => [{
							tag  => "button",
							id   => "start",
							data => "Start"
						}]
					}
				]
			}
		]
	});
	my $modal = Chandra::Element->new({
		tag   => "div",
		class => "start-modal hide"
	});
	$html->add_child($title);
	$html->add_child($game_area);
	$html->add_child($modal);
	return $html;
}

sub render_grid {
	my ($self) = @_;
	return $self->draw_grid($self->blocks->current)->render;
}

sub draw_grid {
	my ($self, $current) = @_;
	$current //= $self->blocks->current;
	my @display = map { [@$_] } @{ $self->grid->grid };
	if ($current && @{$current->cells}) {
		my $cells = $current->cells;
		my $block_row = $current->row // 0;
		my $block_col = $current->col // 0;
		my $block_id  = $current->id  // 1;
		for my $r (0 .. $#{$cells}) {
			for my $c (0 .. $#{$cells->[$r]}) {
				next unless $cells->[$r][$c];
				my $gr = $block_row + $r;
				my $gc = $block_col + $c;
				next if $gr < 0 || $gr >= $self->grid->height;
				next if $gc < 0 || $gc >= $self->grid->width;
				$display[$gr][$gc] = $block_id;
			}
		}
	}
	my $html  = Chandra::Element->new({ tag => 'div', class => 'tetris-area-wrapper' });
	my $table = $html->add_child({ tag => 'table', class => 'tetris-area' });
	for my $row (@display) {
		my $tr = $table->add_child({ tag => 'tr', class => 'tetris-row' });
		for my $cell (@$row) {
			my $class = $cell ? "tetris-col filled block-$cell" : 'tetris-col';
			$tr->add_child({
				tag => 'td',
				class => $class,
				children => [{ tag => 'div' }],
			});
		}
	}
	return $html;
}

sub _lock_and_spawn {
	my ($self) = @_;
	my $grid = $self->grid;
	my $current = $self->blocks->current;
	$grid->lock_block(
		$current->cells, $current->row, $current->col, $current->id
	);
	my $cleared = $grid->clear_lines;
	$self->update_score($cleared);
	if (!$self->spawn_next($current)) {
		return {
			game_over => 1,
			grid => $self->render_grid,
			score => $self->score,
			lines => $self->lines,
			level => $self->level,
		};
	}
	my $next_html = $self->blocks->next->render->render;
	return {
		game_over => 0,
		grid => $self->render_grid,
		score => $self->score,
		lines => $self->lines,
		level => $self->level,
		next_block => $next_html,
	};
}

sub spawn_next {
	my ($self) = @_;
	my $blocks = $self->blocks;
	my $block = $blocks->next;
	$blocks->current($block);
	$block->row(0);
	$block->col(($self->grid->width / 2) - 2);
	return $self->grid->is_valid(
		$block->cells, $block->row, $block->col
	);
}

sub reset_game {
	my ($self) = @_;
	$self->grid->reset;
	$self->score(0);
	$self->lines(0);
	$self->level(1);
}

sub update_score {
	my ($self, $cleared) = @_;
	return unless $cleared;
	my @points = (0, 100, 300, 500, 800);
	my $pts = ($points[$cleared] // 800) * $self->level;
	$self->score($self->score + $pts);
	$self->lines($self->lines + $cleared);
	$self->level(int($self->lines / 10) + 1);
}


sub rotate_cw {
	my ($cells) = @_;
	my $n = scalar @$cells;
	my @r;
	for my $row (0 .. $n - 1) {
		for my $col (0 .. $n - 1) {
			$r[$row][$col] = $cells->[$n - 1 - $col][$row];
		}
	}
	return \@r;
}

sub css {
	return q|
		*, *::before, *::after {
			box-sizing: border-box;
			margin: 0;
			padding: 0;
		}

		:root {
			--background: rgb(20, 24, 27);
			--color: rgb(240, 244, 247);
			--cell: clamp(16px, min(calc((100vw - 160px) / 10), calc((100vh - 80px) / 18)), 40px);
			--grid-w: calc(var(--cell) * 10);
			--grid-h: calc(var(--cell) * 18);
			--panel-w: calc(var(--cell) * 5);
			--border: 1px solid rgb(40, 44, 47);
			--cell-bg: rgb(30, 34, 37);
		}

		body {
			background: var(--background);
			min-height: 100vh;
			display: flex;
			align-items: center;
			justify-content: center;
		}

		.wrapper {
			display: flex;
			flex-direction: column;
			align-items: center;
			gap: 0.5rem;
			padding: 1rem;
		}

		.title {
			color: var(--color);
			font-family: monospace;
			font-size: clamp(1rem, 4vw, 2rem);
			text-align: center;
			letter-spacing: 0.2em;
			text-transform: uppercase;
		}

		.tetris-game-area {
			display: flex;
			flex-direction: row;
			gap: calc(var(--cell) * 0.5);
			align-items: flex-start;
		}

		.tetris-area-wrapper {
			position: relative;
		}

		/* Grid */
		.tetris-area {
			width: var(--grid-w);
			height: var(--grid-h);
			border-collapse: collapse;
			border: var(--border);
			table-layout: fixed;
		}

		.tetris-row {
			height: var(--cell);
		}

		.tetris-col {
			width: var(--cell);
			height: var(--cell);
			padding: 0;
			background: var(--cell-bg);
			border: var(--border);
		}

		.tetris-col > div {
			width: var(--cell);
			height: var(--cell);
		}

		.tetris-area tr:first-child td {
			height: var(--cell);
			background: rgb(230, 60, 60, 0.1);
		}

		/* Piece colors */
		.tetris-col.filled { border-color: rgba(0,0,0,0.4); }
		.block-1 { background: #00f0f0 !important; }
		.block-2 { background: #f0f000 !important; }
		.block-3 { background: #a000f0 !important; }
		.block-4 { background: #00c000 !important; }
		.block-5 { background: #f00000 !important; }
		.block-6 { background: #f0a000 !important; }
		.block-7 { background: #0000f0 !important; }

		/* Right panel */
		.tetris-game-area-right {
			display: flex;
			flex-direction: column;
			gap: calc(var(--cell) * 0.5);
			width: var(--panel-w);
			color: rgb(240, 244, 247);
			font-family: monospace;
		}

		.score-wrapper,
		.lines-wrapper,
		.next-block-wrapper,
		.start-wrapper {
			display: flex;
			flex-direction: column;
			align-items: center;
			gap: 0.25rem;
		}

		.score-wrapper h2,
		.lines-wrapper h2,
		.next-block-wrapper h2 {
			font-size: clamp(0.6rem, calc(var(--cell) * 0.35), 1rem);
			text-transform: uppercase;
			letter-spacing: 0.15em;
			color: rgb(160, 164, 167);
		}

		#score,
		#lines {
			font-size: clamp(0.8rem, calc(var(--cell) * 0.5), 1.5rem);
			font-weight: bold;
		}

		#next-block {
			width: calc(var(--cell) * 4);
			height: calc(var(--cell) * 4);
			border: var(--border);
			background: var(--cell-bg);
			display: flex;
			align-items: center;
			justify-content: center;
		}

		#start {
			width: 100%;
			padding: calc(var(--cell) * 0.2) 0;
			background: rgb(60, 180, 100);
			color: var(--color);
			border: none;
			font-family: monospace;
			font-size: clamp(0.7rem, calc(var(--cell) * 0.35), 1rem);
			letter-spacing: 0.1em;
			text-transform: uppercase;
			cursor: pointer;
			border-radius: 2px;
		}

		#start:hover {
			background: rgb(80, 200, 120);
		}

		/* Next block preview */
		.tetris-block {
			border-collapse: collapse;
			table-layout: fixed;
			margin: auto;
		}

		.tetris-block-row {
			height: calc(var(--cell) * 0.8);
		}

		.tetris-cell {
			width: calc(var(--cell) * 0.8);
			height: calc(var(--cell) * 0.8);
			padding: 0;
			border: 1px solid transparent;
		}

		.tetris-cell.filled {
			border-color: rgba(0,0,0,0.3);
		}

		.tetris-cell.empty {
			background: transparent;
		}

		.tetris-cell > div {
			width: 100%;
			height: 100%;
		}

		.start-modal {
			position: absolute;
			width: 100%;
			height: 100%;
			display: flex;
			align-items: center;
			justify-content: center;
			color: white;
			font-family: monospace;
			font-size: clamp(2rem, 10vw, 6rem);
			font-weight: bold;
			background: rgba(0,0,0,0.6);
			pointer-events: none;
		}

		.start-modal.small {
			font-size: clamp(1rem, 4vw, 2rem);
			text-align: center;
			padding: 1rem;
		}

		.hide {
			display: none !important;
		}
	|;
}



sub js {
	return q|
		var score_el = document.querySelector('#score');
		var lines_el = document.querySelector('#lines');
		var next_block = document.querySelector('#next-block');
		var start_button = document.querySelector('#start');
		var tetris_area = document.querySelector('.tetris-game-area-left');
		var start_modal = document.querySelector('.start-modal');
		var gameInterval = null;
		var isRunning = false;
		var currentLevel = 1;

		function getSpeed(level) {
			return Math.max(80, 800 - (level - 1) * 70);
		}

		function startGameLoop(level) {
			if (gameInterval) clearInterval(gameInterval);
			gameInterval = setInterval(function() {
				window.chandra.invoke('tick', [])
					.then(function(r) { handleGameResponse(r); })
					.catch(function(e) { console.error('tick error:', e); });
			}, getSpeed(level));
		}

		function handleGameResponse(r) {
			if (!r) return;
			if (r.game_over) {
				isRunning = false;
				clearInterval(gameInterval);
				gameInterval = null;
				if (r.grid) tetris_area.innerHTML = r.grid;
				start_modal.innerText = 'GAME OVER\n' + r.score + ' pts';
				start_modal.classList.add('small');
				start_modal.classList.remove('hide');
				start_button.classList.remove('hide');
				setTimeout(function () { start_modal.classList.add('hide') }, 3000);
				return;
			}
			if (r.grid !== undefined) tetris_area.innerHTML = r.grid;
			if (r.score !== undefined) score_el.innerText = r.score;
			if (r.lines !== undefined) lines_el.innerText = r.lines;
			if (r.next_block !== undefined) next_block.innerHTML  = r.next_block;
			if (r.level !== undefined && r.level !== currentLevel) {
				currentLevel = r.level;
				if (isRunning) startGameLoop(currentLevel);
			}
		}

		function startCountdown() {
			var countdown = 3;
			start_modal.classList.remove('hide');
			start_modal.classList.remove('small');
			start_modal.innerText = countdown;
			var timer = setInterval(function() {
				countdown--;
				if (countdown > 0) {
					start_modal.innerText = countdown;
				} else {
					clearInterval(timer);
					start_modal.classList.add('hide');
					isRunning = true;
					startGameLoop(currentLevel);
				}
			}, 1000);
		}

		start_button.addEventListener('click', function() {
			window.chandra.invoke('start_button', [])
				.then(function(r) {
					currentLevel = 1;
					if (r.grid) tetris_area.innerHTML = r.grid;
					if (r.score !== undefined) score_el.innerText = r.score;
					if (r.lines !== undefined) lines_el.innerText = r.lines;
					if (r.next_block) next_block.innerHTML  = r.next_block;
					start_button.classList.add('hide');
					startCountdown();
				})
				.catch(function(e) { console.error('start_button error:', e); });
		});
	|;
}

1;
