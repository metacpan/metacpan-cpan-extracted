#!/usr/bin/perl -w

=head1 NAME

Slaughter::API::MSWin32 - Perl Automation Tool Helper Windows implementation

=cut

=head1 SYNOPSIS

This module is the one that gets loaded upon Windows systems, after the generic
API implementation.  This module implements the Win32-specific primitives.

We also attempt to load C<Slaughter::API::Local::MSWin32>, where site-specific primitives
may be implemented.  If the loading of this additional module fails we report no error/warning.

=cut

=head1 METHODS

Now follows documentation on the available methods.

=cut


use strict;
use warnings;


package Slaughter::API::MSWin32;


our $VERSION = "3.0.6";


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



=head2 Alert

This method is a stub which does nothing but output a line of text to
inform the caller that the method is not implemented.

For an implementation, and documentation, please consult L<Slaughter::API::linux>.

=cut

sub Alert
{
    print "Alert - not implemented for $^O\n";

    #
    #  TODO: Attempt to send email using "The Bat!" or similar
    # cmd-line SMTP client for windows.
    #
}



=head2 FindBinary

This method allows you to search for an executable upon your
system $PATH, or a supplied alternative string.

=for example begin

  if ( FindBinary( Binary => "ls" ) )
  {
      # we have ls!
  }

=for example end

The following parameters are available:

=over 8

=item Binary [mandatory]

The name of the binary file to find.

=item Path [default: $ENV{'PATH'}]

This is assumed to be a semi-colon deliminated list of directories to search
for the binary within.

=back

If the binary is found the full path will be returned, otherwise undef.

=cut

sub FindBinary
{
    my (%params) = (@_);

    my $binary = $params{ 'Binary' } || $params{ 'binary' } || return;
    my $path = $params{ 'Path' } ||
      $params{ 'path' } ||
      $ENV{ 'PATH' };
    my $result = undef;

    foreach my $dir ( split( /;/, $path ) )
    {
        if ( ( -d $dir ) && ( -x ( $dir . "\\" . $binary ) ) )
        {
            return $dir . "\\" . $binary;
        }
        if ( ( -d $dir ) && ( -x ( $dir . "\\" . $binary . ".exe" ) ) )
        {
            return $dir . "\\" . $binary . ".exe";
        }
        if ( ( -d $dir ) && ( -x ( $dir . "\\" . $binary . ".bat" ) ) )
        {
            return $dir . "\\" . $binary . ".bat";
        }
        if ( ( -d $dir ) && ( -x ( $dir . "\\" . $binary . ".cmd" ) ) )
        {
            return $dir . "\\" . $binary . ".cmd";
        }
    }

    return $result;
}




=head2 InstallPackage

This method is a stub which does nothing but output a line of text to
inform the caller that the method is not implemented.

For an implementation, and documentation, please consult L<Slaughter::API::linux>.

=cut

sub InstallPackage
{
    print "InstallPackage - not implemented for $^O\n";
}



=head2 Mounts

This method is a stub which does nothing but output a line of text to
inform the caller that the method is not implemented.

For an implementation, and documentation, please consult L<Slaughter::API::linux>.

=cut

sub Mounts
{
    print "Mounts - not implemented for $^O\n";
}



=head2 PackageInstalled

This method is a stub which does nothing but output a line of text to
inform the caller that the method is not implemented.

For an implementation, and documentation, please consult L<Slaughter::API::linux>.

=cut

sub PackageInstalled
{
    print "PackageInstalled - not implemented for $^O\n";
}




=head2 PercentageUsed

This method is a stub which does nothing but output a line of text to
inform the caller that the method is not implemented.

For an implementation, and documentation, please consult L<Slaughter::API::linux>.

=cut

sub PercentageUsed
{
    print "PercentageUsed - not implemented for $^O\n";
}



=head2 RemovePackage

This method is a stub which does nothing but output a line of text to
inform the caller that the method is not implemented.

For an implementation, and documentation, please consult L<Slaughter::API::linux>.

=cut

sub RemovePackage
{
    print "RemovePackage - not implemented for $^O\n";
}


=head2 UserExists

This method is a stub which does nothing but output a line of text to
inform the caller that the method is not implemented.

For an implementation, and documentation, please consult L<Slaughter::API::linux>.

=cut

sub UserExists
{
    print "UserExists - not implemented for $^O\n";
}


=head2 UserDetails

This method is a stub which does nothing but output a line of text to
inform the caller that the method is not implemented.

For an implementation, and documentation, please consult L<Slaughter::API::linux>.

=cut

sub UserDetails
{
    print "UserDetails - not implemented for $^O\n";
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
