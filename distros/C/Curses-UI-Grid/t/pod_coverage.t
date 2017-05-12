use strict;
use warnings;

use Test::Pod::Coverage tests => 3;

pod_coverage_ok('Curses::UI::Grid', "should have value Curses::UI::Grid.pm POD file" );
pod_coverage_ok('Curses::UI::Grid::Row', "should have value Curses::UI::Grid::Row.pm POD file" );
pod_coverage_ok('Curses::UI::Grid::Cell', "should have value Curses::UI::Grid::Cell.pm POD file" );



