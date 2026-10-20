package Clay::UI::_FrameRegistry;
our $VERSION = '0.07';
use v5.22;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Object::Pad 0.800;
use Scalar::Util qw(refaddr weaken);

class Clay::UI::_FrameRegistry :strict(params) {
	use Clay::XS qw(Clay_GetScrollContainerData);

	my @PADDING_SIDES = qw(left top right bottom);

	# Every widget reference is weak: a widget freed after its frame looks
	# like one the frame never saw.
	field %_by_user_data;   # render-command userData (refaddr) -> widget
	field %_by_element;     # Clay element id -> widget
	field %_rank;           # refaddr -> [ position in the walk (pre-order), widget, element id hash, padding ]
	field @_scroll;         # [ widget, element id hash ] per scroll container

	# Records a widget that emits render commands; returns the userData
	# value that maps them back to it.
	method add_back_reference ($widget) {
		my $user_data = refaddr $widget;
		$_by_user_data{$user_data} = $widget;
		weaken $_by_user_data{$user_data};
		return $user_data;
	}

	# Records a widget Clay declared an element for, in walk order, with
	# the element id hash Clay named it by and the padding of its
	# declaration (a Clay_Padding hash; missing sides and a missing hash
	# are 0, as for Clay).
	method add_element ($widget, $element_id, $padding = undef) {
		$padding //= {};
		$_by_element{ $element_id->{id} } = $widget;
		weaken $_by_element{ $element_id->{id} };
		my %declared = map { $_ => ($padding->{$_} // 0) + 0 } @PADDING_SIDES;
		$_rank{ refaddr $widget } = [ scalar keys %_rank, $widget, $element_id, \%declared ];
		weaken $_rank{ refaddr $widget }[1];
		if ($self->is_scroll_container($widget)) {
			push @_scroll, [ $widget, $element_id ];
			weaken $_scroll[-1][0];
		}
		return;
	}

	# A scroll container is a widget composing HasScroll: only it gets
	# Clay's scroll offset injected and receives OnScroll.
	method is_scroll_container ($widget) {
		return $widget->DOES('Clay::UI::Role::Layout::HasScroll') ? 1 : 0;
	}

	# Every widget the walk declared, element or text: each is one Clay
	# layout element.
	method element_count () {
		return scalar keys %_by_user_data;
	}

	method widget_for ($user_data) {
		return $_by_user_data{$user_data};
	}

	method widget_for_element ($id) {
		return $_by_element{$id};
	}

	# The element id hash the walk declared the widget with, or undef if
	# the walk did not reach it.
	method element_id_of ($widget) {
		return undef unless defined $self->_walk_rank($widget);
		return $_rank{ refaddr $widget }[2];
	}

	# A copy of the padding the walk declared the widget with ({ left,
	# top, right, bottom }), or undef if the walk did not reach it.
	method padding_of ($widget) {
		return undef unless defined $self->_walk_rank($widget);
		return { %{ $_rank{ refaddr $widget }[3] } };
	}

	# Widgets sorted by their position in the walk. Widgets the walk did not
	# reach (added since) follow, in the pre-order of the tree they are in
	# now; ties keep their input order.
	method in_tree_order (@widgets) {
		my $walked  = scalar keys %_rank;
		my %unknown = map { refaddr($_) => $_ } grep { !defined $self->_walk_rank($_) } @widgets;
		my %live_rank;
		for my $root (_distinct_roots(values %unknown)) {
			my $position = 0;
			$live_rank{ refaddr $_ } //= $position++ for $root->subtree;
		}
		my $rank = sub ($widget) {
			return $self->_walk_rank($widget) // $walked + ($live_rank{ refaddr $widget } // 9**9**9);
		};
		my @keyed = map { [ $rank->($widgets[$_]), $_, $widgets[$_] ] } 0 .. $#widgets;
		return map { $_->[2] } sort { $a->[0] <=> $b->[0] || $a->[1] <=> $b->[1] } @keyed;
	}

	# The widget's position in the walk, or undef if the walk did not reach
	# it (a freed widget's address may have been reused).
	method _walk_rank ($widget) {
		my $entry = $_rank{ refaddr $widget };
		return undef unless defined $entry && defined $entry->[1] && refaddr($entry->[1]) == refaddr($widget);
		return $entry->[0];
	}

	sub _distinct_roots (@widgets) {
		my %roots = map { my $root = $_->root; refaddr($root) => $root } @widgets;
		return values %roots;
	}

	# [ widget, element id hash ] for every scroll container that still
	# exists, in walk order.
	method scroll_containers () {
		return map { [ @$_ ] } grep { defined $_->[0] } @_scroll;
	}

	# Where the scroll containers of $ui are now, looked up under the
	# element id this frame declared them with: refaddr => [ widget,
	# element id, position ]. Containers detached since are left out.
	method scroll_positions ($ui) {
		my %positions;
		for my $container ($self->scroll_containers) {
			my ($widget, $element_id) = @$container;
			next unless $ui->owns($widget);
			my $data = Clay_GetScrollContainerData($element_id);
			$positions{ refaddr $widget } = [ $widget, $element_id, $data->{scrollPosition} ] if $data->{found};
		}
		return \%positions;
	}

	# [ widget, dx, dy ] for each container of an earlier scroll_positions
	# that has moved since.
	method scroll_changes ($before) {
		my @changes;
		for my $entry (values %$before) {
			my ($widget, $element_id, $old) = @$entry;
			my $data = Clay_GetScrollContainerData($element_id);
			next unless $data->{found};
			my $new = $data->{scrollPosition};
			my ($dx, $dy) = ($new->{x} - $old->{x}, $new->{y} - $old->{y});
			push @changes, [ $widget, $dx, $dy ] if $dx != 0 || $dy != 0;
		}
		return @changes;
	}
}

1;

__END__

=head1 NAME

Clay::UI::_FrameRegistry - what one Clay::UI frame laid out

=head1 DESCRIPTION

L<Clay::UI> builds one registry per frame while it walks the widget tree
and replaces the previous one only when the frame completes, so a failed
frame leaves the last good registry in place. It answers the questions
the next frame's pointer and scroll handling asks about the last layout:
which widget a render command's C<userData> or a Clay element id
belongs to, where widgets came in the walk, which scroll containers were
declared under which element id, and how far they have scrolled since.

It also defines what a scroll container is: a widget composing
L<Clay::UI::Role::Layout::HasScroll>. The walker injects Clay's scroll
offset only into scroll containers, and only they receive C<OnScroll>.

Widget references are weak.

This module is internal. The API is not part of the public contract.

=head1 METHODS

=over 4

=item C<add_back_reference($widget)>

Records C<$widget>; returns the C<userData> value for its render
commands.

=item C<is_scroll_container($widget)>

1 if C<$widget> is a scroll container, else 0.

=item C<add_element($widget, $element_id, $padding)>

Records a widget Clay declared an element for (an element or a text
widget) in walk order under the element id hash Clay named it by, with
the padding of its declaration (a C<Clay_Padding> hash, or undef for
none; missing sides are 0); a scroll container is also listed by
C<scroll_containers>.

=item C<element_count>

How many widgets C<add_back_reference> recorded: the Clay layout
elements the walk declared, element and text widgets alike.

=item C<widget_for($user_data)>, C<widget_for_element($id)>

The widget, or undef.

=item C<element_id_of($widget)>, C<padding_of($widget)>

The element id hash, or a copy of the padding
(C<< { left, top, right, bottom } >>), the walk declared C<$widget>
with; undef for a widget the walk did not reach.

=item C<in_tree_order(@widgets)>

C<@widgets> sorted by walk position. Widgets the walk did not reach
come last, in the depth-first pre-order of the tree they are in now;
ties keep their original order.

=item C<scroll_containers>

List of C<[ $widget, $element_id ]> for the scroll containers that
still exist, in walk order.

=item C<scroll_positions($ui)>

Hashref C<< refaddr => [ $widget, $element_id, $position ] >> for the
scroll containers that still belong to C<$ui> and that Clay knows,
with their current scroll position. Needs C<$ui>'s Clay context to be
current.

=item C<scroll_changes($positions)>

List of C<[ $widget, $delta_x, $delta_y ]> for the containers of an
earlier C<scroll_positions> result that have moved since.

=back

=cut
