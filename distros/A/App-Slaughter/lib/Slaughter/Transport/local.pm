
=head1 NAME

Slaughter::Transport::local - Local filesystem transport class.

=head1 SYNOPSIS

This transport copes with fetching files and policies from the local filesystem.
It is designed to allow you to test policies on a single host.

=cut

=head1 DESCRIPTION

This transport is slightly different from the others supplied with slaughter
as it involves fetching files from the I<local> filesystem - so there is no
remote server involved at all.

=cut


use strict;
use warnings;



package Slaughter::Transport::local;


#
# The version of our release.
#
our $VERSION = "3.0.6";



=head2 new

Create a new instance of this object.

=cut

sub new
{
    my ( $proto, %supplied ) = (@_);
    my $class = ref($proto) || $proto;

    my $self = {};

    #
    #  Allow user supplied values to override our defaults
    #
    foreach my $key ( keys %supplied )
    {
        $self->{ lc $key } = $supplied{ $key };
    }

    #
    # Explicitly ensure we have no error.
    #
    $self->{ 'error' } = undef;

    bless( $self, $class );
    return $self;

}



=head2 name

Return the name of this transport.

=cut

sub name
{
    return ("local");
}



=head2 isAvailable

Return whether this transport is available.

This module is pure-perl, so we unconditionally return 1.

=cut

sub isAvailable
{
    my ($self) = (@_);

    return 1;
}



=head2 error

Return the last error from the transport.

This is only set in L</isAvailable>.

=cut

sub error
{
    my ($self) = (@_);
    return ( $self->{ 'error' } );
}



=head2 fetchContents

Fetch the contents of the specified file, relative to the specified prefix.

=cut

sub fetchContents
{
    my ( $self, %args ) = (@_);

    #
    #  The prefix to fetch from:  /files/, /modules/, or /policies/.
    #
    my $prefix = $args{ 'prefix' };

    #
    #  The file to retrieve.
    #
    my $file = $args{ 'file' };

    #
    #  The complete path.
    #
    my $complete = $self->{ 'prefix' } . $prefix . $file;

    #
    #  Read the file.
    #
    return ( $self->_readFile($complete) );
}


=begin doc

This is an internal/private method that merely returns the contents of the
named file - or undef on error.

=end doc

=cut

sub _readFile
{
    my ( $self, $file ) = (@_);

    my $txt = undef;

    open( my $handle, "<", $file ) or return ($txt);

    while ( my $line = <$handle> )
    {
        $txt .= $line;
    }
    close($handle);

    return $txt;
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
