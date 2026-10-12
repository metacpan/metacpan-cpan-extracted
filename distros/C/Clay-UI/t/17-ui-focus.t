use v5.22;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Test2::V0;

use lib "t/lib";
use Scalar::Util qw(refaddr);

use Object::Pad 0.800;

use Clay::UI;
use Clay::UI::Test::Box;
use Clay::UI::Test::Text;
use Clay::UI::Revision qw(current_revision);
use Clay::UI::Role::Core::Element;
use Clay::UI::Role::Core::Container;
use Clay::UI::Role::Interaction::Disableable;
use Clay::UI::Role::Interaction::Focusable;
use Clay::UI::Role::Interaction::HasFocusOrder;

sub same ($a, $b, $name) { is(refaddr($a), refaddr($b), $name) }

# -----------------------------------------------------------------------------
# Test fixtures.
# -----------------------------------------------------------------------------

class TestInput
	:does(Clay::UI::Role::Core::Element)
	:does(Clay::UI::Role::Interaction::Focusable)
	:does(Clay::UI::Role::Interaction::Disableable)
{}

# A widget whose class accepts the focus only while its own flag says so.
class TestToggleInput :isa(TestInput) {
	field $accepting = 1;

	method accepts_focus :override () { return $accepting }

	method set_accepting ($value) {
		$accepting = $value;
		$self->focus_eligibility_changed;
		return;
	}
}

# Container that keeps Tab inside itself, like a modal dialog.
class TestTrap
	:does(Clay::UI::Role::Core::Container)
	:does(Clay::UI::Role::Interaction::HasFocusOrder)
{
	method get_next_focus     { $self->default_next_focus(within => $self) }
	method get_previous_focus { $self->default_previous_focus(within => $self) }
}

# Container that always returns the same widget first, then defers.
class TestOverride
	:does(Clay::UI::Role::Core::Container)
	:does(Clay::UI::Role::Interaction::HasFocusOrder)
{
	use Scalar::Util qw(refaddr);
	field $target :param :reader;

	method get_next_focus {
		my $current = $self->ui->interaction->get_focused_widget;
		# If we don't already point at our target, jump to it.
		return $target if !defined($current) || refaddr($current) != refaddr($target);
		# Otherwise behave like the default order would.
		return $self->default_next_focus;
	}

	method get_previous_focus { $self->default_previous_focus }
}

# Helper: build a UI with a box that contains the given children.
sub make_ui (@children) {
	my $root = Clay::UI::Test::Box->new(id => 'root');
	$root->add_child(@children) if @children;
	return Clay::UI->new(root => $root, width => 100, height => 100);
}

# -----------------------------------------------------------------------------
# Focusable defaults.
# -----------------------------------------------------------------------------

subtest 'can_focus takes a plain boolean' => sub {
	my $a = TestInput->new(id => 'a');
	is( $a->can_focus('yes'), 1, 'a true value is stored as 1' );
	is( $a->can_focus(''), 0, 'a false value as 0' );
	like( dies { $a->can_focus([]) }, qr/'can_focus' must be a plain boolean value/, 'a reference dies' );
	like( dies { TestInput->new(id => 'b', can_focus => {}) }, qr/'can_focus' must be a plain boolean value/,
		'also at construction' );
};

subtest 'an OnBlur listener that moves focus again drops the stale OnFocus' => sub {
	my $a = TestInput->new(id => 'a');
	my $b = TestInput->new(id => 'b');
	my $ui = make_ui($a, $b);
	my @log;
	for my $w ($a, $b) {
		$w->on('OnFocus', sub ($e) { push @log, $w->id . ':OnFocus'; return });
		$w->on('OnBlur',  sub ($e) { push @log, $w->id . ':OnBlur'; return });
	}
	$ui->interaction->set_focused_widget($a);
	$a->on('OnBlur', sub ($e) { $ui->interaction->set_focused_widget($a); return });
	@log = ();
	$ui->interaction->set_focused_widget($b);
	is( \@log, [ 'a:OnBlur', 'a:OnFocus' ], 'b never announced focus, so it gets no OnBlur either' );
	same( $ui->interaction->get_focused_widget, $a, 'a keeps the focus' );
};

subtest 'a nested refocus of the same widget delivers OnFocus once' => sub {
	my ($a, $b, $c) = map { TestInput->new(id => $_) } qw(a b c);
	my $ui = make_ui($a, $b, $c);
	my @log;
	for my $w ($a, $b, $c) {
		$w->on('OnFocus', sub ($e) { push @log, $w->id . ':OnFocus'; return });
		$w->on('OnBlur',  sub ($e) { push @log, $w->id . ':OnBlur'; return });
	}
	$ui->interaction->set_focused_widget($a);
	$a->on('OnBlur', sub ($e) {
		$ui->interaction->set_focused_widget($c);
		$ui->interaction->set_focused_widget($b);
		return;
	});
	@log = ();
	$ui->interaction->set_focused_widget($b);
	is( \@log, [ 'a:OnBlur', 'c:OnFocus', 'c:OnBlur', 'b:OnFocus' ], 'b gets its OnFocus exactly once' );
};

subtest 'an OnBlur listener cannot focus into the subtree being removed' => sub {
	my $panel = Clay::UI::Test::Box->new(id => 'panel');
	my $x = TestInput->new(id => 'x');
	my $y = TestInput->new(id => 'y');
	$panel->add_child($x, $y);
	my $ui = make_ui($panel);
	$ui->interaction->set_focused_widget($x);
	$x->on('OnBlur', sub ($e) { $ui->interaction->set_focused_widget($y); return });
	like( dies { $ui->root->remove_child_with_id('panel') }, qr/does not belong to this Clay::UI/,
		'the listener\'s attempt dies' );
	is( $ui->interaction->get_focused_widget, undef, 'nothing is focused' );
	is( $panel->parent, undef, 'the panel was removed all the same' );
};

subtest 'Focusable defaults: can_focus returns 1; is_focused false before focus' => sub {
	my $a  = TestInput->new(id => 'a');
	my $ui = make_ui($a);

	is($a->can_focus, 1, 'can_focus default is 1');
	is($a->is_focused, 0, 'is_focused starts false');
	is($ui->interaction->get_focused_widget, undef, 'no widget focused initially');
};

subtest 'a disabled widget cannot focus' => sub {
	my $a = TestInput->new(id => 'a', disabled => 1);
	make_ui($a);
	is($a->can_focus, 0, 'disabled widget can_focus is 0');
};

# -----------------------------------------------------------------------------
# set_focused_widget validation.
# -----------------------------------------------------------------------------

subtest 'set_focused_widget rejects non-Focusable widgets' => sub {
	my $a  = TestInput->new(id => 'a');
	my $b  = Clay::UI::Test::Box->new(id => 'b');   # not Focusable
	my $ui = make_ui($a, $b);

	like(
		dies { $ui->interaction->set_focused_widget($b) },
		qr/must consume Clay::UI::Role::Interaction::Focusable/,
		'rejects non-Focusable widget',
	);

	$ui->interaction->set_focused_widget($a);
	my $warnings = warnings { like( dies { $ui->interaction->set_focused_widget(5) }, qr/target must be a blessed widget/, 'rejects a non-widget' ) };
	is( $warnings, [], 'without warning first, even while a widget is focused' );
};

subtest 'set_focused_widget rejects can_focus == 0 widgets' => sub {
	my $a  = TestInput->new(id => 'a', disabled => 1);
	my $ui = make_ui($a);

	like(
		dies { $ui->interaction->set_focused_widget($a) },
		qr/not currently focusable/,
		'rejects disabled widget',
	);
};

subtest 'set_focused_widget rejects widgets from a different Clay::UI' => sub {
	my $a   = TestInput->new(id => 'a');
	my $ui1 = make_ui($a);
	my $b   = TestInput->new(id => 'b');
	my $ui2 = make_ui($b);

	like(
		dies { $ui1->interaction->set_focused_widget($b) },
		qr/does not belong to this Clay::UI/,
		'rejects foreign widget',
	);
};

# -----------------------------------------------------------------------------
# Focus events.
# -----------------------------------------------------------------------------

subtest 'set_focused_widget fires OnFocus / OnBlur on edge transitions' => sub {
	my $a  = TestInput->new(id => 'a');
	my $b  = TestInput->new(id => 'b');
	my $ui = make_ui($a, $b);

	my @log;
	$a->on('OnFocus', sub ($e) { push @log, 'a:focus' });
	$a->on('OnBlur',  sub ($e) { push @log, 'a:blur' });
	$b->on('OnFocus', sub ($e) { push @log, 'b:focus' });
	$b->on('OnBlur',  sub ($e) { push @log, 'b:blur' });

	$ui->interaction->set_focused_widget($a);
	is(\@log, ['a:focus'], 'OnFocus fires on initial focus');
	is($a->is_focused, 1, 'a->is_focused now true');

	@log = ();
	$ui->interaction->set_focused_widget($b);
	is(\@log, ['a:blur', 'b:focus'], 'blur previous then focus new');
	is($a->is_focused, 0, 'a no longer focused');
	is($b->is_focused, 1, 'b now focused');

	@log = ();
	$ui->interaction->set_focused_widget(undef);
	is(\@log, ['b:blur'], 'undef blurs without refiring OnFocus');
	is($b->is_focused, 0, 'b blurred');
	is($ui->interaction->get_focused_widget, undef, 'controller cleared');
};

subtest 'setting focus to the already-focused widget is a no-op' => sub {
	my $a  = TestInput->new(id => 'a');
	my $ui = make_ui($a);

	my @log;
	$a->on('OnFocus', sub ($e) { push @log, 'focus' });
	$a->on('OnBlur',  sub ($e) { push @log, 'blur' });

	$ui->interaction->set_focused_widget($a);
	$ui->interaction->set_focused_widget($a);   # idempotent
	is(\@log, ['focus'], 'no refire on same target');
};

subtest 'setting focus to undef when already unfocused is a no-op' => sub {
	my $a  = TestInput->new(id => 'a');
	my $ui = make_ui($a);

	my @log;
	$a->on('OnBlur', sub ($e) { push @log, 'blur' });

	$ui->interaction->set_focused_widget(undef);
	is(\@log, [], 'no events when blurring with no current focus');
};

# -----------------------------------------------------------------------------
# Default focus order: depth-first pre-order, skipping non-focusable.
# -----------------------------------------------------------------------------

subtest 'focus_next from undef focuses the first Focusable' => sub {
	my $a  = TestInput->new(id => 'a');
	my $b  = TestInput->new(id => 'b');
	my $c  = TestInput->new(id => 'c');
	my $ui = make_ui($a, $b, $c);

	$ui->interaction->focus_next;
	same($ui->interaction->get_focused_widget, $a, 'focus lands on first widget');
};

subtest 'focus_next traverses pre-order and wraps around' => sub {
	my $a  = TestInput->new(id => 'a');
	my $b  = TestInput->new(id => 'b');
	my $c  = TestInput->new(id => 'c');
	my $ui = make_ui($a, $b, $c);

	$ui->interaction->set_focused_widget($a);
	$ui->interaction->focus_next;
	same($ui->interaction->get_focused_widget, $b, 'a -> b');
	$ui->interaction->focus_next;
	same($ui->interaction->get_focused_widget, $c, 'b -> c');
	$ui->interaction->focus_next;
	same($ui->interaction->get_focused_widget, $a, 'c wraps to a');
};

subtest 'focus_previous wraps from first to last' => sub {
	my $a  = TestInput->new(id => 'a');
	my $b  = TestInput->new(id => 'b');
	my $c  = TestInput->new(id => 'c');
	my $ui = make_ui($a, $b, $c);

	$ui->interaction->set_focused_widget($a);
	$ui->interaction->focus_previous;
	same($ui->interaction->get_focused_widget, $c, 'a -> c (wrap)');
	$ui->interaction->focus_previous;
	same($ui->interaction->get_focused_widget, $b, 'c -> b');
};

subtest 'focus_previous from undef focuses the last Focusable' => sub {
	my $a  = TestInput->new(id => 'a');
	my $b  = TestInput->new(id => 'b');
	my $ui = make_ui($a, $b);
	$ui->interaction->focus_previous;
	same($ui->interaction->get_focused_widget, $b, 'previous from undef -> last');
};

subtest 'widgets with can_focus == 0 are skipped' => sub {
	my $a  = TestInput->new(id => 'a');
	my $x  = TestInput->new(id => 'x', disabled => 1);
	my $b  = TestInput->new(id => 'b');
	my $ui = make_ui($a, $x, $b);

	$ui->interaction->set_focused_widget($a);
	$ui->interaction->focus_next;
	same($ui->interaction->get_focused_widget, $b, 'disabled widget skipped in default chain');
};

subtest 'default order is depth-first (children before next sibling)' => sub {
	my $deep = TestInput->new(id => 'deep');
	my $a    = Clay::UI::Test::Box->new(id => 'a');
	$a->add_child($deep);
	my $b    = TestInput->new(id => 'b');
	my $root = Clay::UI::Test::Box->new(id => 'root');
	$root->add_child($a, $b);
	my $ui   = Clay::UI->new(root => $root, width => 100, height => 100);

	$ui->interaction->focus_next;
	same($ui->interaction->get_focused_widget, $deep, 'descended into first child first');
	$ui->interaction->focus_next;
	same($ui->interaction->get_focused_widget, $b, 'then on to sibling');
};

# -----------------------------------------------------------------------------
# HasFocusOrder override.
# -----------------------------------------------------------------------------

subtest 'HasFocusOrder takes over when ancestor of focused widget' => sub {
	my $a       = TestInput->new(id => 'a');
	my $b       = TestInput->new(id => 'b');
	my $target  = TestInput->new(id => 'target');
	# Container's subtree contains $a; the override always jumps to $target first.
	my $override = TestOverride->new(id => 'ov', target => $target);
	$override->add_child($a);
	my $root    = Clay::UI::Test::Box->new(id => 'root');
	$root->add_child($override, $b, $target);
	my $ui      = Clay::UI->new(root => $root, width => 100, height => 100);

	# Focus $a (inside the override subtree)
	$ui->interaction->set_focused_widget($a);
	$ui->interaction->focus_next;
	same($ui->interaction->get_focused_widget, $target, 'override redirected to target');
};

subtest 'default order resumes once focus leaves the override subtree' => sub {
	my $a       = TestInput->new(id => 'a');
	my $b       = TestInput->new(id => 'b');
	my $target  = TestInput->new(id => 'target');
	my $override = TestOverride->new(id => 'ov', target => $target);
	$override->add_child($a);
	my $root    = Clay::UI::Test::Box->new(id => 'root');
	$root->add_child($override, $b, $target);
	my $ui      = Clay::UI->new(root => $root, width => 100, height => 100);

	$ui->interaction->set_focused_widget($a);
	$ui->interaction->focus_next;
	same($ui->interaction->get_focused_widget, $target, 'first jump to target via override');
	$ui->interaction->focus_next;
	# $target is not under the override, so the default order applies and
	# wraps to the first focusable widget, $a.
	same($ui->interaction->get_focused_widget, $a, 'default order takes over once focus leaves override subtree');
};

subtest 'default_next_focus / default_previous_focus report the default order' => sub {
	my $a       = TestInput->new(id => 'a');
	my $b       = TestInput->new(id => 'b');
	my $target  = TestInput->new(id => 'target');
	my $override = TestOverride->new(id => 'ov', target => $target);
	$override->add_child($a);
	my $root    = Clay::UI::Test::Box->new(id => 'root');
	$root->add_child($override, $b, $target);
	my $ui      = Clay::UI->new(root => $root, width => 100, height => 100);

	$ui->interaction->set_focused_widget($a);
	same($override->default_next_focus,     $b,      'next after a in the default order is b');
	same($override->default_previous_focus, $target, 'previous before a wraps to target');
};

# -----------------------------------------------------------------------------
# HasFocusOrder on the root decides the first focus; its results are
# validated.
# -----------------------------------------------------------------------------

class ToolbarFirst
	:does(Clay::UI::Role::Core::Container)
	:does(Clay::UI::Role::Interaction::HasFocusOrder)
{
	field $toolbar :param;
	field $calls :reader = 0;
	method get_next_focus {
		$calls++;
		my $focused = $self->ui->interaction->get_focused_widget;
		return $toolbar if !defined($focused) || refaddr($focused) != refaddr($toolbar);
		return $self->default_next_focus;
	}
	method get_previous_focus { $self->default_previous_focus }
}

class FixedOrder
	:does(Clay::UI::Role::Core::Container)
	:does(Clay::UI::Role::Interaction::HasFocusOrder)
{
	field $next :param :accessor = undef;
	method get_next_focus { $next }
	method get_previous_focus { $next }
}

class Plain :does(Clay::UI::Role::Core::Container) {}

subtest 'the root HasFocusOrder chooses the first focus' => sub {
	my $toolbar = TestInput->new(id => 'toolbar');
	my $first   = TestInput->new(id => 'first');
	my $root    = ToolbarFirst->new(id => 'root', toolbar => $toolbar);
	$root->add_child($first, $toolbar);
	my $ui = Clay::UI->new(root => $root, width => 100, height => 100);
	$ui->interaction->focus_next;
	same($ui->interaction->get_focused_widget, $toolbar, 'nothing focused: the root order is consulted');
	is($root->calls, 1, 'get_next_focus ran once');
};

subtest 'an invalid focus-order result dies' => sub {
	my $x    = TestInput->new(id => 'x');
	my $nf   = Plain->new(id => 'nf');
	my $root = FixedOrder->new(id => 'broken');
	$root->add_child($x, $nf);
	my $ui = Clay::UI->new(root => $root, width => 100, height => 100);
	$ui->interaction->set_focused_widget($x);

	$root->next($nf);
	like( dies { $ui->interaction->focus_next }, qr/FixedOrder returned Plain, which is not Clay::UI::Role::Interaction::Focusable/,
		'a non-Focusable result dies naming the class' );
	$root->next('x');
	like( dies { $ui->interaction->focus_next }, qr/FixedOrder returned a non-widget/, 'a non-widget result dies' );
	my $foreign = TestInput->new(id => 'foreign');
	make_ui($foreign);
	$root->next($foreign);
	like( dies { $ui->interaction->focus_next }, qr/which is not part of this Clay::UI/, 'a widget of another UI dies' );

	my $disabled = TestInput->new(id => 'disabled', disabled => 1);
	$root->add_child($disabled);
	$root->next($disabled);
	ok( lives { $ui->interaction->focus_next }, 'a disabled widget of this UI means no change' );
	same($ui->interaction->get_focused_widget, $x, 'focus stayed');
	$root->next(undef);
	ok( lives { $ui->interaction->focus_next }, 'undef means no change' );
};

subtest 'a dying OnBlur listener still completes the focus change' => sub {
	my $a  = TestInput->new(id => 'a');
	my $b  = TestInput->new(id => 'b');
	my $ui = make_ui($a, $b);
	my @log;
	$a->on('OnBlur',  sub ($e) { die "validation failed\n" });
	$b->on('OnFocus', sub ($e) { push @log, 'b:focus'; return });
	$ui->interaction->set_focused_widget($a);
	like( dies { $ui->interaction->set_focused_widget($b) }, qr/^validation failed$/, 'the listener error propagates' );
	same($ui->interaction->get_focused_widget, $b, 'b is focused');
	ok( $b->has_state('focused') && !$a->has_state('focused'), 'both states switched' );
	is( \@log, ['b:focus'], 'OnFocus still fired' );
};

subtest 'a focused widget that can no longer focus loses the focus at once' => sub {
	my @w  = map { TestInput->new(id => $_) } qw(a b c);
	my $ui = make_ui(@w);
	my @log;
	$w[1]->on('OnBlur', sub ($e) { push @log, 'b:blur'; return });
	$ui->interaction->set_focused_widget($w[1]);
	$w[1]->can_focus(0);
	is( [ \@log, $ui->interaction->get_focused_widget ], [ ['b:blur'], undef ], 'can_focus(0) blurs it' );
	$ui->interaction->focus_next;
	same($ui->interaction->get_focused_widget, $w[0], 'Tab starts again at the first focusable widget');
	$w[0]->can_focus(1);
	same($ui->interaction->get_focused_widget, $w[0], 'a write that keeps it focusable changes nothing');
};

# -----------------------------------------------------------------------------
# Removing widgets releases focus held inside them.
# -----------------------------------------------------------------------------

subtest 'removing the focused widget blurs it' => sub {
	my $a  = TestInput->new(id => 'a');
	my $b  = TestInput->new(id => 'b');
	my $ui = make_ui($a, $b);
	my @log;
	$b->on('OnBlur', sub ($e) { push @log, 'b:blur'; return });

	$ui->interaction->set_focused_widget($b);
	$ui->root->remove_child_with_id('b');
	is( \@log, ['b:blur'], 'OnBlur fired on removal' );
	is( $ui->interaction->get_focused_widget, undef, 'nothing is focused' );
	is( $b->is_focused, 0, 'the removed widget is not focused' );
	ok( !$b->has_state('focused'), 'and lost its focused state' );
};

subtest 'removing an ancestor of the focused widget blurs it' => sub {
	my $deep  = TestInput->new(id => 'deep');
	my $panel = Clay::UI::Test::Box->new(id => 'panel');
	$panel->add_child($deep);
	my $ui = make_ui($panel);
	$ui->interaction->set_focused_widget($deep);
	$ui->root->remove_child_with_id('panel');
	is( $ui->interaction->get_focused_widget, undef, 'focus released with the subtree' );
};

subtest 'a removed widget cannot be focused' => sub {
	my $c  = TestInput->new(id => 'c');
	my $ui = make_ui($c);
	$ui->root->remove_child_with_id('c');
	like( dies { $ui->interaction->set_focused_widget($c) }, qr/does not belong to this Clay::UI/, 'focusing it dies' );
};

# -----------------------------------------------------------------------------
# Subtree and focus-scope queries.
# -----------------------------------------------------------------------------

subtest 'descendants lists the subtree in layout pre-order, internal children included' => sub {
	my $panel    = Clay::UI::Test::Box->new(id => 'panel');
	my $inner    = Clay::UI::Test::Box->new(id => 'inner');
	my $text     = Clay::UI::Test::Text->new(text => 'hi');
	my $helper   = Clay::UI::Test::Box->new(id => 'helper');
	my $deep     = TestInput->new(id => 'deep');
	my $sibling  = TestInput->new(id => 'sibling');
	$inner->add_child($text);
	$helper->add_child($deep);
	$panel->add_child($inner, $sibling);
	$panel->add_internal_children($helper);
	is( [ map { refaddr $_ } $panel->descendants ], [ map { refaddr $_ } $inner, $text, $sibling, $helper, $deep ],
		'children with their subtrees, then internal children with theirs' );
	is( [ $deep->descendants ], [], 'a leaf has none' );
};

subtest 'contains answers whether a widget is the invocant or below it' => sub {
	my $panel  = Clay::UI::Test::Box->new(id => 'panel');
	my $inner  = Clay::UI::Test::Box->new(id => 'inner');
	my $text   = Clay::UI::Test::Text->new(text => 'hi');
	my $helper = Clay::UI::Test::Box->new(id => 'helper');
	my $other  = Clay::UI::Test::Box->new(id => 'other');
	$inner->add_child($text);
	$panel->add_child($inner);
	$panel->add_internal_children($helper);
	ok( $panel->contains($panel), 'itself' );
	ok( $panel->contains($text), 'a text node below it' );
	ok( $panel->contains($helper), 'an internal child' );
	ok( $text->contains($text), 'a text node contains itself' );
	ok( !$inner->contains($panel), 'not its parent' );
	ok( !$panel->contains($other), 'not an unrelated widget' );
	like( dies { $panel->contains('panel') }, qr/contains takes a widget, got 'panel'/, 'a non-widget dies' );
};

subtest 'has_focus_within' => sub {
	my $panel = Clay::UI::Test::Box->new(id => 'panel');
	my $deep  = TestInput->new(id => 'deep');
	my $other = TestInput->new(id => 'other');
	$panel->add_child($deep);
	my $ui = make_ui($panel, $other);
	my $interaction = $ui->interaction;
	is( $interaction->has_focus_within($panel), 0, 'nothing focused' );
	$interaction->set_focused_widget($deep);
	is( [ map { $interaction->has_focus_within($_) } $panel, $deep, $ui->root, $other ], [ 1, 1, 1, 0 ],
		'true for the focused widget and its ancestors only' );
	like( dies { $interaction->has_focus_within(undef) }, qr/has_focus_within: takes a widget, got undef/, 'a non-widget dies' );
};

subtest 'focusables lists what can take the focus now, within a scope' => sub {
	my $panel    = TestInput->new(id => 'panel');
	my $first    = TestInput->new(id => 'first');
	my $disabled = TestInput->new(id => 'disabled', disabled => 1);
	my $unwilling = TestInput->new(id => 'unwilling', can_focus => 0);
	my $refusing = TestToggleInput->new(id => 'refusing');
	my $helper   = TestInput->new(id => 'helper');
	my $outside  = TestInput->new(id => 'outside');
	$refusing->set_accepting(0);
	$panel->add_internal_children($first, $disabled, $unwilling, $refusing, $helper);
	my $ui = make_ui($panel, $outside);
	my $ids = sub (@widgets) { [ map { $_->id } @widgets ] };
	is( $ids->($ui->interaction->focusables(within => $panel)), [qw(panel first helper)],
		'the scope root counts; disabled and ineligible widgets do not' );
	is( $ids->($ui->interaction->focusables), [qw(panel first helper outside)], 'without a scope: the whole tree' );
	like( dies { $ui->interaction->focusables(within => TestInput->new(id => 'loose')) },
		qr/focusables: 'within' must be a widget of this Clay::UI/, 'a scope outside the UI dies' );
	like( dies { $ui->interaction->focusables(inside => $panel) }, qr/focusables: unknown argument\(s\): inside/,
		'an unknown argument dies' );
};

subtest 'scoped stepping wraps inside the scope' => sub {
	my $before = TestInput->new(id => 'before');
	my $dialog = Clay::UI::Test::Box->new(id => 'dialog');
	my @inside = map { TestInput->new(id => $_) } qw(x y z);
	my $after  = TestInput->new(id => 'after');
	$dialog->add_child(@inside);
	$inside[1]->disabled(1);
	my $ui = make_ui($before, $dialog, $after);
	my $interaction = $ui->interaction;

	$interaction->set_focused_widget($before);
	same( $interaction->default_next_focus(within => $dialog), $inside[0], 'focus outside: next starts at the first' );
	same( $interaction->default_previous_focus(within => $dialog), $inside[2], 'and previous at the last' );
	$interaction->set_focused_widget($inside[2]);
	same( $interaction->default_next_focus(within => $dialog), $inside[0], 'next wraps around inside the scope' );
	same( $interaction->default_previous_focus(within => $dialog), $inside[0], 'previous skips the disabled one' );
	same( $interaction->default_next_focus, $after, 'without a scope the whole tree is stepped' );
	$_->disabled(1) for @inside;
	is( $interaction->default_next_focus(within => $dialog), undef, 'nothing in the scope can take the focus' );
};

subtest 'a HasFocusOrder passes the scope on to the tracker' => sub {
	my $trap = TestTrap->new(id => 'trap');
	my @inside = map { TestInput->new(id => $_) } qw(p q);
	$trap->add_child(@inside);
	my $ui = make_ui(TestInput->new(id => 'outside'), $trap);
	$ui->interaction->set_focused_widget($inside[0]);
	my @seen;
	for (1 .. 3) {
		$ui->interaction->focus_next;
		push @seen, $ui->interaction->get_focused_widget->id;
	}
	is( \@seen, [qw(q p q)], 'Tab stays inside the trap' );
	$ui->interaction->focus_previous;
	is( $ui->interaction->get_focused_widget->id, 'p', 'and so does Shift-Tab' );
};

subtest 'focus_eligibility_changed releases a widget its class no longer lets take the focus' => sub {
	my $toggle = TestToggleInput->new(id => 'toggle');
	my $ui     = make_ui($toggle);
	my @log;
	$toggle->on('OnBlur', sub ($e) { push @log, 'blur'; return });
	$ui->interaction->set_focused_widget($toggle);
	my $revision = current_revision();
	$toggle->set_accepting(0);
	is( [ \@log, $ui->interaction->get_focused_widget ], [ ['blur'], undef ], 'the focused widget is blurred at once' );
	ok( current_revision() > $revision, 'and the revision is bumped' );
	is( $toggle->can_focus, 0, 'it cannot focus' );
	$toggle->set_accepting(1);
	is( $toggle->can_focus, 1, 'until its class accepts the focus again' );
	ok( lives { TestToggleInput->new(id => 'loose')->set_accepting(0) }, 'outside a UI it only bumps the revision' );
};

# -----------------------------------------------------------------------------
# is_focused tracks transitions.
# -----------------------------------------------------------------------------

subtest 'is_focused tracks focus / blur transitions' => sub {
	my $a  = TestInput->new(id => 'a');
	my $b  = TestInput->new(id => 'b');
	my $ui = make_ui($a, $b);

	is($a->is_focused, 0, 'before: a not focused');
	$ui->interaction->set_focused_widget($a);
	is($a->is_focused, 1, 'after focus(a): a focused');
	$ui->interaction->set_focused_widget($b);
	is($a->is_focused, 0, 'after focus(b): a no longer focused');
	is($b->is_focused, 1, 'after focus(b): b focused');
};

done_testing;
