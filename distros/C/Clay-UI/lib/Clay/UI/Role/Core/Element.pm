package Clay::UI::Role::Core::Element;
our $VERSION = '0.06';
use v5.22;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Object::Pad 0.800;
use Object::Pad::MOP::Class;
use List::Util qw(any uniq);
use Scalar::Util qw(blessed refaddr reftype);
no warnings 'experimental';

use Clay::UI::_validate qw(validate_id is_index shown_value described_value);
use Clay::UI::Revision qw(bump_revision);
use Clay::UI::Role::Layout::HasSizingGroup;
use Clay::UI::Role::Layout::HasParent;
use Clay::UI::Role::Events::Listener;
use Clay::UI::_error qw(croak_ui);

# Contributor method names per class. Object::Pad classes are sealed once
# compiled, so the list never changes after the first lookup.
my %contributors_for;

sub _contributors_of ($class) {
	return $contributors_for{$class} //= [
		sort { $a cmp $b }
		uniq
		grep { /^contribute_/ }
		map  { $_->name }
		Object::Pad::MOP::Class->for_class($class)->all_methods
	];
}

sub _is_widget ($thing) {
	return blessed($thing)
		&& ( $thing->DOES('Clay::UI::Role::Core::Element')
		  || $thing->DOES('Clay::UI::Role::Core::TextNode') );
}

# Validates widgets that are about to be attached somewhere below $anchor
# (the future parent, or the Grid they end up in). Dies before anything is
# written if any of them cannot be attached.
sub _validate_attachment ($anchor, @kids) {
	my %ancestor = map { refaddr($_) => 1 } _self_and_ancestors($anchor);
	my %seen;
	for my $kid (@kids) {
		croak_ui "Clay::UI: child is not a widget (got " . (ref($kid) || 'non-ref') . ")"
			unless _is_widget($kid);
		my $addr = refaddr($kid);
		croak_ui "Clay::UI: the same widget (" . ref($kid) . ") is attached twice in one call"
			if $seen{$addr}++;
		croak_ui "Clay::UI: cannot attach a widget to itself or to one of its descendants (" . ref($kid) . ")"
			if $ancestor{$addr};
		croak_ui "Clay::UI: widget " . ref($kid) . " is the root of a Clay::UI and cannot become a child"
			if defined $kid->_local_ui_controller;
		croak_ui "Clay::UI: widget " . ref($kid) . " is still attached to a parent; remove it first"
			if defined $kid->parent;
	}
	return;
}

# Announces the tree change to the subtrees below @tops (see HasParent's
# tree_changed): every hook runs; returns the first error, or undef.
sub _announce_tree_changes (@tops) {
	my $first_error;
	for my $top (@tops) {
		my $error = $top->_announce_tree_change;
		$first_error //= $error;
	}
	return $first_error;
}

# True when $order is an array reference holding each of 0..$count-1
# exactly once.
sub _is_permutation ($order, $count) {
	return 0 unless ref $order eq 'ARRAY' && @$order == $count;
	my %seen;
	for my $index (@$order) {
		return 0 unless is_index($index) && $index < $count && !$seen{$index}++;
	}
	return 1;
}

# Dies unless $predicate is a code reference.
sub _require_predicate ($method, $predicate) {
	croak_ui "Clay::UI: $method takes a code reference, got " . described_value($predicate)
		unless ref $predicate && reftype($predicate) eq 'CODE';
	return;
}

sub _self_and_ancestors ($node) {
	my @chain;
	for (my $cursor = $node; defined $cursor; $cursor = $cursor->parent) {
		push @chain, $cursor;
	}
	return @chain;
}

role Clay::UI::Role::Core::Element :does(Clay::UI::Role::Layout::HasSizingGroup)
                              :does(Clay::UI::Role::Layout::HasParent)
                              :does(Clay::UI::Role::Events::Listener) {
	field $id :param :reader = undef;
	field @_children;
	field @_internal_children;

	ADJUST {
		validate_id('id', $id) if defined $id;
	}

	method children () {
		return [ @_children ];
	}

	method child_count () {
		return scalar @_children;
	}

	method child_at ($index) {
		croak_ui "Clay::UI: child_at takes an index, got " . described_value($index)
			unless is_index($index);
		return $index < @_children ? $_children[$index] : undef;
	}

	method get_children_with ($predicate) {
		_require_predicate(get_children_with => $predicate);
		return grep { $predicate->($_) } @_children;
	}

	method has_child ($widget) {
		croak_ui "Clay::UI: has_child takes a widget, got " . ( ref($widget) || ( defined $widget ? "'$widget'" : 'undef' ) )
			unless _is_widget($widget);
		return ( any { refaddr($_) == refaddr($widget) } @_children ) ? 1 : 0;
	}

	method internal_children () {
		return [ @_internal_children ];
	}

	# What a frame lays out below this widget: the children, then the
	# internal children. The walker, the focus order and the frame
	# registry read this list, never children.
	method layout_children () {
		return [ @_children, @_internal_children ];
	}

	# Every widget below this one in layout pre-order: each child or
	# internal child followed by its own subtree. Every walk of a subtree
	# in Clay::UI goes through here.
	method descendants () {
		my @below;
		my @stack = @{ $self->layout_children };
		while (@stack) {
			my $node = shift @stack;
			croak_ui "Clay::UI: tree node is not a blessed widget (got " . (ref($node) || 'non-ref') . ")"
				unless blessed $node;
			push @below, $node;
			unshift @stack, @{ $node->layout_children } if $node->DOES('Clay::UI::Role::Core::Element');
		}
		return @below;
	}

	# Internal children belong to the widget class, not to its user: a
	# helper the widget needs in the laid-out tree (a floating scrollbar,
	# a popup) that children and the Container mutators never show or
	# touch. They are validated and parent-stamped like children.
	method add_internal_children (@kids) {
		return $self unless @kids;
		_validate_attachment($self, @kids);
		push @_internal_children, @kids;
		$_->_set_parent($self) for @kids;
		bump_revision();
		my $error = _announce_tree_changes(@kids);
		die $error if defined $error;
		return $self;
	}

	method remove_internal_children (@kids) {
		for my $kid (@kids) {
			croak_ui "Clay::UI: remove_internal_children takes widgets, got " . described_value($kid)
				unless _is_widget($kid);
		}
		my %leaving = map { refaddr($_) => 1 } @kids;
		my @removed = grep { $leaving{ refaddr($_) } } @_internal_children;
		return $self unless @removed;
		@_internal_children = grep { !$leaving{ refaddr($_) } } @_internal_children;
		bump_revision();
		my $error = $self->_release_children(@removed);
		die $error if defined $error;
		return $self;
	}

	method resolve_id ($base, $indices) {
		return $id if defined $id;
		return 'anon:' . length($base) . ":$base/" . join('/', @$indices);
	}

	# The slices are fresh; the values in them may be the widget's own.
	method to_config {
		my %config;
		$self->$_(\%config) for @{ _contributors_of(ref $self) };
		return \%config;
	}

	# For widget classes that keep state of their own: call from their
	# setters so renderers see the change (see Clay::UI::Revision).
	method mark_changed () {
		bump_revision();
		return $self;
	}

	# ---------------------------------------------------------------------
	# Child-list primitives. Every change to the children goes through
	# _splice_children or _detach_children: new children are validated as a
	# whole before anything is written, removed children are detached, the
	# revision (Clay::UI::Revision) is bumped, and every widget of an added
	# or removed subtree gets its tree_changed call once all that is done.
	# Clay::UI::Role::Core::Container and Clay::UI::Grid build their public
	# mutators on these. _adopt_children is the one exception: see there.
	# ---------------------------------------------------------------------

	method _attach_children (@kids) {
		$self->_splice_children(scalar @_children, 0, @kids);
		return;
	}

	# For objects a widget class builds itself and that no tree holds yet
	# (Clay::UI::Grid's cell wrappers and rows): validates, attaches and
	# bumps like _attach_children, but announces nothing. The primitive
	# that attaches the finished subtree announces every widget in it
	# once, when the change is complete.
	method _adopt_children (@kids) {
		croak_ui "Clay::UI: internal error: _adopt_children on a widget that is part of a tree ("
			. ref($self) . ")"
			if defined $self->parent || defined $self->_local_ui_controller;
		_validate_attachment($self, @kids);
		push @_children, @kids;
		$_->_set_parent($self) for @kids;
		bump_revision();
		return;
	}

	method _splice_children ($offset, $length, @kids) {
		croak_ui "Clay::UI: child offset " . shown_value($offset) . " out of range 0.." . scalar(@_children)
			unless is_index($offset) && $offset <= @_children;
		croak_ui "Clay::UI: cannot remove " . shown_value($length) . " children at offset $offset of " . scalar(@_children)
			unless is_index($length) && $offset + $length <= @_children;
		_validate_attachment($self, @kids);
		return () if !@kids && !$length;    # nothing changes, so no revision bump

		my @removed = splice @_children, $offset, $length, @kids;
		$_->_set_parent($self) for @kids;
		bump_revision();
		my $release_error = $self->_release_children(@removed);
		my $hook_error    = _announce_tree_changes(@kids);
		my $error         = $release_error // $hook_error;
		die $error if defined $error;
		return @removed;
	}

	# Puts the children in a new order without detaching any: child $k
	# becomes the child that was at $order->[$k]. $order must hold every
	# index exactly once.
	method _reorder_children ($order) {
		my $count = scalar @_children;
		croak_ui "Clay::UI: a new child order must be an array reference of the indices 0.." . ($count - 1) . " in any order"
			unless _is_permutation($order, $count);
		@_children = @_children[@$order];
		bump_revision();
		return;
	}

	method _detach_children (@kids) {
		my %leaving = map { refaddr($_) => 1 } @kids;
		my @removed = grep { $leaving{ refaddr($_) } } @_children;
		return unless @removed;
		@_children = grep { !$leaving{ refaddr($_) } } @_children;
		bump_revision();
		my $error = $self->_release_children(@removed);
		die $error if defined $error;
		return;
	}

	# Runs after the child list has changed: tells the interaction tracker
	# (hover and focus inside the leaving subtrees are released, with
	# OnHoverStopped / OnBlur bubbling through the still-intact parent
	# slots), clears each child's parent slot, then announces the change
	# to the leaving subtrees (tree_changed). The children are detached
	# and every hook runs even if a listener or a hook dies; returns the
	# first error (a listener's before a hook's), or undef, for the
	# caller to rethrow once its own work is done.
	method _release_children (@kids) {
		return undef unless @kids;
		my $ui = $self->ui;
		my $listener_error;
		if (defined $ui) {
			local $@;
			eval { $ui->interaction->release_subtrees(@kids); 1 }
				or $listener_error = $@ || 'unknown listener error';
		}
		$_->_detach_parent for @kids;
		my $hook_error = _announce_tree_changes(@kids);
		return $listener_error // $hook_error;
	}
}

1;

__END__

=head1 NAME

Clay::UI::Role::Core::Element - base role of every Clay::UI element widget

=head1 SYNOPSIS

	use v5.22;
	use Object::Pad;
	use Clay::XS qw(sizing_fixed);
	use Clay::UI;
	use Clay::UI::Role::Core::Container;
	use Clay::UI::Role::Layout::HasLayout;
	use Clay::UI::Role::Style::HasBackground;

	class My::Panel :strict(params)
		:does(Clay::UI::Role::Core::Container)
		:does(Clay::UI::Role::Layout::HasLayout)
		:does(Clay::UI::Role::Style::HasBackground)
	{}

	my $root = My::Panel->new(
		id     => 'root',
		layout => {
			sizing => { width => sizing_fixed(200), height => sizing_fixed(100) },
		},
		background_color => [255, 0, 0, 255],
	);
	$root->add_child(My::Panel->new(background_color => [0, 0, 255, 255]));

	# The declaration the layout pass sends to Clay for this widget:
	my $config = $root->to_config;
	# { layout => { sizing => ... }, background_color => [255, 0, 0, 255] }

	my $ui       = Clay::UI->new(width => 800, height => 600, root => $root);
	my $commands = $ui->render;

=head1 DESCRIPTION

C<Clay::UI::Role::Core::Element> is the Object::Pad role every element
widget composes, directly or through another role. An element widget
becomes one Clay element (a box) in each frame. Text widgets are the
other kind of widget; they compose L<Clay::UI::Role::Core::TextNode>
instead.

The role provides:

=over 4

=item *

an optional C<id> (L</id>) and the id Clay::UI derives for widgets
without one (L</resolve_id>);

=item *

the list of children (L</children>) and of internal children
(L</internal_children>), with read access only;

=item *

C<to_config> (L</to_config>), which builds the widget's declaration
from the C<contribute_*> methods of its roles (see
L</EXTENDING THE DECLARATION>);

=item *

C<mark_changed> (L</mark_changed>) for widget classes that keep state of
their own.

=back

It also composes L<Clay::UI::Role::Layout::HasSizingGroup> (the
C<width_group> and C<height_group> attributes),
L<Clay::UI::Role::Layout::HasParent> (C<parent>, C<root>, C<ui>,
C<contains>, C<tree_changed>) and
L<Clay::UI::Role::Events::Listener> (C<on>).

Element has no public method that changes the children. Widgets that
hold any children their user gives them compose
L<Clay::UI::Role::Core::Container>, which adds C<add_child> and the
removal methods. Widgets that decide their children themselves (such as
L<Clay::UI::Grid>) compose Element alone and use the internal
child-list methods. The constructor never takes children: a widget
starts empty.

Two terms used below:

=over 4

=item declaration

The hash of settings Clay receives for one element: C<layout>,
C<background_color>, C<border>, C<floating> and so on (see
L<Clay::XS::Structs>). Clay::UI widgets build it with snake_case keys;
the layout pass converts the keys to Clay's camelCase.

=item layout pass

The part of L<Clay::UI/render> that declares the widget tree to Clay:
for every widget it calls C<to_config> (or C<text_config> for a text
widget), opens the Clay element, configures it and walks the children.

=back

=head1 CONSTRUCTOR PARAMETERS

=head2 id

	my $panel = My::Panel->new(id => 'sidebar');
	my $name  = $panel->id;    # 'sidebar', or undef

The element id of the widget: a non-empty string, used as the Clay
element id (C<Clay_GetElementId($id)> gives the same numeric id the
layout pass uses). Optional; without it the layout pass derives an id
from the widget's position (see L</resolve_id>).

The C<id> reader is read-only: an id is set at construction and never
changes.

An undef C<id> means "no id". The constructor dies with
C<Clay::UI: 'id' must be a non-empty string> for a reference or an empty
string, and with C<Clay::UI: 'id' must not start with 'anon:'> for an id
starting with C<anon:>, which is reserved for derived ids.


Two widgets with the same id in one frame are a Clay error; with the
default C<error_handler> of L<Clay::UI> the C<render> dies.

=head2 width_group

The width sizing group; see
L<Clay::UI::Role::Layout::HasSizingGroup/width_group>.

=head2 height_group

The height sizing group; see
L<Clay::UI::Role::Layout::HasSizingGroup/height_group>.

=head1 METHODS

=head2 children

	my $kids = $widget->children;    # arrayref, a new one on every call

Returns a new arrayref holding the direct children, in order. Changing
that array does not change the widget. Internal children (see
L</add_internal_children>) are not included.

=head2 child_count

	my $count = $widget->child_count;

Returns the number of direct children, without copying them. Internal
children are not counted.

=head2 child_at

	my $first = $widget->child_at(0);

Returns the direct child at C<$index> (0 is the first), without copying
the children, or undef for an index past the last child. Internal
children are not included. Dies with
C<Clay::UI: child_at takes an index, got ...> for anything but a
non-negative integer in plain decimal digits (C<-1>, C<1.5>, C<'01'>,
undef and references die).

=head2 get_children_with

	my @foos = $root->get_children_with(sub { ($_->id // '') =~ /^foo_/ });
	my @bars = $root->get_children_with(sub ($child) { $child->isa('My::Bar') });

Returns the direct children for which C<< $predicate->($child) >> is
true, as a list (in scalar context: how many). C<$_> is set to the
child as well, so both calling styles work. Does not look at
grandchildren or internal children. Text widgets are passed too; their
C<id> is undef. Dies with
C<Clay::UI: get_children_with takes a code reference, got ...> for
anything else.

=head2 has_child

	$panel->add_child($footer) unless $panel->has_child($footer);

Returns 1 when the widget is one of the direct children (the very
object, compared by identity), 0 otherwise: for a widget attached
elsewhere, for a grandchild and for an internal child (see
L</add_internal_children>). Dies with
C<Clay::UI: has_child takes a widget, got ...> for anything but a
widget, an id included.

=head2 internal_children

	my $helpers = $widget->internal_children;

Returns a new arrayref holding the internal children, in order.

=head2 layout_children

	my $laid_out = $widget->layout_children;

Returns a new arrayref holding the children followed by the internal
children: everything a frame lays out directly below this widget. The
layout pass, the focus order of L<Clay::UI::Interaction> and the
registry that maps render commands back to widgets read this list.
Widget users want L</children>.

=head2 descendants

	my @below = $widget->descendants;

Returns every widget below this one, not the widget itself, as a list
in layout pre-order: each entry of L</layout_children> followed by its
own subtree. Internal children and the widgets below them are
included, so this is the order in which a frame declares the subtree
and the default focus order walks it. Element widgets and text
widgets are listed alike. To ask whether one widget is below another,
use L<Clay::UI::Role::Layout::HasParent/contains>, which walks up
instead.

=head2 add_internal_children

	$self->add_internal_children($scrollbar);

For widget classes: attaches widgets that the class needs in the
laid-out tree but that are not its user's content, for example a
floating scrollbar over a scroll container or a popup. Internal
children are:

=over 4

=item *

validated and given this widget as C<parent>, like children (see
L</ATTACHING CHILDREN>; the same errors apply);

=item *

laid out after the children, and part of the UI (C<ui>, events,
focus order) like any child;

=item *

invisible to the widget's user: C<children>, C<get_children_with> and
the mutators of L<Clay::UI::Role::Core::Container> never show or remove
them.

=back

Bumps the revision (L<Clay::UI::Revision>) and returns the widget.

=head2 remove_internal_children

	$self->remove_internal_children($scrollbar);

Detaches the given internal children the way removed children are
detached (their C<parent> becomes undef, hover, press and focus inside
them are released, see L</ATTACHING CHILDREN>). Widgets that are not
internal children of this widget are ignored. Bumps the revision when
something was removed. Returns the widget. Dies, changing nothing, with
C<Clay::UI: remove_internal_children takes widgets, got ...> for
anything but widgets.

=head2 to_config

	my $config = $widget->to_config;

Builds and returns the widget's declaration: a new hashref with
snake_case keys. It calls every C<contribute_*> method of the widget's
class once, as C<< $self->$name(\%config) >>, so each one adds its part
(see L</EXTENDING THE DECLARATION>). A widget with nothing to declare
returns C<{}>.

The hashref is new on every call, and so are the parts the roles of
this distribution write (C<layout>, C<border>, ...), but the values
inside them may be the widget's own copies. Treat the result as
read-only; copy what you want to change. The layout pass works on a
camelCase copy of it.

Do not override C<to_config>. Object::Pad roles have no C<SUPER>, so an
override silently drops every C<contribute_*> method; add a
C<contribute_*> method instead.

=head2 resolve_id

	my $id = $widget->resolve_id($base, \@indices);

Returns the string the layout pass hashes with C<Clay_GetElementId> for
this widget: the user's C<id> when it has one, otherwise an anonymous
id derived from the widget's position:

	'anon:' . length($base) . ":$base/" . join('/', @indices)

C<$base> is the id of the nearest ancestor with an id (C<''> when there
is none) and C<@indices> the positions in C<layout_children> on the way
down from that ancestor. For example:

=for highlighter language=text

	root without an id                    anon:0:/
	its third child                       anon:0:/2
	child 1 of the widget 'list'          anon:4:list/1
	child 0 of that child                 anon:4:list/1/0

The length prefix keeps anonymous ids apart from each other (C<a/b> as
an id cannot be confused with an index path), and the reserved C<anon:>
prefix keeps them apart from user ids.

An anonymous id changes when the widget moves: inserting a sibling
before it, or before one of its anonymous ancestors, gives it a new id.
Give an C<id> to widgets that need the same Clay element id from frame
to frame: scroll containers (L<Clay::UI::Role::Layout::HasScroll>
requires one), elements with Clay transitions, and elements you look up
with L<Clay::XS> functions such as C<Clay_GetElementData>.

The layout pass supplies the arguments; calling C<resolve_id> yourself
is only useful in tests.

=head2 mark_changed

=for highlighter language=perl

	$widget->mark_changed;

Bumps the revision (L<Clay::UI::Revision>) and returns the widget. The
accessors of this distribution's roles bump it themselves, and so does
every change to the children. A widget class that keeps state of its
own, which its C<contribute_*> methods turn into the declaration, calls
C<mark_changed> from its setters, so that a renderer that skips
unchanged frames draws the next one.

=head1 EXTENDING THE DECLARATION

C<to_config> knows nothing about layout, colours or borders. It finds
every method of the widget's class whose name starts with
C<contribute_> - from the class, its superclasses and every composed
role - and calls each one with the declaration hash under
construction. Each method writes one part of the declaration. This is
how L<Clay::UI::Role::Layout::HasLayout> adds C<layout>,
L<Clay::UI::Role::Style::HasBackground> adds C<background_color>, and
so on.

A widget class adds a declaration part Clay::UI has no role for by
defining a C<contribute_E<lt>nameE<gt>> method. This class adds Clay's
C<aspectRatio> (see L<Clay::XS::Structs/aspectRatio>):

	use v5.22;
	use Object::Pad;
	use Clay::XS qw(sizing_fixed);
	use Clay::UI;
	use Clay::UI::Box;
	use Scalar::Util ();

	class My::Picture :strict(params) :does(Clay::UI::Box) {
		field $aspect_ratio :param = 1;

		# The constructor and the setter check the value the same way.
		sub checked_ratio {
			my ($ratio) = @_;
			die "My::Picture: aspect_ratio must be a positive number\n"
				unless Scalar::Util::looks_like_number($ratio) && $ratio > 0;
			return $ratio;
		}

		ADJUST {
			checked_ratio($aspect_ratio);
		}

		method aspect_ratio (@new) {
			return $aspect_ratio unless @new;
			$aspect_ratio = checked_ratio($new[0]);
			$self->mark_changed;    # the declaration changes
			return $aspect_ratio;
		}

		# Adds the aspectRatio part to the declaration.
		method contribute_aspect_ratio ($config) {
			$config->{aspect_ratio} = { aspect_ratio => $aspect_ratio };
			return;
		}
	}

	my $picture = My::Picture->new(
		layout           => { sizing => { width => sizing_fixed(200) } },
		background_color => [90, 90, 90, 255],
		aspect_ratio     => 2,
	);
	my $ui = Clay::UI->new(width => 800, height => 600, root => $picture);
	my $commands = $ui->render;    # the rectangle is 200 x 100

	$picture->aspect_ratio(4);
	$commands = $ui->render;       # now 200 x 50

The rules for C<contribute_*> methods:

=over 4

=item *

Each is called once per C<to_config> with the declaration hashref; the
return value is ignored. The methods run in alphabetical order of their
names (C<contribute_background> before C<contribute_layout>).

=item *

Write keys in snake_case, the spelling every stored slice and reader
uses (an attribute set with camelCase keys reads back in snake_case).
camelCase works too, since the layout pass converts every key, but do
not use both spellings of one key: merged slices then collide.

=item *

A part that another method may also write must be merged, not
replaced. L<Clay::UI::Role::Layout::HasLayout> merges the user's
C<layout> over what is already there; defaults go under what is already
there, as L<Clay::UI::Grid> does for its C<layout>:

	method contribute_my_defaults ($config) {
		$config->{layout} = { child_gap => 4, %{ $config->{layout} // {} } };
		return;
	}

=item *

Do not set a value that another C<contribute_*> method of the class
also sets and that cannot be merged, for example a C<contribute_state_colour> that sets
C<background_color> in a class that also has the C<background_color>
attribute (L<Clay::UI::Role::Style::HasBackground>): the result then
depends on the order of the method names. To set the background by
state (L<Clay::UI::Role::Style::HasStates>), either leave the
C<background_color> attribute unset, or compose the roles without
HasBackground instead of L<Clay::UI::Box> (as the C<Settings::Toggle>
class in F<examples/12-ui-interaction.pl> does).

=item *

Write fresh hashes and arrays into the declaration; do not hand out a
container the widget keeps changing.

=item *

Do not set C<user_data>: the layout pass sets it to find the widget
again, and C<render> dies with C<Clay::UI: widget ... set user_data in its config>.

=item *

A setter that changes what a C<contribute_*> method writes calls
L</mark_changed>.

=item *

Clay::XS checks the declaration only when the element is configured,
and ignores unknown keys there: a misspelled key in a
C<contribute_*> method is silently dropped. Values of the wrong shape
make C<render> die. Validate in the constructor and the setters
(C<check_struct> of L<Clay::XS> checks a value against a Clay struct,
see L<Clay::XS/CHECKING STRUCTS>).

=item *

The methods run for every widget in every frame; keep them cheap.

=back

Method names must be unique: Object::Pad dies when two composed roles
provide the same C<contribute_*> method, or when a class defines one
that a role it composes already provides
(C<Method 'contribute_layout' clashes with the one provided by role ...>).
The roles of this distribution use these names:


=over 4

=item *

C<contribute_background> (L<Clay::UI::Role::Style::HasBackground>)

=item *

C<contribute_border> (L<Clay::UI::Role::Style::HasBorder>)

=item *

C<contribute_clip> (L<Clay::UI::Role::Layout::HasScroll>)

=item *

C<contribute_corner_radius> (L<Clay::UI::Role::Style::HasCornerRadius>)

=item *

C<contribute_floating> (L<Clay::UI::Role::Layout::HasFloating>)

=item *

C<contribute_grid_defaults> (L<Clay::UI::Grid>)

=item *

C<contribute_layout> (L<Clay::UI::Role::Layout::HasLayout>)

=item *

C<contribute_sizing_group> (L<Clay::UI::Role::Layout::HasSizingGroup>,
part of every element widget)

=back

A subclass may override a C<contribute_*> method of its superclass;
only the override runs.

The list of C<contribute_*> methods is looked up once per class and
kept, because Object::Pad classes do not change once compiled.

=head1 ATTACHING CHILDREN

Every change to the children - through
L<Clay::UI::Role::Core::Container>, L<Clay::UI::Grid> or
L</add_internal_children> - checks all new children before anything
changes, so a call that dies leaves the widget as it was. It dies when
a new child:

=over 4

=item *

is not a widget: C<Clay::UI: child is not a widget (got ...)>. A widget
is a blessed object composing C<Clay::UI::Role::Core::Element> or
L<Clay::UI::Role::Core::TextNode>;

=item *

appears twice in the call: C<Clay::UI: the same widget (...) is attached twice in one call>;

=item *

is the widget itself or one of its ancestors:
C<Clay::UI: cannot attach a widget to itself or to one of its descendants>;


=item *

is the root of a L<Clay::UI>:
C<Clay::UI: widget ... is the root of a Clay::UI and cannot become a child>;


=item *

still has a parent, even if it is this widget:
C<Clay::UI: widget ... is still attached to a parent; remove it first>
(see L<Clay::UI::Role::Layout::HasParent/ATTACHING AND REMOVING>).


=back

Every change bumps the revision (L<Clay::UI::Revision>). Widgets that
decide their children themselves may also reorder them
(L<Clay::UI::Grid/reorder_rows>); reordering detaches nothing.

Once a change is complete, every widget of each added or removed
subtree gets a call of its
L<tree_changed|Clay::UI::Role::Layout::HasParent/tree_changed> hook,
the subtree's own widget first, then the others in L</descendants>
order. Every hook runs; the change method then dies with the first
error.

A removed child is detached: its C<parent> becomes undef and its
subtree is no longer part of the UI until it is attached again. Hover,
press and focus inside the subtree are released first: a hovered
widget gets C<OnHoverStopped>, the focused widget gets C<OnBlur> (see
L<Clay::UI::Interaction>). A listener of those events that dies does
not stop the removal: the call completes (the C<tree_changed> hooks
included) and then dies with the listener's error.

=head1 SEE ALSO

L<Clay::UI>, L<Clay::UI::Role::Core::Container>,
L<Clay::UI::Role::Core::TextNode>, L<Clay::UI::Box>,
L<Clay::UI::Revision>, L<Clay::XS::Structs>, L<Clay::Manual>.

=cut
