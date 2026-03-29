package Chandra::Event;

use strict;
use warnings;

our $VERSION = '0.02';

# Event object passed to event handlers
# Contains data from the JavaScript event

sub new {
    my ($class, $data) = @_;
    $data //= {};
    return bless $data, $class;
}

# Event type (click, change, keyup, etc.)
sub type { shift->{type} }

# Target element ID
sub target_id { shift->{targetId} }

# Target element name attribute
sub target_name { shift->{targetName} }

# Value (for inputs)
sub value { shift->{value} }

# Checked state (for checkboxes)
sub checked { shift->{checked} }

# Key pressed (for keyboard events)
sub key { shift->{key} }

# Key code (for keyboard events)
sub key_code { shift->{keyCode} }

# Custom data (from data-* attributes or explicit)
sub data {
    my ($self, $key) = @_;
    if (defined $key) {
        return $self->{data}{$key} if ref $self->{data} eq 'HASH';
        return undef;
    }
    return $self->{data};
}

# Get any arbitrary field
sub get {
    my ($self, $key) = @_;
    return $self->{$key};
}

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

=head1 METHODS

=head2 type

The event type (click, change, keyup, submit, etc.)

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

=head2 data($key)

Access custom data passed with the event or data-* attributes.

=cut
