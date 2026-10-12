use v5.22;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Test2::V0;

use lib "t/lib";

use Clay::XS qw(:all);
use Clay::UI;
use Clay::UI::Test::Box;
use Clay::UI::Test::Text;

use Object::Pad;
use Clay::UI::Role::Core::Container;
use Clay::UI::Role::Core::Stateful;
use Clay::UI::Role::Interaction::Pressable;
use Clay::UI::Role::Layout::HasScroll;
use Clay::UI::Role::Layout::HasLayout;
use Clay::UI::Role::Style::HasBackground;

class TestScrollBox :does(Clay::UI::Role::Layout::HasScroll)
                    :does(Clay::UI::Role::Layout::HasLayout)
{}

# Clips without composing HasScroll: not a scroll container.
class TestClipBox :does(Clay::UI::Role::Core::Container)
                  :does(Clay::UI::Role::Layout::HasLayout)
{
	method contribute_clip ($config) {
		$config->{clip} = { vertical => 1 };
		return;
	}
}

class TestButton
	:does(Clay::UI::Role::Core::Stateful)
	:does(Clay::UI::Role::Interaction::Pressable)
	:does(Clay::UI::Role::Layout::HasLayout)
	:does(Clay::UI::Role::Style::HasBackground)
{}

my @errors;
my $error_handler = sub ($err, $userdata) { push @errors, $err };
my $measure_text  = sub ($text, $config, $userdata) {
	return { width => length($text) * ($config->{fontSize} // 16), height => $config->{fontSize} // 16 };
};

sub make_ui ($root) {
	return Clay::UI->new(
		width         => 400,
		height        => 300,
		root          => $root,
		error_handler => $error_handler,
		measure_text  => $measure_text,
	);
}

# -----------------------------------------------------------------------------
# Box composes every property mixin; declaration round-trips through Clay.
# -----------------------------------------------------------------------------

subtest 'Box with all styling slices' => sub {
	@errors = ();
	my $ui = make_ui(
		Clay::UI::Test::Box->new(
			id               => 'styled',
			layout           => {
				sizing  => { width => sizing_fixed(200), height => sizing_fixed(100) },
				padding => { left => 8, right => 8, top => 4, bottom => 4 },
			},
			background_color => [40, 50, 60, 255],
			border_color     => [100, 100, 100, 255],
			border_width     => 1,
			corner_radius    => 4,
		),
	);
	my $cmds = $ui->render;

	is( scalar(@errors), 0, 'no Clay errors' );

	my ($rect) = grep { $_->{commandType} == CLAY_RENDER_COMMAND_TYPE_RECTANGLE } @$cmds;
	ok( defined $rect, 'rectangle emitted' );
	is( $rect->{renderData}{backgroundColor}{r}, 40, 'background r' );
	is( $rect->{renderData}{cornerRadius}{topLeft}, 4, 'corner expanded to four sides' );

	my ($border) = grep { $_->{commandType} == CLAY_RENDER_COMMAND_TYPE_BORDER } @$cmds;
	ok( defined $border, 'border emitted' );
	is( $border->{renderData}{width}{left}, 1, 'border width left' );
};

# -----------------------------------------------------------------------------
# Text leaf dispatches to Clay__OpenTextElement.
# -----------------------------------------------------------------------------

subtest 'Text inside a Box' => sub {
	@errors = ();
	my $wrapper = Clay::UI::Test::Box->new(
		id     => 'wrapper',
		layout => { sizing => { width => sizing_fixed(200), height => sizing_fixed(50) } },
	);
	$wrapper->add_child(
		Clay::UI::Test::Text->new(
			text       => 'hello',
			font_size  => 16,
			text_color => [255, 255, 255, 255],
		),
	);
	my $ui = make_ui($wrapper);
	my $cmds = $ui->render;

	is( scalar(@errors), 0, 'no Clay errors' );

	my ($txt) = grep { $_->{commandType} == CLAY_RENDER_COMMAND_TYPE_TEXT } @$cmds;
	ok( defined $txt, 'text command emitted' );
	is( $txt->{renderData}{textColor}{r}, 255, 'text color r' );
	is( $txt->{renderData}{fontSize}, 16, 'font size' );
};

# -----------------------------------------------------------------------------
# Stateful: HasScroll demands an id.
# -----------------------------------------------------------------------------

subtest 'HasScroll requires id' => sub {
	like(
		dies { TestScrollBox->new },
		qr/requires an explicit 'id'/,
		'missing id fails loud',
	);

	my $panel = TestScrollBox->new(
		id     => 'log',
		layout => { sizing => { width => sizing_grow(), height => sizing_fixed(100) } },
	);
	ok( defined $panel, 'with id constructs' );
};

# -----------------------------------------------------------------------------
# HasScroll emits a clip slice via its contribute_clip method.
# -----------------------------------------------------------------------------

subtest 'HasScroll emits scroll container' => sub {
	@errors = ();
	my $ui = make_ui(
		TestScrollBox->new(
			id     => 'log',
			layout => { sizing => { width => sizing_fixed(200), height => sizing_fixed(100) } },
		),
	);
	my $cmds = $ui->render;

	is( scalar(@errors), 0, 'no Clay errors' );

	# A scroll container emits SCISSOR_START + SCISSOR_END markers.
	my @scissors = grep {
		$_->{commandType} == CLAY_RENDER_COMMAND_TYPE_SCISSOR_START
	 || $_->{commandType} == CLAY_RENDER_COMMAND_TYPE_SCISSOR_END
	} @$cmds;
	is( scalar(@scissors), 2, 'scissor start + end emitted (proves clip slice landed)' );

	# Scroll container should now be queryable.
	my $data = Clay_GetScrollContainerData( Clay_GetElementId('log') );
	ok( $data->{found}, 'scroll container registered with Clay' );
};

# -----------------------------------------------------------------------------
# Pressable role: hover + click callback dispatch on a stateful widget.
# -----------------------------------------------------------------------------

subtest 'Pressable: hover-edge events, press events, live state readers' => sub {
	@errors = ();

	my @hover_start;
	my @hover_stop;
	my @press;
	my @release;

	my $button = TestButton->new(
		id               => 'btn',
		layout           => { sizing => { width => sizing_fixed(100), height => sizing_fixed(40) } },
		background_color => [70, 130, 200, 255],
	);
	$button->on('OnHoverStart',   sub ($e) { push @hover_start, $e->target });
	$button->on('OnHoverStopped', sub ($e) { push @hover_stop,  $e->target });
	$button->on('OnPress',        sub ($e) { push @press,   { x => $e->x, y => $e->y } });
	$button->on('OnRelease',      sub ($e) { push @release, { x => $e->x, y => $e->y } });

	my $ui = make_ui($button);

	# Frame 1: build geometry (no pointer state yet).
	$ui->render;
	$ui->render( pointer_state => { x => -100, y => -100, down => 0 } );

	@hover_start = ();
	@hover_stop  = ();
	@press       = ();

	is( $button->is_hovered, 0, 'pointer not over yet => is_hovered false' );
	is( $button->is_pressed, 0, '...and is_pressed false' );

	# Frame 2: pointer hovering, not pressed. Edge-trigger: OnHoverStart fires.
	$ui->render( pointer_state => { x => 50, y => 20, down => 0 } );

	is( scalar(@hover_start), 1, 'OnHoverStart fired on entry' );
	is( scalar(@hover_stop),  0, 'OnHoverStopped not yet' );
	is( $button->is_hovered,  1, 'is_hovered true' );
	is( $button->is_pressed,  0, 'is_pressed still false (not pressed)' );

	# Frame 3: still hovering => no new edge event.
	$ui->render( pointer_state => { x => 51, y => 21, down => 0 } );

	is( scalar(@hover_start), 1, 'OnHoverStart edge-triggered: no refire while still over' );

	# Frame 4: pointer leaves => OnHoverStopped fires once.
	$ui->render( pointer_state => { x => -100, y => -100, down => 0 } );

	is( scalar(@hover_stop), 1, 'OnHoverStopped fired on exit' );
	is( $button->is_hovered, 0, 'is_hovered back to false' );

	# Frame 5: enter again, this time pressed: OnPress fires in the frame
	# that first reports the pointer down.
	$ui->render( pointer_state => { x => 50, y => 20, down => 1 } );
	is( scalar(@press),  1,  'OnPress fired in the first down-frame' );
	is( $button->is_pressed, 1, 'is_pressed true while held' );

	# Holding => no refire on subsequent frames (still PRESSED, not PRESSED_THIS_FRAME).
	$ui->render( pointer_state => { x => 50, y => 20, down => 1 } );
	is( scalar(@press),   1, 'OnPress edge-triggered: no refire while held' );
	is( scalar(@release), 0, 'OnRelease not yet (still held)' );

	# Release the pointer while over the button: OnRelease fires in the
	# frame that first reports the pointer up.
	$ui->render( pointer_state => { x => 50, y => 20, down => 0 } );
	is( scalar(@release),    1, 'OnRelease fired in the first up-frame' );
	is( $button->is_pressed, 0, 'is_pressed back to false after release' );

	# Hold still => no refire.
	$ui->render( pointer_state => { x => 50, y => 20, down => 0 } );
	is( scalar(@release), 1, 'OnRelease edge-triggered: no refire while idle' );

	# Press, then drag off-element and release: OnRelease must NOT fire,
	# because the release does not happen over the widget the press started
	# on. is_pressed drops to 0 once the pointer leaves.
	$ui->render( pointer_state => { x => 50, y => 20, down => 1 } );
	$ui->render( pointer_state => { x => 50, y => 20, down => 1 } );
	is( scalar(@press), 2, 'second press registered once' );

	$ui->render( pointer_state => { x => -100, y => -100, down => 1 } );  # drag off, still down
	is( $button->is_pressed, 0, 'is_pressed reset once pointer leaves the widget' );

	$ui->render( pointer_state => { x => -100, y => -100, down => 0 } );  # release off-element
	is( scalar(@release), 1, 'no OnRelease when release happens off-element (click-cancel)' );
};

# -----------------------------------------------------------------------------
# A Text leaf can be the root of a Clay::UI.
# -----------------------------------------------------------------------------

subtest 'bare Text at root' => sub {
	@errors = ();
	my $ui = make_ui(Clay::UI::Test::Text->new( text => 'standalone' ));
	my $cmds = $ui->render;

	is( scalar(@errors), 0, 'no Clay errors' );
	my ($txt) = grep { $_->{commandType} == CLAY_RENDER_COMMAND_TYPE_TEXT } @$cmds;
	is( $txt->{renderData}{stringContents}, 'standalone', 'the root text leaf is rendered' );
};

# -----------------------------------------------------------------------------
# Text attributes are mutable post-construction: writes are reflected on the
# next text_config.
# -----------------------------------------------------------------------------

subtest 'Text attributes are mutable' => sub {
	my $label = Clay::UI::Test::Text->new( text => 'hi', font_size => 16 );

	$label->text('updated');
	$label->font_size(24);
	$label->text_color([255, 0, 0, 255]);
	$label->letter_spacing(2);

	is( $label->text, 'updated', 'text accessor reflects write' );

	my $cfg = $label->text_config;
	is( $cfg->{font_size},      24,              'text_config sees new font_size' );
	is( $cfg->{text_color},     [255, 0, 0, 255], 'text_config sees new text_color' );
	is( $cfg->{letter_spacing}, 2,               'text_config sees new letter_spacing' );
};

# -----------------------------------------------------------------------------
# HasScroll containers scroll: render feeds wheel input to Clay and the
# walker positions the children at Clay's scroll offset. An explicit
# child_offset takes over (manual scrolling).
# -----------------------------------------------------------------------------

subtest 'HasScroll content moves with scroll input' => sub {
	@errors = ();
	my $panel = TestScrollBox->new(
		id     => 'log',
		layout => { sizing => { width => sizing_fixed(100), height => sizing_fixed(50) }, layout_direction => CLAY_TOP_TO_BOTTOM },
	);
	my @rows = map {
		Clay::UI::Test::Box->new(id => "row$_",
			layout => { sizing => { width => sizing_fixed(100), height => sizing_fixed(20) } })
	} 0 .. 5;
	$panel->add_child(@rows);
	my $ui = make_ui($panel);
	my $row0_y = sub { Clay_GetElementData(Clay_GetElementId('row0'))->{boundingBox}{y} };

	$ui->render;
	$ui->render(pointer_state => { x => 50, y => 25, down => 0 });
	is( $row0_y->(), 0, 'content starts unscrolled' );
	$ui->render(pointer_state => { x => 50, y => 25, down => 0 }, scroll_delta => { x => 0, y => -1.5 });
	is( $row0_y->(), -15, 'a wheel delta moves the children' );

	$panel->child_offset({ x => 0, y => -40 });
	$ui->render(pointer_state => { x => 50, y => 25, down => 0 });
	is( $row0_y->(), -40, 'an explicit child_offset wins' );
	is( scalar(@errors), 0, 'no Clay errors' );
};

subtest 'a clip slice without HasScroll clips but does not scroll' => sub {
	@errors = ();
	my $panel = TestClipBox->new(
		id     => 'plain',
		layout => { sizing => { width => sizing_fixed(100), height => sizing_fixed(50) }, layout_direction => CLAY_TOP_TO_BOTTOM },
	);
	$panel->add_child(map {
		Clay::UI::Test::Box->new(id => "line$_",
			layout => { sizing => { width => sizing_fixed(100), height => sizing_fixed(20) } })
	} 0 .. 5);
	my $ui = make_ui($panel);
	my $line0_y = sub { Clay_GetElementData(Clay_GetElementId('line0'))->{boundingBox}{y} };

	$ui->render;
	$ui->render(pointer_state => { x => 50, y => 25, down => 0 });
	my $cmds = $ui->render(pointer_state => { x => 50, y => 25, down => 0 }, scroll_delta => { x => 0, y => -1.5 });
	ok( (grep { $_->{commandType} == CLAY_RENDER_COMMAND_TYPE_SCISSOR_START } @$cmds), 'the children are clipped' );
	is( $line0_y->(), 0, 'a wheel delta does not move them' );
	is( scalar(@errors), 0, 'no Clay errors' );
};

# -----------------------------------------------------------------------------
# HasScroll flags are mutable: writes are reflected in the next clip slice.
# -----------------------------------------------------------------------------

subtest 'HasScroll attributes are mutable' => sub {
	my $box = TestScrollBox->new( id => 'scroller', horizontal => 0, vertical => 1 );

	$box->horizontal(1);
	$box->vertical(0);
	$box->child_offset({ x => 10, y => 20 });

	my $cfg = $box->to_config;
	is( $cfg->{clip}{horizontal},   1, 'clip sees new horizontal flag' );
	is( $cfg->{clip}{vertical},     0, 'clip sees new vertical flag' );
	is( $cfg->{clip}{child_offset}, { x => 10, y => 20 }, 'clip sees new child_offset' );
};

subtest 'child_count and child_at read the children without copying them' => sub {
	my $box  = Clay::UI::Test::Box->new(id => 'box');
	my @kids = map { Clay::UI::Test::Box->new(id => "kid$_") } 0 .. 2;
	$box->add_child(@kids);
	$box->add_internal_children(Clay::UI::Test::Box->new(id => 'helper'));
	is( $box->child_count, scalar @{ $box->children }, 'child_count is the number of children, internal ones left out' );
	is( [ map { Scalar::Util::refaddr($box->child_at($_)) } 0 .. 2 ], [ map { Scalar::Util::refaddr($_) } @{ $box->children } ],
		'child_at agrees with children' );
	is( $box->child_at(3), undef, 'an index past the last child gives undef' );
	for my $bad (-1, 1.5, '01', undef, [0]) {
		like( dies { $box->child_at($bad) }, qr/^Clay::UI: child_at takes an index, got /,
			'child_at dies for ' . ( ref $bad || $bad // 'undef' ) );
	}
};

subtest 'child methods reject malformed offsets, ids, predicates and widgets' => sub {
	my $box  = Clay::UI::Test::Box->new(id => 'box');
	my $kept = Clay::UI::Test::Box->new(id => 'kept');
	$box->add_child($kept);
	for my $offset ('abc', 0.5, -1, '01', undef, []) {
		like( dies { $box->insert_children($offset, Clay::UI::Test::Box->new) }, qr/^Clay::UI: child offset \S+ out of range 0\.\.1/,
			'insert_children dies for offset ' . ( ref $offset || $offset // 'undef' ) );
	}
	like( dies { $box->remove_child_with_id(undef) }, qr/^Clay::UI: remove_child_with_id takes an id string, got undef/,
		'remove_child_with_id dies for undef' );
	like( dies { $box->remove_child_with_id(['kept']) }, qr/^Clay::UI: remove_child_with_id takes an id string, got ARRAY/,
		'and for a reference' );
	like( dies { $box->remove_children_with('kept') }, qr/^Clay::UI: remove_children_with takes a code reference, got 'kept'/,
		'remove_children_with dies for anything but a code reference' );
	like( dies { $box->get_children_with(undef) }, qr/^Clay::UI: get_children_with takes a code reference, got undef/,
		'so does get_children_with' );
	like( dies { $box->remove_internal_children('kept') }, qr/^Clay::UI: remove_internal_children takes widgets, got 'kept'/,
		'remove_internal_children dies for anything but widgets' );
	is( [ map { Scalar::Util::refaddr($_) } @{ $box->children } ], [ Scalar::Util::refaddr($kept) ], 'nothing changed' );
};

done_testing;
