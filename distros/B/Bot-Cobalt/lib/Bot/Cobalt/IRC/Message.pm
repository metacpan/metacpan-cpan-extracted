package Bot::Cobalt::IRC::Message;
$Bot::Cobalt::IRC::Message::VERSION = '0.021003';
## Message class. Inherits from Event

use v5.10;
use strictures 2;

use Bot::Cobalt::Common;

use Moo;
extends 'Bot::Cobalt::IRC::Event';

has message => (
  required  => 1,
  is        => 'rw',
  isa       => Str,
  trigger   => sub {
    my ($self, $value) = @_;

    $self->_set_stripped(
      strip_color( strip_formatting($value) )
    ) if $self->has_stripped;

    if ($self->has_message_array) {
      $self->message_array([ split ' ', $self->stripped ]);
    }
  },
);

has targets => (
  required  => 1,
  is        => 'rw',
  isa       => ArrayObj,
  coerce    => 1,
  trigger   => sub {
    my ($self, $value) = @_;
    $self->_set_target($value->[0]) if $self->has_target;
  }
);

has target  => (
  lazy      => 1,
  is        => 'rwp',
  isa       => Str,
  predicate => 'has_target',
  default   => sub { $_[0]->targets->[0] },
);

## May or may not have a channel.
has channel => (
  lazy      => 1,
  is        => 'rw',
  isa       => Str,
  default   => sub {
    $_[0]->target =~ /^[#&+!]/ ? $_[0]->target : ''
  },
);

## Message content.
has stripped => (
  lazy      => 1,
  is        => 'rwp',
  isa       => Str,
  predicate => 'has_stripped',
  default   => sub {
    strip_color( strip_formatting($_[0]->message) )
  },
);

has message_array => (
  lazy      => 1,
  is        => 'rw',
  isa       => ArrayObj,
  coerce    => 1,
  predicate => 'has_message_array',
  default   => sub { [ split ' ', $_[0]->stripped ] },
  trigger   => sub {
    my ($self) = @_;
    if ($self->has_message_array_sp) {
      $self->_set_message_array_sp([ split / /, $self->stripped ]);
    }
  },
);

has message_array_sp => (
  lazy      => 1,
  is        => 'rwp',
  isa       => ArrayObj,
  coerce    => 1,
  predicate => 'has_message_array_sp',
  default   => sub { [ split / /, $_[0]->stripped ] },
);


1;
__END__

=pod

=head1 NAME

Bot::Cobalt::IRC::Message - An incoming IRC message

=head1 SYNOPSIS

  sub Bot_private_msg {
    my ($self, $core) = splice @_, 0, 2;
    my $msg = ${ $_[0] };

    my $context  = $msg->context;
    my $stripped = $msg->stripped;
    my $nickname = $msg->src_nick;
    . . .
  }

=head1 DESCRIPTION

Incoming IRC messages are broadcast to the plugin pipeline via
L<Bot::Cobalt::IRC>; this is the base class providing an easy object
interface to parsed messages.

This is the most frequently used Event subclass; the methods
inherited from L<Bot::Cobalt::IRC::Event> are also documented
here for convenience.

=head1 METHODS

=head2 context

Returns the server context name.

=head2 src

Returns the full source of the message in the form of C<nick!user@host>

=head2 src_nick

The 'nick' portion of the message's L</src>.

=head2 src_user

The 'user' portion of the message's L</src>.

May be undefined if the message was "odd."

=head2 src_host

The 'host' portion of the message's L</src>.

May be undefined if the message was "odd."

=head2 targets

A L<List::Objects::WithUtils::Array> containing any seen destinations for this
message.

=head2 target

The first seen destination, as a string.

Same as C<< $msg->targets->[0] >>

=head2 channel

Undefined if the destination for the message doesn't appear to be a
properly-prefixed channel; otherwise the same value as L</target>.

=head2 message

The unstripped, unparsed message string we were originally given.

=head2 stripped

The color and formatting stripped L</message>.

=head2 message_array

A L<List::Objects::WithUtils::Array> containing the message string split on
white space.

"Extra" spaces are not preserved; see L</message_array_sp>.

B<message_array> can be modified in the case of command-prefixed public
messages; see L<Bot::Cobalt::IRC::Message::Public/cmd>.

=head2 message_array_sp

Similar to L</message_array>, except all spaces are preserved, including
leading spaces.

=head1 SEE ALSO

L<Bot::Cobalt::IRC::Message::Public> -- subclass for public messages

L<Bot::Cobalt::IRC::Event> -- base class for IRC events

L<Bot::Cobalt::Manual::Plugins>

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

L<http://www.cobaltirc.org>

=cut
