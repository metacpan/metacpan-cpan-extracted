# Before `make install' is performed this script should be runnable width
# `make test'. After `make install' it should work as `perl 1.t'

use warnings;
use strict;

use FindBin;
use lib "$FindBin::RealBin/../lib";

use Test::More tests => 5;
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
	-sh				 => 5, # canas height
	-sw				 => 100, # canvas width
	-canvasscr => $canvasscr,
);



{
		my $grid = Curses::UI::Grid->new(
			-rows      => 1,
			-columns   => 0,
			-editable	 => 1,
			%silence_test_mode_option,
		);
		my $bindings = $grid->bindings;
		is(keys %$bindings, 16, "16 bindings set for editable grid");
}	

{
		my $grid = Curses::UI::Grid->new(
			-rows      => 1,
			-columns   => 0,
			-editable	 => 0,
			%silence_test_mode_option,
		);
		my $bindings = $grid->bindings;
		is(keys %$bindings, 11, "11 bindings set for read only grid");
}	