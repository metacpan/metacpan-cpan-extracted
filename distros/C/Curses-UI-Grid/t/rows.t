# Before `make install' is performed this script should be runnable width
# `make test'. After `make install' it should work as `perl 1.t'

use warnings;
use strict;

use FindBin;
use lib "$FindBin::RealBin/../lib";

use Test::More tests => 57;
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
my %silence_test_mode_option = (
  -test_more => 1,
	-sh				 => 6, # canas height
	-sw				 => 100, # canvas width
	-canvasscr => $canvasscr,
);



{
		my $grid = Curses::UI::Grid->new(
			-rows      => 0,
			-columns   => 0,
			-editable	 => 1,
			%silence_test_mode_option,
		);

    $grid->add_cell('COLUMN1',
      -width => 8,
      -label => 'Column 1',
    );
      
     $grid->add_cell('COLUMN2',
       -width => 8,
       -label => 'Column 2',
     );
    
		$grid->add_row(undef,
      -fg    => 'black',
      -bg    => 'yellow',
		  -cells => { 
		    COLUMN1 => "DATA $_ 1", 
		    COLUMN2 => "DATA $_ 2" , 
		  }, 
		) for 1 .. 3;
		
		$grid->layout_content;
		for (1 .. 3) {
				my $row = $grid->get_foused_row;
				is($row->id, "row$_", "should move to row $_");
				is($row->get_value('COLUMN1'), "DATA $_ 1", "should be data for row $_ cell 1");
				is($row->get_value('COLUMN2'), "DATA $_ 2", "should be data for row $_ cell 2");
				$grid->next_row;
		}
		{
				my $row = $grid->get_foused_row;
				is($row->{-id}, 'row4', 'should create row still space in grid');
		}
		for (1 .. 3) {
				$grid->prev_row;
				my $row = $grid->get_foused_row;
				my $i = 4 - $_;
				is($row->id, "row$i", "should move to row $i");
				is($row->get_value('COLUMN1'), "DATA $i 1", "should be data for row $i cell 1");
				is($row->get_value('COLUMN2'), "DATA $i 2", "should be data for row $i cell 2");
				
		}
		{
				$grid->next_row;
				my $row = $grid->get_foused_row;
				is($row->get_value('COLUMN1'), "DATA 2 1", "should be data for row 2 cell 1");
				is($row->get_value('COLUMN2'), "DATA 2 2", "should be data for row 2 cell 2");
				ok($grid->insert_row, "should insert row");
				$row = $grid->get_foused_row;
				ok(! $row->get_value('COLUMN1'), "should be data for a new inserted row cell 1");
				ok(! $row->get_value('COLUMN2'), "should be data for a new inserted row cell 2");
		}
		$grid->first_row;
		for (1 .. 4) {
				my @data = $_ < 2
				  ? ('DATA 1 1', 'DATA 1 2')
					: ($_ == 2
						? (undef, undef)
						: ('DATA ' . ($_ - 1) . ' 1', 'DATA ' . ($_ - 1) . ' 2'));
				my $row = $grid->get_foused_row;
				is($row->id, "row$_", "should move to row $_");
				is($row->get_value('COLUMN1'), $data[0], "should be data for row $_ cell 1");
				is($row->get_value('COLUMN2'), $data[1], "should be data for row $_ cell 2");
				$grid->next_row;
		}
		
		{
				my $row = $grid->last_row;
				is($row->id, 'row4', 'should be row 4');
				$grid->delete_row;
		}
		
		{
				my $row = $grid->get_foused_row;
				is($row->id, 'row3', 'shoud be row 3 after deleting row 4');
		}
		
		$grid->first_row;
		ok($grid->insert_row, "should insert row $_")
		  for 1 .. 4;
	
		for (1 .. 4) {	
				my $row = $grid->get_foused_row;
				is($row->id, "row$_", "should move to row $_");
				is($row->get_value('COLUMN1'), undef, "should be data for row $_ cell 1");
				is($row->get_value('COLUMN2'), undef, "should be data for row $_ cell 2");
				$grid->next_row;
		}
		
		
}

