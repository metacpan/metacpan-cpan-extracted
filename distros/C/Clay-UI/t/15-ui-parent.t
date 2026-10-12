use v5.22;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Test2::V0;

use lib "t/lib";
use Scalar::Util qw(refaddr);

sub same ($a, $b, $name) { is(refaddr($a), refaddr($b), $name) }

use Object::Pad 0.800;
use Clay::UI;
use Clay::XS ();
use Clay::UI::Revision qw(current_revision);
use Clay::UI::Test::Box;
use Clay::UI::Test::Grid;
use Clay::UI::Test::Text;
use Clay::UI::Role::Core::Container;
use Clay::UI::Role::Interaction::Focusable;
use Clay::UI::Role::Layout::GridCell;

class FocusBox :strict(params)
	:does(Clay::UI::Role::Core::Container)
	:does(Clay::UI::Role::Interaction::Focusable)
{}

# tree_changed calls, as "label:parent id:ui or no-ui". A class cannot
# override a method of a role it composes itself, so the hooks live in
# subclasses.
my @tree_log;

sub log_tree_change ($label, $widget) {
	my $parent = $widget->parent;
	push @tree_log, join ':', $label, (defined $parent ? $parent->id // ref $parent : '-'), (defined $widget->ui ? 'ui' : 'no-ui');
	return;
}

class HookBox :strict(params) :isa(FocusBox) {
	field $die_with :writer = undef;

	method tree_changed :override () {
		$self->SUPER::tree_changed;
		main::log_tree_change($self->id, $self);
		die $die_with if defined $die_with;
		return;
	}
}

class HookGridCell :strict(params) :isa(HookBox) :does(Clay::UI::Role::Layout::GridCell) {}

class HookText :strict(params) :isa(Clay::UI::Test::Text) {
	method tree_changed :override () {
		$self->SUPER::tree_changed;
		main::log_tree_change($self->text, $self);
		return;
	}
}

# -----------------------------------------------------------------------------
# Parent stamping: children attached via add_child get their parent slot
# filled before any tree walk runs.
# -----------------------------------------------------------------------------

subtest 'root widget has no parent and is its own root' => sub {
	my $root = Clay::UI::Test::Box->new;
	is($root->parent, undef, 'root parent is undef');
	same($root->root, $root, 'root->root is itself');
};

subtest 'children added via add_child are parent-stamped' => sub {
	my $parent = Clay::UI::Test::Box->new(id => 'p');
	my $kid    = Clay::UI::Test::Box->new(id => 'k');
	$parent->add_child($kid);
	same($kid->parent, $parent, 'add_child stamps parent');
	same($kid->root,   $parent, 'add_child child root resolves');
};

subtest 'insert_children puts widgets before an index without detaching the others' => sub {
	my $parent = Clay::UI::Test::Box->new(id => 'p');
	my ($a, $b, $c, $d) = map { Clay::UI::Test::Box->new(id => $_) } qw(a b c d);
	$parent->add_child($a, $d);
	$parent->insert_children(1, $b, $c);
	is( [ map { $_->id } @{ $parent->children } ], [qw(a b c d)], 'the new children sit at the offset, in order' );
	same($b->parent, $parent, 'they are parent-stamped');
	same($parent->children->[3], $d, 'the child after the offset is the same object');
	$parent->insert_children(4, Clay::UI::Test::Box->new(id => 'e'));
	is( [ map { $_->id } @{ $parent->children } ], [qw(a b c d e)], 'the child count appends' );
	like( dies { $parent->insert_children(6, Clay::UI::Test::Box->new) }, qr/child offset 6 out of range 0\.\.5/, 'an offset past the end dies' );
	is( scalar @{ $parent->children }, 5, 'and changes nothing' );
};

subtest 'TextNode children are parent-stamped too' => sub {
	my $text = Clay::UI::Test::Text->new(text => 'hi');
	my $box  = Clay::UI::Test::Box->new;
	$box->add_child($text);
	same($text->parent, $box, 'text node parent set');
	same($text->root,   $box, 'text node root resolves');
	is( $text->id, undef, 'a text node answers id with undef' );
	is( [ $box->get_children_with(sub { ($_->id // '') eq 'none' }) ], [], 'so predicates may read it unguarded' );
};

# -----------------------------------------------------------------------------
# Deep chains: root walks all the way to the top, no matter the depth.
# -----------------------------------------------------------------------------

subtest 'root walks a multi-level chain' => sub {
	my $leaf = Clay::UI::Test::Box->new(id => 'leaf');
	my $b    = Clay::UI::Test::Box->new(id => 'b');
	$b->add_child($leaf);
	my $a    = Clay::UI::Test::Box->new(id => 'a');
	$a->add_child($b);
	my $root = Clay::UI::Test::Box->new(id => 'r');
	$root->add_child($a);
	same($leaf->root, $root, 'leaf->root reaches the top');
	same($b->root,    $root, 'mid-chain->root reaches the top');
	same($a->root,    $root, 'one-from-top->root reaches the top');
};

# -----------------------------------------------------------------------------
# Attaching: a widget can be attached whenever it has no parent.
# -----------------------------------------------------------------------------

subtest 'adding a widget that has a parent to a second parent dies' => sub {
	my $kid = Clay::UI::Test::Box->new(id => 'k');
	my $p1  = Clay::UI::Test::Box->new;
	$p1->add_child($kid);
	my $p2  = Clay::UI::Test::Box->new;
	like(
		dies { $p2->add_child($kid) },
		qr/widget Clay::UI::Test::Box is still attached to a parent; remove it first/,
		'second-parent attempt dies with descriptive message',
	);
	same($kid->parent, $p1, 'the widget keeps its parent');
	is(scalar @{ $p2->children }, 0, 'the second parent has no children');
};

subtest 'adding a widget again to its own parent also dies' => sub {
	my $kid = Clay::UI::Test::Box->new(id => 'k');
	my $p   = Clay::UI::Test::Box->new;
	$p->add_child($kid);
	like(
		dies { $p->add_child($kid) },
		qr/still attached to a parent/,
		'second add under same parent dies',
	);
	is(scalar @{ $p->children }, 1, 'the widget is a child once');
};

subtest 'a removed widget can be added back to the same parent' => sub {
	my $kid = Clay::UI::Test::Box->new(id => 'k');
	my $p   = Clay::UI::Test::Box->new;
	$p->add_child($kid, Clay::UI::Test::Box->new(id => 'other'));
	$p->remove_child($kid);
	is($kid->parent, undef, 'parent slot cleared by remove_child');
	same($kid->root, $kid, 'the removed widget is the root of its subtree');
	ok(lives { $p->add_child($kid) }, 're-adding lives');
	same($kid->parent, $p, 'the parent is stamped again');
	is([ map { $_->id } @{ $p->children } ], [ 'other', 'k' ], 'the widget is appended');
};

subtest 'a removed widget can move to another parent' => sub {
	my $kid  = Clay::UI::Test::Box->new(id => 'k');
	my $leaf = Clay::UI::Test::Box->new(id => 'leaf');
	$kid->add_child($leaf);
	my $p1 = Clay::UI::Test::Box->new;
	my $p2 = Clay::UI::Test::Box->new;
	$p1->add_child($kid);
	$p1->clear_children;
	ok(lives { $p2->add_child($kid) }, 'adding to another parent lives');
	same($kid->parent, $p2, 'the new parent is stamped');
	same($leaf->root, $p2, 'its subtree moved along');
	$p2->remove_children_with(sub { $_->id eq 'k' });
	ok(lives { $p1->add_child($kid) }, 'and it can move back after remove_children_with');
	same($kid->parent, $p1, 'back at the first parent');
};

# -----------------------------------------------------------------------------
# Children by identity: remove_child and has_child compare the widget
# itself, so widgets without an id and text widgets are reachable.
# -----------------------------------------------------------------------------

subtest 'remove_child removes the given widgets by identity' => sub {
	my $p     = Clay::UI::Test::Box->new;
	my $plain = Clay::UI::Test::Box->new;
	my $twin  = Clay::UI::Test::Box->new;
	my $label = Clay::UI::Test::Text->new(text => 'label');
	$p->add_child($plain, $twin, $label);
	same($p->remove_child($plain, $label), $p, 'remove_child returns the widget');
	is(scalar @{ $p->children }, 1, 'two of three children left');
	same($p->children->[0], $twin, 'the one that was not named stays');
	is([ $plain->parent, $label->parent ], [ undef, undef ], 'both are detached, the text widget too');
};

subtest 'remove_child ignores widgets that are not its children' => sub {
	my $p         = Clay::UI::Test::Box->new;
	my $other     = Clay::UI::Test::Box->new;
	my $elsewhere = Clay::UI::Test::Box->new;
	my $grandkid  = Clay::UI::Test::Box->new;
	my $kid       = Clay::UI::Test::Box->new;
	my $helper    = Clay::UI::Test::Box->new;
	$other->add_child($elsewhere);
	$kid->add_child($grandkid);
	$p->add_child($kid);
	$p->add_internal_children($helper);
	my $before = current_revision();
	$p->remove_child(Clay::UI::Test::Box->new, $elsewhere, $grandkid, $helper);
	is(current_revision(), $before, 'nothing changed, so the revision stays');
	same($elsewhere->parent, $other, 'a widget attached elsewhere keeps its parent');
	same($grandkid->parent, $kid, 'a grandchild keeps its parent');
	same($helper->parent, $p, 'an internal child stays');
	is(scalar @{ $p->children }, 1, 'the child is still there');
};

subtest 'remove_child takes widgets only' => sub {
	my $p   = Clay::UI::Test::Box->new;
	my $kid = Clay::UI::Test::Box->new(id => 'kid');
	$p->add_child($kid);
	like(dies { $p->remove_child($kid, 'kid') },
		qr/^Clay::UI: remove_child takes widgets, got 'kid'; remove a child by its id with remove_child_with_id at /,
		'an id dies and names remove_child_with_id');
	like(dies { $p->remove_child(undef) }, qr/^Clay::UI: remove_child takes widgets, got undef;/, 'undef dies');
	like(dies { $p->remove_child({}) },    qr/^Clay::UI: remove_child takes widgets, got HASH;/,  'a plain reference dies');
	same($kid->parent, $p, 'a dying call removes nothing');
};

subtest 'has_child answers by identity for direct children' => sub {
	my $p        = Clay::UI::Test::Box->new;
	my $kid      = Clay::UI::Test::Box->new;
	my $label    = Clay::UI::Test::Text->new(text => 'label');
	my $grandkid = Clay::UI::Test::Box->new;
	my $helper   = Clay::UI::Test::Box->new;
	my $other    = Clay::UI::Test::Box->new;
	my $stranger = Clay::UI::Test::Box->new;
	$kid->add_child($grandkid);
	$other->add_child($stranger);
	$p->add_child($kid, $label);
	$p->add_internal_children($helper);
	is([ map { $p->has_child($_) } $kid, $label ], [ 1, 1 ], 'a child and a text child');
	is([ map { $p->has_child($_) } $grandkid, $helper, $stranger, Clay::UI::Test::Box->new ], [ 0, 0, 0, 0 ],
		'not a grandchild, an internal child, a widget attached elsewhere or a loose widget');
	$p->remove_child($kid);
	is($p->has_child($kid), 0, 'not after its removal');
	like(dies { $p->has_child('kid') }, qr/^Clay::UI: has_child takes a widget, got 'kid' at /, 'an id dies');
};

# -----------------------------------------------------------------------------
# Weak-ref behaviour: the parent slot does not keep the parent alive.
# -----------------------------------------------------------------------------

subtest 'parent slot is a weak reference' => sub {
	my $kid;
	{
		my $parent = Clay::UI::Test::Box->new;
		$parent->add_child(Clay::UI::Test::Box->new(id => 'k'));
		($kid) = @{ $parent->children };
		same($kid->parent, $parent, 'parent set inside scope');
	}
	# $parent is gone; $kid survives through the lexical above, and its
	# weak parent slot reads undef.
	is($kid->parent, undef, 'parent slot collapses to undef after GC');
	same($kid->root, $kid,  'root falls back to self once chain is gone');
};

# -----------------------------------------------------------------------------
# add_child rejects non-widget children.
# -----------------------------------------------------------------------------

subtest 'non-widget children are rejected by add_child' => sub {
	my $p = Clay::UI::Test::Box->new;
	like(
		dies { $p->add_child('not a widget') },
		qr/not a widget/,
		'add_child rejects non-widgets',
	);
};

# -----------------------------------------------------------------------------
# add_child validates the whole call before changing anything.
# -----------------------------------------------------------------------------

subtest 'a failed add_child changes nothing' => sub {
	my $p     = Clay::UI::Test::Box->new(id => 'p');
	my $new   = Clay::UI::Test::Box->new(id => 'new');
	my $other = Clay::UI::Test::Box->new;
	my $old   = Clay::UI::Test::Box->new(id => 'old');
	$other->add_child($old);

	like( dies { $p->add_child($new, $old) }, qr/still attached to a parent; remove it first/,
		'a kid that has a parent fails the call' );
	is( $new->parent, undef, 'the valid kid was not parented' );
	is( scalar @{ $p->children }, 0, 'the parent has no new children' );
	ok( lives { $p->add_child($new) }, 'the valid kid can still be attached' );

	my $k = Clay::UI::Test::Box->new(id => 'k');
	like( dies { $p->add_child($k, $k) }, qr/attached twice in one call/, 'a duplicate within one call dies' );
	is( $k->parent, undef, 'and leaves the kid unattached' );
};

subtest 'cycles are rejected' => sub {
	my $s = Clay::UI::Test::Box->new(id => 's');
	like( dies { $s->add_child($s) }, qr/cannot attach a widget to itself or to one of its descendants/,
		'a widget cannot be its own child' );

	my $top  = Clay::UI::Test::Box->new(id => 'top');
	my $leaf = Clay::UI::Test::Box->new(id => 'leaf');
	$top->add_child($leaf);
	like( dies { $leaf->add_child($top) }, qr/cannot attach a widget to itself or to one of its descendants/,
		'an ancestor cannot become a child' );
	same( $leaf->root, $top, 'the tree is unchanged' );
};

subtest 'a Clay::UI root cannot become a child' => sub {
	my $root = Clay::UI::Test::Box->new(id => 'root');
	my $ui   = Clay::UI->new(root => $root, width => 100, height => 100);
	like( dies { Clay::UI::Test::Box->new->add_child($root) }, qr/is the root of a Clay::UI/,
		'bound root rejected' );
};

subtest 'children returns a copy' => sub {
	my $p = Clay::UI::Test::Box->new;
	$p->add_child(Clay::UI::Test::Box->new);
	push @{ $p->children }, 'junk';
	is( scalar @{ $p->children }, 1, 'changing the returned array does not change the widget' );
};

subtest 'a widget whose old parent is gone can be attached again' => sub {
	my $kid = Clay::UI::Test::Box->new(id => 'k');
	{
		my $parent = Clay::UI::Test::Box->new;
		$parent->add_child($kid);
	}
	is( $kid->parent, undef, 'the old parent is gone' );
	my $new = Clay::UI::Test::Box->new;
	ok( lives { $new->add_child($kid) }, 'attaching it lives' );
	same( $kid->parent, $new, 'the new parent is stamped' );
};

subtest 'a removed widget can become a Clay::UI root' => sub {
	my $app   = Clay::UI::Test::Box->new(id => 'app');
	my $panel = Clay::UI::Test::Box->new(id => 'panel');
	$app->add_child($panel);
	$app->remove_child_with_id('panel');
	my $ui;
	ok( lives { $ui = Clay::UI->new(root => $panel, width => 10, height => 10) }, 'Clay::UI->new lives' );
	same( $panel->ui, $ui, 'the controller is stamped on it' );
	like( dies { $app->add_child($panel) }, qr/is the root of a Clay::UI/, 'and as a root it cannot become a child' );
};

# -----------------------------------------------------------------------------
# Clay::UI back-reference: every widget reachable from the root can find
# its Clay::UI controller via $self->ui.
# -----------------------------------------------------------------------------

subtest 'internal children are laid out but are not children' => sub {
	my $box    = Clay::UI::Test::Box->new(id => 'box');
	my $kid    = Clay::UI::Test::Box->new(id => 'kid');
	my $helper = Clay::UI::Test::Box->new(
		id               => 'helper',
		background_color => [ 1, 2, 3, 255 ],
		layout           => { sizing => { width => Clay::XS::sizing_fixed(10), height => Clay::XS::sizing_fixed(10) } },
	);
	$box->add_child($kid);
	$box->add_internal_children($helper);
	same($helper->parent, $box, 'an internal child is parent-stamped');
	is([ map { $_->id } @{ $box->children } ],          ['kid'],           'children shows only the children');
	is([ map { $_->id } @{ $box->internal_children } ], ['helper'],        'internal_children shows the helper');
	is([ map { $_->id } @{ $box->layout_children } ],   [ 'kid', 'helper' ], 'layout_children lays out both, children first');
	$box->clear_children;
	is([ map { $_->id } @{ $box->layout_children } ], ['helper'], 'clear_children leaves the internal children alone');
	like(dies { $box->add_internal_children($helper) }, qr/still attached/, 'attaching it again dies like add_child');

	my $ui = Clay::UI->new(root => $box, width => 100, height => 100);
	same($helper->ui, $ui, 'an internal child reaches the controller');
	my @drawn = map { $ui->widget_for($_->{userData}) } @{ $ui->render };
	ok((grep { defined && refaddr($_) == refaddr($helper) } @drawn), 'the walker declares the internal child');

	$box->remove_internal_children($helper, Clay::UI::Test::Box->new);
	is($helper->parent, undef, 'remove_internal_children detaches it and ignores strangers');
	is($box->layout_children, [], 'and it is laid out no more');
	ok(lives { $box->add_child($helper) }, 'a removed internal child can become a child');
};

subtest 'unattached widget ui() is undef' => sub {
	my $w = Clay::UI::Test::Box->new;
	is($w->ui, undef, 'no ui controller before Clay::UI->new');
};

subtest 'a removed subtree has no controller' => sub {
	my $root   = Clay::UI::Test::Box->new(id => 'root');
	my $branch = Clay::UI::Test::Box->new(id => 'branch');
	my $leaf   = Clay::UI::Test::Box->new(id => 'leaf');
	$branch->add_child($leaf);
	$root->add_child($branch);
	my $ui = Clay::UI->new(root => $root, width => 100, height => 100);
	same($leaf->ui, $ui, 'attached leaf reaches the controller');
	$root->remove_child_with_id('branch');
	is($branch->ui, undef, 'removed widget has no controller');
	is($leaf->ui,   undef, 'nor do its descendants');
};

subtest 'a dying OnBlur listener does not stop the detachment' => sub {
	my $root  = Clay::UI::Test::Box->new(id => 'root');
	my $panel = Clay::UI::Test::Box->new(id => 'panel');
	my $input = FocusBox->new(id => 'input');
	$panel->add_child($input);
	$root->add_child($panel);
	my $ui = Clay::UI->new(root => $root, width => 100, height => 100);
	$ui->interaction->set_focused_widget($input);
	$input->on('OnBlur', sub ($e) { die "blur listener bug\n" });

	like( dies { $root->remove_child_with_id('panel') }, qr/^blur listener bug$/, 'remove_child_with_id dies with the listener error' );
	is( scalar @{ $root->children }, 0, 'the panel was removed' );
	is( $panel->parent, undef, 'and detached' );
	is( $input->ui, undef, 'its subtree has no controller' );
	is( $ui->interaction->get_focused_widget, undef, 'focus was released' );
	like( dies { $ui->interaction->set_focused_widget($input) }, qr/does not belong to this Clay::UI/,
		'the removed widget cannot be focused again' );

	my $grid = Clay::UI::Test::Grid->new(id => 'grid');
	my $cell = FocusBox->new(id => 'cell');
	$grid->append_row([ $cell ]);
	my $grid_ui = Clay::UI->new(root => $grid, width => 100, height => 100);
	$grid_ui->interaction->set_focused_widget($cell);
	$cell->on('OnBlur', sub ($e) { die "blur listener bug\n" });
	like( dies { $grid->remove_row(0) }, qr/^blur listener bug$/, 'remove_row dies with the listener error' );
	is( $grid->row_count, 0, 'the row was removed' );
	is( $cell->ui, undef, 'the cell is detached' );
	is( $grid_ui->interaction->get_focused_widget, undef, 'focus was released' );
};

subtest 'Clay::UI stamps itself on the root; descendants reach it via ui()' => sub {
	my $leaf = Clay::UI::Test::Box->new(id => 'leaf');
	my $mid  = Clay::UI::Test::Box->new(id => 'mid');
	$mid->add_child($leaf);
	my $root = Clay::UI::Test::Box->new(id => 'root');
	$root->add_child($mid);
	my $ui   = Clay::UI->new(root => $root, width => 100, height => 100);

	same($root->ui, $ui, 'root sees its Clay::UI');
	same($mid->ui,  $ui, 'descendant sees Clay::UI through root walk');
	same($leaf->ui, $ui, 'deep descendant sees Clay::UI');
};

subtest 'a widget with a parent cannot be a Clay::UI root' => sub {
	my $app   = Clay::UI::Test::Box->new(id => 'app');
	my $panel = Clay::UI::Test::Box->new(id => 'panel');
	$app->add_child($panel);
	like(
		dies { Clay::UI->new(root => $panel, width => 100, height => 100) },
		qr/'root' must not have a parent/,
		'Clay::UI->new rejects a parented root',
	);
};

subtest 'second Clay::UI on the same root dies' => sub {
	my $root = Clay::UI::Test::Box->new;
	my $ui   = Clay::UI->new(root => $root, width => 100, height => 100);
	my $current = Clay::XS::Clay_GetCurrentContext();
	like(
		dies { Clay::UI->new(root => $root, width => 50, height => 50) },
		qr/'root' is already the root of another Clay::UI/,
		'cannot re-attach root to a second Clay::UI',
	);
	ref_is( Clay::XS::Clay_GetCurrentContext(), $current, 'the current Clay context is unchanged' );
	ok( lives { $ui->render }, 'the first Clay::UI still renders' );
};

# -----------------------------------------------------------------------------
# tree_changed: every widget of a subtree whose place changed is told, once
# the change is complete.
# -----------------------------------------------------------------------------

sub hook_ui ($root) { return Clay::UI->new(root => $root, width => 100, height => 100) }

subtest 'tree_changed runs on every widget of an attached subtree, in pre-order' => sub {
	my $root = HookBox->new(id => 'root');
	my $ui   = hook_ui($root);
	my ($panel, $a, $b) = map { HookBox->new(id => $_) } qw(panel a b);
	$a->add_child(HookText->new(text => 'text'));
	$panel->add_child($a, $b);
	@tree_log = ();
	$root->add_child($panel);
	is( \@tree_log, [ 'panel:root:ui', 'a:panel:ui', 'text:a:ui', 'b:panel:ui' ], 'once each, with parent and ui already set' );
};

subtest 'on removal tree_changed runs after OnBlur, with ui undef' => sub {
	my $root  = HookBox->new(id => 'root');
	my $panel = HookBox->new(id => 'panel');
	my $input = HookBox->new(id => 'input');
	$panel->add_child($input);
	$root->add_child($panel);
	my $ui = hook_ui($root);
	$ui->interaction->set_focused_widget($input);
	$input->on('OnBlur', sub ($e) { push @tree_log, 'OnBlur'; return });
	@tree_log = ();
	$root->remove_child($panel);
	is( \@tree_log, [ 'OnBlur', 'panel:-:no-ui', 'input:panel:no-ui' ], 'the subtree has left when the hooks run' );
};

subtest 'tree_changed runs on internal children' => sub {
	my $root   = HookBox->new(id => 'root');
	my $ui     = hook_ui($root);
	my $helper = HookBox->new(id => 'helper');
	@tree_log = ();
	$root->add_internal_children($helper);
	$root->remove_internal_children($helper);
	is( \@tree_log, [ 'helper:root:ui', 'helper:-:no-ui' ], 'when they are added and removed' );
};

subtest 'a new Clay::UI announces itself to the root\'s subtree' => sub {
	my $root  = HookBox->new(id => 'root');
	my $child = HookBox->new(id => 'child');
	$root->add_child($child);
	@tree_log = ();
	my $ui = hook_ui($root);
	is( \@tree_log, [ 'root:-:ui', 'child:root:ui' ], 'every widget, with ui already set' );
};

subtest 'a hook that dies while a Clay::UI is built fails the construction cleanly' => sub {
	my $ui      = hook_ui(HookBox->new(id => 'other'));
	my $current = Clay::XS::Clay_GetCurrentContext();
	my $root    = HookBox->new(id => 'root');
	my $child   = HookBox->new(id => 'child');
	$root->add_child($child);
	$root->set_die_with("root hook bug\n");
	@tree_log = ();
	like( dies { hook_ui($root) }, qr/^root hook bug$/, 'new dies with the hook error' );
	is( \@tree_log, [ 'root:-:ui', 'child:root:ui' ], 'after every hook ran' );
	ref_is( Clay::XS::Clay_GetCurrentContext(), $current, 'the context current before is current again' );
	$root->set_die_with(undef);
	ok( lives { hook_ui($root)->render }, 'the root can become the root of another Clay::UI' );
};

subtest 'reordering is no tree change' => sub {
	my $grid = Clay::UI::Test::Grid->new(id => 'grid');
	$grid->append_row([ HookBox->new(id => 'first') ]);
	$grid->append_row([ HookBox->new(id => 'second') ]);
	@tree_log = ();
	$grid->reorder_rows([ 1, 0 ]);
	is( \@tree_log, [], 'no tree_changed call' );
};

subtest 'every hook runs even if one dies' => sub {
	my $root  = HookBox->new(id => 'root');
	my $panel = HookBox->new(id => 'panel');
	my ($bad, $worse, $good) = map { HookBox->new(id => $_) } qw(bad worse good);
	$panel->add_child($bad, $worse, $good);
	$bad->set_die_with("first hook bug\n");
	$worse->set_die_with("second hook bug\n");
	my $ui = hook_ui($root);
	@tree_log = ();
	like( dies { $root->add_child($panel) }, qr/^first hook bug$/, 'the first error is rethrown' );
	is( \@tree_log, [ 'panel:root:ui', 'bad:panel:ui', 'worse:panel:ui', 'good:panel:ui' ], 'after every hook ran' );
	same( $panel->parent, $root, 'and the change is complete' );

	my $holder = HookBox->new(id => 'holder');
	$holder->add_child(HookBox->new(id => 'leaf'));
	$root->add_child($holder);
	my $leaf = $holder->children->[0];
	$ui->interaction->set_focused_widget($leaf);
	$leaf->on('OnBlur', sub ($e) { die "blur listener bug\n" });
	like( dies { $root->remove_child($panel, $holder) }, qr/^blur listener bug$/,
		'a release listener error wins over the hook errors after it' );
	is( [ $panel->parent, $holder->parent ], [ undef, undef ], 'both subtrees are detached' );
};

# Each Grid mutator builds the new row or cell first and announces it once
# it is in the grid: a cell the grid wraps ('wrapped') and a GridCell that
# is its own wrapper ('own') each get one call, with ui set.
my %grid_mutations = (
	append_row           => [ sub ($grid, @cells) { $grid->append_row([@cells]) },           qw(wrapped own) ],
	insert_row           => [ sub ($grid, @cells) { $grid->insert_row(0, [@cells]) },        qw(wrapped own) ],
	append_spanning_row  => [ sub ($grid, @cells) { $grid->append_spanning_row(@cells) },    qw(own) ],
	replace_row          => [ sub ($grid, @cells) { $grid->replace_row(0, [@cells]) },       qw(wrapped own) ],
	replace_spanning_row => [ sub ($grid, @cells) { $grid->replace_spanning_row(0, @cells) }, qw(wrapped) ],
	set_cell             => [ sub ($grid, @cells) { $grid->set_cell(0, 1, @cells) },         qw(wrapped) ],
);
for my $name (sort keys %grid_mutations) {
	my ($mutate, @labels) = @{ $grid_mutations{$name} };
	subtest "Grid's $name announces every new cell once, inside the grid" => sub {
		my $root = HookBox->new(id => 'root');
		my $grid = Clay::UI::Test::Grid->new(id => 'grid');
		$root->add_child($grid);
		my $ui = hook_ui($root);
		$grid->append_row([ HookBox->new(id => 'old') ]);
		my %class_of = (wrapped => 'HookBox', own => 'HookGridCell');
		my @cells = map { $class_of{$_}->new(id => $_) } @labels;
		@tree_log = ();
		$mutate->($grid, @cells);
		my %calls;
		for my $entry (@tree_log) {
			my ($label, $ui_flag) = ( split /:/, $entry )[ 0, -1 ];
			push @{ $calls{$label} }, $ui_flag unless $label eq 'old';
		}
		is( \%calls, { map { $_ => ['ui'] } @labels }, 'one call per new cell, with ui set' );
	};
}

subtest 'a dying hook in append_row leaves the row added' => sub {
	my $root = HookBox->new(id => 'root');
	my $grid = Clay::UI::Test::Grid->new(id => 'grid');
	$root->add_child($grid);
	my $ui   = hook_ui($root);
	my $cell = HookGridCell->new(id => 'cell');
	$cell->set_die_with("cell hook bug\n");
	like( dies { $grid->append_row([ $cell, HookBox->new(id => 'other') ]) }, qr/^cell hook bug$/,
		'append_row dies with the hook error' );
	is( $grid->row_count, 1, 'after the row was added' );
	same( $cell->parent->parent, $grid, 'with the cell in it' );
	$cell->set_die_with(undef);
	my $next = HookGridCell->new(id => 'next');
	$grid->append_row([$next]);
	isnt( $next->height_group, $cell->height_group, 'the next row gets a height group of its own' );
	is( $next->width_group, $cell->width_group, 'and shares the first column' );
};

done_testing;
