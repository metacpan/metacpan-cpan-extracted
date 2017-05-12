#!/usr/bin/perl -w

=head1 NAME

Slaughter::Private - Perl Automation Tool Helper Internal Details

=cut

=head1 SYNOPSIS

This module implements the non-public API of the Slaughter administration tool.

Users are not expected to use, touch, browse, or modify the code in this module!

=cut


=head1 METHODS

Now follows documentation on the available methods.

=cut

use strict;
use warnings;

package Slaughter::Private;


#
# The version of our release.
#
our $VERSION = "3.0.6";


=head2 fetchFromTransport

This primitive will retrieve a file from the central server, using
the specified transport.

The various transports are pluggable and live beneath the Slaughter::Transport
namespace.

=for example begin

  fetchFromTransport( "/etc/motd" );

=for example end

A single parameter is accepted which is the name of the file
to fetch, relative to the transport's root.

On success the file's contents are returned.  On failure undef
is returned.

=cut

sub fetchFromTransport
{
    my ($url) = (@_);

    $::template{ 'verbose' } && print "\tfetchFromTransport( $url ) \n";

    my $content = undef;


    #
    #  Make requests for:
    #
    #  url.$fqdn
    #  url.$hostname
    #  url.$role
    #  url.$os
    #  url.$arch
    #  url
    #
    #  Return the first one that matches, if any do.
    #
    my @urls;

    push( @urls, $url . "." . $::fqdn );
    push( @urls, $url . "." . $::hostname );
    push( @urls, $url . "." . $::role )
      if ( defined($::role) && length($::role) );
    push( @urls, $url . "." . $::os );
    push( @urls, $url . "." . $::arch );
    push( @urls, $url );


    foreach my $attempt (@urls)
    {
        $content =
          $::TRANSPORT->fetchContents( prefix => "/files/",
                                       file   => $attempt );

        if ( defined($content) )
        {
            $::template{ 'verbose' } && print "\t$attempt OK\n";
            return ($content);
        }
        else
        {
            $::template{ 'verbose' } &&
              print "\t$attempt failed - continuing\n";
        }
    }

    #
    #  Failed
    #
    $::template{ 'verbose' } &&
      print "\tFailed to fetch any of our attempts for $url\n";
    return $content;
}




=head2 checksumFile

This primitive will attempt to calculate and return the SHA digest of
the specified file.

The method attempts to use both L<Digest::SHA> & L<Digest::SHA1>,
returning the result from the first one which is present.

=for example begin

  checksumFile( "/etc/motd" );

=for example end

A single parameter is accepted which is the name of the file
to hash.

On success the hash is returned, on failure undef is returned.

=cut

sub checksumFile
{
    my ($file) = (@_);

    my $hash = undef;

    foreach my $module (qw! Digest::SHA Digest::SHA1 !)
    {

        # If we succeeded in calculating the hash we're done.
        next if ( defined($hash) );

        # Attempt to load the module
        my $eval = "use $module;";

        ## no critic (Eval)
        eval($eval);
        ## use critic

        #
        #  Loaded module, with no errors.
        #
        if ( !$@ )
        {
            my $object = $module->new;

            open my $handle, "<", $file or
              die "Failed to read $file to hash contents with $module - $!";
            $object->addfile($handle);
            close($handle);

            $hash = $object->hexdigest();
        }
    }

    unless ( defined $hash )
    {
        die "Failed to calculate hash of $file - internal error.";
    }

    return ($hash);
}


1;



=head1 LICENSE

Copyright (c) 2010-2015 by Steve Kemp.  All rights reserved.

This module is free software;
you can redistribute it and/or modify it under
the same terms as Perl itself.
The LICENSE file contains the full text of the license.

=cut

=head1 AUTHOR

Steve Kemp <steve@steve.org.uk>

=cut
