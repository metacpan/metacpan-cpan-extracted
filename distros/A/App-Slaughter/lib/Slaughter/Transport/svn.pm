
=head1 NAME

Slaughter::Transport::svn - Subversion transport class.

=head1 SYNOPSIS

This transport copes with cloning a remote Subversion repository to the local filesystem.

=cut

=head1 DESCRIPTION

This module uses the L<Slaughter::Transport::revisionControl> base-class in such
a way as to offer a Subversion-based transport.

All the implementation, except for the setup of some variables, comes from that
base class.

=cut

=head1 IMPLEMENTATION

The following commands are set in the L</_init> method:

=over 8

=item cmd_clone

This is set to "C<svn checkout>".

=item cmd_update

This is set to "C<svn update>".

=item cmd_version

This is set to "C<svn --version>".

=item name

This is set to "C<svn>".

=back

=cut


use strict;
use warnings;



package Slaughter::Transport::svn;

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

Initialiaze this object, by setting up the Subversion-specific commands, etc.

=cut

sub _init
{
    my ($self) = (@_);

    #
    # The name of our derived transport.
    #
    $self->{ 'name' } = "svn";

    #
    # The command to invoke the version of our revision control system.
    #
    # Used to test that it is installed.
    #
    $self->{ 'cmd_version' } = "svn --version";

    #
    # The command to clone our remote repository.
    #
    $self->{ 'cmd_clone' } = "svn checkout";
    $self->{ 'cmd_clone' } .= " $self->{'transportargs'} "
      if ( $self->{ 'transportargs' } );
    $self->{ 'cmd_clone' } .= " #SRC# #DST#";


    #
    #  The command to update our repository - NOT USED
    #
    $self->{ 'cmd_update' } = "svn update";

    #
    #  All done.
    #
    return $self;

}


1;


=head1 AUTHOR

Steve Kemp <steve@steve.org.uk>

stamas http://cstamas.hu/

=cut

=head1 LICENSE

Copyright (c) 2010-2015 by Steve Kemp.  All rights reserved.

This module is free software;
you can redistribute it and/or modify it under
the same terms as Perl itself.
The LICENSE file contains the full text of the license.

=cut
