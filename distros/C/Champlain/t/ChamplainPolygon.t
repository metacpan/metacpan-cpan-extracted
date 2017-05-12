#!/usr/bin/perl

use strict;
use warnings;

use Clutter::TestHelper tests => 52;

use Champlain;

my $DEFAULT_FILL_COLOR = Champlain::Polygon->new()->get_fill_color;
my $DEFAULT_STROKE_NAME = Champlain::Polygon->new()->get_stroke_color;

exit tests();

sub tests {
	test_empty();
	test_setters();
	test_points();
	return 0;
}


sub test_empty {
	my $polygon = Champlain::Polygon->new();
	isa_ok($polygon, 'Champlain::Polygon');
	
	my @points = $polygon->get_points();
	is_deeply(\@points, [], "No points on a new polygon");
	
	$polygon->clear_points();
	is_deeply(\@points, [], "No points on a cleared polygon");
	
	$polygon->clear_points();
	is_deeply(\@points, [], "No points on a cleared polygon (2 times)");

	is_color($polygon->get_fill_color, $DEFAULT_FILL_COLOR, "fill_color is set on a new polygon");
	is_color($polygon->get_stroke_color, $DEFAULT_STROKE_NAME, "stroke_color is set on a new polygon");
	
	ok(!$polygon->get_fill, "fill is unset on a new polygon");
	ok($polygon->get_stroke, "stroke is set on a new polygon");
	is($polygon->get_stroke_width, 2, "stroke_width is set on a new polygon");
	
	# These fields have no accessor yet
	ok(!$polygon->get('closed-path'), "closed-path is unset on a new polygon");
	ok($polygon->get('visible'), "closed-path is set on a new polygon");

	$polygon->set_mark_points(TRUE);
	is($polygon->get_mark_points, TRUE, "set_mark_points(TRUE)");

	$polygon->set_mark_points(FALSE);
	is($polygon->get_mark_points, FALSE, "set_mark_points(FALSE)");
}


sub test_setters {
	my $polygon = Champlain::Polygon->new();
	isa_ok($polygon, 'Champlain::Polygon');


	my $color;
	
	$color = Clutter::Color->new(0xaa, 0xdd, 0x37, 0xbb);
	$polygon->set_fill_color($color);
	is_color($polygon->get_fill_color, $color, "set_fill_color");
	
	$color = Clutter::Color->new(0x44, 0x33, 0x23, 0x2b);
	$polygon->set_stroke_color($color);
	is_color($polygon->get_stroke_color, $color, "set_stroke_color");
	
	{
		my $old_fill = $polygon->get_fill;
		$polygon->set_fill(!$old_fill);
		is($polygon->get_fill, !$old_fill, "set_fill()");
	}
	
	{
		my $old_stroke = $polygon->get_stroke;
		$polygon->set_stroke(!$old_stroke);
		is($polygon->get_stroke, !$old_stroke, "set_stroke()");
	}

	{	
		my $old_stroke_width = $polygon->get_stroke_width;
		$polygon->set_stroke_width($old_stroke_width + 2);
		is($polygon->get_stroke_width, $old_stroke_width + 2, "set_stroke_width()");
	}


	$polygon->hide();
	ok(!$polygon->get('visible'), "hide()");
	$polygon->show();
	ok($polygon->get('visible'), "show()");
}


sub test_points {
	my $polygon = Champlain::Polygon->new();
	isa_ok($polygon, 'Champlain::Polygon');

	my @remove = ();

	$polygon->append_point(8, 4);
	is_polygon(
		$polygon,
		[
			8, 4,
		],
		"append_point()"
	);

	push @remove, $polygon->append_point(4, 9);
	is_polygon(
		$polygon,
		[
			8, 4,
			4, 9,
		],
		"append_point()"
	);

	$polygon->insert_point(7, 10, 1);
	is_polygon(
		$polygon,
		[
			8, 4,
			7, 10,
			4, 9,
		],
		"insert_point() in the middle"
	);

	$polygon->append_point(5, 3);
	is_polygon(
		$polygon,
		[
			8, 4,
			7, 10,
			4, 9,
			5, 3,
		],
		"polygon: 4 points"
	);

	push @remove, $polygon->insert_point(1, 2, 0);
	is_polygon(
		$polygon,
		[
			1, 2,
			8, 4,
			7, 10,
			4, 9,
			5, 3,
		],
		"insert_point() at the beginning"
	);

	$polygon->insert_point(10, 20, 5);
	is_polygon(
		$polygon,
		[
			1, 2,
			8, 4,
			7, 10,
			4, 9,
			5, 3,
			10, 20,
		],
		"insert_point() at the end"
	);

	push @remove, $polygon->insert_point(30, 240, 17);
	is_polygon(
		$polygon,
		[
			1, 2,
			8, 4,
			7, 10,
			4, 9,
			5, 3,
			10, 20,
			30, 240,
		],
		"insert_point() past the end"
	);

	foreach my $point (@remove) {
		$polygon->remove_point($point);
	}
	is_polygon(
		$polygon,
		[
			8, 4,
			7, 10,
			5, 3,
			10, 20,
		],
		"remove_point()"
	);


	# Clear the polygon (it should be empty after)
	$polygon->clear_points();
	is_polygon($polygon, [], "clear_points()");

	$polygon->append_point(100, 200);
	is_polygon($polygon, [100, 200], "add_point on a cleared polygon");
}


#
# Assert that two colors are identical.
#
sub is_polygon {
	my ($polygon, $expected, $message) = @_;

	my @points = map { ($_->lat, $_->lon) } $polygon->get_points;
	is_deeply(\@points, $expected, $message);
}


#
# Assert that two colors are identical.
#
sub is_color {
	my ($got, $expected, $message) = @_;
	my $tester = Test::Builder->new();
	my $are_colors = 1;
	$are_colors &= $tester->is_eq(ref($got), 'Clutter::Color', "$message, got is a Clutter::Color");
	$are_colors &= $tester->is_eq(ref($expected), 'Clutter::Color', "$message, expected a Clutter::Color");

	if (! $are_colors) {
		$tester->ok(0, "$message, can't compare color components") for 1 .. 4;
		return;
	}

	$tester->is_num($got->red, $expected->red, "$message, red matches");
	$tester->is_num($got->green, $expected->green, "$message, green matches");
	$tester->is_num($got->blue, $expected->blue, "$message, blue matches");
	$tester->is_num($got->alpha, $expected->alpha, "$message, alpha matches");
}
