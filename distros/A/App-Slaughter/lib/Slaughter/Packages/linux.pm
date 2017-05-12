#!/usr/bin/perl -w

=head1 NAME

Slaughter::Packages::linux - Abstractions for GNU/Linux package management.

=cut

=head1 DESCRIPTION

This module contains code for dealing with system packages.

If you wish to support a new packaging system for GNU/Linux based
distributions this should be the only place you need to touch.

=cut

=head1 METHODS

Now follows documentation on the available methods.

=cut


use strict;
use warnings;


package Slaughter::Packages::linux;


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

    bless( $self, $class );
    return $self;

}



=head2 recognised

Does the local system match a known type?

=cut

sub recognised
{
    my ($self) = (@_);

    #
    #  RPM?
    #
    if ( ( -x "/bin/rpm" ) &&
         ( -x "/usr/bin/yum" ) &&
         ( -d "/etc/sysconfig" ) )
    {
        return ("rpm");
    }


    #
    #  APT?
    #
    if ( ( -x "/usr/bin/apt-get" ) &&
         ( -e "/etc/apt/sources.list" ) &&
         ( -d "/etc/network" ) )
    {
        return ("apt-get");
    }

    return 0;
}



=head2 isInstalled

Is the package installed?

=cut

sub isInstalled
{
    my ( $self, $package ) = (@_);

    #
    #  Get the type of the system, to make sure we can continue.
    #
    my $type = $self->recognised();
    return 0 unless ($type);

    #
    #  Is this apt-based?
    #
    if ( $type eq "apt-get" )
    {
        my %installed;

        $ENV{ 'COLUMNS' } = 300;

        open my $handle, "-|", "dpkg --list" or
          die "Failed to run dpkg: $!";

        while (<$handle>)
        {
            if ( $_ =~ /ii([ \t]+)([^\t ]+)[\t ]/ )
            {
                $installed{ $2 } += 1;
            }
        }
        close($handle);

        if ( $installed{ $package } )
        {
            return 1;
        }
    }

    #
    #  Is this RPM based?
    #
    if ( $type eq "rpm" )
    {
        my %installed;

        open my $handle, "-|", "rpm -qa" or
          die "Failed to run rpm: $!";

        while (<$handle>)
        {
            if ( $_ =~ /^(.*?)-([0-9])(.*)$/ )
            {
                $installed{ $1 } += 1;
            }
        }
        close($handle);

        if ( $installed{ $package } )
        {
            return 1;
        }
    }

    return 0;
}



=head2 installPackage

Install a package upon the local system.

=cut

sub installPackage
{
    my ( $self, $package ) = (@_);

    #
    #  Get the type of the system, to make sure we can continue.
    #
    my $type = $self->recognised();
    return 0 unless ($type);

    #
    #  Is this apt-based?
    #
    if ( $type eq "apt-get" )
    {
        $ENV{ 'DEBIAN_FRONTEND' } = "noninteractive";
        my $cmd = "apt-get -q -y install $package";
        system($cmd );
    }

    #
    #  Is this rpm-based?
    #
    if ( $type eq "rpm" )
    {
        my $cmd = "yum install -y $package";
        system($cmd );
    }
}



=head2 removePackage

Remove the specified package.

=cut

sub removePackage
{
    my ( $self, $package ) = (@_);

    #
    #  Get the type of the system, to make sure we can continue.
    #
    my $type = $self->recognised();
    return 0 unless ($type);

    #
    #  Is this apt-based?
    #
    if ( $type eq "apt-get" )
    {
        $ENV{ 'DEBIAN_FRONTEND' } = "noninteractive";
        my $cmd = "apt-get -q -y remove $package";
        system($cmd );
    }

    #
    #  Is this rpm-based?
    #
    if ( $type eq "rpm" )
    {
        my $cmd = "rpm -e $package";
        system($cmd );
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
