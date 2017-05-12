package BeamX::Peer::Listener;

use Types::Standard ':all';
use Moo;

our $VERSION = '0.003';

extends 'Beam::Listener';

#pod =attr peer
#pod
#pod An optional reference to a peer object, allowing the emitter to
#pod send it an event directly using L<BeamX::Emitter::send>.  The 
#pod object must consume the B<BeamX::Emitter> role.
#pod
#pod =cut

#pod =method has_peer
#pod
#pod   $bool = $self->has_peer();
#pod
#pod This returns true if the object's peer attribute has been set
#pod
#pod =cut

has peer => (
    is       => 'ro',
    weak_ref => 1,
    isa      => ConsumerOf ['BeamX::Peer::Emitter'],
    predicate => 1
);

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

BeamX::Peer::Listener

=head1 VERSION

version 0.003

=head1 SYNOPSIS

  # optional peer
  %args = ( peer => $peer );
  $emitter->subscribe( $event_name, $subref, %args );

=head1 DESCRIPTION

This is the default Listener object created by the
L<BeamX::Emitter::subscribe> method when a callback subscription is
registered.  It sub-classes L<Beam::Listener>.

=head1 ATTRIBUTES

=head2 peer

An optional reference to a peer object, allowing the emitter to
send it an event directly using L<BeamX::Emitter::send>.  The 
object must consume the B<BeamX::Emitter> role.

=head1 METHODS

=head2 has_peer

  $bool = $self->has_peer();

This returns true if the object's peer attribute has been set

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
#pod   # optional peer
#pod   %args = ( peer => $peer );
#pod   $emitter->subscribe( $event_name, $subref, %args );
#pod
#pod
#pod =head1 DESCRIPTION
#pod
#pod This is the default Listener object created by the
#pod L<BeamX::Emitter::subscribe> method when a callback subscription is
#pod registered.  It sub-classes L<Beam::Listener>.
