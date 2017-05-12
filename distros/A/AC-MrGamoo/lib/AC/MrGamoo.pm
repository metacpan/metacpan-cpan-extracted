# -*- perl -*-

# Copyright (c) 2010 AdCopy
# Author: Jeff Weisberg
# Created: 2010-May-13 18:18 (EDT)
# Function: documentation
#
# $Id: MrGamoo.pm,v 1.2 2011/01/12 19:29:21 jaw Exp $

package AC::MrGamoo;
use strict;

our $VERSION = 1.0;

=head1 NAME

AC::MrGamoo - Map/Reduce Framework

=head1 SYNOPSIS

    use AC::MrGamoo::D;
    use strict;

    my $m = AC::MrGamoo::D->new( );

    $m->daemon( $configfile, {
      argv		=> \@ARGV,
      foreground	=> $OPT{f},
      debugall		=> $OPT{d},
      port		=> $OPT{p},
    } );

    exit;

=head1 CONFIG FILE

various parameters need to be specified in a config file.
if you modify the file, it will be reloaded automagically.

=over 4

=item port

specify the TCP port to use

    port 3504

=item environment

specify the environment or realm to run in, so you can run multiple
independent map/reduce networks, such as production, staging, and dev.

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
systems in different datacenters.

    secret squeamish-ossifrage

=item syslog

specify a syslog facility for log messages.

    syslog local5

=item basedir

local directory to store files

    basedir         /home/data

=item debug

enable debugging for a particular section

    debug job

=back

=head1 BUGS

Too many to list here.

=head1 SEE ALSO

    AC::MrGamoo::Client

=head1 AUTHOR

    Jeff Weisberg - http://www.solvemedia.com/

=cut



1;
