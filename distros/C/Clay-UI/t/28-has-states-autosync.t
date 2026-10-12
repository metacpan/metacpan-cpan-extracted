use v5.22;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Test2::V0;

use lib "t/lib";

use Clay::XS qw(:all);
use Object::Pad 0.800;

use Clay::UI;
use Clay::UI::Test::Box;
use Clay::UI::Role::Core::Element;
use Clay::UI::Role::Style::HasStates;
use Clay::UI::Role::Interaction::Hoverable;
use Clay::UI::Role::Interaction::Pressable;
use Clay::UI::Role::Interaction::Focusable;
use Clay::UI::Role::Layout::HasLayout;

# -----------------------------------------------------------------------------
# Widget composing every interaction role, and HasStates explicitly:
# 'hovered', 'pressed', and 'focused' are derived states - answered live
# from the interaction tracker and the UI's focus, never stored.
# -----------------------------------------------------------------------------

class TestStateWidget
	:does(Clay::UI::Role::Core::Element)
	:does(Clay::UI::Role::Layout::HasLayout)
	:does(Clay::UI::Role::Style::HasStates)
	:does(Clay::UI::Role::Interaction::Pressable)
	:does(Clay::UI::Role::Interaction::Focusable)
{}

# Same shape, no explicit HasStates composition: Hoverable, Pressable, and
# Focusable each :does(HasStates), so widgets composing them get the state
# set transitively.
class TestImplicitWidget
	:does(Clay::UI::Role::Core::Element)
	:does(Clay::UI::Role::Layout::HasLayout)
	:does(Clay::UI::Role::Interaction::Pressable)
	:does(Clay::UI::Role::Interaction::Focusable)
{}

sub make_ui ($child) {
	my $root = Clay::UI::Test::Box->new(id => 'root');
	$root->add_child($child);
	return Clay::UI->new(
		width        => 400,
		height       => 300,
		root         => $root,
		measure_text => sub ($, $, $) { return { width => 0, height => 0 } },
	);
}

subtest 'hover transitions sync into states()' => sub {
	my $w = TestStateWidget->new(
		id     => 'hov',
		layout => { sizing => { width => sizing_fixed(100), height => sizing_fixed(40) } },
	);
	my $ui = make_ui($w);

	$ui->render;
	$ui->render(pointer_state => { x => -100, y => -100, down => 0 });

	is([sort $w->states], [], 'no states before pointer enters');

	$ui->render(pointer_state => { x => 50, y => 20, down => 0 });
	ok($w->has_state('hovered'), 'hovered added on pointer enter');

	$ui->render(pointer_state => { x => -100, y => -100, down => 0 });
	ok(!$w->has_state('hovered'), 'hovered removed on pointer leave');
};

subtest 'press transitions sync into states()' => sub {
	my $w = TestStateWidget->new(
		id     => 'prs',
		layout => { sizing => { width => sizing_fixed(100), height => sizing_fixed(40) } },
	);
	my $ui = make_ui($w);

	$ui->render;
	$ui->render(pointer_state => { x => -100, y => -100, down => 0 });

	# Enter pressed: the states follow in the same frame.
	$ui->render(pointer_state => { x => 50, y => 20, down => 1 });
	ok($w->has_state('hovered'), 'hovered set while pressed');
	ok($w->has_state('pressed'), 'pressed added in the first down-frame');

	# Release: cleared in the first up-frame.
	$ui->render(pointer_state => { x => 50, y => 20, down => 0 });
	ok(!$w->has_state('pressed'), 'pressed cleared after release');
	ok($w->has_state('hovered'),  'hovered still active (still over widget)');
};

subtest 'pointer leaves while pressed: both pressed and hovered clear' => sub {
	my $w = TestStateWidget->new(
		id     => 'drag',
		layout => { sizing => { width => sizing_fixed(100), height => sizing_fixed(40) } },
	);
	my $ui = make_ui($w);

	$ui->render;
	$ui->render(pointer_state => { x => -100, y => -100, down => 0 });

	$ui->render(pointer_state => { x => 50, y => 20, down => 1 });
	$ui->render(pointer_state => { x => 50, y => 20, down => 1 });
	ok($w->has_state('pressed'), 'pressed before drag-off');

	# Drag off while still held.
	$ui->render(pointer_state => { x => -100, y => -100, down => 1 });
	ok(!$w->has_state('pressed'), 'pressed cleared when pointer leaves while held');
	ok(!$w->has_state('hovered'), 'hovered cleared when pointer leaves');
};

subtest 'focus transitions sync into states() atomically with OnFocus/OnBlur' => sub {
	my $w = TestStateWidget->new(
		id     => 'foc',
		layout => { sizing => { width => sizing_fixed(100), height => sizing_fixed(40) } },
	);
	my $ui = make_ui($w);

	$ui->render;
	ok(!$w->has_state('focused'), 'no focused state before focus');

	# Atomicity: 'focused' must already be in states() by the time OnFocus
	# fires (and gone before OnBlur fires). State sync happens at the event
	# site in set_focused_widget, not at a later render boundary.
	my ($focused_at_event, $blurred_at_event);
	$w->on('OnFocus', sub ($) { $focused_at_event = $w->has_state('focused') });
	$w->on('OnBlur',  sub ($) { $blurred_at_event = $w->has_state('focused') });

	$ui->interaction->set_focused_widget($w);
	ok($w->has_state('focused'), 'focused added by set_focused_widget');
	ok($focused_at_event,        'has_state(focused) is true inside OnFocus handler');

	$ui->interaction->set_focused_widget(undef);
	ok(!$w->has_state('focused'),  'focused removed by blur');
	ok(defined $blurred_at_event,  'OnBlur handler ran');
	ok(!$blurred_at_event,         'has_state(focused) is false inside OnBlur handler');
};

subtest 'HasStates is composed transitively through interaction roles' => sub {
	my $w = TestImplicitWidget->new(
		id     => 'imp',
		layout => { sizing => { width => sizing_fixed(100), height => sizing_fixed(40) } },
	);
	my $ui = make_ui($w);

	ok($w->DOES('Clay::UI::Role::Style::HasStates'),
		'composing Pressable/Focusable drags HasStates in');
	ok($w->can('has_state'), 'has_state method is available');

	$ui->render;
	$ui->render(pointer_state => { x => -100, y => -100, down => 0 });
	$ui->render(pointer_state => { x => 50, y => 20, down => 0 });
	ok($w->has_state('hovered'), 'hovered state synced without explicit HasStates composition');
};

subtest 'all three states coexist on a fully interactive widget' => sub {
	my $w = TestStateWidget->new(
		id     => 'all',
		layout => { sizing => { width => sizing_fixed(100), height => sizing_fixed(40) } },
	);
	my $ui = make_ui($w);

	$ui->render;
	$ui->render(pointer_state => { x => -100, y => -100, down => 0 });

	$ui->interaction->set_focused_widget($w);
	$ui->render(pointer_state => { x => 50, y => 20, down => 1 });
	$ui->render(pointer_state => { x => 50, y => 20, down => 1 });

	is(
		[sort $w->states],
		[sort qw(focused hovered pressed)],
		'states() reflects every active condition',
	);
};

subtest 'derived states sit beside user states and cannot be written' => sub {
	my $w = TestStateWidget->new(id => 'mixed');
	my $ui = make_ui($w);
	$w->add_state('selected');
	$ui->interaction->set_focused_widget($w);
	is( [ sort $w->states ], [qw(focused selected)], 'states() lists user and derived states' );
	$w->clear_states;
	is( [ $w->states ], ['focused'], 'clear_states clears only user states' );
	like( dies { $w->remove_state('focused') }, qr/state 'focused' is derived/, 'derived states are read-only' );
	$ui->interaction->set_focused_widget(undef);
	ok( !$w->has_state('focused'), 'and follow the UI' );
};

done_testing;
