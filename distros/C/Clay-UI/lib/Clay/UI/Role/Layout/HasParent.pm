package Clay::UI::Role::Layout::HasParent;
our $VERSION = '0.07';
use v5.22;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Object::Pad 0.800;
use Exporter 'import';
use List::Util qw(first);
use Scalar::Util qw(blessed refaddr weaken);
use Clay::UI::_error qw(croak_ui);
use Clay::UI::_validate qw(described_value require_predicate);

our @EXPORT_OK = qw(is_widget);

# A widget is an element or a text widget: only those can be in a tree.
# The roles are named, not loaded, so this needs no use of them.
sub is_widget ($thing) {
	return blessed($thing)
		&& ($thing->DOES('Clay::UI::Role::Core::Element') || $thing->DOES('Clay::UI::Role::Core::TextNode')) ? 1 : 0;
}

role Clay::UI::Role::Layout::HasParent {
	field $parent :reader = undef;
	field $_ui_controller = undef;

	method _set_parent ($new_parent) {
		croak_ui "Clay::UI: parent must be a blessed widget"
			unless blessed $new_parent;
		croak_ui "Clay::UI: widget " . ref($self) . " is still attached to a parent; remove it first"
			if defined $parent;
		$parent = $new_parent;
		weaken $parent;
		return;
	}

	# Clears the parent slot when the widget is removed from its parent; the
	# widget can then be attached again.
	method _detach_parent () {
		$parent = undef;
		return;
	}

	# The widgets above this one, nearest first; the widget itself is not
	# one of them.
	method ancestors () {
		my @chain;
		for (my $node = $parent; defined $node; $node = $node->parent) {
			push @chain, $node;
		}
		return @chain;
	}

	# The widget itself or its nearest ancestor that $predicate accepts,
	# or undef.
	method closest ($predicate) {
		require_predicate(closest => $predicate);
		return first { $predicate->($_) } $self, $self->ancestors;
	}

	# The widget, then every widget below it in layout pre-order.
	method subtree () {
		return ($self, $self->DOES('Clay::UI::Role::Core::Element') ? $self->descendants : ());
	}

	method root () {
		my @ancestors = $self->ancestors;
		return @ancestors ? $ancestors[-1] : $self;
	}

	# True when $widget is this widget or below it.
	method contains ($widget) {
		croak_ui "Clay::UI: contains takes a widget, got " . described_value($widget)
			unless is_widget($widget);
		return defined $widget->closest(sub ($node) { refaddr($node) == refaddr($self) }) ? 1 : 0;
	}

	method _set_ui_controller ($ui) {
		croak_ui "Clay::UI: ui controller must be a Clay::UI instance"
			unless blessed($ui) && $ui->isa('Clay::UI');
		croak_ui "Clay::UI: widget already bound to a Clay::UI controller"
			if defined $_ui_controller;
		$_ui_controller = $ui;
		weaken $_ui_controller;
		return;
	}

	method _local_ui_controller () { $_ui_controller }

	method ui () {
		my $top = $self->root;
		return $top->_local_ui_controller;
	}

	# Called on every widget of a subtree whose place in a tree changed,
	# once the change is complete. Widget classes override it.
	method tree_changed () {
		return;
	}

	# Calls tree_changed on this widget and every widget below it, in
	# layout pre-order. Every hook runs even if one dies; returns the
	# first error, or undef.
	method _announce_tree_change () {
		my $first_error;
		for my $widget ($self->subtree) {
			local $@;
			eval { $widget->tree_changed; 1 } or $first_error //= $@ || 'unknown tree_changed error';
		}
		return $first_error;
	}
}

1;

__END__

=head1 NAME

Clay::UI::Role::Layout::HasParent - parent, root and UI of a Clay::UI widget

=head1 SYNOPSIS

	use v5.22;
	use Object::Pad;
	use Clay::UI;
	use Clay::UI::Box;

	class My::Box :strict(params) :does(Clay::UI::Box) {}

	my $root  = My::Box->new(id => 'root');
	my $panel = My::Box->new(id => 'panel');
	my $child = My::Box->new;
	$root->add_child($panel);
	$panel->add_child($child);

	my $ui = Clay::UI->new(width => 800, height => 600, root => $root);

	$child->parent;       # $panel
	$child->ancestors;    # ($panel, $root)
	$child->root;         # $root
	$child->ui;           # $ui
	$panel->contains($child);    # 1
	$child->closest(sub { defined $_->id });    # $panel
	$panel->subtree;      # ($panel, $child)

	use Clay::UI::Role::Layout::HasParent qw(is_widget);
	is_widget($child);    # 1
	$ui->owns($child);    # 1

	$root->remove_child($panel);
	$child->root;      # $panel: the removed subtree stands alone
	$child->ui;        # undef

=head1 DESCRIPTION

C<Clay::UI::Role::Layout::HasParent> gives every widget its way through
the tree: C<parent>, C<ancestors>, C<closest>, C<root>, C<ui>,
C<contains> and C<subtree>, and the hook C<tree_changed> that tells a
widget its place in a tree changed. L<Clay::UI::Role::Core::Element>
and L<Clay::UI::Role::Core::TextNode> compose it, so every element
widget and every text widget has these methods. Its package also
exports the function L</is_widget>, the one test for "is this a
widget".

Each tree question has one answer: the widgets above a widget are its
C<ancestors>, the nearest one with some property is what C<closest>
returns, the widget and everything below it is its C<subtree>, and
whether a widget is in a UI's tree is L<Clay::UI/owns>. Use these
instead of walking C<parent> or C<children> yourself.

The parent reference is weak: it does not keep the parent alive. A
widget tree is held together by parents holding their children, and a
whole tree by the L<Clay::UI> that has its root.

=head1 METHODS

=head2 parent

	my $parent = $widget->parent;

Returns the widget this one is a child (or internal child) of. Returns
undef when the widget was never attached, was removed from its parent,
or its parent has been freed. Read-only: attaching and removing
(L</ATTACHING AND REMOVING>) set it.

=head2 ancestors

	my @above = $widget->ancestors;

Returns the widgets above this one, nearest first: its parent, the
parent's parent, and so on up to the root. The widget itself is not
included, so a widget without a parent returns the empty list. Internal
children have their widget as parent like any child. If an ancestor has
been freed, the list ends at the highest ancestor still reachable. The
walk runs on every call.

=head2 closest

	my $scroller = $widget->closest(sub ($node) { $node->DOES('Clay::UI::Role::Layout::HasScroll') });

Returns the widget itself, or else its nearest ancestor, for which the
predicate returns true; undef when none does. The predicate is called
with one widget at a time (also in C<$_>), the widget itself first,
then up through L</ancestors> until it accepts one. To start strictly
above the widget, call it on the parent, or search C<ancestors>. Dies
with C<Clay::UI: closest takes a code reference, got ...> when the
predicate is not a code reference.

=head2 subtree

	my @all = $widget->subtree;

Returns the widget itself followed by every widget below it in layout
pre-order (L<Clay::UI::Role::Core::Element/descendants>, internal
children included). For a text widget, which has no children, that is
the widget alone.

=head2 root

	my $top = $widget->root;

Follows C<parent> up to the topmost widget and returns it; for a widget
without a parent that is the widget itself. If an ancestor has been
freed, returns the highest ancestor still reachable. The walk runs on
every call; nothing is cached.

=head2 ui

	my $ui = $widget->ui;

Returns the L<Clay::UI> whose tree this widget is part of: the UI
created with C<< Clay::UI->new(root => $root) >> for the widget's
C<root>. Returns undef when the widget is not part of a UI: not yet
attached to one, removed from it, or the UI has been freed (the
reference to the UI is weak).

=head2 contains

	if ($panel->contains($widget)) { ... }

Returns 1 when C<$widget> is this widget or below it (it walks up from
C<$widget> through C<parent>, so internal children count), 0
otherwise. Works for element and text widgets on both sides. Dies with
C<Clay::UI: contains takes a widget, got ...> for anything else (see
L</is_widget>). For the list of widgets below a widget, see
L</subtree>.

=head2 tree_changed

	class My::Box :strict(params) :does(Clay::UI::Box) {}
	class My::Panel :strict(params) :isa(My::Box) {
		method tree_changed :override () {
			$self->SUPER::tree_changed;
			say 'now in ', (defined $self->ui ? 'a UI' : 'no UI');
			return;
		}
	}

A hook for widget classes that must react when their place in a tree
changes, for example to rebuild what depends on the UI they are in.
It does nothing here; you never call it yourself. Clay::UI calls it on
B<every> widget of a subtree (the subtree's own widget first, then the
others in layout pre-order, internal children included, see
L<Clay::UI::Role::Core::Element/descendants>) when the subtree's top
widget:

=over 4

=item *

gets a parent: C<add_child>, C<insert_children>, a row or cell a
L<Clay::UI::Grid> adds, C<add_internal_children>;

=item *

loses its parent: every removal listed under L</ATTACHING AND REMOVING>;

=item *

becomes the root of a L<Clay::UI> (C<< Clay::UI->new(root => ...) >>).

=back

It runs once the change is complete: the parent slots are set or
cleared, and for a removal the leaving subtree's hover and focus are
released (its C<OnHoverStopped> and C<OnBlur> listeners have run), so
C<parent> and C<ui> answer the new place: C<ui> is undef in a removed
subtree. A call that moves several subtrees (replacing a row, say)
completes every move before the first hook runs. Each widget gets one
call per change: a L<Clay::UI::Grid> builds a new row (or the wrapper
of a new cell) completely before it puts it into the grid, and only
then announces it. Reordering children
(L<Clay::UI::Grid/reorder_rows>) changes no place and calls nothing.

Every hook runs even if one dies; the method that changed the tree
then dies with the first error, the tree already changed. When a
release listener died as well, its error (the earlier one) is the one
rethrown and hook errors are dropped, as later listener errors are.
For a subclass of Clay::UI, the hooks of the root's subtree run while
C<< Clay::UI->new >> is still building the UI, before the subclass's
own ADJUST blocks: a hook must not rely on what those set up.

Override it in a subclass with C<:override> and call
C<< $self->SUPER::tree_changed >>: an Object::Pad class cannot override
a method of a role it composes itself, so the override goes into a
subclass of the class that composes the role (as in the example, and
as for L<Clay::UI::Role::Interaction::Focusable/accepts_focus>).
C<_set_parent> and C<_detach_parent>, which set and clear the parent
slot, are private to Clay::UI; do not override them.

=head1 FUNCTIONS

=head2 is_widget

	use Clay::UI::Role::Layout::HasParent qw(is_widget);

	if (is_widget($thing)) { ... }

Returns 1 when C<$thing> is a widget: a blessed object composing
L<Clay::UI::Role::Core::Element> or L<Clay::UI::Role::Core::TextNode>.
Only those can be part of a widget tree. Returns 0 for anything else,
also for an object that composes only some of the roles a widget is
made of (C<HasParent> alone, say). Exported on request.

=head1 ATTACHING AND REMOVING

A widget can be attached whenever it has no parent. Attaching (for
example L<Clay::UI::Role::Core::Container/add_child>) sets its parent;
attaching a widget that still has one dies with
C<Clay::UI: widget ... is still attached to a parent; remove it first>,
whether the new parent is another widget or the same one again.


Removing a widget (C<remove_child>, C<remove_child_with_id>,
C<remove_children_with>,
C<clear_children>, a removed or replaced row or cell of a
L<Clay::UI::Grid>, C<remove_internal_children>) detaches it:

=over 4

=item *

its C<parent> becomes undef and it is the C<root> of its own subtree;

=item *

C<ui> returns undef for the whole subtree;

=item *

hover, press and focus inside the subtree are released on the way out,
with the usual C<OnHoverStopped> and C<OnBlur> events, so the subtree
is idle when it comes back.

=back

A detached widget, like one whose parent has been freed, can be
attached again, to its old parent or another one, or become the root of
a new L<Clay::UI>. Once attached, the next C<render> lays it out, and
it can be hovered and pressed from the frame after that (the pointer is
tested against the previous frame's layout). Without an C<id> it gets the id derived from
its new position (see L<Clay::UI::Role::Core::Element/resolve_id>).

The root of a L<Clay::UI> belongs to that UI as long as the UI exists:
it cannot become a child, and a second Clay::UI on the same root dies.
The root refers to its UI weakly, so once the Clay::UI object is freed
the root is free again (it can become a child or the root of a new
Clay::UI).

=head1 SEE ALSO

L<Clay::UI::Role::Core::Element/ATTACHING CHILDREN>,
L<Clay::UI::Role::Core::Container>, L<Clay::UI>.

=cut
