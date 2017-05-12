#!/usr/bin/perl

use strict;
use warnings;

use Clutter::TestHelper tests => 324;
use Test::Builder;

use Champlain ':coords';
use File::Spec;

# Path to a valid image
my $FILENAME = File::Spec->catfile('examples', 'images', 'who.png');

my $DEFAULT_COLOR = Champlain::Marker->new()->get_color;
my $DEFAULT_TEXT_COLOR = Champlain::Marker->new()->get_text_color;
my $DEFAULT_FONT_NAME = Champlain::Marker->new()->get_font_name;


exit tests();


sub tests {

	test_new();
	test_new_with_text();
	test_new_from_file();
	test_new_full();
	test_new_with_image();
	test_global_colors();

	return 0;
}


sub test_global_colors {

	Champlain::Marker->set_highlight_color(Clutter::Color->new(0xff, 0xff, 0x00));
	is_color(
		Champlain::Marker->get_highlight_color,
		Clutter::Color->new(0xff, 0xff, 0x00),
		"get_highlight_color()"
	);


	Champlain::Marker->set_highlight_text_color(Clutter::Color->new(0xff, 0xef, 0x00));
	is_color(
		Champlain::Marker->get_highlight_text_color,
		Clutter::Color->new(0xff, 0xef, 0x00),
		"get_highlight_color()"
	);
}


sub test_new {
	my $marker = Champlain::Marker->new();
	isa_ok($marker, 'Champlain::Marker');
	generic_test($marker);
}


sub test_new_with_text {

	my $marker;

	# Create a label without mandatory arguments
	$marker = Champlain::Marker->new_with_text("Home");
	isa_ok($marker, 'Champlain::Marker');
	is($marker->get_text, 'Home', "new_with_text() sets 'text'");
	ok($marker->get_font_name, "new_with_text(font = undef) sets 'font_name'");
	isa_ok($marker->get_text_color, 'Clutter::Color', "new_with_text(text_color = undef) sets 'text_color'");
	isa_ok($marker->get_color, 'Clutter::Color', "new_with_text(color = undef) sets 'color'");
	generic_test($marker);


	# Create a label by specifying the colors
	$marker = Champlain::Marker->new_with_text(
		"Bratislava",
		"Airmole 14",
		Clutter::Color->new(0xf3, 0x94, 0x07, 0xbb), # orange
		Clutter::Color->new(0xff, 0xff, 0xff, 0xff), # white
	);
	isa_ok($marker, 'Champlain::Marker');
	is($marker->get_text, 'Bratislava', "new_with_text() sets 'text'");
	is($marker->get_font_name, 'Airmole 14', "new_with_text() sets 'font_name'");
	is_color(
		$marker->get_text_color,
		Clutter::Color->new(0xf3, 0x94, 0x07, 0xbb),
		"new_with_text() sets 'text_color'"
	);
	is_color(
		$marker->get_color,
		Clutter::Color->new(0xff, 0xff, 0xff, 0xff),
		"new_with_text() sets 'color'"
	);
	generic_test($marker);
}


sub test_new_from_file {
	my $marker = Champlain::Marker->new_from_file($FILENAME);
	isa_ok($marker, 'Champlain::Marker');
	isa_ok($marker->get_image, 'Clutter::Actor');
	generic_test($marker);
	
	# Assert that using a file that doesn't exist throws an exception
	eval {
		$marker = Champlain::Marker->new_from_file("does-not-exist.gif");
	};
	isa_ok($@, "Glib::File::Error");
}


sub test_new_full {
	my $texture = Clutter::Texture->new();	
	my $marker = Champlain::Marker->new_full("hello", $texture);
	isa_ok($marker, 'Champlain::Marker');
	is($marker->get_text, 'hello', "new_full() sets 'text'");
	isa_ok($marker->get_image, 'Clutter::Actor');
	generic_test($marker);


	$marker = Champlain::Marker->new_full("null-image", undef);
	isa_ok($marker, 'Champlain::Marker');
	is($marker->get_text, 'null-image', "new_full(text, undef) sets 'text'");
	is($marker->get_image, undef, "new_full(text, undef) sets no image");
	generic_test($marker);
}


sub test_new_with_image {
	my $texture = Clutter::Texture->new();	
	my $marker = Champlain::Marker->new_with_image($texture);
	isa_ok($marker, 'Champlain::Marker');
	isa_ok($marker->get_image, 'Clutter::Actor');
	generic_test($marker);
}


sub generic_test {
	my ($marker) = @_;

	# Test that the normal properties have default values
	ok(!$marker->get_use_markup, "use markup is false by default");
	is($marker->get_alignment, 'left', "alignment is 'left' by default");
	ok(!$marker->get_wrap, "wrap is false by default");
	is($marker->get_ellipsize, 'none', "ellipsize is 'none' by default");
	ok($marker->get_single_line_mode, "single_line_mode is true by default");
	ok($marker->get_draw_background, "draw-background is true by default");

	# Test the setters
	$marker->set_use_markup(TRUE);
	ok($marker->get_use_markup, "set_use_markup()");

	$marker->set_alignment('center');
	is($marker->get_alignment, 'center', "set_alignment()");

	$marker->set_wrap(TRUE);
	ok($marker->get_wrap, "set_wrap()");

	$marker->set_ellipsize('start');
	is($marker->get_ellipsize, 'start', "set_ellipsize()");

	$marker->set_single_line_mode(FALSE);
	ok(!$marker->get_single_line_mode, "set_single_line_mode()");

	$marker->set_draw_background(FALSE);
	ok(!$marker->get_draw_background, "set_draw_background()");

	
	$marker->set_text("dummy test");
	is($marker->get_text, "dummy test", "set_text()");
#	$marker->set_text(undef);
#	is($marker->get_text, undef, "set_text(undef)");

	$marker->set_image(Clutter::Ex::DeadActor->new());
	isa_ok($marker->get_image, 'Clutter::Ex::DeadActor', "set_image()");
#	$marker->set_image(undef);
#	is($marker->get_image, undef, "set_image(undef)");

	my $color = Clutter::Color->new(0xca, 0xfe, 0xbe, 0xef);
	$marker->set_color($color);
	is_color($marker->get_color, $color, "set_color()");

	# Setting the background color to undef resets the color to the default value
	$marker->set_color(undef);
	is_color(
		$marker->get_color, 
		$DEFAULT_COLOR,
		"set_color(undef) resets the color"
	);

	my $text_color = Clutter::Color->new(0xca, 0xfe, 0xbe, 0xef);
	$marker->set_text_color($text_color);
	is_color($marker->get_text_color, $text_color, "set_text_color()");
	
	# Setting the text color to undef resets the color to the default value
	$marker->set_text_color(undef);
	is_color(
		$marker->get_text_color, 
		$DEFAULT_TEXT_COLOR, 
		"set_text_color(undef) resets the color"
	);

	$marker->set_font_name("Mono 14");
	is($marker->get_font_name, "Mono 14", "set_font_name()");
	$marker->set_font_name(undef);
	is($marker->get_font_name, $DEFAULT_FONT_NAME, "set_font_name(undef)");


	# Can't be tested but at least we call it
	$marker->queue_redraw();
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


#
# An empty actor.
#
package Clutter::Ex::DeadActor;
use Glib::Object::Subclass 'Clutter::Actor',;

# This is a an empty actor. This class is needed because Clutter::Actor is an
# abstract class.

