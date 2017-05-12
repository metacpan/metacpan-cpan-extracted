#!/usr/bin/perl -w

=head1 NAME

Slaughter::Info::MSWin32 - Determine information about a Windows host.

=cut

=head1 SYNOPSIS

This module is the Windows version of the Slaughter information-gathering
module.

Modules beneath the C<Slaughter::Info> namespace are loaded when slaughter
is executed, they are used to populate a hash with information about
the current host.

This module is loaded only on Windows systems, and will determine such details
as the operating system version, the processor type, etc.

The correct information-gathering module is loaded at run-time via the use of the C<$^O> variable, and if no system-specific module is available then the generic L<Slaughter::Info::generic> module is used as a fall-back.

The information discovered can be dumped by running C<slaughter>

=for example begin

      ~# slaughter --dump

=for example end

Usage of this module is as follows:

=for example begin

    use Slaughter::Info::MSWin32;

    my $obj  = Slaughter::Info::MSWin32->new();
    my $data = $obj->getInformation();

    # use info now ..
    print $data->{'arch'} . "-bit architecture\n";

=for example end

When this module is used an attempt is also made to load the module
C<Slaughter::Info::Local::MSWin32> - if that succeeds it will be used to
augment the information discovered and made available to slaughter
policies.

=cut

=head1 METHODS

Now follows documentation on the available methods.

=cut


use strict;
use warnings;


package Slaughter::Info::MSWin32;


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

This function retrieves meta-information about the current host.

The return value is a hash-reference of data determined dynamically.


B<NOTE> This module has only been tested under Strawberry perl.

=cut

sub getInformation
{
    my ($self) = (@_);

    #
    #  The data we will return
    #
    my $ref;

    #
    #  Kernel version.
    #
    $ref->{ 'kernel' } = $ENV{ 'OS' };
    chomp( $ref->{ 'kernel' } ) if ( $ref->{ 'kernel' } );

    #
    #  Are we i386/amd64?
    #
    my $type = $ENV{ 'PROCESSOR_ARCHITECTURE' };
    if ($type)
    {
        if ( $type =~ /x86/i )
        {
            $ref->{ 'arch' } = "i386";
            $ref->{ 'bits' } = 32;
        }
        else
        {
            $ref->{ 'arch' } = "amd64";
            $ref->{ 'bits' } = 64;
        }
    }
    else
    {
        $ref->{ 'arch' } = "unknown";
        $ref->{ 'bits' } = 0;
    }

    #
    # This should be portable.
    #
    $ref->{ 'path' } = $ENV{ 'PATH' };

    #
    #  IP address(es).
    #
    my $ip = "ipconfig";

    #
    #  This if-test should always succeed, or this module wouldn't be loaded
    # for real.
    #
    #  It is present to skip this section of code when running the test-suite
    # on a GNU/Linux host.
    #
    #
    if ( $^O =~ /win32/i )
    {
        my $count = 1;

        foreach my $line ( split( /[\r\n]/, `$ip` ) )
        {
            next if ( !defined($line) || !length($line) );
            chomp($line);

            #
            #  This matches something like:
            #
            #  IP Address. . . . . . . . . . . . : 10.6.11.138
            #
            #
            if ( $line =~ /IP Address.* : (.*)/ )
            {
                my $ip = $1;

                #
                # Save away the IP address in "ip0", "ip1", "ip2" .. etc.
                #
                $ref->{ "ip" . $count } = $ip;
                $count += 1;
            }
        }

        if ( $count > 0 )
        {
            $ref->{ 'ipcount' } = ( $count - 1 );
        }
    }


    #
    #  Find the name of our release.
    #
    #  This if-test should always succeed, or this module wouldn't be loaded
    # for real.
    #
    #  It is present to skip this section of code when running the test-suite
    # on a GNU/Linux host.
    #
    if ( $^O =~ /win32/i )
    {
        my @win_info = Win32::GetOSVersion();
        my $version  = $win_info[0];
        my $distrib  = Win32::GetOSName();

        # work around for historical reasons
        $distrib = 'WinXP' if $distrib =~ /^WinXP/;
        $ref->{ 'version' }      = $version;
        $ref->{ 'distribution' } = $distrib;
    }

    #
    #  Return the data
    #
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
