#!/usr/bin/perl -w

=head1 NAME

Slaughter::Info::linux - Determine information about a Linux host.

=cut

=head1 SYNOPSIS

This module is the GNU/Linux version of the Slaughter information-gathering
module.

Modules beneath the C<Slaughter::Info> namespace are loaded when slaughter
is executed, they are used to populate a hash with information about
the current host.

This module is loaded only on linux systems, and will determine such details
as the local hostname, the free RAM, any IP addresses, etc.

The correct information-gathering module is loaded at run-time via the use of the C<$^O> variable, and if no system-specific module is available then the generic L<Slaughter::Info::generic> module is used as a fall-back.

The information discovered can be dumped by running C<slaughter>

=for example begin

      ~# slaughter --dump

=for example end

Usage of this module is as follows:

=for example begin

    use Slaughter::Info::linux;

    my $obj  = Slaughter::Info::linux->new();
    my $data = $obj->getInformation();

    # use info now ..
    print "We have software RAID\n" if ( $data->{'softwareraid'} );

=for example end

When this module is used an attempt is also made to load the module
C<Slaughter::Info::Local::linux> - if that succeeds it will be used to
augment the information discovered and made available to slaughter
policies.

=cut

=head1 METHODS

Now follows documentation on the available methods.

=cut


use strict;
use warnings;


package Slaughter::Info::linux;


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
    #  Fully Qualified hostname
    #
    #  1.  If we can find /etc/hostname, then use that.
    #
    if ( -e "/etc/hostname" )
    {
        open( my $file, "<", "/etc/hostname" ) or
          die "Failed to read /etc/hostname - $!";
        $ref->{ 'fqdn' } = <$file>;
        chomp( $ref->{ 'fqdn' } );
        close($file);
    }
    else
    {

        #
        #  Call "hostname".
        #
        $ref->{ 'fqdn' } = `hostname`;
        chomp( $ref->{ 'fqdn' } );

        #
        # If it is unqualified retry with --fqdn.
        #
        if ( $ref->{ 'fqdn' } !~ /\./ )
        {
            $ref->{ 'fqdn' } = `hostname --fqdn`;
            chomp( $ref->{ 'fqdn' } );
        }
    }


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
    # This should be portable.
    #
    $ref->{ 'path' } = $ENV{ 'PATH' };

    #
    #  Is this a xen host, or guest?
    #
    $ref->{ 'xen' } = 1 if -d "/proc/xen/capabilities";

    #
    #  Detect virtualized CPU, as well as processor count, and architecture.
    #
    if ( open( my $cpu, "<", "/proc/cpuinfo" ) )
    {
        $ref->{ 'cpu_count' } = -1;

        foreach my $line (<$cpu>)
        {
            chomp($line);
            $ref->{ 'kvm' } = 1 if ( $line =~ /model/ && $line =~ /qemu/i );

            if ( $line =~ /model name\s+: (.*)$/ )
            {
                $ref->{ 'cpumodel' } = $1;
            }
            if ( $line =~ /processor\s+: (\d+)/ )
            {
                $ref->{ 'cpu_count' } = $1 if ( $ref->{ 'cpu_count' } < $1 );
            }
            if ( $line =~ /flags\s+:(.*)/ )
            {
                my $flags = $1;
                if ( $flags =~ /lm/ )
                {
                    $ref->{ 'arch' } = "amd64";
                    $ref->{ 'bits' } = 64;
                }
                else
                {
                    $ref->{ 'arch' } = "i386";
                    $ref->{ 'bits' } = 32;
                }
            }
        }

        $ref->{ 'cpu_count' }++;
        close($cpu);
    }


    #
    #  Are we i386/amd64.  This shouldn't be necessary since the information
    # should have been read from /proc/cpuinfo
    #
    if ( !$ref->{ 'arch' } )
    {
        my $type = `file /bin/ls`;
        if ( $type =~ /64-bit/i )
        {
            $ref->{ 'arch' } = "amd64";
            $ref->{ 'bits' } = 64;
        }
        else
        {
            $ref->{ 'arch' } = "i386";
            $ref->{ 'bits' } = 32;
        }
    }


    #
    #  Software RAID?
    #
    if ( ( -e "/proc/mdstat" ) &&
         ( -x "/sbin/mdadm" ) )
    {
        if ( open( my $mdstat, "<", "/proc/mdstat" ) )
        {
            foreach my $line (<$mdstat>)
            {
                if ( ( $line =~ /^md([0-9]+)/ ) &&
                     ( $line =~ /active/i ) )
                {
                    $ref->{ 'softwareraid' } = 1;
                    $ref->{ 'raid' }         = "software";
                }
            }
            close($mdstat);
        }
    }


    #
    #  Memory total and memory free.
    #
    if ( open( my $mem, "<", "/proc/meminfo" ) )
    {
        foreach my $line (<$mem>)
        {
            chomp($line);
            if ( $line =~ /MemTotal:\s+(\d+) kB/ )
            {
                $ref->{ 'memtotal' } = $1;
            }
            if ( $line =~ /MemFree:\s+(\d+) kB/ )
            {
                $ref->{ 'memfree' } = $1;
            }
        }
        close($mem);
    }


    #
    #  Kernel version.
    #
    $ref->{ 'kernel' } = `uname -r`;
    chomp( $ref->{ 'kernel' } );


    #
    #  IP address(es).
    #
    my $ip = undef;

    $ip = "/sbin/ip" if ( -x "/sbin/ip" );
    $ip = "/bin/ip"  if ( -x "/bin/ip" );


    if ( defined($ip) )
    {

        #
        #  Two commands to find the IP addresses we have
        #
        my @cmd = ( " -o -f inet addr show scope global",
                    " -o -f inet6 addr show scope global"
                  );

        #
        #  Run each
        #
        foreach my $cmd (@cmd)
        {
            my $count  = 1;
            my $family = "ip";
            $family = "ip6" if ( $cmd =~ /inet6/i );

            foreach my $line ( split( /[\r\n]/, `$ip $cmd` ) )
            {
                next if ( !defined($line) || !length($line) );
                chomp($line);

                #
                #  This matches something like:
                #
                #  eth0 inet 192.168.1.9/24 brd 192.168.1.255 scope global eth0
                #
                # or
                #  eth0 inet6 2001:41c8:1:5abb::62/64 scope global valid_lft forever preferred_lft forever
                #
                #
                if ( $line =~ /(inet|inet6)[ \t]+([^ \t+]+)[ \t]+/ )
                {
                    my $proto = $1;
                    my $ip    = $2;

                    #
                    #  Strip off /24, /128, etc.
                    #
                    $ip =~ s/\/.*//g;

                    #
                    # Save away the IP address in "ip0", "ip1", "ip2" .. etc.
                    #
                    $ref->{ $family . "_" . $count } = $ip;
                    $count += 1;
                }
            }

            if ( $count > 0 )
            {
                $ref->{ $family . '_count' } = ( $count - 1 );
            }
        }
    }

    #
    #  Find the name of our release
    #
    my $version = "unknown";
    my $distrib = "unknown";
    my $release = "unknown";
    if ( -x "/usr/bin/lsb_release" )
    {
        foreach
          my $line ( split( /[\r\n]/, `/usr/bin/lsb_release -a 2>/dev/null` ) )
        {
            chomp $line;
            if ( $line =~ /Distributor ID:\s*(.*)/ )
            {
                $distrib = $1;
            }
            if ( $line =~ /Release:\s*(.*)/ )
            {
                $version = $1;
            }
            if ( $line =~ /Codename:\s*(.*)/ )
            {
                $release = $1;
            }
        }
    }
    $ref->{ 'version' }      = $version;
    $ref->{ 'distribution' } = $distrib;
    $ref->{ 'release' }      = $release;


    #
    #  TODO: 3Ware RAID?
    #

    #
    #  TODO: HP RAID?
    #

    #
    # Load Average
    #
    my $uptime = `uptime`;
    chomp($uptime);
    if ( $uptime =~ /load average:[ \t]*(.*)/ )
    {
        $uptime = $1;
        $uptime =~ s/,//g;
        $ref->{ 'load_average' } = $uptime;

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
