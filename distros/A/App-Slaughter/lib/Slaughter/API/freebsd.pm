#!/usr/bin/perl -w

=head1 NAME

Slaughter::API::freebsd - Perl Automation Tool Helper FreeBSD implementation

=cut

=head1 SYNOPSIS

This module is the one that gets loaded upon FreeBSD systems, after the generic
API implementation.  It implements the platform-specific parts of our primitives.

We also attempt to load C<Slaughter::API::Local::freebsd>, where site-specific primitives
may be implemented.  If the loading of this additional module fails we report no error/warning.

=cut


=head1 METHODS

Now follows documentation on the available methods.

=cut


use strict;
use warnings;


package Slaughter::API::freebsd;


our $VERSION = "3.0.6";



#
#  Package abstraction helpers.
#
use Slaughter::Packages::freebsd;


=head2 import

Export all subs in this package into the main namespace.

=cut

sub import
{
    ## no critic
    no strict 'refs';
    ## use critic

    my $caller = caller;

    while ( my ( $name, $symbol ) = each %{ __PACKAGE__ . '::' } )
    {
        next if $name eq 'BEGIN';     # don't export BEGIN blocks
        next if $name eq 'import';    # don't export this sub
        next unless *{ $symbol }{ CODE };    # export subs only

        my $imported = $caller . '::' . $name;
        *{ $imported } = \*{ $symbol };
    }
}




=head2 InstallPackage

The InstallPackage primitive will allow you to install a system package.

This method uses L<Slaughter::Packages::freebsd>.

=for example begin

   foreach my $package ( qw! bash tcsh ! )
   {
       if ( PackageInstalled( Package => $package ) )
       {
           print "$package installed\n";
       }
       else
       {
           InstallPackage( Package => $package );
       }
   }

=for example end

The following parameters are available:

=over

=item Package [mandatory]

The name of the package to install.

=back

=cut

sub InstallPackage
{
    my (%params) = (@_);

    my $package = $params{ 'Package' } || return;

    #
    #  Gain access to the package helper.
    #
    my $helper = Slaughter::Packages::freebsd->new();

    #
    #  If we recognise the system, install the package
    #
    if ( $helper->recognised() )
    {
        $helper->installPackage( $params{ 'Package' } );
    }
    else
    {
        print "Unknown package-type.  Packaging support not present.\n";
    }
}




=head2 PackageInstalled

Test whether a given system package is installed.

This method uses L<Slaughter::Packages::freebsd>.

=for example begin

  if ( PackageInstalled( Package => "bash" ) )
  {
      print "bash installed\n";
  }

=for example end

The following parameters are supported:

=over 8

=item Package

The name of the package to test.

=back

The return value will be a 0 if not installed, or 1 if it is.

=cut

sub PackageInstalled
{
    my (%params) = (@_);

    my $package = $params{ 'Package' } || return;

    #
    #  Gain access to the package helper.
    #
    my $helper = Slaughter::Packages::freebsd->new();

    #
    #  If we recognise the system, test the package installation state.
    #
    if ( $helper->recognised() )
    {
        $helper->isInstalled($package);
    }
    else
    {
        print "Unknown package-type.  Packaging support not present.\n";
    }
}




=head2 RemovePackage

Remove the specified system package from the system.

This method uses L<Slaughter::Packages::freebsd>.

=for example begin

  if ( PackageInstalled( Package => 'telnetd' ) )
  {
      RemovePackage( Package => 'telnetd' );
  }

=for example end

The following parameters are supported:

=over 8

=item Package

The name of the package to remove.

=back

=cut

sub RemovePackage
{
    my (%params) = (@_);

    my $package = $params{ 'Package' } || return;

    #
    #  Gain access to the package helper.
    #
    my $helper = Slaughter::Packages::freebsd->new();

    #
    #  If we recognise the system, remove the package
    #
    if ( $helper->recognised() )
    {
        $helper->removePackage( $params{ 'Package' } );
    }
    else
    {
        print "Unknown package-type.  Packaging support not present.\n";
    }
}



=head2 UserCreate

Create a new user for the system.

=for example begin

  # TODO

=for example end

The following parameters are required:

=over 8

=item Login

The username to create.

=item UID

The UID for the user.

=item GID

The primary GID for the user.

=back

You may optionally specify the GCos field to use.

=cut

sub UserCreate
{
    my (%params) = (@_);

    #
    #  Ensure we have the variables we need.
    #
    foreach my $variable (qw! Login UID GID !)
    {
        if ( !defined( $params{ $variable } ) )
        {

            #
            #  Return undef..
            #
            return ( $params{ $variable } );
        }
    }

    #
    #  If the GCos field isn't set then define it.
    #
    $params{ 'Gcos' } = $params{ 'Login' } if ( !$params{ 'Gcos' } );

    # name:uid:gid:class:change:expire:gecos:home_dir:shell:password

    my $line =
      "$params{ 'Login' }:$params{ 'UID' }:::::$params{ 'Gcos' }::/bin/sh:";
    my $cmd = "echo $line | adduser -G wheel -q -w random -f -";
    RunCommand( Cmd => $cmd );
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
