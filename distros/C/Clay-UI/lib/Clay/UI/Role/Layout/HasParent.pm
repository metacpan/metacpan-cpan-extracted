package Clay::UI::Role::Layout::HasParent;
our $VERSION = '0.06';
use v5.22;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Object::Pad 0.800;
use Scalar::Util qw(blessed refaddr weaken);
use Clay::UI::_error qw(croak_ui);

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

	method root () {
		my $node = $self;
		while (defined(my $next = $node->parent)) {
			$node = $next;
		}
		return $node;
	}

	# True when $widget is this widget or below it.
	method contains ($widget) {
		croak_ui "Clay::UI: contains takes a widget, got " . (ref($widget) || (defined $widget ? "'$widget'" : 'undef'))
			unless blessed $widget && $widget->DOES('Clay::UI::Role::Layout::HasParent');
		for (my $node = $widget; defined $node; $node = $node->parent) {
			return 1 if refaddr($node) == refaddr($self);
		}
		return 0;
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
		my @subtree = ($self, $self->DOES('Clay::UI::Role::Core::Element') ? $self->descendants : ());
		my $first_error;
		for my $widget (@subtree) {
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

	$child->parent;    # $panel
	$child->root;      # $root
	$child->ui;        # $ui
	$panel->contains($child);    # 1

	$root->remove_child($panel);
	$child->root;      # $panel: the removed subtree stands alone
	$child->ui;        # undef

=head1 DESCRIPTION

C<Clay::UI::Role::Layout::HasParent> gives every widget its way up the
tree: C<parent>, C<root>, C<ui> and C<contains>, and the hook
C<tree_changed> that tells a widget its place in a tree changed. L<Clay::UI::Role::Core::Element>
and L<Clay::UI::Role::Core::TextNode> compose it, so every element
widget and every text widget has these methods.

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
C<Clay::UI: contains takes a widget, got ...> for anything else. For
the list of widgets below an element, see
L<Clay::UI::Role::Core::Element/descendants>.

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
