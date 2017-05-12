
=head1 NAME

Slaughter::Transport::revisionControl - Transport base-class.

=head1 SYNOPSIS

This is a base-class for a generic revision control based transport.

=cut

=head1 DESCRIPTION

This module implements the primitives which our transport API demands, but
it does so in an abstract fashion with the intention that sub-classes
will provide the missing configuration to allow it to be used.

This module may be used by any revision-control system, or other tool,
that allows a fetch of a remote repository to be carried out by a simple
command such as:

=for example begin

  $cmd repository-location destination-path

=for example end

In our derived Mercurical class we set the command to "C<hg clone>", similarly
in the GIT class we use "C<git clone>".  Finally although it isn't a revision
control system our rsync implementation works via a subclass precisely
because it is possible to fetch a remote tree using a simple command,
in that case it is:

=for example begin

  rsync -qazr repository-location destination-path

=for example end

B<NOTE>:  A full checkout of the remote repository is always inititated by
this module.

It is possible that a future extension to this module will allow an existing
repository to be uploaded in-place.

=cut

=head1 SUBCLASSING

If you wish to write your own transport for a revision control tool,
or similar command that will fetch a remote repository, you must
subclass this class and implement the C<_init> method.

The following parameters should be populated in your derived class:

=over 8

=item C<cmd_clone>

The command to clone the repository.  This will have the repository location, as specified by "C<--prefix>", and the destination directory appended to it.

The command will have with the strings "C<#SRC#>" and "C<#DST#>" replaced with the source of the fetch and the destination into which to fetch it repectively.

The following, taken from C<Slaughter::Transport::hg>, demonstrates this:

=for example begin

    $self->{ 'cmd_clone' } = "hg clone #SRC# #DST#";

=for example end


=item C<cmd_update>

A command to call to update an I<existing> repository.  Currently each time slaughter runs it will pull the remote repository from scratch to a brand new temporary directory, it is possible in the future we will work with a local directory that persists - at that point having the ability to both checkout and update a remote repository will be useful.

=item C<cmd_version>

A command to call which will output the version of the revision control system.   This may be any command which outputs text, as the output is discarded.  The purposes is to ensure that the binary required for cloning is present on the system.

=item C<name>

The name of the transport.

=back

For a sample implementation please consult C<Slaughter::Transport::hg>.

=cut


=head1 METHODS

Now follows documentation on the available methods.

=cut


use strict;
use warnings;



package Slaughter::Transport::revisionControl;

#
# The version of our release.
#
our $VERSION = "3.0.6";




=head2 new

Create a new instance of this object.

This constructor calls the "C<_init>" method of any derived class, if present,
which is where we'll expect the setup mentioned in L</SUBCLASSING> to take place.

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

    #
    #  This will get replaced by sub-classes.
    #
    $self->{ 'name' } = "revisionControl";

    bless( $self, $class );

    #
    #  We expect a derived class will implement an "_init" method,
    # which will populate the variables we expect.
    #
    #  We don't call this method unconditionally for the simple reason
    # that we wish this class to be constructable by our test suite.
    #
    if ( UNIVERSAL::can( $self, '_init' ) )
    {
        $self->_init();
        $self->{ 'setup' } = 1;
    }

    return $self;

}


=head2 isAvailable

Is this module available?  This uses the details from the derived class
to determine whether I<that> transport is available.

We regard the transport as available if the execution of the command
stored in L</cmd_version> succeeds.

=cut

sub isAvailable
{
    my ($self) = (@_);

    $self->{ 'error' } = "";

    #
    #  If the _init method didn't get called we've not been subclassed,
    # and that means we don't have the commands we should run setup.
    #
    if ( !$self->{ 'setup' } )
    {
        $self->{ 'error' } =
          "This is a base-class, and should not be used directly\n";
        return 0;
    }

    if ( !-d $self->{ 'transportdir' } )
    {
        $self->{ 'error' } =
          "Transport directory went away: $self->{'transportdir'}\n";
        return 0;
    }

    if ( system("$self->{'cmd_version'} >/dev/null 2>/dev/null") != 0 )
    {
        $self->{ 'error' } =
          "Failed to execute '$self->{'cmd_version'}', is $self->{'name'} installed?\n";
        return 0;
    }

    return 1;
}



=head2 error

Return the last error from the transport, this is set in L</isAvailable>.

=cut

sub error
{
    my ($self) = (@_);
    return ( $self->{ 'error' } );
}



=head2 name

Return the name of this transport.  This will be setup in the derived class,
via the L</name> parameter.

=cut

sub name
{
    my ($self) = (@_);
    return ( $self->{ 'name' } );
}



=begin doc

Clone the repository.

This is called only once, when the object is constructed.  It will be
called by slaughter, for example, to clone the repository prior to
processing policies.

=end doc

=cut

sub setup
{
    my ($self) = (@_);

    #
    #  The repository, and the destination to which we clone it.
    #
    my $repo = $self->{ 'prefix' };
    my $dst  = $self->{ 'transportdir' };

    $self->{ 'verbose' } && print "Fetching $repo into $dst\n";

    #
    #  Convert "#SRC#" and "#DST#" into the appropriate args from our
    # cloning command, and then execute it.
    #
    my $cmd = $self->{ 'cmd_clone' };
    $cmd =~ s/#SRC#/$repo/g;
    $cmd =~ s/#DST#/$dst/g;

    #
    #  Hide output unless we're being verbose.
    #
    $cmd .= " >/dev/null 2>/dev/null" unless ( $self->{ 'verbose' } );

    if ( system("$cmd") != 0 )
    {
        $self->{ 'verbose' } &&
          print "WARNING: Failed to clone repository, command failed: $cmd";
    }
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



=head2 fetchContents

Fetch a file from within the checked-out repository.

Given a root repository of /path/to/repo/ the file is looked for beneath
/path/to/repo/files.

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
    my $complete = $self->{ 'transportdir' } . $prefix . $file;

    #
    #  Read the file.
    #
    return ( $self->_readFile($complete) );
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
