package Clay::UI::Enum::Bubble;
our $VERSION = '0.07';
use v5.22;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Object::Pad 0.800;
use Object::PadX::Enum;

enum Clay::UI::Enum::Bubble {
	item ALWAYS;
	item IF_CONTINUE;
	item NEVER;
}

1;

__END__

=head1 NAME

Clay::UI::Enum::Bubble - how far a Clay::UI event travels up the widget tree

=head1 SYNOPSIS

	use v5.22;
	use warnings;

	use Clay::UI::Enum::Bubble;
	use Clay::UI::Events::Event;

	my $event = Clay::UI::Events::Event->new(
		name        => 'OnPing',
		bubble_mode => Clay::UI::Enum::Bubble->ALWAYS,
	);
	say $event->bubble_mode->name;    # ALWAYS
	say 'travels to every ancestor'                  # compare with == and !=
		if $event->bubble_mode == Clay::UI::Enum::Bubble->ALWAYS;

=head1 DESCRIPTION

Every event has a I<bubble mode>
(L<Clay::UI::Events::Event/bubble_mode>). When a widget fires an event
(L<Clay::UI::Role::Events::Emitter/fire_event>), all listeners of that
widget for the event's name run first, in the order they were
registered. Then the bubble mode decides whether the event moves on to
the widget's parent, where the same happens again, up to the root
widget.

A listener I<stops> the event when it returns anything but
C<< Clay::UI::Enum::Result->CONTINUE >>, including C<undef> and an
empty C<return> (see L<Clay::UI::Enum::Result>). Stopping never skips
other listeners of the same widget: the decision is made per widget,
after all its listeners ran.

The values are singleton objects (built with L<Object::PadX::Enum>);
compare them with C<==> and C<!=>.

=head1 VALUES

=head2 ALWAYS

	Clay::UI::Enum::Bubble->ALWAYS

The event visits the widget and every ancestor, whatever the listeners
return. C<handled_by> names the first widget where a listener stopped
it.

=head2 IF_CONTINUE

	Clay::UI::Enum::Bubble->IF_CONTINUE

The event moves on to the parent unless a listener of the current
widget stopped it. A widget without listeners for the event passes it
on. This is the default of L<Clay::UI::Events::Event> and of the
built-in C<OnPress>, C<OnRelease>, C<OnScroll>, C<OnFocus> and
C<OnBlur>.

=head2 NEVER

	Clay::UI::Enum::Bubble->NEVER

Only the widget the event was fired at sees it; ancestors never do.
The default of C<OnHoverStart> and C<OnHoverStopped>.

=head1 METHODS

=head2 name

	my $name = $mode->name;    # 'ALWAYS', 'IF_CONTINUE' or 'NEVER'

The value's name.

=head2 values

	my @modes = Clay::UI::Enum::Bubble->values;

All three values, in the order C<ALWAYS>, C<IF_CONTINUE>, C<NEVER>.

=head2 from_name

	my $mode = Clay::UI::Enum::Bubble->from_name('NEVER');

The value with that name. Further methods (C<ordinal>,
C<from_ordinal>) come from L<Object::PadX::Enum>.

=head1 SEE ALSO

L<Clay::UI::Enum::Result>, L<Clay::UI::Role::Events::Emitter>,
L<Clay::UI::Events::Event>.

=cut
