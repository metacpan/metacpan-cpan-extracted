#!/usr/bin/env perl

# 02-sidebar-demo.pl - The sidebar layout from Clay's README, in Perl.
#
# Rebuilds the README example (a sidebar with a profile header and five
# items next to a main content area) with the low-level Clay::XS calls,
# runs two frames and asks which elements lie under a simulated pointer.
# Prints a short summary of the second frame's render commands.
#
# Shows:
#   - a reusable component written as a plain Perl sub
#   - ids with an index for repeated elements
#   - fixed, growing and fitting sizes side by side
#   - hit testing needs one completed frame before the pointer is set
#
# Features: Clay_Initialize, Clay_MinMemorySize, Clay_SetMeasureTextFunction, Clay_BeginLayout, Clay_EndLayout, Clay__OpenElementWithId, Clay_GetElementId, Clay_GetElementIdWithIndex, Clay__ConfigureOpenElement, Clay__OpenTextElement, Clay__CloseElement, Clay_SetPointerState, Clay_GetPointerOverIds, stringId, offset, sizing_grow, sizing_fixed, padding_all, childGap, childAlignment, CLAY_TOP_TO_BOTTOM, CLAY_ALIGN_X_LEFT, CLAY_ALIGN_Y_CENTER, CLAY_RENDER_COMMAND_TYPE_RECTANGLE, CLAY_RENDER_COMMAND_TYPE_TEXT, CLAY_RENDER_COMMAND_TYPE_BORDER, CLAY_RENDER_COMMAND_TYPE_IMAGE
#
# Requires: nothing beyond this distribution.
#
# Run with:
#
#     perl -Ilib -Iblib/lib -Iblib/arch examples/02-sidebar-demo.pl

use v5.22;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Clay::XS qw(:all);

my $COLOR_LIGHT  = [224, 215, 210, 255];
my $COLOR_RED    = [168,  66,  28, 255];
my $COLOR_ORANGE = [225, 138,  50, 255];

# A reusable "sidebar item" component. Just a Perl sub.
sub sidebar_item ($index) {
	Clay__OpenElementWithId( Clay_GetElementIdWithIndex("SidebarItem", $index) );
	Clay__ConfigureOpenElement({
		layout          => { sizing => { width => sizing_grow(), height => sizing_fixed(50) } },
		backgroundColor => $COLOR_ORANGE,
	});
	Clay__CloseElement();
}

my $ctx = Clay_Initialize(
	Clay_MinMemorySize(),
	{ width => 1024, height => 768 },
	sub ($err, $userdata) { warn "Clay error: $err->{errorText}\n" },
);

Clay_SetMeasureTextFunction(sub ($text, $config, $userdata) {
	my $fs = $config->{fontSize} || 16;
	return { width => length($text) * $fs * 0.55, height => $fs };
});

sub build_layout () {
	Clay__OpenElementWithId( Clay_GetElementId("OuterContainer") );
	Clay__ConfigureOpenElement({
		layout => {
			sizing   => { width => sizing_grow(), height => sizing_grow() },
			padding  => padding_all(16),
			childGap => 16,
		},
		backgroundColor => [250, 250, 255, 255],
	});

		Clay__OpenElementWithId( Clay_GetElementId("SideBar") );
		Clay__ConfigureOpenElement({
			layout => {
				layoutDirection => CLAY_TOP_TO_BOTTOM,
				sizing          => { width  => sizing_fixed(300), height => sizing_grow() },
				padding         => padding_all(16),
				childGap        => 16,
			},
			backgroundColor => $COLOR_LIGHT,
		});

			Clay__OpenElementWithId( Clay_GetElementId("ProfilePictureOuter") );
			Clay__ConfigureOpenElement({
				layout => {
					sizing         => { width => sizing_grow() },
					padding        => padding_all(16),
					childGap       => 16,
					childAlignment => { x => CLAY_ALIGN_X_LEFT, y => CLAY_ALIGN_Y_CENTER },
				},
				backgroundColor => $COLOR_RED,
			});
				Clay__OpenElementWithId( Clay_GetElementId("ProfilePicture") );
				Clay__ConfigureOpenElement({
					layout => { sizing => { width => sizing_fixed(60), height => sizing_fixed(60) } },
				});
				Clay__CloseElement();

				Clay__OpenTextElement(
					"Clay - UI Library",
					{ fontSize => 24, textColor => [255, 255, 255, 255] },
				);
			Clay__CloseElement();

			sidebar_item($_) for 0 .. 4;

		Clay__CloseElement();

		Clay__OpenElementWithId( Clay_GetElementId("MainContent") );
		Clay__ConfigureOpenElement({
			layout          => { sizing => { width => sizing_grow(), height => sizing_grow() } },
			backgroundColor => $COLOR_LIGHT,
		});
		Clay__CloseElement();

	Clay__CloseElement();
}

# First frame: build geometry. We need this before pointer interaction
# can detect anything.
Clay_BeginLayout();
build_layout();
my $frame1 = Clay_EndLayout(0);
printf "Frame 1: %d render commands\n", scalar @$frame1;

# Second frame: simulate a pointer hover over the third sidebar item.
Clay_SetPointerState({ x => 160, y => 320 }, 0);
Clay_BeginLayout();
build_layout();
my $frame2 = Clay_EndLayout(0);

my @over = @{ Clay_GetPointerOverIds() };
printf "Frame 2: %d elements under pointer\n", scalar @over;
# Element ids carry the string they were made from; an id made with an
# index (Clay_GetElementIdWithIndex) keeps that index in offset. The first
# id is Clay's own root element, which wraps every layout.
for my $id (@over) {
	printf "  %s%s\n", $id->{stringId}, $id->{offset} ? "[$id->{offset}]" : '';
}

# Print the per-type breakdown so the reader can see what the renderer
# would have to handle.
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
