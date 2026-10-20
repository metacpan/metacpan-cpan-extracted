package Clay::UI::Interaction;
our $VERSION = '0.07';
use v5.22;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Object::Pad 0.800;
use List::Util qw(first);
use Scalar::Util qw(blessed refaddr weaken);

use Clay::UI::Events::OnHoverStart;
use Clay::UI::Events::OnHoverStopped;
use Clay::UI::Events::OnPress;
use Clay::UI::Events::OnRelease;
use Clay::UI::Events::OnScroll;
use Clay::UI::Events::OnFocus;
use Clay::UI::Events::OnBlur;
use Clay::XS qw(CLAY_ATTACH_TO_NONE);
use Clay::UI::Revision qw(bump_revision);
use Clay::UI::_validate qw(is_finite_number described_value);
use Clay::UI::_error qw(croak_ui);
use Clay::UI::Role::Layout::HasParent qw(is_widget);

my %UPDATE_ARGS = map { $_ => 1 } qw(over down x y scrolled);

my $HOVERABLE   = 'Clay::UI::Role::Interaction::Hoverable';
my $PRESSABLE   = 'Clay::UI::Role::Interaction::Pressable';
my $FOCUSABLE   = 'Clay::UI::Role::Interaction::Focusable';
my $DISABLEABLE = 'Clay::UI::Role::Interaction::Disableable';
my $FOCUS_ORDER = 'Clay::UI::Role::Interaction::HasFocusOrder';
my $SCROLLABLE  = 'Clay::UI::Role::Layout::HasScroll';
my $FLOATING    = 'Clay::UI::Role::Layout::HasFloating';

class Clay::UI::Interaction :strict(params) {
	field $ui :param :weak;

	# Sorts widgets into the tree order of the last layout (Clay::UI
	# passes its frame registry's in_tree_order).
	field $tree_order :param;

	ADJUST {
		croak_ui "Clay::UI::Interaction: 'tree_order' must be a coderef" unless ref $tree_order eq 'CODE';
	}

	# Widgets keyed by refaddr; the values are weak references, so a freed
	# widget leaves an undef value behind and never counts.
	field %_hovered;
	field %_armed;
	field %_pressed;
	field @_under_pointer;
	field $_down   = 0;
	field $_firing = 0;
	field $_focused;

	# The widgets whose OnHoverStart / OnFocus has been delivered and not
	# yet followed by OnHoverStopped / OnBlur (weak, like the state sets).
	# A queued event is delivered only while it still matches the state,
	# so these keep every stop after its start, every blur after its focus.
	field %_hover_announced;
	field $_focus_announced;

	# Subtrees release_subtrees is detaching: they no longer belong to the
	# UI, so no listener can hover, press or focus a widget in them.
	field @_leaving;

	method is_hovered ($widget) { return _holds(\%_hovered, $widget) }
	method is_armed   ($widget) { return _holds(\%_armed,   $widget) }
	method is_pressed ($widget) { return _holds(\%_pressed, $widget) }

	method under_pointer () {
		return [ grep { defined } @_under_pointer ];
	}

	# One pointer frame: the widgets under the pointer (topmost first),
	# whether the button is down, where the pointer is and which scroll
	# containers moved. Updates the state first, then fires the events.
	method update (%args) {
		croak_ui "Clay::UI::Interaction::update: called from one of its own listeners" if $_firing;
		_require_ui($ui, 'update');
		my $input  = $self->_parse_update(%args);
		my @events = $self->_apply($input);

		$_firing = 1;
		my $ok    = eval { $self->_fire_due(@events); 1 };
		my $error = $@;
		$_firing = 0;
		die $error unless $ok;
		return;
	}

	method _parse_update (%args) {
		my @unknown = sort grep { !$UPDATE_ARGS{$_} } keys %args;
		_fail('unknown argument(s): ' . join(', ', @unknown)) if @unknown;
		_fail("'over' must be an arrayref of widgets") unless ref $args{over} eq 'ARRAY';
		_fail("'down' is required") unless exists $args{down};
		_fail("'down' must be a plain boolean value") if ref $args{down};
		for my $axis ('x', 'y') {
			next unless defined $args{$axis};
			_fail("'$axis' must be a finite number") unless is_finite_number($args{$axis});
		}
		$self->_require_own($_, 'over') for @{ $args{over} };

		my $scrolled = $args{scrolled} // [];
		_fail("'scrolled' must be an arrayref of [widget, dx, dy]") unless ref $scrolled eq 'ARRAY';
		my %scrolled_seen;
		for my $entry (@$scrolled) {
			_fail("'scrolled' entries must be [widget, dx, dy]")
				unless ref $entry eq 'ARRAY' && @$entry == 3 && is_finite_number($entry->[1]) && is_finite_number($entry->[2]);
			$self->_require_own($entry->[0], 'scrolled');
			_fail("'scrolled' must hold scroll containers (widgets composing $SCROLLABLE)")
				unless $entry->[0]->DOES($SCROLLABLE);
			_fail("'scrolled' lists the same widget twice") if $scrolled_seen{ refaddr $entry->[0] }++;
		}
		return {
			over     => [ @{ $args{over} } ],
			down     => $args{down} ? 1 : 0,
			x        => $args{x} // 0,
			y        => $args{y} // 0,
			scrolled => $scrolled,
		};
	}

	# True for a widget of this UI's tree that is not being detached.
	method _owns ($widget) {
		return 0 unless defined $ui && $ui->owns($widget);
		return !grep { $_->contains($widget) } @_leaving;
	}

	method _require_own ($widget, $arg) {
		_fail("'$arg' must hold widgets of this Clay::UI") unless $self->_owns($widget);
		return;
	}

	# State changes for one frame; returns the events in firing order.
	method _apply ($input) {
		my $states_before = $self->_state_signature;
		my $press_edge   = $input->{down} && !$_down;
		my $release_edge = !$input->{down} && $_down;
		$_down = $input->{down};

		my %over            = map { refaddr($_) => $_ } grep { $_->DOES($HOVERABLE) } @{ $input->{over} };
		my @over_pressables = _press_candidates(grep { $_->DOES($PRESSABLE) } @{ $input->{over} });
		my %press_candidate = map { refaddr($_) => 1 } @over_pressables;

		# Everything whose state may change: what is under the pointer now
		# plus what was hovered, armed or pressed before.
		my %candidates = (
			(map { refaddr($_) => $_ } _live(\%_hovered), _live(\%_armed), _live(\%_pressed)),
			%over,
		);
		my @candidates = values %candidates;
		my @pressables = grep { $_->DOES($PRESSABLE) } @candidates;

		my (@hover_stopped, @hover_started);
		for my $widget (@candidates) {
			my $is_over = exists $over{ refaddr $widget };
			if ($is_over && !$self->is_hovered($widget)) {
				_remember(\%_hovered, $widget);
				push @hover_started, $widget;
			} elsif (!$is_over && $self->is_hovered($widget)) {
				delete $_hovered{ refaddr $widget };
				push @hover_stopped, $widget;
			}
		}

		my ($press_origin, $release_origin);
		if ($press_edge) {
			_remember(\%_armed, $_) for @over_pressables;
			$press_origin = _event_origin(@over_pressables);
		} elsif ($release_edge) {
			$release_origin = _event_origin(grep { $self->is_armed($_) } @over_pressables);
			%_armed = ();
		}
		%_pressed = ();
		for my $widget (@pressables) {
			_remember(\%_pressed, $widget)
				if $input->{down} && $self->is_armed($widget) && $press_candidate{ refaddr $widget };
		}
		_prune(\%_hovered, \%_armed);

		@_under_pointer = @{ $input->{over} };
		weaken $_ for @_under_pointer;
		bump_revision() if $self->_state_signature ne $states_before;

		my ($x, $y) = @$input{qw(x y)};
		my %scroll_of = map { refaddr($_->[0]) => $_ } @{ $input->{scrolled} };
		return (
			(map { $self->_hover_stopped_event($_) } $tree_order->(@hover_stopped)),
			(map { $self->_hover_started_event($_) } $tree_order->(@hover_started)),
			(defined $press_origin   ? $self->_owned_event($press_origin,   Clay::UI::Events::OnPress->new(x => $x, y => $y))   : ()),
			(defined $release_origin ? $self->_owned_event($release_origin, Clay::UI::Events::OnRelease->new(x => $x, y => $y)) : ()),
			(map {
				my (undef, $dx, $dy) = @{ $scroll_of{ refaddr $_ } };
				$self->_owned_event($_, Clay::UI::Events::OnScroll->new(delta_x => $dx, delta_y => $dy));
			} $tree_order->(map { $_->[0] } @{ $input->{scrolled} })),
		);
	}

	# -----------------------------------------------------------------
	# Queued events. Each is [ $widget, $event, $claim ]: $claim runs right
	# before delivery and returns false when an earlier listener of the
	# same dispatch has made the event stale (the widget left the tree, its
	# hover or focus changed again, a nested call already announced it); it
	# records what a delivered event announced.
	# -----------------------------------------------------------------

	method _hover_started_event ($widget) {
		return [ $widget, Clay::UI::Events::OnHoverStart->new, sub {
			return 0 unless $self->is_hovered($widget) && !_holds(\%_hover_announced, $widget);
			_remember(\%_hover_announced, $widget);
			return 1;
		} ];
	}

	method _hover_stopped_event ($widget) {
		return [ $widget, Clay::UI::Events::OnHoverStopped->new, sub {
			return 0 if $self->is_hovered($widget) || !_holds(\%_hover_announced, $widget);
			delete $_hover_announced{ refaddr $widget };
			return 1;
		} ];
	}

	method _focus_event ($widget) {
		return [ $widget, Clay::UI::Events::OnFocus->new, sub {
			return 0 unless $self->is_focused($widget);
			return 0 if defined $_focus_announced && refaddr($_focus_announced) == refaddr($widget);
			$_focus_announced = $widget;
			weaken $_focus_announced;
			return 1;
		} ];
	}

	method _blur_event ($widget) {
		return [ $widget, Clay::UI::Events::OnBlur->new, sub {
			return 0 if $self->is_focused($widget);
			return 0 unless defined $_focus_announced && refaddr($_focus_announced) == refaddr($widget);
			undef $_focus_announced;
			return 1;
		} ];
	}

	# Press, release and scroll events: due while the widget is in the tree.
	method _owned_event ($widget, $event) {
		return [ $widget, $event, sub { $self->_owns($widget) } ];
	}

	# Delivers every event that is still due, even if a listener dies, then
	# rethrows the first exception.
	method _fire_due (@events) {
		my $first_error;
		for my $entry (@events) {
			my ($widget, $event, $claim) = @$entry;
			my $ok = eval { $widget->fire_event($event) if $claim->(); 1 };
			$first_error //= ($@ || 'unknown listener error') unless $ok;
		}
		_prune(\%_hover_announced);
		die $first_error if defined $first_error;
		return;
	}

	# Called by an Element while the subtrees below @tops leave the tree:
	# the widgets in them stop being hovered, armed and pressed and are no
	# longer under the pointer, and focus inside them is released. Then the
	# hovered ones get OnHoverStopped and the focused one OnBlur. Until this
	# returns the subtrees count as gone already (see _owns).
	method release_subtrees (@tops) {
		my $leaving = sub ($widget) { grep { $_->contains($widget) } @tops };
		my $states_before = $self->_state_signature;
		my @stopped = grep { $leaving->($_) } _live(\%_hovered);
		delete $_hovered{ refaddr $_ } for @stopped;
		for my $state (\%_armed, \%_pressed) {
			delete $state->{ refaddr $_ } for grep { $leaving->($_) } _live($state);
		}
		@_under_pointer = grep { defined && !$leaving->($_) } @_under_pointer;
		weaken $_ for @_under_pointer;

		my @events = map { $self->_hover_stopped_event($_) } $tree_order->(@stopped);
		my $heir_error;
		if (defined $_focused && $leaving->($_focused)) {
			my $lost = $_focused;
			(my $heir, $heir_error) = $self->_heir_of($lost, $leaving);
			$_focused = $heir;
			weaken $_focused if defined $_focused;
			push @events, $self->_blur_event($lost), (defined $heir ? $self->_focus_event($heir) : ());
		}
		bump_revision() if $self->_state_signature ne $states_before;

		push @_leaving, @tops;
		my $ok    = eval { $self->_fire_due(@events); 1 };
		my $error = $@;
		splice @_leaving, -@tops if @tops;
		die $heir_error if defined $heir_error;
		die $error unless $ok;
		return;
	}

	# Called by a widget that became disabled or can no longer take focus:
	# it is disarmed and unpressed, and loses the focus (OnBlur) at once.
	method release_ineligible ($widget) {
		_require_ui($ui, 'release_ineligible');
		my $states_before = $self->_state_signature;
		if (!_is_enabled($widget)) {
			delete $_armed{ refaddr $widget };
			delete $_pressed{ refaddr $widget };
		}
		bump_revision() if $self->_state_signature ne $states_before;
		return unless $self->is_focused($widget) && !$widget->can_focus;

		my ($heir, $heir_error) = $self->_heir_of($widget, sub ($node) { 0 });
		my $ok    = eval { $self->set_focused_widget($heir); 1 };
		my $error = $@;
		die $heir_error if defined $heir_error;
		die $error unless $ok;
		return;
	}

	# The widget that takes the focus when the focused widget $lost leaves
	# the tree ($leaving tells which widgets go with it) or can no longer
	# take the focus. Walking up from $lost, a node that stays and can take
	# the focus is the heir; otherwise the widget its focus_heir names is,
	# when that one stays and can take the focus. Leaving nodes are asked
	# too, so a removed popup names who comes after it. Returns the heir
	# (undef: nobody) and the error of a focus_heir hook that died or
	# returned a non-widget: then nobody inherits, and the caller rethrows
	# the error once the focus is consistent and the events fired.
	method _heir_of ($lost, $leaving) {
		my $heir;
		my $ok = eval {
			for (my $node = $lost; defined $node; $node = $node->parent) {
				my $stays = !$leaving->($node);
				if ($stays && $self->can_take_focus($node)) {
					$heir = $node;
					last;
				}
				my $named = $self->_named_heir($node);
				next unless defined $named && !$leaving->($named) && $self->can_take_focus($named);
				$heir = $named;
				last;
			}
			1;
		};
		return $ok ? ($heir, undef) : (undef, $@ || 'unknown focus_heir error');
	}

	# What the node's focus_heir hook names: a widget, or undef when the
	# node has no hook or names nobody.
	method _named_heir ($node) {
		return undef unless $node->can('focus_heir');
		my $named = $node->focus_heir;
		return $named if !defined $named || is_widget($named);
		croak_ui "Clay::UI::Interaction: " . ref($node) . " returned " . described_value($named) . " from focus_heir, which is not a widget\n";
	}

	# Who is hovered, armed, pressed and focused, as a string that changes
	# exactly when one of those does.
	method _state_signature () {
		my $focused = defined $_focused ? refaddr $_focused : '';
		return join ';', $focused,
			map { join ',', sort { $a <=> $b } map { refaddr $_ } _live($_) } \%_hovered, \%_armed, \%_pressed;
	}

	# -----------------------------------------------------------------
	# Focus. Moves only on request, walking the live tree: it must work
	# before the first render and right after the tree changed, while
	# pointer events follow the last frame, which they were hit-tested
	# against.
	# -----------------------------------------------------------------

	method get_focused_widget () {
		return $_focused;
	}

	method is_focused ($widget) {
		return defined $_focused && refaddr($_focused) == refaddr($widget) ? 1 : 0;
	}

	# True when the focused widget is $widget or below it.
	method has_focus_within ($widget) {
		_require_widget('has_focus_within', $widget);
		return defined $_focused && $widget->contains($_focused) ? 1 : 0;
	}

	# The widgets of the scope that can take the focus now, in tree order.
	method focusables (%args) {
		my $within = $self->_focus_scope('focusables', %args);
		return grep { $self->can_take_focus($_) } _focusables_in($within);
	}

	# undef blurs. Focusing the focused widget again is a no-op.
	method set_focused_widget ($widget) {
		_require_ui($ui, 'set_focused_widget');
		return if !defined $_focused && !defined $widget;
		$self->_check_focus_target($widget) if defined $widget;
		return if defined $widget && $self->is_focused($widget);

		# The focused widget changes before any listener runs; a dying
		# OnBlur listener still lets OnFocus fire, and an OnBlur listener
		# that moves focus again makes this OnFocus stale.
		my $previous = $_focused;
		$_focused = $widget;
		weaken $_focused if defined $_focused;
		bump_revision();

		$self->_fire_due(
			(defined $previous ? $self->_blur_event($previous) : ()),
			(defined $widget   ? $self->_focus_event($widget) : ()),
		);
		return;
	}

	method focus_next () {
		$self->_move_focus(1);
		return;
	}

	method focus_previous () {
		$self->_move_focus(-1);
		return;
	}

	# The default order, ignoring the orders of HasFocusOrder widgets but
	# not their entry hooks: the next / previous Focusable after the
	# focused widget in depth-first pre-order that can focus now, wrapping
	# around within the scope.
	method default_next_focus (%args) {
		return $self->_step_focus(1, $self->_focus_scope('default_next_focus', %args));
	}

	method default_previous_focus (%args) {
		return $self->_step_focus(-1, $self->_focus_scope('default_previous_focus', %args));
	}

	# The widget the default order focuses after ($direction 'next') or
	# before ('previous') the whole subtree of $widget, stepping within
	# the scope of the nearest HasFocusOrder above $widget (its
	# focus_scope, or itself), else the whole tree. How a HasFocusOrder
	# leaves its subtree.
	method focus_after ($widget, $direction) {
		_require_ui($ui, 'focus_after');
		_require_widget('focus_after', $widget);
		croak_ui "Clay::UI::Interaction::focus_after: $widget does not belong to this Clay::UI" unless $self->_owns($widget);
		my $step = _step_of('focus_after', $direction);
		my $owner = $self->_focus_order_above($widget);
		my $scope = defined $owner ? $self->_scope_of_order($owner) : $ui->root;
		return $self->_step_focus_after($step, $scope, $widget);
	}

	# The nearest HasFocusOrder strictly above $widget.
	method _focus_order_above ($widget) {
		return first { $_->DOES($FOCUS_ORDER) } $widget->ancestors;
	}

	# The subtree a HasFocusOrder's order covers: its focus_scope when it
	# has one, else itself.
	method _scope_of_order ($order) {
		return $order unless $order->can('focus_scope');
		my $scope = $order->focus_scope;
		croak_ui "Clay::UI::Interaction: " . ref($order) . " returned " . (blessed $scope ? ref $scope : defined $scope ? "'$scope'" : 'undef') . " from focus_scope, which is not a widget of this Clay::UI\n"
			unless $self->_owns($scope);
		return $scope;
	}

	sub _step_of ($method, $direction) {
		return 1  if defined $direction && $direction eq 'next';
		return -1 if defined $direction && $direction eq 'previous';
		croak_ui "Clay::UI::Interaction::$method: direction must be 'next' or 'previous', got " . (defined $direction ? "'$direction'" : 'undef');
	}

	# The subtree a focus query covers: the widget given as 'within', which
	# must belong to this UI, or else the whole tree.
	method _focus_scope ($method, %args) {
		_require_ui($ui, $method);
		my @unknown = sort grep { $_ ne 'within' } keys %args;
		croak_ui "Clay::UI::Interaction::$method: unknown argument(s): " . join(', ', @unknown) if @unknown;
		return $ui->root unless exists $args{within};
		my $within = $args{within};
		croak_ui "Clay::UI::Interaction::$method: 'within' must be a widget of this Clay::UI"
			unless $ui->owns($within);
		return $within;
	}

	# What set_focused_widget accepts, without dying.
	method can_take_focus ($widget) {
		return 0 unless blessed $widget && $widget->DOES($FOCUSABLE) && $self->_owns($widget);
		return $widget->can_focus ? 1 : 0;
	}

	method _check_focus_target ($widget) {
		return if $self->can_take_focus($widget);
		my $fail = sub ($message) { croak_ui "Clay::UI::Interaction::set_focused_widget: target $message" };
		$fail->('must be a blessed widget') unless blessed $widget;
		$fail->("must consume $FOCUSABLE") unless $widget->DOES($FOCUSABLE);
		$fail->('does not belong to this Clay::UI') unless $self->_owns($widget);
		$fail->('is not currently focusable (can_focus returned false)');
	}

	method _move_focus ($step) {
		_require_ui($ui, $step > 0 ? 'focus_next' : 'focus_previous');
		my $order  = $self->_focus_order_owner;
		my $target = defined $order
			? $self->_validate_focus_order($order, $step > 0 ? $order->get_next_focus : $order->get_previous_focus)
			: $self->_step_focus($step, $ui->root);
		$self->set_focused_widget($target) if defined $target;
		return;
	}

	# The nearest HasFocusOrder ancestor of the focused widget (including
	# itself); with nothing focused, the root if it composes HasFocusOrder.
	method _focus_order_owner () {
		return ($_focused // $ui->root)->closest(sub ($node) { $node->DOES($FOCUS_ORDER) });
	}

	# undef means "no change", as does a focusable widget of this UI that
	# is disabled right now; anything else a HasFocusOrder returns is a bug
	# in that class.
	method _validate_focus_order ($order, $widget) {
		return undef unless defined $widget;
		my $fail = sub ($message) { croak_ui "Clay::UI::Interaction: " . ref($order) . " returned $message\n" };
		$fail->('a non-widget from its focus order') unless blessed $widget;
		$fail->(ref($widget) . ", which is not $FOCUSABLE") unless $widget->DOES($FOCUSABLE);
		$fail->(ref($widget) . ', which is not part of this Clay::UI') unless $self->_owns($widget);
		return $widget->can_focus ? $widget : undef;
	}

	# The next Focusable of the subtree $within after the focused widget in
	# pre-order ($step 1) or before it ($step -1) that can take the focus
	# now, wrapping around. With the focus outside the subtree, the first
	# (or last) one. The focused widget itself may have been disabled while
	# focused.
	method _step_focus ($step, $within) {
		my ($nodes, $focusables) = _focus_candidates($within);
		my $start;
		if (defined $_focused) {
			($start) = grep { refaddr($nodes->[ $focusables->[$_] ]) == refaddr($_focused) } 0 .. $#$focusables;
		}
		return $self->_pick_focus($step, $nodes, $focusables, $start);
	}

	# The same step, but from the whole subtree of $from: forward from its
	# last node, backward from its first. With $from outside $within, the
	# first (or last) one.
	method _step_focus_after ($step, $within, $from) {
		my ($nodes, $focusables) = _focus_candidates($within);
		my ($first) = grep { refaddr($nodes->[$_]) == refaddr($from) } 0 .. $#$nodes;
		return $self->_pick_focus($step, $nodes, $focusables, undef) unless defined $first;
		my @from_subtree = $from->subtree;
		my $last = $first + $#from_subtree;
		my $start;
		if ($step > 0) {
			my @before = grep { $focusables->[$_] <= $last } 0 .. $#$focusables;
			$start = @before ? $before[-1] : -1;
		}
		else {
			my @after = grep { $focusables->[$_] >= $first } 0 .. $#$focusables;
			$start = @after ? $after[0] : scalar @$focusables;
		}
		return $self->_pick_focus($step, $nodes, $focusables, $start);
	}

	# The subtree of $within in pre-order, and the positions of its
	# Focusables in it.
	sub _focus_candidates ($within) {
		my @nodes = $within->subtree;
		my @focusables = grep { $nodes[$_]->DOES($FOCUSABLE) } 0 .. $#nodes;
		return (\@nodes, \@focusables);
	}

	# Steps from the Focusable at position $start (undef: from before the
	# first, or after the last) to the first one that can take the focus,
	# wrapping around. A candidate at or below a HasFocusOrder that has an
	# entry hook, lies below the scope and does not hold the focus is what
	# that owner's get_entry_focus returns instead; when that is undef,
	# the walk continues into the owner.
	method _pick_focus ($step, $nodes, $focusables, $start) {
		my $count = @$focusables;
		return undef unless $count;
		$start //= $step > 0 ? -1 : $count;
		for my $offset (1 .. $count) {
			my $candidate = $nodes->[ $focusables->[ ($start + $step * $offset) % $count ] ];
			my $owner = $self->_entry_owner_of($candidate, $nodes->[0]);
			if (defined $owner) {
				my $entry = $self->_validate_focus_order($owner, $owner->get_entry_focus($step > 0 ? 'next' : 'previous'));
				return $entry if defined $entry;
			}
			return $candidate if $self->can_take_focus($candidate);
		}
		return undef;
	}

	# The outermost HasFocusOrder with an entry hook between $candidate
	# (included) and $within (excluded) that does not contain the focused
	# widget.
	method _entry_owner_of ($candidate, $within) {
		my $outermost;
		for my $node ($candidate, $candidate->ancestors) {
			last if refaddr($node) == refaddr($within);
			next unless $node->DOES($FOCUS_ORDER) && $node->can('get_entry_focus');
			next if defined $_focused && $node->contains($_focused);
			$outermost = $node;
		}
		return $outermost;
	}

	# -----------------------------------------------------------------
	# Helpers.
	# -----------------------------------------------------------------

	sub _fail ($message) {
		croak_ui "Clay::UI::Interaction::update: $message";
	}

	sub _require_ui ($ui, $method) {
		croak_ui "Clay::UI::Interaction::$method: its Clay::UI no longer exists" unless defined $ui;
		return;
	}

	sub _require_widget ($method, $widget) {
		croak_ui "Clay::UI::Interaction::$method: takes a widget, got " . described_value($widget)
			unless is_widget($widget);
		return;
	}

	# Every Focusable of the subtree $within (itself first) in depth-first
	# pre-order, focusable right now or not.
	sub _focusables_in ($within) {
		return grep { $_->DOES($FOCUSABLE) } $within->subtree;
	}

	sub _is_enabled ($widget) {
		return !$widget->DOES($DISABLEABLE) || $widget->is_enabled;
	}

	# The Pressables under the pointer that a press or release may reach:
	# the enabled ones, unless the Pressable the click lands on (the
	# origin among all of them) is disabled. A disabled widget absorbs the
	# click, so a disabled button inside a pressable card does not click
	# the card.
	sub _press_candidates (@pressables) {
		my $landing = _event_origin(@pressables);
		return () unless defined $landing && _is_enabled($landing);
		return grep { _is_enabled($_) } @pressables;
	}

	sub _holds ($state, $widget) {
		my $held = $state->{ refaddr $widget };
		return defined $held && refaddr($held) == refaddr($widget) ? 1 : 0;
	}

	sub _remember ($state, $widget) {
		$state->{ refaddr $widget } = $widget;
		weaken $state->{ refaddr $widget };
		return;
	}

	sub _live ($state) {
		return grep { defined } values %$state;
	}

	sub _prune (@states) {
		for my $state (@states) {
			delete $state->{$_} for grep { !defined $state->{$_} } keys %$state;
		}
		return;
	}

	# The widget a press or release belongs to. Pointer-over order lists
	# the topmost Clay root first and each root in pre-order, so a later
	# Pressable in the first one's root is its descendant or drawn over
	# it: the last one wins. Ancestors are skipped, as synthetic input may
	# list them after their descendants.
	sub _event_origin (@pressables) {
		my $origin = shift @pressables;
		return undef unless defined $origin;
		my $root_addr = refaddr(_floating_root($origin)) // 0;
		for my $next (@pressables) {
			next if $next->contains($origin);
			next unless (refaddr(_floating_root($next)) // 0) == $root_addr;
			$origin = $next;
		}
		return $origin;
	}

	# The widget whose Clay root $widget is laid out in: its nearest
	# floating ancestor (itself included), or undef for the main root.
	sub _floating_root ($widget) {
		return $widget->closest(\&_is_floating);
	}

	sub _is_floating ($widget) {
		return 0 unless $widget->DOES($FLOATING);
		my $floating = $widget->floating;
		return defined $floating && ($floating->{attach_to} // CLAY_ATTACH_TO_NONE) != CLAY_ATTACH_TO_NONE;
	}
}

1;

__END__

=head1 NAME

Clay::UI::Interaction - hover, press and focus state of a Clay::UI

=head1 SYNOPSIS

	use v5.22;
	use warnings;
	use feature 'signatures';
	no warnings 'experimental::signatures';

	use Object::Pad;
	use Clay::UI;
	use Clay::UI::Box;
	use Clay::UI::Role::Interaction::Pressable;
	use Clay::UI::Role::Interaction::Focusable;

	class My::Panel  :strict(params) :does(Clay::UI::Box) {}
	class My::Button :strict(params)
		:does(Clay::UI::Box)
		:does(Clay::UI::Role::Interaction::Pressable)
		:does(Clay::UI::Role::Interaction::Focusable)
	{}

	my $save   = My::Button->new(id => 'save');
	my $cancel = My::Button->new(id => 'cancel');
	my $root   = My::Panel->new(id => 'root');
	$root->add_child($save, $cancel);
	my $ui = Clay::UI->new(width => 400, height => 300, root => $root);

	$save->on('OnRelease', sub ($event) { say 'save clicked'; return });

	my $interaction = $ui->interaction;

	# Synthetic input, for example in a test or for keyboard activation:
	$interaction->update(over => [ $root, $save ], down => 1, x => 40, y => 12);
	$interaction->update(over => [ $root, $save ], down => 0, x => 40, y => 12);

	$interaction->is_hovered($save);    # 1, also $save->is_hovered
	$interaction->is_pressed($save);    # 0: the button is up again
	my $widgets = $interaction->under_pointer;   # [ $root, $save ]

	# Focus, for example from a Tab key handler:
	$interaction->focus_next;                    # focuses $save
	$interaction->focus_next;                    # focuses $cancel
	$interaction->set_focused_widget($save);
	my $focused = $interaction->get_focused_widget;   # $save
	$interaction->has_focus_within($root);       # 1: $save is below it
	my @tab_stops = $interaction->focusables;    # ($save, $cancel)

=head1 DESCRIPTION

Every L<Clay::UI> owns one interaction tracker, returned by
C<< $ui->interaction >>. The tracker holds:

=over 4

=item *

which widgets are I<hovered> (L<Clay::UI::Role::Interaction::Hoverable>
widgets under the pointer),

=item *

which are I<armed> (L<Clay::UI::Role::Interaction::Pressable> widgets
that were under the pointer when it went down, until it goes up),

=item *

which are I<pressed> (armed, enabled, under the pointer, button down),

=item *

and which widget has the I<focus>
(L<Clay::UI::Role::Interaction::Focusable>).

=back

It turns pointer input into changes of these sets and fires the events
that go with them (C<OnHoverStart>, C<OnHoverStopped>, C<OnPress>,
C<OnRelease>, C<OnScroll>, C<OnFocus>, C<OnBlur>; see
L<Clay::UI/EVENTS>). C<< $ui->render >> passes it the real pointer
every frame through L</update>; you may call C<update> with synthetic
input between frames. Synthetic state lasts until the next C<render>
reports where the real pointer is.

The widget readers C<is_hovered>, C<is_pressed> and C<is_focused>, and
the derived C<hovered>, C<pressed> and C<focused> states of
L<Clay::UI::Role::Style::HasStates>, ask this object. Widgets hold no
interaction state of their own.

Whenever the hovered, armed, pressed or focused widgets change, the
tracker bumps the revision (L<Clay::UI::Revision>), because widgets may
look different in those states.

=head1 CONSTRUCTOR

=head2 new

	my $interaction = Clay::UI::Interaction->new(ui => $ui, tree_order => $sorter);

L<Clay::UI> creates its tracker itself (read it with
L<Clay::UI/interaction>); you never need to. Both parameters are
required; unknown parameters die.

=head2 ui

The L<Clay::UI> the tracker belongs to. The tracker holds it weakly;
the methods that need it die once it is freed, with
C<Clay::UI::Interaction::update: its Clay::UI no longer exists> (the
method's own name in place of C<update>).

=head2 tree_order

A coderef called as C<< $sorter->(@widgets) >> that returns the widgets
in the tree order of the last layout (depth-first pre-order). Events of
one kind fire in this order. Clay::UI passes a coderef that asks its
last completed frame. C<new> dies with
C<Clay::UI::Interaction: 'tree_order' must be a coderef> for anything
else.


=head1 POINTER METHODS

=head2 update

	$interaction->update(
		over     => [ $panel, $button ],   # widgets under the pointer, topmost root first
		down     => 1,                     # button state
		x        => 40,                    # pointer position for OnPress / OnRelease
		y        => 12,
		scrolled => [ [ $list, 0, -30 ] ], # scroll containers that moved
	);

Processes one pointer frame: changes the hovered, armed and pressed
widgets, then fires the events. L<Clay::UI/render> calls it every
frame; call it yourself to feed synthetic input. Named arguments:

=over 4

=item over

Required. Arrayref of the widgets under the pointer, in Clay's
pointer-over order: the topmost floating element first, and each
floating element (or the main tree) in depth-first pre-order. Within
one such root, a later widget is therefore a descendant of an earlier
one or drawn over it. Every widget must belong to this Clay::UI. Only
Hoverable widgets become hovered and only Pressable widgets can be
armed or pressed; L</under_pointer> reports all of them.

=item down

Required. Whether the pointer button is down, a plain boolean. A change
from up to down is a I<press>, from down to up a I<release>.

=item x

=item y

Optional. The pointer position that C<OnPress> and C<OnRelease> carry;
finite numbers, default 0.

=item scrolled

Optional. Arrayref of C<[ $widget, $delta_x, $delta_y ]> entries, one
per scroll container (a widget composing
L<Clay::UI::Role::Layout::HasScroll>) that moved; each gets an
C<OnScroll> with those deltas. A widget may appear only once.

=back

Order of work:

=over 4

=item 1.

All state changes happen first: hover, arming, pressing (see
L</PRESS AND RELEASE>), and the list behind L</under_pointer>.

=item 2.

Then the events fire in this order: every C<OnHoverStopped>, every
C<OnHoverStart>, C<OnPress>, C<OnRelease>, every C<OnScroll>. Events of
one kind fire in tree order; widgets the last layout did not reach come
after the others, in the depth-first pre-order of the tree they are in
now.

=item 3.

Every event fires even if a listener dies; C<update> then rethrows the
first error.

=back

An event that an earlier listener of the same call made stale is
dropped: C<OnPress>, C<OnRelease> and C<OnScroll> for a widget that has
left the tree, C<OnHoverStart> for a widget that is no longer hovered,
C<OnHoverStopped> for one that is hovered again. A widget gets
C<OnHoverStopped> only after its C<OnHoverStart>, and C<OnBlur> only
after its C<OnFocus>.

Listeners may change the tree and the focus, but may not call
C<update> again, and that includes listeners of the events
C<< $ui->render >> fires.

Returns nothing. Dies (all messages start with
C<Clay::UI::Interaction::update:>) for an unknown argument, a missing
C<over> or C<down>, a reference as C<down>, a non-finite C<x> or C<y>,
a widget in C<over> or C<scrolled> that does not belong to this
Clay::UI (C<'over' must hold widgets of this Clay::UI>), a malformed
C<scrolled> entry, a C<scrolled> widget that is no scroll container, a
widget listed twice in C<scrolled>, and a call from one of its own
listeners (C<called from one of its own listeners>). Also dies with
C<Clay::UI::Interaction::update: its Clay::UI no longer exists>.

=head2 under_pointer

	my $widgets = $interaction->under_pointer;

Returns a new arrayref of the widgets of the last C<update>'s C<over>
(normally: under the pointer at the last C<render>), in that order,
Hoverable or not. Widgets that have been freed or removed from the
tree since are left out.

=head2 is_hovered

	my $bool = $interaction->is_hovered($widget);

Returns 1 while C<$widget> is hovered, 0 otherwise.
L<Clay::UI::Role::Interaction::Hoverable/is_hovered> asks this.

=head2 is_armed

	my $bool = $interaction->is_armed($widget);

Returns 1 while C<$widget> is armed (see L</PRESS AND RELEASE>), 0
otherwise.

=head2 is_pressed

	my $bool = $interaction->is_pressed($widget);

Returns 1 while C<$widget> is pressed, 0 otherwise.
L<Clay::UI::Role::Interaction::Pressable/is_pressed> asks this.

=head1 PRESS AND RELEASE

Only enabled Pressables take part: a widget composing
L<Clay::UI::Role::Interaction::Disableable> that is disabled is never
armed or pressed, although it is still hovered. Below, I<candidates>
are the enabled Pressables in C<over>, in C<over>'s order, unless the
Pressable the pointer lands on (the origin, chosen by the rule below
among all Pressables in C<over>, enabled or not) is disabled: then there
are no candidates. A disabled widget absorbs the click, as a disabled
button does in HTML. Pressing a disabled button inside a pressable card
arms and presses nothing, and the card gets neither C<OnPress> nor
C<OnRelease>; dragging a pressed card onto its disabled button unpresses
the card. A disabled card around an enabled button does not stop the
button.

=over 4

=item Press

On a press (C<down> changes from false to true), every candidate
becomes armed, and one of them gets C<OnPress>: the I<origin>.

=item Origin

Start with the first candidate. Walk through the remaining candidates
in order; a candidate replaces the current pick unless it is an
ancestor of the current pick, or it lies in a different I<root> than
the first candidate. A widget's root is its nearest ancestor (or
itself) that composes L<Clay::UI::Role::Layout::HasFloating> with a
C<floating> setting whose C<attach_to> is not C<CLAY_ATTACH_TO_NONE>;
widgets without such an ancestor share the main root. The last pick is
the origin.

In effect: of nested Pressables the innermost one wins (a button inside
a pressable card); of overlapping siblings, such as the children of a
C<CLAY_BACK_TO_FRONT> container, the later one wins; a Pressable inside
a floating element beats every Pressable below that element, because
Clay lists the topmost floating element first.

=item Pressed

After every C<update>, a Pressable is pressed when it is armed, enabled
and in C<over>, and C<down> is true. Dragging off an armed widget
unpresses it; dragging back on (button still down) presses it again.
Dragging onto a widget that was not armed does not press it.

=item Release

On a release (C<down> changes from true to false), the origin is chosen
again by the same rule, but only among the candidates that are armed.
It gets C<OnRelease>: a completed click. Then every widget is disarmed.
A press on a button inside a pressable card that is dragged off the
button and released over the card gives the card its C<OnRelease>,
because the press armed both. A release over no armed candidate fires
nothing.

=back

C<OnPress> and C<OnRelease> bubble with C<IF_CONTINUE>
(L<Clay::UI::Enum::Bubble>): the card in the example above sees the
button's C<OnPress> only as a bubbled event, when the button has no
C<OnPress> listener or all its listeners return
C<< Clay::UI::Enum::Result->CONTINUE >>.

=head1 FOCUS

The focus is held by at most one widget, a
L<Clay::UI::Role::Interaction::Focusable> of this UI. It changes only
through:

=over 4

=item *

L</set_focused_widget>, L</focus_next> and L</focus_previous>;

=item *

the removal of a subtree that holds the focused widget (it gets
C<OnBlur>, see L</REMOVED WIDGETS>);

=item *

the focused widget becoming unable to take the focus, through
C<can_focus(0)> or by being disabled (it gets C<OnBlur>, see
L</release_ineligible>).

=back

In the last two cases the focus does not simply vanish: it goes to the
widget's I<heir> (see L</Focus heirs>), which gets C<OnFocus> right after
the C<OnBlur>.

C<render> never moves the focus. Event listeners, pointer listeners
included, may move it.

The focus follows the widget tree as it is now, while pointer events
follow the tree of the last layout: the focus must work before the
first C<render> and right after the tree changed, whereas the pointer
was tested against the last layout.

L</set_focused_widget>, L</focus_next>, L</focus_previous>,
L</focusables>, L</default_next_focus> and L</default_previous_focus>
die with
C<Clay::UI::Interaction::E<lt>methodE<gt>: its Clay::UI no longer exists>
once the Clay::UI that owns this tracker has been freed.

=head2 Focus scopes

L</focusables>, L</default_next_focus> and L</default_previous_focus>
take an optional C<< within => $widget >>: the I<focus scope>, a
subtree of this UI (C<$widget> and every widget below it in layout
pre-order, see L<Clay::UI::Role::Core::Element/descendants>). Without
it they cover the whole tree. A modal dialog keeps Tab inside itself
with a HasFocusOrder that steps within its own subtree (see
L<Clay::UI::Role::Interaction::HasFocusOrder/default_next_focus>).
C<within> must be a widget of this UI; anything else dies with
C<Clay::UI::Interaction::E<lt>methodE<gt>: 'within' must be a widget of this Clay::UI>,
and another argument dies with
C<Clay::UI::Interaction::E<lt>methodE<gt>: unknown argument(s): ...>.

=head2 Focus heirs

When the focused widget leaves the tree or can no longer take the
focus, the tracker hands the focus to an I<heir>, so that keys keep
reaching the part of the screen the user was working in. It walks up
from the widget that loses the focus (itself first, then its
ancestors) and stops at the first node where one of these holds:

=over 4

=item 1.

The node stays in the tree and can take the focus
(L</can_take_focus>): it is the heir.

=item 2.

The node has a L</focus_heir> method that returns a widget that stays
in the tree and can take the focus: that widget is the heir. Nodes that
are being removed are asked too, so a removed popup can name the
widget that comes after it.

=back

When no node qualifies, nothing has the focus afterwards. Nodes that are
being removed never become the heir themselves, nor may a hook name
one. The old widget's C<OnBlur> fires first, then the heir's
C<OnFocus>, in the same batch of events; while the C<OnBlur> listeners
run, L</get_focused_widget> already returns the heir.

=head2 focus_heir

	method focus_heir () { return $self->active_tab_button }

A hook any widget class may implement (no role declares it): who takes
the focus when the focus inside this widget is lost, and the widget
itself cannot take it. Called during the walk described in
L</Focus heirs>, without arguments; returns a widget, or C<undef> for
"none, ask my ancestors". A widget that is being removed or cannot take
the focus right now counts as C<undef>. A tab view names its active
tab, a collapsible section its header, a popup the widget that had the
focus before it opened.

Anything but a widget or C<undef> is a bug in the class: the walk stops,
nothing inherits the focus, and the removal or setter that lost it dies
afterwards with
C<Clay::UI::Interaction: E<lt>classE<gt> returned ... from focus_heir, which is not a widget>.
A hook that dies is treated the same way, with its own error.

=head2 get_focused_widget

	my $widget = $interaction->get_focused_widget;

Returns the widget that has the focus, or C<undef> when none has it (or
the focused widget has been freed; the tracker holds it weakly).

=head2 is_focused

	my $bool = $interaction->is_focused($widget);

Returns 1 when C<$widget> has the focus, 0 otherwise.
L<Clay::UI::Role::Interaction::Focusable/is_focused> asks this.

=head2 has_focus_within

	my $bool = $interaction->has_focus_within($panel);

Returns 1 when the focused widget is C<$panel> or below it (also below
an internal child), 0 otherwise, also when nothing is focused. Use it
to draw a panel differently while the keyboard is in it, or to close a
popup once the focus left it. Dies with
C<Clay::UI::Interaction::has_focus_within: takes a widget, got ...> for
anything but a widget.

=head2 focusables

	my @widgets = $interaction->focusables;
	my @inside  = $interaction->focusables(within => $dialog);

Returns the widgets of the scope (see L</Focus scopes>; the scope's
own widget included) that can take the focus now (L</can_take_focus>),
in depth-first pre-order of the current tree. Disabled widgets and
widgets whose C<can_focus> is false are left out.

=head2 can_take_focus

	my $bool = $interaction->can_take_focus($widget);

Returns 1 when L</set_focused_widget> would accept C<$widget> now: it
composes L<Clay::UI::Role::Interaction::Focusable>, belongs to this UI
(and is not being removed), and its C<can_focus> is true. Returns 0
otherwise, also for a non-widget. Use it to find a widget to focus, for
example the nearest ancestor of a clicked widget that can take the
focus:

	my $target = $clicked->closest(sub ($node) { $interaction->can_take_focus($node) });
	$interaction->set_focused_widget($target) if defined $target;

=head2 set_focused_widget

	$interaction->set_focused_widget($widget);
	$interaction->set_focused_widget(undef);     # clear the focus

Gives the focus to C<$widget>, or clears it for C<undef>. Focusing the
widget that already has the focus, or clearing an empty focus, does
nothing (no events).

The target is checked before anything changes. Dies with
C<Clay::UI::Interaction::set_focused_widget: target> followed by
C<must be a blessed widget>,
C<must consume Clay::UI::Role::Interaction::Focusable>,
C<does not belong to this Clay::UI> or
C<is not currently focusable (can_focus returned false)>.


Then the focus moves (the derived C<focused> state moves with it), the
revision is bumped, and L<Clay::UI::Events::OnBlur> fires at the widget
that had the focus (if any), then L<Clay::UI::Events::OnFocus> at the
new one (if any). Both fire even if the first listener dies; the first
error is rethrown afterwards, with the focus already moved. An
C<OnBlur> listener may move the focus again; the C<OnFocus> of this
call is then dropped, since its widget no longer has the focus.

=head2 focus_next

	$interaction->focus_next;

Moves the focus to the next widget, for example on Tab. Returns
nothing.

=over 4

=item Default order

The depth-first pre-order of the current tree (children before the
next sibling), skipping widgets whose C<can_focus> is false and
wrapping around at the end. With nothing focused, the first widget that
can take the focus gets it. Internal children of widgets count like
children.

=item Entering a subtree with its own order

When the next widget of the default order lies at or below a
HasFocusOrder widget that does not hold the focus and has an entry hook
(L<Clay::UI::Role::Interaction::HasFocusOrder/get_entry_focus>), that
widget decides where the focus enters: its hook is called with
C<'next'> and its result is validated like a custom order's. C<undef>
lets the default order continue into the subtree. With such widgets
nested in each other, the outermost one that does not hold the focus
decides. A widget that is the scope of the walk, or above it, is not
asked.

=item Custom order

If the focused widget or one of its ancestors composes
L<Clay::UI::Role::Interaction::HasFocusOrder>, the nearest such widget
decides: its C<get_next_focus> is called. With nothing focused, the root
widget decides if it composes HasFocusOrder. Its result must be C<undef>
(the focus stays), or a Focusable widget of this UI, which gets the
focus (or the focus stays, when its C<can_focus> is false right now).
Anything else dies with
C<Clay::UI::Interaction: E<lt>classE<gt> returned ...>, naming the
HasFocusOrder class and what was wrong.


=back

=head2 focus_previous

	$interaction->focus_previous;

Moves the focus to the previous widget, for example on Shift+Tab: the
mirror of L</focus_next>. With nothing focused, the last widget that
can take the focus gets it; a HasFocusOrder decides through its
C<get_previous_focus>.

=head2 default_next_focus

	my $widget = $interaction->default_next_focus;
	my $inside = $interaction->default_next_focus(within => $dialog);

Returns the widget the default order (see L</focus_next>) would focus
next, ignoring the orders of HasFocusOrder widgets but honouring their
entry hooks, or C<undef> when no widget can take the focus. Changes
nothing. A HasFocusOrder widget calls it to fall back to the default
order (see
L<Clay::UI::Role::Interaction::HasFocusOrder/default_next_focus>).

With C<within> (see L</Focus scopes>) only the scope's widgets count:
the next one after the focused widget, wrapping around inside the
scope, or the first one when the focus is outside the scope or nothing
is focused. The scope itself is never asked for an entry, so a
HasFocusOrder that steps within its own subtree does not re-enter its
own hook.

=head2 default_previous_focus

	my $widget = $interaction->default_previous_focus;
	my $inside = $interaction->default_previous_focus(within => $dialog);

The mirror of L</default_next_focus>: with the focus outside the scope,
the last widget of the scope.

=head2 focus_after

	my $next     = $interaction->focus_after($widget, 'next');
	my $previous = $interaction->focus_after($widget, 'previous');

Returns the widget the default order would focus after the whole
subtree of C<$widget> (C<'next'>), or before it (C<'previous'>), or
C<undef> when no widget can take the focus. Changes nothing. This is
how a HasFocusOrder widget hands the focus on once it has stepped
through its own subtree: C<< $self->ui->interaction->focus_after($self, 'next') >>.

The step stays inside the scope of the nearest HasFocusOrder above
C<$widget>: that widget's
L<focus_scope|Clay::UI::Role::Interaction::HasFocusOrder/focus_scope>
when it has one, else the widget itself. Without such an ancestor, the
whole tree is the scope. The order wraps around inside the scope, so a
subtree at the end of a modal dialog hands the focus to the first widget
of the dialog, not to the window behind it. Entry hooks apply as in
L</default_next_focus>.

C<$widget> must be a widget of this UI, and the direction one of the two
words; anything else dies with
C<Clay::UI::Interaction::focus_after: ...>.

=head2 release_ineligible

	$interaction->release_ineligible($widget);

Drops what C<$widget> may no longer have, at once. A disabled widget
stops being armed and pressed. A focused widget whose C<can_focus> is
now false loses the focus to its heir (see L</Focus heirs>) as through
L</set_focused_widget>: it gets C<OnBlur> and the heir C<OnFocus> before
this returns. A widget that may keep everything is left alone. Bumps
the revision when a state changed.

The C<disabled> writer of L<Clay::UI::Role::Interaction::Disableable>,
the C<can_focus> writer of L<Clay::UI::Role::Interaction::Focusable>
and its C<focus_eligibility_changed> call it; a class whose
C<accepts_focus> answer changes calls C<focus_eligibility_changed>
rather than this.

=head1 REMOVED WIDGETS

When a subtree leaves the tree, the tracker releases it at once, during
the removal:

=over 4

=item 1.

Its hovered widgets stop being hovered, its armed and pressed widgets
are dropped, its widgets leave L</under_pointer>, and if a widget inside
it has the focus, the focus moves to that widget's heir outside the
subtree (see L</Focus heirs>), or nowhere. The revision is bumped when a
state changed.

=item 2.

The hovered widgets get C<OnHoverStopped> (in tree order), the
focused widget gets C<OnBlur> and its heir C<OnFocus>. The removed widgets are still attached
to their parents while these events fire, so C<OnBlur> bubbles through
the old ancestors and C<< $event->target->parent >> still works.

=back

Armed or pressed widgets get no event: a pending click is simply
dropped, and the next release fires nothing for them.

While these events fire, the subtree already counts as gone: a listener
cannot hover, press or focus a widget inside it (C<update> and
C<set_focused_widget> die as for a widget of another UI). Every event
fires even if a listener dies; the first error is rethrown after the
children are detached.

=head2 release_subtrees

	$interaction->release_subtrees(@top_widgets);

Does the above for every widget in C<@top_widgets> and everything below
them. The child methods of L<Clay::UI::Role::Core::Element> (and so of
L<Clay::UI::Role::Core::Container> and L<Clay::UI::Grid>) call it once
per change, with all removed children, while the children are still
attached. A widget class that detaches children some other way must
call it too; otherwise you do not call it yourself.

=head1 SEE ALSO

L<Clay::UI> (L<Clay::UI/HOW A FRAME WORKS>, L<Clay::UI/EVENTS>),
L<Clay::UI::Role::Interaction::Hoverable>,
L<Clay::UI::Role::Interaction::Pressable>,
L<Clay::UI::Role::Interaction::Focusable>,
L<Clay::UI::Role::Interaction::Disableable>,
L<Clay::UI::Role::Interaction::HasFocusOrder>, L<Clay::Manual>.

=cut
