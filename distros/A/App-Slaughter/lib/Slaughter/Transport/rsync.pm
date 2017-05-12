
=head1 NAME

Slaughter::Transport::rsync - rsync transport class.

=head1 SYNOPSIS

This transport copes with fetching a remote store to the local system, via rsync.

=cut

=head1 DESCRIPTION

This module uses the L<Slaughter::Transport::revisionControl> base-class in such
a way as to offer a rsync-based transport.

All the implementation, except for the setup of some variables, comes from that
base class.

=cut

=head1 IMPLEMENTATION

The following commands are set in the L</_init> method:

=over 8

=item cmd_clone

This is set to "C<rsync -qazr>".

=item cmd_update

This is set to "C<rsync -qazr>" - identical to that used in the clone, as rsync
is always incremental in nature.

=item cmd_version

This is set to "C<rsync --version>".

=item name

This is set to "C<rsync>".

=back

=cut


use strict;
use warnings;



package Slaughter::Transport::rsync;

#
# The version of our release.
#
our $VERSION = "3.0.6";



use parent 'Slaughter::Transport::revisionControl';



=head2 new

Create a new instance of this object.

=cut

sub new
{
    my ( $class, %args ) = @_;
    return $class->SUPER::new(%args);
}


=head2 _init

Initialiaze this object, by setting up the rsync-specific commands, etc.

=cut

sub _init
{
    my ($self) = (@_);

    #
    # The name of our derived transport.
    #
    $self->{ 'name' } = "rsync";

    #
    #  The command to invoke the version of our revision control system.
    # Used to test that it is installed.
    #
    $self->{ 'cmd_version' } = "rsync --version";

    #
    # The command to clone our remote repository.
    #
    $self->{ 'cmd_clone' } = "rsync -qazr --delete";
    $self->{ 'cmd_clone' } .= " $self->{'transportargs'} "
      if ( $self->{ 'transportargs' } );
    $self->{ 'cmd_clone' } .= " #SRC# #DST#";

    #
    #  The command to update our repository - NOT USED
    #
    #  In the case or rsync an update is the same as a clone
    #
    $self->{ 'cmd_update' } = $self->{ 'cmd_clone' };

}


1;


=head1 AUTHOR

Steve Kemp <steve@steve.org.uk>

=cut

=head1 LICENSE

Copyright (c) 2010-2015 by Steve Kemp.  All rights reserved.

This module is free software;
you can redistribute it and/or modify it under
the same terms as Perl itself.
The LICENSE file contains the full text of the license.

=cut
