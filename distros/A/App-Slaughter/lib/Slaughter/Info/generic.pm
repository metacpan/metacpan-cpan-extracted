#!/usr/bin/perl -w

=head1 NAME

Slaughter::Info::generic - Determine information about a generic host.

=cut

=head1 SYNOPSIS

This module is the generic version of the Slaughter information-gathering
module.

Modules beneath the C<Slaughter::Info> namespace are loaded when slaughter
is executed, they are used to populate a hash with information about
the current host.

This module is loaded when no specific module matches the local system,
and is essentially a no-operation module.  A real info-module is loaded
by consulting with the value of C<$^O>, so for example we might load
C<Slaughter::Info::linux>.

The information discovered can be dumped by running C<slaughter>

=for example begin

      ~# slaughter --dump

=for example end

Usage of this module is as follows:

=for example begin

     use Slaughter::Info::generic;

     my $obj  = Slaughter::Info::generic->new();
     my $data = $obj->getInformation();

=for example end

B<NOTE>: The data retrieved by this generic module is almost empty.

The only user-callable method is the C<getInformation> method which
is designed to return a hash of data about the current system.

=cut


=head1 METHODS

Now follows documentation on the available methods.

=cut


use strict;
use warnings;


package Slaughter::Info::generic;

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
    bless( $self, $class );
    return $self;

}


=head2 getInformation

This function retrieves meta-information about the current host,
and is the fall-back module which is used if a system-specific
information module cannot be loaded.

The return value is a hash-reference of data determined dynamically.

Currently the following OS-specific modules exist:

=over 8

=item C<Slaughter::Info::linux>

=item C<Slaughter::Info::MSWin32>

=back

=cut

sub getInformation
{
    my ($self) = (@_);

    #
    #  The data we will return.
    #
    my $ref;

    #
    # We're unknown..?
    #
    $ref->{ 'unknown' } = "all";

    #
    # This should be portable.
    #
    $ref->{ 'path' } = $ENV{ 'PATH' };

    # return the data.
    return ($ref);
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
