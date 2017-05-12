package BeamX::Peer::Emitter;

# ABSTRACT: Beam::Emitter with peer-to-peer messaging

use Types::Standard ':all';
use Safe::Isa;

use Moo::Role;
with 'Beam::Emitter';

our $VERSION = '0.003';

sub _find_listener {

    my ( $self, $peer, $name ) = @_;

    return if !defined $peer;

    return ( grep { $_->has_peer && $_->peer == $peer }
          $self->listeners( $name ) )[0];
}

=method subscribe

  # subscribe as Beam::Emitter does
  $emitter->subscribe( $event_name, $subref, [, %args] );

Subscribe to the named event from C<$emitter>.  C<$subref>
will be called when the event is emitted.

By default, the emitter tracks the listener with an object of class
L<BeamX::Peer::Listener>.  C<%args> is used to pass arguments
to its constructor.

To enable C<$emitter> to send the event directly to a C<$peer> via
the L<send> method, specify the peer with the C<peer> key in C<%args>.

  $emitter->subscribe( $event_name, $subref, peer => $peer, %args );

To use a different listener class, subclass B<BeamX::Peer::Emitter>
and pass its name via the C<class> key in C<%args>.

  $emitter->subscribe( $event_name, $subref, class => MyListener, %args );

=cut

around subscribe => sub {

    my $orig = shift;

    splice( @_, 3, 0, class => 'BeamX::Peer::Listener', );

    &$orig;
};

=method send

  $emitter->send( $peer, $event_name [, %args] );

Send the named event to the specified peer.  C<%args> is a list of
name, value pairs to pass to the L<Beam::Event> constructor; use the
C<class> key to specify an alternate event class.

=cut

sub send {

    my ( $self, $peer, $name, %args ) = @_;

    my $listener = $self->_find_listener( $peer, $name )
      or return;

    my $class = delete $args{class} || "Beam::Event";

    $args{emitter} ||= $self;
    $args{name}    ||= $name;

    my $event = $class->new( %args );
    $listener->callback->( $event );
    return $event;
}

=method send_args

  $emitter->send_args( $peer, $event_name, @args] );

Send the named event to the specified peer.  C<@args> will be passed
to the subscribed callback.

=cut

sub send_args {

    my ( $self, $peer, $name, @args ) = @_;

    my $listener = $self->_find_listener( $peer, $name )
      or return;

    $listener->callback->( @args );
    return;
}


1;

# COPYRIGHT

__END__


=head1 SYNOPSIS

# EXAMPLE: examples/synopsis.pl

Results in:

  Broadcast Event object:
  non-peer: received event 'alert' from node N1
  N2: received event 'alert' from node N1

  Send Event object directly to $n2
  N2: received event 'alert' from node N1

  Broadcast arbitrary args
  non-peer: Server's Down!
  N2: Server's Down!

  Send arbitrary args directly to $n2
  N2: Let's get coffee!


=head1 DESCRIPTION

B<BeamX::Peer::Emitter> is a role (based upon L<Beam::Emitter>) which
adds the ability to notify individual subscribers (peers) of
events to L<Beam::Emitter>'s publish/subscribe capabilities.



=head1 SEE ALSO

L<Beam::Emitter>
