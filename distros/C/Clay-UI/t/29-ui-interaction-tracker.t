use v5.22;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Test2::V0;

use lib 't/lib';

use Object::Pad 0.800;
use Clay::UI;
use Clay::UI::Enum::Result;
use Clay::UI::Test::Box;
use Clay::UI::Role::Core::Container;
use Clay::UI::Role::Core::Stateful;
use Clay::UI::Role::Interaction::Hoverable;
use Clay::UI::Role::Interaction::Pressable;
use Clay::UI::Role::Layout::HasFloating;
use Clay::UI::Role::Layout::HasScroll;
use Clay::XS qw(CLAY_ATTACH_TO_PARENT);

# -----------------------------------------------------------------------------
# The interaction tracker turns pointer input into hover / armed / pressed
# state and events. Driven with synthetic input: no layout, no geometry.
# -----------------------------------------------------------------------------

class HoverBox :strict(params)
	:does(Clay::UI::Role::Core::Stateful)
	:does(Clay::UI::Role::Core::Container)
	:does(Clay::UI::Role::Interaction::Hoverable)
{}

class Button :strict(params)
	:does(Clay::UI::Role::Core::Stateful)
	:does(Clay::UI::Role::Core::Container)
	:does(Clay::UI::Role::Interaction::Pressable)
{}

class FloatingButton :strict(params) :isa(Button) :does(Clay::UI::Role::Layout::HasFloating) {}

class ScrollPanel :strict(params) :does(Clay::UI::Role::Layout::HasScroll) {}

sub make_ui (@children) {
	my $root = Clay::UI::Test::Box->new(id => 'page');
	$root->add_child(@children);
	return Clay::UI->new(width => 100, height => 100, root => $root);
}

sub log_events ($log, $widget, @names) {
	for my $name (@names) {
		$widget->on($name, sub ($e) { push @$log, $widget->id . ":$name"; return });
	}
	return;
}

subtest 'hover follows the widgets under the pointer' => sub {
	my $box = HoverBox->new(id => 'hb');
	my $ui  = make_ui($box);
	my @log;
	log_events(\@log, $box, qw(OnHoverStart OnHoverStopped));
	$ui->interaction->update(over => [$box], down => 0);
	is( \@log, ['hb:OnHoverStart'], 'entering fires OnHoverStart' );
	is( [ $box->is_hovered, $box->has_state('hovered') ], [ 1, 1 ], 'reader and derived state agree' );
	$ui->interaction->update(over => [$box], down => 0);
	is( \@log, ['hb:OnHoverStart'], 'staying fires nothing' );
	$ui->interaction->update(over => [], down => 0);
	is( \@log, [ 'hb:OnHoverStart', 'hb:OnHoverStopped' ], 'leaving fires OnHoverStopped' );
	is( $box->is_hovered, 0, 'no longer hovered' );
};

subtest 'a nested press has one origin and bubbles to the ancestor' => sub {
	my $card  = Button->new(id => 'card');
	my $inner = Button->new(id => 'inner');
	$card->add_child($inner);
	my $ui = make_ui($card);
	my @log;
	my $inner_result = Clay::UI::Enum::Result->CONTINUE;
	$inner->on('OnPress', sub ($e) { push @log, 'inner'; return $inner_result });
	$card->on('OnPress',  sub ($e) { push @log, 'card(target=' . $e->target->id . ')'; return });
	$ui->interaction->update(over => [ $card, $inner ], down => 1, x => 3, y => 4);
	is( \@log, [ 'inner', 'card(target=inner)' ], 'the button fires once, the card sees only the bubbled event' );

	@log = ();
	$inner_result = Clay::UI::Enum::Result->HANDLED;
	$ui->interaction->update(over => [ $card, $inner ], down => 0);
	$ui->interaction->update(over => [ $card, $inner ], down => 1);
	is( \@log, ['inner'], 'HANDLED stops the event at the button' );
};

subtest 'a Pressable in a floating root beats later ones below it' => sub {
	my $back    = Button->new(id => 'back');
	my $front   = Button->new(id => 'front');
	my $tooltip = FloatingButton->new(id => 'tip', floating => { attach_to => CLAY_ATTACH_TO_PARENT });
	$front->add_child($tooltip);
	my $ui = make_ui($back, $front);
	my @log;
	log_events(\@log, $_, 'OnPress') for $back, $front, $tooltip;
	$ui->interaction->update(over => [ $tooltip, $back, $front ], down => 1);
	is( $log[0], 'tip:OnPress', 'the floating root comes first and wins over the main root' );

	@log = ();
	$ui->interaction->update(over => [ $back, $front ], down => 0);
	$ui->interaction->update(over => [ $back, $front ], down => 1);
	is( \@log, ['front:OnPress'], 'of two overlapping siblings, the later one wins' );
};

subtest 'press, drag out, drag back in, release' => sub {
	my $button = Button->new(id => 'btn');
	my $ui = make_ui($button);
	my $interaction = $ui->interaction;
	my @positions;
	$button->on('OnPress',   sub ($e) { push @positions, [ press   => $e->x, $e->y ]; return });
	$button->on('OnRelease', sub ($e) { push @positions, [ release => $e->x, $e->y ]; return });

	$interaction->update(over => [$button], down => 1, x => 5, y => 6);
	is( [ $interaction->is_armed($button), $button->is_pressed ], [ 1, 1 ], 'armed and pressed' );
	$interaction->update(over => [], down => 1);
	is( [ $interaction->is_armed($button), $button->is_pressed, $button->has_state('pressed') ], [ 1, 0, 0 ],
		'still armed but not pressed off the button' );
	$interaction->update(over => [$button], down => 1);
	is( $button->is_pressed, 1, 'pressed again back on it' );
	$interaction->update(over => [$button], down => 0, x => 7, y => 8);
	is( \@positions, [ [ press => 5, 6 ], [ release => 7, 8 ] ], 'OnPress and OnRelease carry the position' );
	is( [ $interaction->is_armed($button), $button->is_pressed ], [ 0, 0 ], 'the release disarms' );
};

subtest 'a press that started elsewhere is no click' => sub {
	my $button = Button->new(id => 'btn');
	my $ui = make_ui($button);
	my @log;
	log_events(\@log, $button, qw(OnPress OnRelease));
	$ui->interaction->update(over => [], down => 1);
	$ui->interaction->update(over => [$button], down => 1);
	is( $button->is_pressed, 0, 'dragging in does not press the button' );
	$ui->interaction->update(over => [$button], down => 0);
	is( \@log, [], 'no OnPress and no OnRelease' );
};

subtest 'every event fires before the first listener error is rethrown' => sub {
	my $button = Button->new(id => 'a');
	my $ui = make_ui($button);
	my @log;
	$button->on('OnHoverStart', sub ($e) { die "handler bug\n" });
	$button->on('OnPress',      sub ($e) { push @log, 'press'; die "press bug\n" });
	like( dies { $ui->interaction->update(over => [$button], down => 1) }, qr/^handler bug$/,
		'the first error is rethrown' );
	is( \@log, ['press'], 'the event queued after the failing one still fired' );
	is( $button->is_pressed, 1, 'state was updated before the events' );
	ok( lives { $ui->interaction->update(over => [$button], down => 1) }, 'the next update works' );
};

subtest 'update validates its input' => sub {
	my $box   = HoverBox->new(id => 'hb');
	my $ui    = make_ui($box);
	my $other = HoverBox->new(id => 'other');
	my $i = $ui->interaction;
	like( dies { $i->update(over => [], down => 0, pointer => 1) }, qr/unknown argument\(s\): pointer/, 'unknown argument' );
	like( dies { $i->update(down => 0) }, qr/'over' must be an arrayref/, 'over is required' );
	like( dies { $i->update(over => []) }, qr/'down' is required/, 'down is required' );
	like( dies { $i->update(over => [], down => []) }, qr/'down' must be a plain boolean/, 'down is a plain value' );
	like( dies { $i->update(over => [], down => 0, x => 'left') }, qr/'x' must be a finite number/, 'x is a number' );
	like( dies { $i->update(over => [$other], down => 0) }, qr/'over' must hold widgets of this Clay::UI/,
		'a widget of no UI is rejected' );
	like( dies { $i->update(over => [], down => 0, scrolled => [ [ $box, 1 ] ]) }, qr/'scrolled' entries must be/,
		'scrolled entries are checked' );
	like( dies { $i->update(over => [], down => 0, scrolled => [ [ $box, 0, 1 ] ]) },
		qr/'scrolled' must hold scroll containers/, 'only scroll containers scroll' );
	my $panel = ScrollPanel->new(id => 'panel');
	$ui->root->add_child($panel);
	like( dies { $i->update(over => [], down => 0, scrolled => [ [ $panel, 0, 1 ], [ $panel, 0, 2 ] ]) },
		qr/'scrolled' lists the same widget twice/, 'each container at most once' );
};

subtest 'events an earlier listener made stale are dropped' => sub {
	my $outer = HoverBox->new(id => 'outer');
	my $inner = Button->new(id => 'inner');
	$outer->add_child($inner);
	my $ui = make_ui($outer);
	my @log;
	log_events(\@log, $inner, qw(OnHoverStart OnHoverStopped OnPress));
	$outer->on('OnHoverStart', sub ($e) { push @log, 'outer:OnHoverStart'; $outer->remove_child_with_id('inner'); return });
	$ui->interaction->update(over => [ $outer, $inner ], down => 1);
	is( \@log, ['outer:OnHoverStart'], 'the removed widget gets neither its OnHoverStart, its OnHoverStopped nor its OnPress' );
	is( [ $inner->is_hovered, $inner->parent ], [ 0, undef ], 'it is detached and not hovered' );
};

subtest 'events of one kind fire in tree order before the first render' => sub {
	my @boxes = map { HoverBox->new(id => "b$_") } 1 .. 6;
	my $ui = make_ui(@boxes);
	my @log;
	log_events(\@log, $_, 'OnHoverStart') for @boxes;
	$ui->interaction->update(over => [ reverse @boxes ], down => 0);
	is( \@log, [ map { "b$_:OnHoverStart" } 1 .. 6 ], 'the live tree decides the order' );
};

subtest 'a release over an armed ancestor reaches the ancestor' => sub {
	my $card   = Button->new(id => 'card');
	my $button = Button->new(id => 'btn');
	$card->add_child($button);
	my $ui = make_ui($card);
	my @log;
	log_events(\@log, $_, qw(OnPress OnRelease)) for $card, $button;
	$ui->interaction->update(over => [ $card, $button ], down => 1);
	$ui->interaction->update(over => [$card], down => 0);
	is( \@log, [ 'btn:OnPress', 'card:OnRelease' ], 'the press armed the card, so releasing on it is its click' );
};

subtest 'update cannot be called from its own listeners' => sub {
	my $box = HoverBox->new(id => 'hb');
	my $ui = make_ui($box);
	my $nested;
	$box->on('OnHoverStart', sub ($e) { $nested = dies { $ui->interaction->update(over => [], down => 0) }; return });
	$ui->interaction->update(over => [$box], down => 0);
	like( $nested, qr/called from one of its own listeners/, 'the nested call died' );
	is( $box->is_hovered, 1, 'and changed nothing' );
};

subtest 'a removed subtree leaves the interaction at once' => sub {
	my $card   = HoverBox->new(id => 'card');
	my $button = Button->new(id => 'btn');
	$card->add_child($button);
	my $ui = make_ui($card);
	my @log;
	log_events(\@log, $_, qw(OnHoverStopped OnRelease)) for $card, $button;
	$ui->interaction->update(over => [ $card, $button ], down => 1);
	$ui->root->remove_child_with_id('card');
	is( [ sort @log ], [ 'btn:OnHoverStopped', 'card:OnHoverStopped' ], 'OnHoverStopped during the removal, no OnRelease' );
	is( [ $button->is_hovered, $button->is_pressed, $ui->interaction->is_armed($button) ], [ 0, 0, 0 ],
		'hover, press and arming dropped' );
	is( $ui->interaction->under_pointer, [], 'no longer under the pointer' );
	@log = ();
	$ui->interaction->update(over => [], down => 0);
	is( \@log, [], 'the release fires nothing for the removed button' );
};

done_testing;
