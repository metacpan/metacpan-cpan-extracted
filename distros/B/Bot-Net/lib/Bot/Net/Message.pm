use strict;
use warnings;

package Bot::Net::Message;
use base qw/ Class::Accessor::Fast /;

use Carp;
use English;
use Scalar::Util qw/ blessed reftype /;

__PACKAGE__->mk_accessors( 
    qw/
        sender_nick sender_host
        _recipient_nicks _recipient_groups
        _message
        public
    /
);

=head1 NAME

Bot::Net::Message - encapsulate messages to and from bots

=head1 SYNOPSIS

  my $message = Bot::Net::Message->new({
      sender_nick     => $from_nick,
      sender_host     => $from_host,
      recipient_nicks => $to_nick,
      message         => $message,
      public          => 0,
  });

=head1 DESCRIPTION

Just a simple class for encapsulating bot messages.

=head1 METHODS

=head2 new HASHREF

Create a new message. The C<HASHREF> keys can be the name of any of the accessor methods described for this class. The values are the values to assign to each key.

=cut

sub new {
    my $class = shift;
    my $args  = shift;

    my $self = bless {}, $class;

    for my $key (keys %$args) {
        if (my $method = $self->can($key)) {
            $method->($self, $args->{$key});
        }
        else {
            croak "Unknown accessor $key used in creating a message.";
        }
    }

    return $self;
}

=head2 sender_nick [ NICK ]

This accessor contains the nick of the message's sender. Pass an argument to change the value.

=head2 sender_host [ HOST ]

This accessor contains the host of the message's sender. Pass an argument to change the value.

=head2 recipient_nicks [ NICKS ]

This accessor returns a reference to an array of nicks that recieved the message. This is generally only set of L</private> returns a true value. You may pass a nick or array of nicks to set this value.

=cut

sub recipient_nicks {
    my $self = shift;

    if (@_) {
        my $reftype = reftype $_[0];
        if (defined $reftype and $reftype eq 'ARRAY' and not blessed $_[0]) {
            $self->_recipient_nicks([ @{ $_[0] } ]);
        }

        else {
            $self->_recipient_nicks([ @_ ]);
        }
    }

    return $self->_recipient_nicks;
}

=head2 recipient_groups [ GROUPS ]

This returns the groups that recieved a public message. This should be set only when L</public> returns true. You may pass a group or an array of groups to set here.

=cut

sub recipient_groups {
    my $self = shift;

    if (@_) {
        my $reftype = reftype $_[0];
        if (defined $reftype and $reftype eq 'ARRAY' and not blessed $_[0]) {
            $self->_recipient_groups([ @{ $_[0] } ]);
        }

        else {
            $self->_recipient_groups([ @_ ]);
        }
    }

    return $self->_recipient_groups;
}

=head2 message [ MESSAGE ]

This accessor returns the message that was sent. Pass a parameter or array of parameters to alter the message. If an array is passed, the elements of the array will be joined using C<$,> (i.e., C<$OUTPUT_FIELD_SEPARATOR> for those who use L<English>).

=cut

sub message {
    my $self = shift;

    if (@_) {
        $self->_message( join $OUTPUT_FIELD_SEPARATOR||'', @_ );
    }

    return $self->_message;
}

=head2 public [ BOOL ]

Returns true if the message sent was sent to a chat group rather than directly to a set of nicks. Pass a true or false value in to alter the value. If this is set to true, then L</private> will be set to false and vice versa.

=head2 private [ BOOL ]

Returns true if the message was sent to a specific set of nicks rather than to a chat group. Pass a true or false value to alter the value. The opposite value will be returned by L</public>.

=cut

sub private {
    my $self = shift;

    if (@_) {
        $self->public( !$_[0] );
    }

    return !$self->public;
}

=head1 AUTHORS

Andrew Sterling Hanenkamp C<< <hanenkamp@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 Boomer Consulting, Inc. All Rights Reserved.

This program is free software and may be modified and distributed under the same terms as Perl itself.

=cut

1;
