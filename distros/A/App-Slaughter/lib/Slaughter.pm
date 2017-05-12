#!/usr/bin/perl -w

=head1 NAME

Slaughter - Perl Automation Tool Helper

=cut

=head1 SYNOPSIS

This module is the platform-independant library which is used to abstract
the implementations of the Slaughter primitives.

It is loaded via:

=for example begin

   use Slaughter;

=for example end

This usage actually dynamically loads the appropriate module from beneath the
Slaughter::API namespace - which will contain the primitive implementation.

Initially we load the L<Slaughter::API::generic> module which contains pure-perl
implemenation, and then we load the OS-specific module from the supported set:

=over 8

=item L<Slaughter::API::linux>

The implemetnation of our primitive API for GNU/Linux.

=item L<Slaughter::API::freebsd>

The implemetnation of our primitive API for FreeBSD.

=back

Assuming that the OS-specific module is successfully loaded we we will also
load any I<local> OS-specific module.  (e.g. C<Slaughter::API::Local::linux>.)

Fallback implementations in our generic module merely output a suitable
error message:

=for example begin

  This module is not implemented for $^O

=for example end

This allows compiled policies to execute, without throwing errors, and also
report upon the primitives which need to be implemented or adapted.

=cut

=head1 EXTENSIONS

At the same time as loading the appropriate module from beneath the
C<Slaughter::API> name-space this module will attempt to load an identically
named module from beneath the Slaughter::API::Local namespace.

This allows you to keep develop your own custom-primitives.

=cut


=head1 METHODS

Now follows documentation on the available methods.

=cut


use strict;
use warnings;


#
# The version of our release.
#
our $VERSION = "3.0.6";

BEGIN
{

    #
    #  The generic module which is always available.
    #
    my $generic = "use Slaughter::API::generic";

    #
    #  Replacement implementations which are OS-specific.
    #
    my $specific = "use Slaughter::API::$^O;";

    ## no critic (Eval)
    eval($generic);
    ## use critic

    ## no critic (Eval)
    eval($specific);
    ## use critic

    #
    # If there were no errors in loading the OS-specific module we'll continue
    # and look for a local extension module too:
    #
    if ( !$@ )
    {
        my $ext = "use Slaughter::API::Local::$^O;";

        ## no critic (Eval)
        eval($ext);
        ## use critic

        #
        #  We don't care if the local-module fails to load because we expect
        # it to be missing in the general case.
        #
    }
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
