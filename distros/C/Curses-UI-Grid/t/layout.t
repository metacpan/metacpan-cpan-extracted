# Before `make install' is performed this script should be runnable width
# `make test'. After `make install' it should work as `perl 1.t'

use warnings;
use strict;

use FindBin;
use lib "$FindBin::RealBin/../lib";

use Test::More tests => 43;
BEGIN { use_ok('Curses::UI::Grid') };
BEGIN { use_ok('Curses::UI::Grid::Cell') };
BEGIN { use_ok('Curses::UI::Grid::Row') };

sub addstr {shift};
sub attron {shift};
sub attroff {shift};
sub move {shift};
sub noutrefresh {shift};
sub vline {shift};
sub hline {shift};
my $canvasscr = bless {}; 




{
		print "## basic layout for 2 cells\n";
		my $grid_width = 13;
		my $grid = Curses::UI::Grid->new(
			-rows      => 2,
			-columns   => 0,
			-test_more => 1,
			-sh				 => 5, # canas height
			-sw				 => $grid_width, # canvas width
			-canvasscr => $canvasscr,
		);

		is($grid->rows_count, 2, 'create 2 rows for grid');
		my $cell_width = 10;
		$grid->add_cell("cell$_",
			-width=> $cell_width ,
			-align => 'L',
		) for 1 .. 2;

		$grid->layout_cells;
		my $cell1 = $grid->get_cell('cell1');
		is($cell1->x, 0, 'absolute x for cell 1');
		is($cell1->current_width, $cell_width, 'width on screen for cell 1');

		my $cell2 = $grid->get_cell('cell2');
		is($cell2->x, $cell_width + 1, 'absolute x for cell 2');
		
		

		is($cell2->current_width, $grid_width - $cell_width - 1, 'width on screen for cell 2');
		
		is($grid->x_offset, 0, 'virtual scroll');
		my $cell2_hidden_width = $cell2->width - $cell2->current_width;
		ok($grid->next_cell, 'next cell');
		is($grid->x_offset, $cell2_hidden_width - 1  , 'virtual scroll');

		is($cell1->x, 0, 'absolute x for cell 1');
		is($cell1->current_width, $grid_width - $cell2->current_width - 1, 'decreased width on screen for cell 1');
		is($cell2->x, $cell1->current_width + 1, 'absolute x for cell 2');
}



{
		print "## basic layout for 5 cells\n";
		my $grid_width = 29;
		my $grid = Curses::UI::Grid->new(
			-rows      => 1,
			-columns   => 4,
			-test_more => 1,
			-sh				 => 5, # canas height
			-sw				 => $grid_width, # canvas width
			-canvasscr => $canvasscr,
		);

		$grid->set_cell_width('cell1', 7);
		$grid->set_cell_width('cell2', 14);
		$grid->set_cell_width('cell3', 5);


		$grid->layout_cells;
		my $cell1 = $grid->get_cell('cell1');
		my $cell2 = $grid->get_cell('cell2');
		my $cell3 = $grid->get_cell('cell3');
		my $cell4 = $grid->get_cell('cell4');
		my $cell;
		{
				is($grid->x_offset, 0, 'virtual scroll');

				is($cell1->x, 0, 'absolute x for cell 1');
				is($cell1->current_width, 7, 'width on screen for cell 1');
				is($cell2->x, 8, 'absolute x for cell 2');
				is($cell2->current_width, 14, 'width on screen for cell 2');
				is($cell3->x, 23, 'absolute x for cell 3');
				is($cell3->current_width, 5, 'width on screen for cell 3');
				ok(! $cell4->x, 'no x for hidden cell4');
				ok(! $cell4->current_width, 'no width for hidden cell4');
				
		}
		{		
				ok($cell = $grid->next_cell, 'next cell');
				is($cell2, $cell, 'current cell is cell2');

				is($grid->x_offset, 0, 'virtual scroll');
				is($cell1->x, 0, 'absolute x for cell 1');
				is($cell1->current_width, 7, 'width on screen for cell 1');
				is($cell2->x, 8, 'absolute x for cell 2');
				is($cell2->current_width, 14, 'width on screen for cell 2');
				is($cell3->current_width, 5, 'width for cell3');
				ok(! $cell4->x, 'no x for hidden cell4');
				ok(! $cell4->current_width, 'no width for hidden cell4');

		}

		{
				ok($cell = $grid->next_cell, 'next cell');
				is($cell3, $cell, 'current cell is cell3');
				is($grid->x_offset, 0, 'virtual scroll');

				is($cell1->x, 0, 'absolute x for cell 1');
				is($cell1->current_width, 7, 'width on screen for cell 1');
				
				
				is($cell2->x, 8, 'absolute x for cell 2');
				is($cell2->current_width, $cell2->width, 'width on screen for cell 2');
				is($cell3->current_width, 5, 'width for cell3');
				ok(! $cell4->x, 'no x for hidden cell4');
				ok(! $cell4->current_width, 'no width for hidden cell4');
		}
		
		
	#is($grid->x_offset, 0, 'virtual scroll');



}
