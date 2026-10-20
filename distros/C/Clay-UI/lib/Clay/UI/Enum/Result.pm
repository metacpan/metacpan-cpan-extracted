package Clay::UI::Enum::Result;
our $VERSION = '0.07';
use v5.22;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Object::Pad 0.800;
use Object::PadX::Enum;

enum Clay::UI::Enum::Result {
	item HANDLED;
	item CONTINUE;
}

1;

__END__

=head1 NAME

Clay::UI::Enum::Result - what an event listener returns: stop the event or let it continue

=head1 SYNOPSIS

	use v5.22;
	use warnings;
	use feature 'signatures';
	no warnings 'experimental::signatures';

	use Object::Pad;
	use Clay::UI::Box;
	use Clay::UI::Events::OnPress;
	use Clay::UI::Enum::Result;

	class My::Panel :strict(params) :does(Clay::UI::Box) {}

	my $card   = My::Panel->new(id => 'card');
	my $button = My::Panel->new(id => 'button');
	$card->add_child($button);

	$card->on('OnPress', sub ($event) { say 'card saw the press'; return });
	$button->on('OnPress', sub ($event) {
		say 'button pressed';
		return Clay::UI::Enum::Result->CONTINUE;   # let the card see it too
	});

	my $result = $button->fire_event(Clay::UI::Events::OnPress->new);
	say 'stopped at ', $result == Clay::UI::Enum::Result->HANDLED ? 'the card' : 'nowhere';

=head1 DESCRIPTION

An event listener's return value decides whether the event I<stops>
at the listener's widget. Return C<CONTINUE> to let it go on; anything
else stops it. The bubble mode of the event decides what stopping means
(L<Clay::UI::Enum::Bubble>): with C<IF_CONTINUE> the event does not
move on to the parent, with C<ALWAYS> and C<NEVER> it travels as it
would anyway, but the widget is still recorded as the event's
C<handled_by>.

L<Clay::UI::Role::Events::Emitter/fire_event> and
L<Clay::UI::Events::Event/result> also report the outcome as one of
these values.

The values are singleton objects (built with L<Object::PadX::Enum>);
compare them with C<==> and C<!=>.

=head1 VALUES

=head2 HANDLED

	return Clay::UI::Enum::Result->HANDLED;

Stops the event at this widget. Returning C<undef>, an empty C<return>,
or any other value has the same effect: only C<CONTINUE> lets an event
go on. As a result of C<fire_event>: some listener stopped the event,
and C<< $event->handled_by >> names the widget.

=head2 CONTINUE

	return Clay::UI::Enum::Result->CONTINUE;

Lets the event go on to the parent (with C<IF_CONTINUE>). As a result
of C<fire_event>: no listener stopped the event.

=head1 METHODS

C<name>, C<values> and C<from_name> work as described in
L<Clay::UI::Enum::Bubble/METHODS>.

=head1 SEE ALSO

L<Clay::UI::Enum::Bubble>, L<Clay::UI::Role::Events::Emitter>,
L<Clay::UI::Role::Events::Listener>.

=cut
