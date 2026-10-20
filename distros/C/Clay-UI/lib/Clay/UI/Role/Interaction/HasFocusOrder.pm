package Clay::UI::Role::Interaction::HasFocusOrder;
our $VERSION = '0.07';
use v5.22;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Object::Pad 0.800;

use Clay::UI::Role::Layout::HasParent;

role Clay::UI::Role::Interaction::HasFocusOrder :does(Clay::UI::Role::Layout::HasParent) {
	method get_next_focus;
	method get_previous_focus;

	method default_next_focus (%args) {
		my $ui = $self->ui;
		return defined $ui ? $ui->interaction->default_next_focus(%args) : undef;
	}

	method default_previous_focus (%args) {
		my $ui = $self->ui;
		return defined $ui ? $ui->interaction->default_previous_focus(%args) : undef;
	}
}

1;

__END__

=head1 NAME

Clay::UI::Role::Interaction::HasFocusOrder - role for containers that choose the focus order in their subtree

=head1 SYNOPSIS

	use v5.22;
	use warnings;
	use feature 'signatures';
	no warnings 'experimental::signatures';

	use Object::Pad;
	use Clay::UI;
	use Clay::UI::Box;
	use Clay::UI::Role::Interaction::Focusable;
	use Clay::UI::Role::Interaction::HasFocusOrder;

	class My::Input :strict(params)
		:does(Clay::UI::Box)
		:does(Clay::UI::Role::Interaction::Focusable)
	{}

	# A form whose first Tab goes to the toolbar, although it comes last.
	class My::Form :strict(params)
		:does(Clay::UI::Box)
		:does(Clay::UI::Role::Interaction::HasFocusOrder)
	{
		field $toolbar :param :reader;

		method get_next_focus () {
			return $toolbar unless defined $self->ui->interaction->get_focused_widget;
			return $self->default_next_focus;
		}

		method get_previous_focus () {
			return $self->default_previous_focus;
		}
	}

	my $toolbar = My::Input->new(id => 'toolbar');
	my $form    = My::Form->new(id => 'form', toolbar => $toolbar);
	$form->add_child(My::Input->new(id => 'name'), My::Input->new(id => 'email'), $toolbar);
	my $ui = Clay::UI->new(width => 400, height => 300, root => $form);

	for (1 .. 4) {
		$ui->interaction->focus_next;
		say $ui->interaction->get_focused_widget->id;   # toolbar, name, email, toolbar
	}

=head1 DESCRIPTION

By default, C<focus_next> and C<focus_previous>
(L<Clay::UI::Interaction>) move the focus in the depth-first pre-order
of the widget tree. A widget that composes this role decides the order
inside its subtree instead. It does not need to take the focus itself:
HasFocusOrder does not imply L<Clay::UI::Role::Interaction::Focusable>.

Which widget decides:

=over 4

=item *

With a focused widget: the nearest widget composing HasFocusOrder among
the focused widget and its ancestors. When there is none, the default
order applies.

=item *

With nothing focused: the root widget of the L<Clay::UI>, if it
composes HasFocusOrder; otherwise the default order applies.

=back

The deciding widget's L</get_next_focus> (for C<focus_next>) or
L</get_previous_focus> (for C<focus_previous>) is called without
arguments and must return one of:

=over 4

=item C<undef>

The focus stays where it is.

=item a Focusable widget of the same Clay::UI

It gets the focus, unless its C<can_focus> is 0 at that moment; then
the focus stays where it is.

=back

Anything else is a bug in the composing class: a non-widget, a widget
that does not compose L<Clay::UI::Role::Interaction::Focusable>, or a
widget that is not part of this Clay::UI. C<focus_next> /
C<focus_previous> then die with
C<Clay::UI::Interaction: E<lt>classE<gt> returned ...>, naming the class
and the problem.

The order decides what happens while the focus is inside the subtree.
Two optional methods say how the focus gets in and out:

=over 4

=item *

L</get_entry_focus> is asked when the default order, coming from
outside, would land at or below this widget: for example a view that
wants Tab to stop on itself before it steps through its content.

=item *

L<focus_after|Clay::UI::Interaction/focus_after> hands the focus on
after the subtree, inside the scope of the enclosing order
(L</focus_scope>): for example that view, once Tab passed its last
widget.

=back

The role composes L<Clay::UI::Role::Layout::HasParent> (for C<ui>).

=head1 REQUIRED METHODS

The composing class must implement both.

=head2 get_next_focus

	method get_next_focus () { ... }

Returns the widget that should get the focus on C<focus_next>, or
C<undef> to keep it. C<< $self->ui->interaction->get_focused_widget >>
tells where the focus is now (C<undef> when nothing is focused).

=head2 get_previous_focus

	method get_previous_focus () { ... }

Returns the widget that should get the focus on C<focus_previous>, or
C<undef>; the mirror of L</get_next_focus>.

=head1 OPTIONAL METHODS

The composing class may implement these; the tracker checks for them
with C<can>. The role does not provide them, so a class is free to
define them.

=head2 get_entry_focus

	method get_entry_focus ($direction) { return $self }

Called when the default order (L<Clay::UI::Interaction/focus_next>,
L</default_next_focus>, L<Clay::UI::Interaction/focus_after>), coming
from outside this widget's subtree, would focus a widget at or below
it. C<$direction> is C<'next'> or C<'previous'>. Returns the widget
that should get the focus instead, validated like the result of
L</get_next_focus>, or C<undef> to let the default order continue into
the subtree. It is not called while the focus is inside the subtree,
nor for a walk whose scope is this widget or below it, so a class may
use L</default_next_focus> with C<< within => $self >> freely. With
such widgets nested, the outermost one that does not hold the focus is
asked.

=head2 focus_scope

	method focus_scope () { return $dialog }

The subtree this widget's order covers, when it is not the widget's own
subtree: a widget of the same Clay::UI. L<Clay::UI::Interaction/focus_after>
steps inside it when it hands the focus on after a subtree below this
widget. A modal backdrop whose order keeps Tab inside its dialog returns
the dialog here, so a view at the end of the dialog hands the focus to
the dialog's first widget and never to the backdrop or the window
behind it. Without this method the scope is the widget itself.

=head1 PROVIDED METHODS

=head2 default_next_focus

	return $self->default_next_focus;
	return $self->default_next_focus(within => $self);

Returns the widget the default order would focus next from the
currently focused widget, ignoring the orders of other HasFocusOrder
widgets but honouring their entry hooks (see
L<Clay::UI::Interaction/default_next_focus>), or C<undef> when no
widget can take the focus or this widget does not belong to a
Clay::UI. Use it for partial overrides: handle the special case, and
return C<< $self->default_next_focus >> for everything else.

The arguments go to the tracker as they are. With
C<< within => $widget >> (a focus scope, see
L<Clay::UI::Interaction/Focus scopes>) the order is limited to that
subtree and wraps around inside it, which is how a modal dialog keeps
Tab inside itself:

	method get_next_focus ()     { return $self->default_next_focus(within => $self) }
	method get_previous_focus () { return $self->default_previous_focus(within => $self) }

=head2 default_previous_focus

	return $self->default_previous_focus;
	return $self->default_previous_focus(within => $self);

The mirror of L</default_next_focus>.

=head1 SEE ALSO

L<Clay::UI::Interaction/FOCUS>, L<Clay::UI::Interaction/focus_next>,
L<Clay::UI::Role::Interaction::Focusable>.

=cut
