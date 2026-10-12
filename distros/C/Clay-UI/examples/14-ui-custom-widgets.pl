#!/usr/bin/env perl

# 14-ui-custom-widgets.pl - Writing your own Clay::UI widget classes.
#
# Builds a small profile card from three home-made widget classes (an
# image, a card with a decoration of its own and a text field), aligns
# the labels of a form with a sizing group, and then shows what happens
# when things go wrong: missing or reserved ids, invalid attributes and a
# tree that does not fit max_element_count. Prints a summary to stdout.
#
# Shows:
#   - a widget class that adds its own keys (image, aspect ratio, overlay
#     colour) to its element declaration, checked against Clay's schema
#   - a widget field whose setter tells renderers about the change
#   - a widget with an internal child that its users never see
#   - form labels in separate rows sharing one width (sizing group)
#   - a widget role that requires an id, and the ids Clay::UI derives
#     for widgets without one
#   - a custom measure_text, and max_element_count with the default and
#     a custom error_handler (error types by name)
#   - the error messages for invalid attributes, and the error object
#     check_struct dies with
#
# Features: Clay::UI::Box, Clay::UI::Text, contribute_, to_config, image, image_data, aspect_ratio, overlay_color, check_struct, Clay::XS::StructError, mark_changed, current_revision, add_internal_children, internal_children, floating, attach_to, attach_points, CLAY_ATTACH_TO_PARENT, layout_children, children, clear_children, width_group, Clay::UI::Role::Core::Stateful, resolve_id, Clay_GetElementId, Clay_GetElementData, bounding_box, measure_text, error_handler, max_element_count, errorType, errorText, CLAY_ERROR_TYPE_UNBALANCED_OPEN_CLOSE, path, expected, CLAY_RENDER_COMMAND_TYPE_IMAGE, CLAY_RENDER_COMMAND_TYPE_OVERLAY_COLOR_START, CLAY_RENDER_COMMAND_TYPE_OVERLAY_COLOR_END, CLAY_RENDER_COMMAND_TYPE_TEXT
#
# Requires: nothing beyond this distribution.
#
# Run with:
#
#     perl -Ilib -Iblib/lib -Iblib/arch examples/14-ui-custom-widgets.pl

use v5.22;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Object::Pad 0.800;
use Scalar::Util qw(refaddr);

use Clay::XS qw(:all);
use Clay::UI;
use Clay::UI::Box;
use Clay::UI::Revision qw(current_revision);
use Clay::UI::Role::Core::Element;
use Clay::UI::Role::Core::Stateful;
use Clay::UI::Role::Layout::HasLayout;
use Clay::UI::Role::Style::HasCornerRadius;
use Clay::UI::Text;

# Clay::UI ships roles, not classes: each widget class is one line that
# composes the role it needs (see Clay::Manual, GETTING STARTED).
class My::Box  :strict(params) :does(Clay::UI::Box)  {}
class My::Text :strict(params) :does(Clay::UI::Text) {}

# ---- An image widget with declaration keys of its own ----
#
# Clay::UI builds an element's declaration by calling every method of the
# widget whose name starts with contribute_ (see Clay::UI::Role::Core::
# Element, to_config). The roles bring contributors for layout, colours,
# borders and so on; a class adds Clay keys no role covers - here image,
# aspect_ratio and overlay_color - with a contributor of its own. Keys
# are snake_case; Clay::UI converts them to Clay's camelCase.
#
# The values are checked where they are set, with Clay::XS's check_struct,
# so a bad value dies in the constructor or setter, not in a later frame.
# See Clay::Manual, WIDGETS, "Writing your own widget class".

class Profile::Image :strict(params)
	:does(Clay::UI::Role::Core::Element)
	:does(Clay::UI::Role::Layout::HasLayout)
	:does(Clay::UI::Role::Style::HasCornerRadius)
{
	use Clay::XS qw(check_struct);

	# imageData is an opaque number Clay hands back in the IMAGE render
	# command; a renderer uses it to find the picture (here: a texture id).
	field $texture_id   :param;
	field $aspect_ratio :param = 1;
	field $dimmed       :param = 0;

	my $DIM_COLOR = { r => 0, g => 0, b => 0, a => 120 };

	ADJUST {
		$self->_check_texture_id($texture_id);
		check_struct('Clay_AspectRatioElementConfig', { aspectRatio => $aspect_ratio }, 'aspect_ratio');
	}

	method _check_texture_id ($id) {
		check_struct('Clay_ImageElementConfig', { imageData => $id }, 'texture_id');
		return;
	}

	# Writers of a widget's own fields call mark_changed, which bumps the
	# revision, so a renderer that skips unchanged frames draws the next one.
	method texture_id (@new) {
		return $texture_id unless @new;
		$self->_check_texture_id($new[0]);
		$texture_id = $new[0];
		$self->mark_changed;
		return $texture_id;
	}

	method dimmed (@new) {
		return $dimmed unless @new;
		$dimmed = $new[0] ? 1 : 0;
		$self->mark_changed;
		return $dimmed;
	}

	method contribute_image ($config) {
		$config->{image}        = { image_data => $texture_id };
		$config->{aspect_ratio} = { aspect_ratio => $aspect_ratio };
		# Clay tints the element and everything inside it with this colour.
		$config->{overlay_color} = $DIM_COLOR if $dimmed;
		return;
	}
}

# ---- A card with an internal child ----
#
# The ribbon is part of the card's look, not of its content: it is added
# with add_internal_children, so children, add_child, clear_children and
# the other Container methods never see it. The layout pass lays out
# layout_children: the children first, then the internal children.

class Profile::Card :strict(params) :does(Clay::UI::Box) {
	use Clay::XS qw(padding_all CLAY_ATTACH_TO_PARENT CLAY_ATTACH_POINT_RIGHT_TOP);

	ADJUST :params (:$ribbon) {
		my $badge = My::Box->new(
			layout   => { padding => padding_all(3) },
			floating => {
				attach_to     => CLAY_ATTACH_TO_PARENT,
				attach_points => { element => CLAY_ATTACH_POINT_RIGHT_TOP, parent => CLAY_ATTACH_POINT_RIGHT_TOP },
			},
			background_color => [200, 40, 40, 255],
		);
		$badge->add_child(My::Text->new(text => $ribbon, font_size => 10, text_color => [255, 255, 255, 255]));
		$self->add_internal_children($badge);
	}
}

# ---- A widget that requires an id ----
#
# Composing Clay::UI::Role::Core::Stateful makes the constructor die
# without an id. Use it for widgets whose Clay state is looked up by
# element id (scroll containers compose it for that reason), or that
# your own code finds by id.

class Profile::TextField :strict(params)
	:does(Clay::UI::Box)
	:does(Clay::UI::Role::Core::Stateful)
{}

# ---- Build the tree ----

my $LABEL_GROUP = 1;    # any id in 0 .. 2**20 - 1; 0 means "no group"

sub label_cell ($text) {
	# Each label sits in a box of the same width group: Clay sizes every
	# element of a group to the widest one, across rows. See Clay::Manual,
	# THE LAYOUT MODEL, "Sizing groups".
	my $cell = My::Box->new(width_group => $LABEL_GROUP, layout => { padding => { right => 8 } });
	$cell->add_child(My::Text->new(text => $text, font_size => 14));
	return $cell;
}

sub form_row ($label, $field_id, $value) {
	my $row   = My::Box->new(layout => { child_alignment => { y => CLAY_ALIGN_Y_CENTER } });
	my $field = Profile::TextField->new(
		id               => $field_id,
		layout           => { sizing => { width => sizing_fixed(160) }, padding => padding_all(4) },
		background_color => [255, 255, 255, 255],
		border_color     => [150, 150, 160, 255],
		border_width     => 1,
	);
	$field->add_child(My::Text->new(text => $value, font_size => 14));
	$row->add_child(label_cell($label), $field);
	return $row;
}

my $avatar = Profile::Image->new(
	id            => 'avatar',
	texture_id    => 42,
	aspect_ratio  => 4 / 3,
	layout        => { sizing => { width => sizing_fixed(96) } },
	corner_radius => 6,
);

my $form = My::Box->new(
	id     => 'form',
	layout => { layout_direction => CLAY_TOP_TO_BOTTOM, child_gap => 6 },
);
my @rows = (
	form_row('Name',           'field-name',  'Ada Lovelace'),
	form_row('E-mail address', 'field-email', 'ada@example.org'),
	form_row('City',           'field-city',  'London'),
);
$form->add_child(@rows);

my $card = Profile::Card->new(
	id               => 'card',
	ribbon           => 'NEW',
	layout           => { padding => padding_all(12), child_gap => 12 },
	background_color => [235, 238, 245, 255],
);
$card->add_child($avatar, $form);

my $page = My::Box->new(
	id     => 'page',
	layout => { sizing => { width => sizing_grow(), height => sizing_grow() }, padding => padding_all(10) },
);
$page->add_child($card);

# ---- Custom measure_text ----
#
# Clay asks measure_text for the size of each word it lays out (and caches
# the answers). This one gives narrow letters half a width, so labels of
# the same length still differ, and counts how often Clay asked.

my $measure_calls = 0;

sub measure_text ($text, $config, $userdata) {
	$measure_calls++;
	my $size   = $config->{fontSize} || 16;
	my $narrow = () = $text =~ /[ilj.,:;!|' ]/g;
	my $wide   = length($text) - $narrow;
	return { width => ($wide * 0.6 + $narrow * 0.3) * $size, height => $size };
}

my $ui = Clay::UI->new(width => 420, height => 200, root => $page, measure_text => \&measure_text);
my $commands = $ui->render;

sub box_of ($widget) {
	my $box = $ui->bounding_box($widget);
	return sprintf '%gx%g at (%g, %g)', @{$box}{qw(width height x y)};
}

sub heading ($title) {
	say "\n$title";
	return;
}

# ---- 1. The image widget's own declaration keys ----

heading('1. Profile::Image adds image, aspect_ratio and overlay_color');
my ($image_command) = grep { $_->{commandType} == CLAY_RENDER_COMMAND_TYPE_IMAGE } @$commands;
printf "  IMAGE command: imageData=%d, %s\n", $image_command->{renderData}{imageData}, box_of($avatar);
say '  (96 wide with aspect ratio 4:3, so Clay made it 72 high)';

# to_config returns the declaration the contributors built, before the
# layout pass turns its snake_case keys into Clay's camelCase.
my $avatar_config = $avatar->to_config;
printf "  to_config keys: %s\n", join ', ', sort keys %$avatar_config;
printf "  to_config image: { image_data => %d }\n", $avatar_config->{image}{image_data};

my $revision = current_revision();
$avatar->dimmed(1);
printf "  dimmed(1) bumped the revision: %s\n", current_revision() > $revision ? 'yes' : 'no';
my @overlay = grep {
	$_->{commandType} == CLAY_RENDER_COMMAND_TYPE_OVERLAY_COLOR_START || $_->{commandType} == CLAY_RENDER_COMMAND_TYPE_OVERLAY_COLOR_END
} @{ $ui->render };
printf "  next frame has %d overlay commands (start and end around the image)\n", scalar @overlay;

# ---- 2. Internal children ----

heading('2. Profile::Card keeps its ribbon as an internal child');
printf "  children: %d, internal_children: %d, layout_children: %d\n",
	scalar @{ $card->children }, scalar @{ $card->internal_children }, scalar @{ $card->layout_children };
my $ribbon = $card->internal_children->[0];
printf "  ribbon: %s (floats at the card's top right corner)\n", box_of($ribbon);
my $spare = Profile::Card->new(ribbon => 'SALE');
$spare->add_child(My::Box->new);
$spare->clear_children;
printf "  another card after clear_children: %d children, %d internal child\n",
	scalar @{ $spare->children }, scalar @{ $spare->internal_children };

# ---- 3. Sizing group ----

heading('3. Form labels share one width through width_group');
for my $row (@rows) {
	my ($label_cell, $field) = @{ $row->children };
	printf "  %-12s label %-22s field starts at x=%g\n", $field->id, box_of($label_cell), $ui->bounding_box($field)->{x};
}

# ---- 4. Ids ----
#
# A widget without an id gets one derived from its position below the
# nearest ancestor that has one; resolve_id builds it from that ancestor's
# id and the child indices on the way down. This helper finds both with
# the public tree methods; Clay finds the element under the derived id,
# at the place bounding_box reports for the widget.

sub derived_id_of ($widget) {
	my @indices;
	my $node = $widget;
	while (!defined $node->id && defined $node->parent) {
		my $siblings = $node->parent->layout_children;
		my ($index)  = grep { refaddr($siblings->[$_]) == refaddr($node) } 0 .. $#$siblings;
		unshift @indices, $index;
		$node = $node->parent;
	}
	return $widget->resolve_id($node->id // '', \@indices);
}

heading('4. Ids');
my $second_label = $rows[1]->children->[0];
my $derived      = derived_id_of($second_label);
my $element      = Clay_GetElementData(Clay_GetElementId($derived));
printf "  second label cell has no id; Clay::UI derives '%s'\n", $derived;
printf "  Clay_GetElementData finds it at y=%g, bounding_box says y=%g\n",
	$element->{boundingBox}{y}, $ui->bounding_box($second_label)->{y};
say '  (a derived id changes when the widget moves; give an id to widgets whose';
say '  Clay state must follow them, like scroll containers)';

sub first_line_of_error ($code) {
	return 'no error' if eval { $code->(); 1 };
	my ($line) = split /\n/, "$@";
	$line =~ s/ at \S+ line \d+\.?\z//;
	return $line;
}

printf "  Stateful without id: %s\n", first_line_of_error(sub { Profile::TextField->new });
printf "  reserved id:         %s\n", first_line_of_error(sub { My::Box->new(id => 'anon:mine') });

# ---- 5. Invalid attributes ----
#
# Every attribute is checked where it is set, in the constructor or in the
# accessor, and the message names the attribute and the key path.

heading('5. Invalid attributes die where they are set');
printf "  - %s\n", first_line_of_error(sub { My::Box->new(layout => { child_gapp => 4 }) });
printf "  - %s\n", first_line_of_error(sub { My::Box->new(background_color => [255, 0, 0]) });
printf "  - %s\n", first_line_of_error(sub { $form->layout({ padding => { left => -8 } }) });
printf "  - %s\n", first_line_of_error(sub { My::Box->new(width_group => 2**20) });
printf "  - %s\n", first_line_of_error(sub { Profile::Image->new(texture_id => -1) });
printf "  - %s\n", first_line_of_error(sub { My::Box->new(colour => [0, 0, 0, 255]) });

# check_struct dies with a Clay::XS::StructError object, not a string, so
# a widget class that checks with it lets its callers inspect the error.
my $struct_error = do {
	local $@;
	eval { Profile::Image->new(texture_id => -1); 1 } ? undef : $@;
};
die "Profile::Image accepted texture_id -1\n" unless ref $struct_error && $struct_error->isa('Clay::XS::StructError');
printf "  texture_id -1 died with a %s: path %s, expected %s\n",
	ref $struct_error, join(' -> ', @{ $struct_error->path }), $struct_error->expected;

# ---- 6. max_element_count and error_handler ----
#
# Each widget is one Clay element, but two of max_element_count are not
# available to widgets: Clay_BeginLayout opens Clay's own root element,
# and Clay refuses to open an element when only one free slot is left.
# With max_element_count 6, four widgets fit.
#
# Clay reports no error when it refuses an element: it sets a flag and
# then ignores every later open and close call of the frame. The elements
# it did open are never closed, so the error Clay_EndLayout reports is
# "There were still open layout elements ..."
# (CLAY_ERROR_TYPE_UNBALANCED_OPEN_CLOSE), and the only render command
# is a TEXT command with Clay's own capacity message. The default
# error_handler makes render die; Clay::UI then replaces that misleading
# error with one that names max_element_count. A handler of your own
# receives Clay's error data unchanged (errorType and errorText).

heading('6. max_element_count and error_handler');

# errorType is a number; map the CLAY_ERROR_TYPE_* constants to names.
my %ERROR_TYPE_NAME = map { (Clay::XS->can($_)->() => s/^CLAY_ERROR_TYPE_//r) }
	grep { /^CLAY_ERROR_TYPE_/ } @Clay::XS::EXPORT_OK;

sub boxes_tree ($count) {
	my $root = My::Box->new(id => 'root');
	$root->add_child(map { My::Box->new } 2 .. $count);
	return $root;
}

my $fitting_ui = Clay::UI->new(width => 100, height => 100, root => boxes_tree(4), max_element_count => 6);
$fitting_ui->render;
say '  4 widgets with max_element_count 6: render succeeds';

my $strict_ui = Clay::UI->new(width => 100, height => 100, root => boxes_tree(5), max_element_count => 6);
printf "  5 widgets, default handler: %s\n", first_line_of_error(sub { $strict_ui->render });

my @clay_errors;
my $lenient_ui = Clay::UI->new(
	width             => 100,
	height            => 100,
	root              => boxes_tree(5),
	max_element_count => 6,
	error_handler     => sub ($error, $userdata) { push @clay_errors, $error },
);
my $kept = $lenient_ui->render;
printf "  5 widgets, own handler: Clay reported %d error(s):\n", scalar @clay_errors;
for my $error (@clay_errors) {
	my $note = $error->{errorType} == CLAY_ERROR_TYPE_UNBALANCED_OPEN_CLOSE ? ' (here: the tree did not fit)' : '';
	printf "    %s%s: %s\n", $ERROR_TYPE_NAME{ $error->{errorType} }, $note, $error->{errorText};
}
printf "  render returned %d command(s):\n", scalar @$kept;
printf "    %s \"%s\"\n", ($_->{commandType} == CLAY_RENDER_COMMAND_TYPE_TEXT ? 'TEXT' : $_->{commandType}),
	$_->{renderData}{stringContents} // '' for @$kept;

heading('7. measure_text');
printf "  Clay called measure_text %d times for the profile card frames\n", $measure_calls;
