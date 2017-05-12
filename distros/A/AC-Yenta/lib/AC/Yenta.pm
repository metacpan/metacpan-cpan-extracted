# -*- perl -*-

# Copyright (c) 2010 AdCopy
# Author: Jeff Weisberg
# Created: 2010-May-13 18:18 (EDT)
# Function: documentation
#
# $Id$

package AC::Yenta;
use strict;

our $VERSION = 1.1;

=head1 NAME

AC::Yenta - eventually-consistent distributed key/value data store. et al.

=head1 SYNOPSIS

    use AC::Yenta::D;
    use strict;

    my $y = AC::Yenta::D->new( );

    $y->daemon( $configfile, {
      argv		=> \@ARGV,
      foreground	=> $OPT{f},
      debugall		=> $OPT{d},
      port		=> $OPT{p},
    } );

    exit;


=head1 USAGE

    Copy + Paste from the example code into your own code.
    Copy + Paste from the example config into your own config.
    Send in bug report.

=head1 YIDDISH-ENGLISH GLOSSARY

	Kibitz - Gossip. Casual information exchange with ones peers.

	Yenta - 1. An old woman who kibitzes with other yentas.
		2. Software which kibitzes with other yentas.


=head1 DESCRIPTION

=head2 Peers

All of the running yentas are peers. There is no master server.
New nodes can be added or removed on the fly with no configuration.

=head2 Kibitzing

Each yenta kibitzes (gossips) with the other yentas in the network
to exchange status information, distribute key-value data, and
detect and correct inconsistent data.

=head2 Eventual Consistency

Key-value data is versioned with timestamps. By default, newest wins.
Maps can be configured to keep and return multiple versions and client
code can use other conflict resolution mechanisms.

Lost, missing or otherwise inconsistent data is detected
by kibitzing merkle tree hash values.

=head2 Topological awareness

Yentas can take network topology into account when tranferring
data around to minimize long-distance transfers. You will need to
write a custom C<MySelf> class with a C<my_datacenter> function.

=head2 Multiple Network Interfaces / NAT

Yentas can take advantage of multiple network interfaces with
different IP addresses (eg. a private internal network + a public network),
or multiple addresses (eg. a private addresses and a public address)
and various NAT configurations.

You will need to write a custom C<MySelf> class and C<my_network_info>
function.

=head2 Network Information

By default, yentas obtain their primary IP address by calling
C<gethostbyname( hostname() )>. If this either does not work on your
systems, or isn't the value you want to use,
you will need to write a custom C<MySelf> class and C<my_network_info>
function.



=head1 CONFIG FILE

various parameters need to be specified in a config file.
if you modify the file, it will be reloaded automagically.

=over 4

=item port

specify the TCP port to use

    port 3503

=item environment

specify the environment or realm to run in, so you can run multiple
independent yenta networks, such as production, staging, and dev.

    environment prod

=item allow

specify networks allowed to connect.

    allow 127.0.0.1
    allow 192.168.10.0/24

=item seedpeer

specify initial peers to contact when starting. the author generally
specifies 2 on the east coast, and 2 on the west coast.

    seedpeer 192.168.10.11:3503
    seedpeer 192.168.10.12:3503

=item secret

specify a secret key used to encrypt data transfered between
yentas in different datacenters.

    secret squeamish-ossifrage

=item syslog

specify a syslog facility for log messages.

    syslog local5

=item debug

enable debugging for a particular section

    debug map

=item map

configure a map (a collection of key-value data). you do not need
to configure the same set of maps on all servers. maps should be
configured similarly on all servers that they are on.

    map users {
	backend	    bdb
        dbfile      /home/acdata/users.ydb
        history     4
    }

=back

=head1 BUGS

Too many to list here.

=head1 SEE ALSO

    AC::Yenta::Client

    Amazon Dynamo - http://www.allthingsdistributed.com/2007/10/amazons_dynamo.html

=head1 AUTHOR

    Jeff Weisberg - http://www.solvemedia.com/

=cut

1;
