#!/usr/bin/perl -w

=head1 NAME

Slaughter::Info::openbsd - Determine information about an OpenBSD host.

=cut

=head1 SYNOPSIS

This module is the OpenBSD version of the Slaughter information-gathering
module.

Modules beneath the C<Slaughter::Info> namespace are loaded when slaughter
is executed, they are used to populate a hash with information about
the current host.

This module is loaded only on OpenBSD systems, and will determine such details
as the local hostname, the free RAM, any IP addresses, etc.

The correct information-gathering module is loaded at run-time via the use of the C<$^O> variable, and if no system-specific module is available then the generic L<Slaughter::Info::generic> module is used as a fall-back.

The information discovered can be dumped by running C<slaughter>

=for example begin

      ~# slaughter --dump

=for example end

Usage of this module is as follows:

=for example begin

    use Slaughter::Info::openbsd;

    my $obj  = Slaughter::Info::openbsd->new();
    my $data = $obj->getInformation();

    # use info now ..
    print "We have $data->{'ip_count'} IPv4 addresses.\n";
    print "We have $data->{'ip6_count'} IPv6 addresses.\n";

=for example end

When this module is used an attempt is also made to load the module
C<Slaughter::Info::Local::openbsd> - if that succeeds it will be used to
augment the information discovered and made available to slaughter
policies.

=cut


=head1 METHODS

Now follows documentation on the available methods.

=cut


use strict;
use warnings;


package Slaughter::Info::openbsd;



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

=cut

sub getInformation
{
    my ($self) = (@_);

    #
    #  The data we will return.
    #
    my $ref;

    #
    #  Call "hostname" to determine the local hostname.
    #
    $ref->{ 'fqdn' } = `hostname`;
    chomp( $ref->{ 'fqdn' } );

    #
    #  Get the hostname and domain name as seperate strings.
    #
    if ( $ref->{ 'fqdn' } =~ /^([^.]+)\.(.*)$/ )
    {
        $ref->{ 'hostname' } = $1;
        $ref->{ 'domain' }   = $2;
    }
    else
    {

        #
        #  Better than nothing, right?
        #
        $ref->{ 'hostname' } = $ref->{ 'fqdn' };
        $ref->{ 'domain' }   = $ref->{ 'fqdn' };
    }


    #
    #  Kernel version.
    #
    $ref->{ 'release' } = `uname -r`;
    chomp( $ref->{ 'release' } );

    #
    #  Are we i386/amd64?
    #
    $ref->{ 'arch' } = `uname -p`;
    chomp( $ref->{ 'arch' } );

    #
    # This should be portable.
    #
    $ref->{ 'path' } = $ENV{ 'PATH' };

    #
    #  Count of IPv4/IPv6 addresses.
    #
    my $ipv4 = 1;
    my $ipv6 = 1;

    #
    #  Parse the output of /sbin/ifconfig.
    #
    foreach my $line ( split( /[\r\n]/, `ifconfig` ) )
    {
        chomp($line);
        next unless ( $line =~ /(inet|inet6)/ );

        if ( $line =~ /inet ([^ \t]+)/ )
        {
            my $addr = $1;
            next if ( $addr =~ /^127\./i );
            $ref->{ 'ip_' . $ipv4 } = $addr;
            $ipv4 += 1;
        }
        if ( $line =~ /inet6 ([^ \t]+)/ )
        {
            my $addr = $1;
            next if ( $addr =~ /fe80/i );
            $ref->{ 'ip6_' . $ipv6 } = $addr;
            $ipv6 += 1;
        }
    }

    # counts of addresses
    $ref->{ 'ip_count' }  = $ipv4;
    $ref->{ 'ip6_count' } = $ipv6;

    #
    # Load Average - This test will always succeed on an OpenBSD
    # system, but it is here to allow the module to be loaded/tested
    # upon a GNU/Linux host
    #
    if ( $^O =~ /openbsd/ )
    {
        $ref->{ 'load_average' } = `sysctl -n vm.loadavg`;
        chomp( $ref->{ 'load_average' } );

        #
        #  Split into per-minute values.
        #
        my @avg = split( /[ \t]/, $ref->{ 'load_average' } );
        $ref->{ 'load_average_1' }  = $avg[0];
        $ref->{ 'load_average_5' }  = $avg[1];
        $ref->{ 'load_average_15' } = $avg[2];

    }

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
