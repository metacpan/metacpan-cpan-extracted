use v5.22;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Test2::V0;

use lib 't/lib';

use Object::Pad 0.800;
use Clay::UI;
use Clay::UI::Box;
use Clay::XS qw(Clay_GetElementId Clay_SetTransitionHandlers Clay_EaseOut set_scroll_position sizing_fixed);
use Clay::UI::Revision qw(bump_revision current_revision);
use Clay::UI::Test::Box;
use Clay::UI::Test::Text;
use Clay::UI::Test::Grid;
use Clay::UI::Test::GridCell;
use Clay::UI::Role::Core::Container;
use Clay::UI::Role::Core::Stateful;
use Clay::UI::Role::Layout::HasScroll;
use Clay::UI::Role::Interaction::Hoverable;
use Clay::UI::Role::Interaction::Focusable;

# -----------------------------------------------------------------------------
# The process-wide revision grows whenever something a frame lays out or
# draws changes, so a renderer can skip frames while it stays the same.
# -----------------------------------------------------------------------------

class ScrollPanel :strict(params) :does(Clay::UI::Role::Layout::HasScroll) {}

class ScrollBox :strict(params) :does(Clay::UI::Box) :does(Clay::UI::Role::Layout::HasScroll) {}

class HoverBox :strict(params)
	:does(Clay::UI::Role::Core::Container)
	:does(Clay::UI::Role::Interaction::Hoverable)
{}

class FocusBox :strict(params)
	:does(Clay::UI::Role::Core::Container)
	:does(Clay::UI::Role::Interaction::Focusable)
{}

class FadingBox :strict(params) :does(Clay::UI::Box) {
	method contribute_transition ($config) {
		$config->{transition} = { duration => 1, properties => Clay::XS::CLAY_TRANSITION_PROPERTY_BACKGROUND_COLOR() };
		return;
	}
}

sub bumps ($code) {
	my $before = current_revision();
	$code->();
	return current_revision() > $before ? 1 : 0;
}

subtest 'bump_revision increments the counter and returns it' => sub {
	my $before = current_revision();
	like( $before, qr/\A[0-9]+\z/, 'the counter is a non-negative integer' );
	is( bump_revision(), $before + 1, 'bump_revision returns the new value' );
	is( current_revision(), $before + 1, 'current_revision reports it' );
};

my $box    = Clay::UI::Test::Box->new(id => 'box');
my $text   = Clay::UI::Test::Text->new(text => 'hi');
my $scroll = ScrollPanel->new(id => 'scroll');
my $grid   = Clay::UI::Test::Grid->new(id => 'grid');
my $hover  = HoverBox->new(id => 'hover');
my $kid    = Clay::UI::Test::Box->new(id => 'other-kid');

# [ name, write, read ] for a sample of the setters.
my @setters = (
	[ 'layout',           sub { $box->layout({ child_gap => 4 }) },             sub { $box->layout } ],
	[ 'background_color', sub { $box->background_color([1, 2, 3, 255]) },       sub { $box->background_color } ],
	[ 'border_width',     sub { $box->border_width(2) },                        sub { $box->border_width } ],
	[ 'corner_radius',    sub { $box->corner_radius(3) },                       sub { $box->corner_radius } ],
	[ 'floating',         sub { $box->floating({ z_index => 1 }) },             sub { $box->floating } ],
	[ 'width_group',      sub { $box->width_group(5) },                         sub { $box->width_group } ],
	[ 'vertical',         sub { $scroll->vertical(0) },                         sub { $scroll->vertical } ],
	[ 'text',             sub { $text->text('ho') },                            sub { $text->text } ],
	[ 'text_color',       sub { $text->text_color([9, 9, 9, 255]) },            sub { $text->text_color } ],
	[ 'row_gap',          sub { $grid->row_gap(2) },                            sub { $grid->row_gap } ],
	[ 'append_row',       sub { $grid->append_row([ Clay::UI::Test::Text->new ]) }, sub { $grid->row_count } ],
	[ 'add_state',        sub { $hover->add_state('selected') },                sub { $hover->has_state('selected') } ],
	[ 'clear_states',     sub { $hover->clear_states },                         sub { $hover->states } ],
	[ 'add_child',        sub { $box->add_child(Clay::UI::Test::Box->new(id => 'kid')) }, sub { $box->children } ],
	[ 'remove_child_with_id', sub { $box->remove_child_with_id('kid') },        sub { $box->get_children_with(sub { 1 }) } ],
	[ 'add_child again',  sub { $box->add_child($kid) },                        sub { $box->has_child($kid) } ],
	[ 'remove_child',     sub { $box->remove_child($kid) },                     sub { $box->children } ],
);

subtest 'widget setters bump the revision' => sub {
	ok( bumps($_->[1]), $_->[0] ) for @setters;
};

subtest 'reading an attribute does not bump the revision' => sub {
	ok( !bumps($_->[2]), $_->[0] ) for @setters;
	ok( !bumps(sub { $box->add_child }), 'add_child without children' );
};

subtest 'writing the current sizing group back does not bump the revision' => sub {
	my $grouped = Clay::UI::Test::Box->new(width_group => 7, height_group => 3);
	ok( !bumps(sub { $grouped->width_group(7); $grouped->height_group(3) }), 'a user group' );
	my $owner = Clay::UI::Test::Grid->new(id => 'owner');
	my $cell  = Clay::UI::Test::GridCell->new;
	$owner->append_row([$cell]);
	ok( !bumps(sub { $cell->width_group($cell->width_group); $cell->height_group($cell->height_group) }),
		'a group the grid stamped' );
	ok( bumps(sub { $grouped->width_group(8) }), 'another group does' );
};

subtest 'mark_changed bumps the revision and returns the widget' => sub {
	my $returned;
	ok( bumps(sub { $returned = $box->mark_changed }), 'on an element' );
	ref_is( $returned, $box, 'which it returns' );
	ok( bumps(sub { $returned = $text->mark_changed }), 'on a text node' );
	ref_is( $returned, $text, 'which it returns' );
};

subtest 'resizing the viewport bumps the revision' => sub {
	my $ui = Clay::UI->new(width => 100, height => 100, root => Clay::UI::Test::Box->new);
	ok( bumps(sub { $ui->width(120) }),  'width' );
	ok( bumps(sub { $ui->height(80) }),  'height' );
	ok( !bumps(sub { $ui->width; $ui->height }), 'reading them does not' );
};

subtest 'hover changes bump the revision' => sub {
	my $root   = Clay::UI::Test::Box->new(id => 'page');
	my $target = HoverBox->new(id => 'target');
	$root->add_child($target);
	my $ui = Clay::UI->new(width => 100, height => 100, root => $root);

	ok( bumps(sub { $ui->interaction->update(over => [$target], down => 0) }), 'hover starts' );
	ok( !bumps(sub { $ui->interaction->update(over => [$target], down => 0) }), 'staying hovered does not' );
	ok( bumps(sub { $ui->interaction->update(over => [], down => 0) }), 'hover stops' );
};

subtest 'focus changes bump the revision' => sub {
	my $root  = Clay::UI::Test::Box->new(id => 'page');
	my $input = FocusBox->new(id => 'input');
	$root->add_child($input);
	my $ui = Clay::UI->new(width => 100, height => 100, root => $root);

	ok( bumps(sub { $ui->interaction->set_focused_widget($input) }), 'focusing' );
	ok( !bumps(sub { $ui->interaction->set_focused_widget($input) }), 'focusing the focused widget again does not' );
	ok( bumps(sub { $ui->interaction->set_focused_widget(undef) }), 'blurring' );
};

subtest 'setting a scroll position bumps the revision' => sub {
	my $root = ScrollBox->new(id => 'log', layout => { sizing => { width => sizing_fixed(10), height => sizing_fixed(2) } });
	$root->add_child(Clay::UI::Test::Box->new(layout => { sizing => { width => sizing_fixed(10), height => sizing_fixed(9) } }));
	my $ui = Clay::UI->new(width => 20, height => 20, root => $root);
	$ui->render;

	ok( bumps(sub { set_scroll_position(Clay_GetElementId('log'), { x => 0, y => -3 }) }), 'set_scroll_position' );
	is( bump_revision(), current_revision(), 'bump_revision still returns the current value' );
};

subtest 'laid_out_revision is the revision a frame shows' => sub {
	my $root = HoverBox->new(id => 'root');
	$root->add_child(Clay::UI::Test::Box->new(layout => { sizing => { width => sizing_fixed(10), height => sizing_fixed(10) } }));
	my $ui = Clay::UI->new(width => 20, height => 20, root => $root);
	is( $ui->laid_out_revision, undef, 'undef before the first frame' );
	my $hovered = 0;
	$root->on(OnHoverStart => sub ($event) { $hovered++; $root->add_child(Clay::UI::Test::Box->new); return });
	$ui->render;
	is( $ui->laid_out_revision, current_revision(), 'a frame shows every change before its layout' );
	my $before = current_revision();
	$ui->render(pointer_state => { x => 2, y => 2, down => 0 });
	is( $hovered, 1, 'a listener changed the tree during the frame' );
	ok( current_revision() > $before, 'which bumped the revision' );
	is( $ui->laid_out_revision, current_revision(), 'and the frame shows that change too' );
	bump_revision();
	isnt( $ui->laid_out_revision, current_revision(), 'a later change is not shown yet' );
};

subtest 'scrolling inside render bumps the revision' => sub {
	my $root = ScrollBox->new(id => 'log', layout => { sizing => { width => sizing_fixed(10), height => sizing_fixed(2) } });
	$root->add_child(Clay::UI::Test::Box->new(layout => { sizing => { width => sizing_fixed(10), height => sizing_fixed(9) } }));
	my $ui = Clay::UI->new(width => 20, height => 20, root => $root);
	$ui->render(pointer_state => { x => 5, y => 1, down => 0 });
	$ui->render;

	ok( bumps(sub { $ui->render(scroll_delta => [0, -1]) }), 'wheel input that moves the container' );
	ok( !bumps(sub { $ui->render }), 'a frame without movement does not' );
};

subtest 'a running transition bumps the revision' => sub {
	my $root = FadingBox->new(id => 'fade', background_color => [255, 0, 0, 255], layout => { sizing => { width => sizing_fixed(10), height => sizing_fixed(10) } });
	my $ui = Clay::UI->new(width => 20, height => 20, root => $root);
	Clay_SetTransitionHandlers(sub ($args, $userdata) {
		my $eased = Clay_EaseOut($args);
		$args->{current} = $eased->{current};
		return $eased->{complete};
	});
	$ui->render(delta_time => 0.25);
	ok( !bumps(sub { $ui->render(delta_time => 0.25) }), 'an idle element does not' );

	$root->background_color([0, 0, 0, 255]);
	$ui->render(delta_time => 0.25);    # the colour starts to move
	ok( bumps(sub { $ui->render(delta_time => 0.25) }), 'a frame that animates an element bumps the revision' );
	my $frames = 0;
	$frames++ while $frames < 10 && bumps(sub { $ui->render(delta_time => 0.25) });
	ok( $frames >= 2 && $frames < 10, "until the animation is over ($frames more frames)" );
	is( $ui->render->[0]{renderData}{backgroundColor}{r}, 0, 'and the final colour is shown' );
};


done_testing;
