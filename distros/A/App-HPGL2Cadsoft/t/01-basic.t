#!/usr/bin/perl
#
# Copyright (C) 2014 by Lieven Hollevoet

# This test runs basic module tests

use Modern::Perl;
use Test::More;

BEGIN { use_ok 'App::HPGL2Cadsoft'; }
BEGIN { use_ok 'Test::Exception'; }
BEGIN { use_ok 'Test::Warn'; }
BEGIN { use_ok 'Grid::Coord'; }

require Test::Exception;
require Test::Warn;
require Grid::Coord;

# Check we get an error message on missing input parameters
my $reporter;

can_ok ('App::HPGL2Cadsoft', qw(scaling_factor input_file output_file));

throws_ok { $reporter = App::HPGL2Cadsoft->new() } qr/Attribute .+ is required/, "Checking missing parameters";
throws_ok { $reporter = App::HPGL2Cadsoft->new(input_file => 't/stim/missing_file.hpgl') } qr/Could not open file .t\/stim\/missing_file.+/, "Checking missing file";

my $app = App::HPGL2Cadsoft->new(input_file => 't/stim/heart.hpgl');

ok $app, 'object created';
ok $app->isa('App::HPGL2Cadsoft'), 'and it is the right class';

# Check if parsing the example HPGL file yields the correct result
my ($lines, $skipped);
warning_like { ($lines, $skipped) = $app->_parse_hpgl() } qr/HPGL command not parsed: 'PUx'/, "HPGL parser";
is $lines, 506, 'parsed HPGL #lines correctly';
is $skipped, 81, 'skipped correct number of empty movemens';

# Check if scaled bounding box is correct size
$app->_scale();
$app->_calculate_bbox();

my $bbox = $app->_bbox();

ok $bbox->isa('Grid::Coord'), 'bounding box is the correct class';
is int($bbox->max_x()), 24, 'correct max_x';
is int($bbox->max_y()), 34, 'correct max_y';


done_testing();