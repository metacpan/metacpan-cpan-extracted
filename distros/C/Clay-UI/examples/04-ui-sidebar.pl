#!/usr/bin/env perl

# 04-ui-sidebar.pl - The 02-sidebar-demo.pl layout, rebuilt on Clay::UI.
#
# Lays out the same elements and produces the same render commands as the
# low-level version: the open / configure / close calls are replaced by a
# tree of Clay::UI::Box and Clay::UI::Text widgets that Clay::UI lays out.
# A second frame moves the pointer over a sidebar item and lists the
# widgets under it: three, where 02 lists four element ids, because Clay's
# own root element (Clay__RootContainer) belongs to no widget. Prints a
# summary of the render commands.
#
# Shows:
#   - building a widget tree from two small widget classes
#   - laying it out with Clay::UI and counting the render commands
#   - asking which widgets are under the pointer
#
# Features: Clay::UI, Clay::UI::Box, Clay::UI::Text, add_child, render, pointer_state, interaction, under_pointer, id, measure_text, error_handler, sizing_grow, sizing_fixed, padding_all, child_gap, child_alignment, layout_direction, background_color, CLAY_TOP_TO_BOTTOM, CLAY_ALIGN_X_LEFT, CLAY_ALIGN_Y_CENTER, CLAY_RENDER_COMMAND_TYPE_RECTANGLE, CLAY_RENDER_COMMAND_TYPE_TEXT, CLAY_RENDER_COMMAND_TYPE_BORDER, CLAY_RENDER_COMMAND_TYPE_IMAGE
#
# Requires: nothing beyond this distribution.
#
# Run with:
#
#     perl -Ilib -Iblib/lib -Iblib/arch examples/04-ui-sidebar.pl

use v5.22;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Object::Pad 0.800;

use Clay::XS qw(:all);
use Clay::UI;
use Clay::UI::Box;
use Clay::UI::Text;

# Clay::UI ships roles, not classes: each widget class is one line that
# composes the role it needs (see Clay::Manual, GETTING STARTED).
class My::Box  :strict(params) :does(Clay::UI::Box)  {}
class My::Text :strict(params) :does(Clay::UI::Text) {}

my $COLOR_LIGHT  = [224, 215, 210, 255];
my $COLOR_RED    = [168,  66,  28, 255];
my $COLOR_ORANGE = [225, 138,  50, 255];

sub sidebar_item ($index) {
	return My::Box->new(
		id               => "SidebarItem-$index",
		layout           => { sizing => { width => sizing_grow(), height => sizing_fixed(50) } },
		background_color => $COLOR_ORANGE,
	);
}

sub build_tree () {
	my $outer = My::Box->new(
		id => 'OuterContainer',
		layout => {
			sizing    => { width => sizing_grow(), height => sizing_grow() },
			padding   => padding_all(16),
			child_gap => 16,
		},
		background_color => [250, 250, 255, 255],
	);

	my $sidebar = My::Box->new(
		id => 'SideBar',
		layout => {
			layout_direction => CLAY_TOP_TO_BOTTOM,
			sizing           => { width => sizing_fixed(300), height => sizing_grow() },
			padding          => padding_all(16),
			child_gap        => 16,
		},
		background_color => $COLOR_LIGHT,
	);

	my $profile_outer = My::Box->new(
		id => 'ProfilePictureOuter',
		layout => {
			sizing          => { width => sizing_grow() },
			padding         => padding_all(16),
			child_gap       => 16,
			child_alignment => { x => CLAY_ALIGN_X_LEFT, y => CLAY_ALIGN_Y_CENTER },
		},
		background_color => $COLOR_RED,
	);
	$profile_outer->add_child(
		My::Box->new(
			id     => 'ProfilePicture',
			layout => { sizing => { width => sizing_fixed(60), height => sizing_fixed(60) } },
		),
		My::Text->new(
			text       => 'Clay - UI Library',
			font_size  => 24,
			text_color => [255, 255, 255, 255],
		),
	);

	$sidebar->add_child($profile_outer);
	$sidebar->add_child(sidebar_item($_)) for 0 .. 4;

	my $main = My::Box->new(
		id => 'MainContent',
		layout => { sizing => { width => sizing_grow(), height => sizing_grow() } },
		background_color => $COLOR_LIGHT,
	);

	$outer->add_child($sidebar, $main);
	return $outer;
}

my $ui = Clay::UI->new(
	width         => 1024,
	height        => 768,
	root          => build_tree(),
	measure_text  => sub ($text, $config, $userdata) {
		my $fs = $config->{fontSize} || 16;
		return { width => length($text) * $fs * 0.55, height => $fs };
	},
	error_handler => sub ($err, $userdata) { warn "Clay error: $err->{errorText}\n" },
);

# Frame 1: geometry.
my $frame1 = $ui->render;
printf "Frame 1: %d render commands\n", scalar @$frame1;

# Frame 2: hover the third sidebar item.
my $frame2 = $ui->render( pointer_state => { x => 160, y => 320, down => 0 } );

my $hovered = $ui->interaction->under_pointer;
printf "Frame 2: %d widgets under pointer\n", scalar @$hovered;
for my $widget (@$hovered) {
	printf "  %s\n", $widget->id;
}

my %by_type;
$by_type{ $_->{commandType} }++ for @$frame2;
print "\nRender command type breakdown:\n";
for my $type (sort keys %by_type) {
	my $name = (
		CLAY_RENDER_COMMAND_TYPE_RECTANGLE() == $type ? 'RECTANGLE' :
		CLAY_RENDER_COMMAND_TYPE_TEXT()      == $type ? 'TEXT'      :
		CLAY_RENDER_COMMAND_TYPE_BORDER()    == $type ? 'BORDER'    :
		CLAY_RENDER_COMMAND_TYPE_IMAGE()     == $type ? 'IMAGE'     :
		"type=$type"
	);
	printf "  %-12s %d\n", $name, $by_type{$type};
}
