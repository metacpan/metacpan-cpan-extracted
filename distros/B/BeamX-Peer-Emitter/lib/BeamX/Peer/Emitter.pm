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

#pod =method subscribe
#pod
#pod   # subscribe as Beam::Emitter does
#pod   $emitter->subscribe( $event_name, $subref, [, %args] );
#pod
#pod Subscribe to the named event from C<$emitter>.  C<$subref>
#pod will be called when the event is emitted.
#pod
#pod By default, the emitter tracks the listener with an object of class
#pod L<BeamX::Peer::Listener>.  C<%args> is used to pass arguments
#pod to its constructor.
#pod
#pod To enable C<$emitter> to send the event directly to a C<$peer> via
#pod the L<send> method, specify the peer with the C<peer> key in C<%args>.
#pod
#pod   $emitter->subscribe( $event_name, $subref, peer => $peer, %args );
#pod
#pod To use a different listener class, subclass B<BeamX::Peer::Emitter>
#pod and pass its name via the C<class> key in C<%args>.
#pod
#pod   $emitter->subscribe( $event_name, $subref, class => MyListener, %args );
#pod
#pod =cut

around subscribe => sub {

    my $orig = shift;

    splice( @_, 3, 0, class => 'BeamX::Peer::Listener', );

    &$orig;
};

#pod =method send
#pod
#pod   $emitter->send( $peer, $event_name [, %args] );
#pod
#pod Send the named event to the specified peer.  C<%args> is a list of
#pod name, value pairs to pass to the L<Beam::Event> constructor; use the
#pod C<class> key to specify an alternate event class.
#pod
#pod =cut

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

#pod =method send_args
#pod
#pod   $emitter->send_args( $peer, $event_name, @args] );
#pod
#pod Send the named event to the specified peer.  C<@args> will be passed
#pod to the subscribed callback.
#pod
#pod =cut

sub send_args {

    my ( $self, $peer, $name, @args ) = @_;

    my $listener = $self->_find_listener( $peer, $name )
      or return;

    $listener->callback->( @args );
    return;
}


1;

#
# This file is part of BeamX-Peer-Emitter
#
# This software is Copyright (c) 2016 by the Smithsonian Astrophysical Observatory.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#

=pod

=encoding UTF-8

=head1 NAME

BeamX::Peer::Emitter - Beam::Emitter with peer-to-peer messaging

=head1 VERSION

version 0.003

=head1 SYNOPSIS

 use 5.10.0;
 use Safe::Isa;
 
 sub fmt_msg {
     $_[0]->$_isa( 'Beam::Event' )
       ? sprintf( "received event '%s' from node %s", $_[0]->name, $_[0]->emitter->id )
       : join( ' ', @_ );
 }
 
 
 package Node {
 
     use Safe::Isa;
     use Moo;
     with 'BeamX::Peer::Emitter';
 
     has id => (
         is       => 'ro',
         required => 1,
     );
 
     sub recv {
 
         my $self = shift;
 
         say $self->id, ': ', &::fmt_msg;
     }
 
 }
 
 my $n1 = Node->new( id => 'N1' );
 my $n2 = Node->new( id => 'N2' );
 
 
 # standard Beam::Emitter event
 $n1->subscribe( 'alert', sub { say 'non-peer: ', &fmt_msg  } );
 
 # explicit peer event
 $n1->subscribe( 'alert', sub { $n2->recv( @_ ) }, peer => $n2 );
 
 say "Broadcast Event object:";
 $n1->emit( 'alert' );
 
 say "\nSend Event object directly to \$n2";
 $n1->send( $n2, 'alert' );
 
 say "\nBroadcast arbitrary args";
 $n1->emit_args( 'alert', q[Server's Down!] );
 
 say "\nSend arbitrary args directly to \$n2";
 $n1->send_args( $n2, 'alert', q[Let's get coffee!] );

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

=head1 METHODS

=head2 subscribe

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

=head2 send

  $emitter->send( $peer, $event_name [, %args] );

Send the named event to the specified peer.  C<%args> is a list of
name, value pairs to pass to the L<Beam::Event> constructor; use the
C<class> key to specify an alternate event class.

=head2 send_args

  $emitter->send_args( $peer, $event_name, @args] );

Send the named event to the specified peer.  C<@args> will be passed
to the subscribed callback.

=head1 SEE ALSO

L<Beam::Emitter>

=head1 AUTHOR

Diab Jerius <djerius@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by the Smithsonian Astrophysical Observatory.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut

__END__


#pod =head1 SYNOPSIS
#pod
#pod # EXAMPLE: examples/synopsis.pl
#pod
#pod Results in:
#pod
#pod   Broadcast Event object:
#pod   non-peer: received event 'alert' from node N1
#pod   N2: received event 'alert' from node N1
#pod
#pod   Send Event object directly to $n2
#pod   N2: received event 'alert' from node N1
#pod
#pod   Broadcast arbitrary args
#pod   non-peer: Server's Down!
#pod   N2: Server's Down!
#pod
#pod   Send arbitrary args directly to $n2
#pod   N2: Let's get coffee!
#pod
#pod
#pod =head1 DESCRIPTION
#pod
#pod B<BeamX::Peer::Emitter> is a role (based upon L<Beam::Emitter>) which
#pod adds the ability to notify individual subscribers (peers) of
#pod events to L<Beam::Emitter>'s publish/subscribe capabilities.
#pod
#pod
#pod
#pod =head1 SEE ALSO
#pod
#pod L<Beam::Emitter>
