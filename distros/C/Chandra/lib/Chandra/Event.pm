package Chandra::Event;

use strict;
use warnings;

our $VERSION = '0.10';

# XS methods are registered under the Chandra bootstrap.
# Ensure the shared object is loaded.
require Chandra;

1;

__END__

=head1 NAME

Chandra::Event - Event object for element handlers

=head1 SYNOPSIS

	# In an element handler:
	onclick => sub {
	    my ($event, $app) = @_;

	print "Event type: ", $event->type, "\n";
	print "Target ID: ", $event->target_id, "\n";
	print "Value: ", $event->value, "\n";
	}

=head1 DESCRIPTION

Chandra::Event wraps the event data sent from JavaScript when a DOM event
fires. It is passed as the first argument to element event handlers
(C<onclick>, C<onchange>, etc.).

=head1 CONSTRUCTOR

=head2 new

	my $event = Chandra::Event->new(\%data);

Creates a new event from a hashref. Typically called internally by
L<Chandra::Bind> during dispatch, not by user code.

The C<%data> hash may contain: C<type>, C<targetId>, C<targetName>,
C<value>, C<checked>, C<key>, C<keyCode>, and any custom fields.

=head1 METHODS

=head2 type

The event type (C<click>, C<change>, C<keyup>, C<submit>, etc.).

=head2 target_id

The ID attribute of the element that fired the event.

=head2 target_name

The name attribute of the element.

=head2 value

The current value (for input/select elements).

=head2 checked

Boolean checked state (for checkboxes).

=head2 key

The key pressed (for keyboard events).

=head2 key_code

The numeric key code (for keyboard events).

=head2 data

	my $val = $event->data($key);

Access custom data passed with the event or data-* attributes.

=head2 get

	my $val = $event->get($key);

Access any arbitrary field from the raw event data by key.

=head1 SEE ALSO

L<Chandra::Element>, L<Chandra::Bind>

=cut
