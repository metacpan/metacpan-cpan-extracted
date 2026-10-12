use v5.22;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Test2::V0;

use lib 't/lib';
use Scalar::Util qw(refaddr weaken);

use Object::Pad 0.800;
use Clay::XS qw(:all);
use Clay::UI;
use Clay::UI::Enum::Result;
use Clay::UI::Test::Box;
use Clay::UI::Test::Text;
use Clay::UI::Role::Core::Container;
use Clay::UI::Role::Core::Stateful;
use Clay::UI::Role::Interaction::Hoverable;
use Clay::UI::Role::Interaction::Pressable;
use Clay::UI::Role::Layout::HasLayout;
use Clay::UI::Role::Layout::HasFloating;
use Clay::UI::Role::Layout::HasScroll;

# -----------------------------------------------------------------------------
# render feeds the real pointer to the interaction tracker before the
# layout pass. The tracker's own rules are tested with synthetic input in
# t/29-ui-interaction-tracker.t; these tests cover what render adds:
# Clay's pointer-over order, listeners running between frames, scroll.
# -----------------------------------------------------------------------------

class HoverBox :strict(params)
	:does(Clay::UI::Role::Core::Stateful)
	:does(Clay::UI::Role::Core::Container)
	:does(Clay::UI::Role::Interaction::Hoverable)
	:does(Clay::UI::Role::Layout::HasLayout)
{}

class Button :strict(params)
	:does(Clay::UI::Role::Core::Stateful)
	:does(Clay::UI::Role::Core::Container)
	:does(Clay::UI::Role::Interaction::Pressable)
	:does(Clay::UI::Role::Layout::HasLayout)
	:does(Clay::UI::Role::Layout::HasFloating)
{}

class ScrollPanel :strict(params)
	:does(Clay::UI::Role::Layout::HasScroll)
	:does(Clay::UI::Role::Layout::HasLayout)
{}

sub fixed ($width, $height) {
	return { sizing => { width => sizing_fixed($width), height => sizing_fixed($height) } };
}

sub make_ui ($root) {
	return Clay::UI->new(width => 300, height => 200, root => $root,
		measure_text => sub ($text, $config, $userdata) { return { width => 1, height => 1 } });
}

sub page (@children) {
	my $root = Clay::UI::Test::Box->new(id => 'page', layout => { sizing => { width => sizing_grow(), height => sizing_grow() } });
	$root->add_child(@children);
	return $root;
}

sub pointer ($ui, $x, $y, $down = 0) {
	return $ui->render(pointer_state => { x => $x, y => $y, down => $down });
}

sub log_events ($log, $widget, @names) {
	for my $name (@names) {
		$widget->on($name, sub ($e) { push @$log, $widget->id . ":$name"; return });
	}
	return;
}

subtest 'a Pressable is freed after scope exit' => sub {
	my $weak;
	{
		my $button = Button->new(id => 'b');
		$weak = $button;
		weaken $weak;
	}
	is( $weak, undef, 'no reference cycle keeps it alive' );
};

subtest 'no ghost click on the first pointer frame' => sub {
	my $button = Button->new(id => 'btn', layout => fixed(100, 40));
	my @log;
	log_events(\@log, $button, qw(OnPress OnRelease OnHoverStart));
	my $ui = make_ui($button);
	$ui->render;
	pointer($ui, 50, 20);
	is( \@log, ['btn:OnHoverStart'], 'a resting pointer only hovers' );
	@log = ();
	pointer($ui, 50, 20);
	is( \@log, [], 'and never releases' );
	is( $button->is_pressed, 0, 'not pressed' );
};

subtest 'render without pointer_state keeps the pointer' => sub {
	my $box = HoverBox->new(id => 'hb', layout => fixed(100, 40));
	my @log;
	log_events(\@log, $box, qw(OnHoverStart OnHoverStopped));
	my $ui = make_ui(page($box));
	$ui->render;
	pointer($ui, 50, 20);
	@log = ();
	$ui->render;
	is( \@log, [], 'no hover events without new input' );
	is( $box->is_hovered, 1, 'still hovered' );
	ok( ( grep { refaddr($_) == refaddr($box) } @{ $ui->interaction->under_pointer } ), 'under_pointer agrees' );
};

subtest 'overlapping Pressables that are not nested get one press' => sub {
	my $under = Button->new(id => 'under', layout => fixed(100, 100));
	my $over  = Button->new(id => 'over',  layout => fixed(100, 100),
		floating => { attach_to => CLAY_ATTACH_TO_PARENT, pointer_capture_mode => CLAY_POINTER_CAPTURE_MODE_PASSTHROUGH });
	my @log;
	log_events(\@log, $_, 'OnPress') for $under, $over;
	my $ui = make_ui(page($under, $over));
	$ui->render;
	pointer($ui, 10, 10);
	pointer($ui, 10, 10, 1);
	is( \@log, ['over:OnPress'], 'only the topmost widget is pressed' );
	ok( $under->is_hovered && $over->is_hovered, 'both are hovered' );
};

subtest 'a dying listener makes render die after all events fired' => sub {
	my $a = Button->new(id => 'a', layout => fixed(50, 50));
	my @log;
	$a->on('OnHoverStart', sub ($e) { die "handler bug\n" });
	$a->on('OnPress',      sub ($e) { push @log, 'press'; return });
	my $ui = make_ui(page($a));
	$ui->render;
	pointer($ui, -10, -10);
	like( dies { pointer($ui, 10, 10, 1) }, qr/^handler bug$/, 'render dies with the listener error' );
	is( \@log, ['press'], 'the event queued after the failing one still fired' );
	is( $a->is_pressed, 1, 'state was updated before the events' );
	ok( lives { pointer($ui, 10, 10, 1) }, 'the next render works' );
};

subtest 'a hover listener may change the tree' => sub {
	my $hint = Clay::UI::Test::Box->new(id => 'hint', layout => fixed(10, 10));
	my $box  = HoverBox->new(id => 'hb', layout => fixed(50, 50));
	my $root = page($box, $hint);
	$box->on('OnHoverStart', sub ($e) { $root->remove_child_with_id('hint'); return });
	my $ui = make_ui($root);
	$ui->render;
	pointer($ui, -10, -10);
	ok( lives { pointer($ui, 10, 10) }, 'removing a sibling from a listener is fine' );
	is( scalar @{ $root->children }, 1, 'the sibling is gone' );
};

subtest 'a listener may render another Clay::UI' => sub {
	my $other = make_ui(Clay::UI::Test::Box->new(id => 'other', layout => fixed(20, 20)));
	my $box   = HoverBox->new(id => 'hb', layout => fixed(50, 50));
	my $late  = HoverBox->new(id => 'late', layout => fixed(50, 50));
	my $root  = page($box);
	$box->on('OnHoverStart', sub ($e) { $other->render; $root->add_child($late); return });
	my $ui = make_ui($root);
	$ui->render;
	pointer($ui, -10, -10);
	pointer($ui, 10, 10);
	pointer($ui, 60, 10);
	is( $late->is_hovered, 1, 'the frame with the new widget was laid out in this UI\'s context' );
};

subtest 'a removed hovered widget gets OnHoverStopped at once' => sub {
	my $box = HoverBox->new(id => 'hb', layout => fixed(50, 50));
	my @log;
	log_events(\@log, $box, 'OnHoverStopped');
	my $root = page($box);
	my $ui = make_ui($root);
	$ui->render;
	pointer($ui, 10, 10);
	$root->remove_child_with_id('hb');
	is( \@log, ['hb:OnHoverStopped'], 'hover stopped during remove_child_with_id' );
	is( $box->is_hovered, 0, 'and is_hovered cleared' );
	$ui->render;
	is( \@log, ['hb:OnHoverStopped'], 'the next render fires nothing more' );
};

subtest 'a removed widget added to another parent renders and is hovered again' => sub {
	my $box    = HoverBox->new(id => 'hb', layout => fixed(50, 50));
	my $spacer = Clay::UI::Test::Box->new(id => 'spacer', layout => fixed(60, 50));
	my $panel  = Clay::UI::Test::Box->new(id => 'panel', layout => fixed(100, 50));
	$box->add_child(Clay::UI::Test::Text->new(text => 'label'));
	my @log;
	log_events(\@log, $box, qw(OnHoverStart OnHoverStopped));
	my $root = page($box, $spacer, $panel);
	my $ui = make_ui($root);
	$ui->render;
	pointer($ui, 10, 10);
	$root->remove_child_with_id('hb');
	pointer($ui, 250, 10);
	is( \@log, [ 'hb:OnHoverStart', 'hb:OnHoverStopped' ], 'hovered, then released by the removal' );

	$panel->add_child($box);
	my ($label) = grep { $_->{commandType} == CLAY_RENDER_COMMAND_TYPE_TEXT } @{ $ui->render };
	is( $label->{boundingBox}{x}, 60, 'its subtree renders inside the new parent' );
	is( refaddr($ui->widget_for($label->{userData})->parent), refaddr($box), 'and maps back to it' );
	pointer($ui, 80, 10);
	is( \@log, [ 'hb:OnHoverStart', 'hb:OnHoverStopped', 'hb:OnHoverStart' ], 'it is hovered at its new place' );
	is( $box->is_hovered, 1, 'is_hovered agrees' );
};

subtest 'hover events do not bubble' => sub {
	my $outer = HoverBox->new(id => 'outer', layout => fixed(100, 100));
	my $inner = HoverBox->new(id => 'inner', layout => fixed(50, 50));
	$outer->add_child($inner);
	my @log;
	$outer->on('OnHoverStart', sub ($e) { push @log, 'outer<-' . $e->target->id; return Clay::UI::Enum::Result->CONTINUE });
	$inner->on('OnHoverStart', sub ($e) { push @log, 'inner<-' . $e->target->id; return Clay::UI::Enum::Result->CONTINUE });
	my $ui = make_ui($outer);
	$ui->render;
	pointer($ui, 10, 10);
	is( \@log, [ 'outer<-outer', 'inner<-inner' ], 'each hovered widget gets its own event, in tree order' );
};

subtest 'a dying listener does not reset scroll positions' => sub {
	my $panel = ScrollPanel->new(id => 'log', layout => { %{ fixed(100, 50) }, layout_direction => CLAY_TOP_TO_BOTTOM });
	$panel->add_child(map { Clay::UI::Test::Box->new(layout => fixed(100, 20)) } 1 .. 6);
	my $box = HoverBox->new(id => 'hb', layout => fixed(50, 50));
	my $explode = 0;
	$box->on('OnHoverStart', sub ($e) { die "listener bug\n" if $explode; return });
	my $ui = make_ui(page($panel, $box));
	my $position = sub () { Clay_GetScrollContainerData(Clay_GetElementId('log'))->{scrollPosition}{y} };
	$ui->render;
	pointer($ui, 50, 25);
	$ui->render(pointer_state => { x => 50, y => 25 }, scroll_delta => [0, -2]);
	pointer($ui, 50, 25);
	my $before = $position->();
	ok( $before < 0, 'the panel is scrolled' );
	$explode = 1;
	like( dies { pointer($ui, 120, 25) }, qr/^listener bug$/, 'the frame with the dying listener dies' );
	$explode = 0;
	pointer($ui, 120, 25);
	is( $position->(), $before, 'the scroll position survived' );
};

subtest 'OnScroll carries the scroll delta' => sub {
	my $panel = ScrollPanel->new(id => 'log', layout => { %{ fixed(100, 50) }, layout_direction => CLAY_TOP_TO_BOTTOM });
	$panel->add_child(map { Clay::UI::Test::Box->new(layout => fixed(100, 20)) } 1 .. 6);
	my @deltas;
	$panel->on('OnScroll', sub ($e) { push @deltas, [ $e->delta_x, $e->delta_y ]; return });
	my $ui = make_ui($panel);
	$ui->render;
	pointer($ui, 50, 25);
	$ui->render(pointer_state => { x => 50, y => 25 }, scroll_delta => [0, -2]);
	is( \@deltas, [ [ 0, -20 ] ], 'one event with the position change' );
	$ui->render(pointer_state => { x => 50, y => 25 });
	is( scalar @deltas, 1, 'no event without movement' );
};

done_testing;
