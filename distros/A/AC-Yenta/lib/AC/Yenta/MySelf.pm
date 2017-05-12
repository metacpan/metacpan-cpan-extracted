# -*- perl -*-

# Copyright (c) 2010 AdCopy
# Author: Jeff Weisberg
# Created: 2010-Jan-18 18:10 (EST)
# Function: stub for customization
#
# $Id$

package AC::Yenta::MySelf;
use AC::Yenta::Customize;
use AC::Import;
use strict;

our @ISA    = 'AC::Yenta::Customize';
our @EXPORT = qw(my_server_id my_network_info my_datacenter);
our @CUSTOM = (@EXPORT, 'init');


1;

=head1 NAME

AC::Yenta::MySelf - customize yenta to your own environment

=head1 SYNOPSIS

    emacs /myperldir/Local/Yenta/MySelf.pm
    copy. paste. edit.

    use lib '/myperldir';
    my $y = AC::Yenta::D->new(
        class_myself        => 'Local::Yenta::MySelf',
    );

=head1 DESCRIPTION

provide functions to override default behavior. you may define
any or all of the following functions.

=head2 my_server_id

return a unique identity for this yenta instance. typically,
something similar to the server hostname.

    sub my_server_id {
        return 'yenta@' . hostname();
    }

=head2 my_datacenter

return the name of the local datacenter. yenta will use this
to determine which systems are local (same datacenter) and
which are remote (different datacenter), and will tune various
behaviors accordingly.

    sub my_datacenter {
        my($domain) = hostname() =~ /^[\.]+\.(.*)/;
        return $domain;
    }

=head2 my_network_info

return information about the various networks this server has.

    sub my_network_info {
        my $public_ip = inet_ntoa(scalar gethostbyname(hostname()));
        my $privat_ip = inet_ntoa(scalar gethostbyname('internal-' . hostname()));


        return [
            # use this IP for communication with servers this datacenter (same natdom)
            { ip => $privat_ip, natdom => my_datacenter() },
            # otherwise use this IP
            { ip => $public_ip },
        ]
    }

=head2 init

inialization function called at startup. typically used to lookup hostanmes, IP addresses,
and such and store them in variables to make the above functions faster.

    my $HOSTNAME;
    my $DOMAIN;
    sub init {
        $HOSTNAME = hostname();
        ($DOMAIN) = $HOSTNAME =~ /^[\.]+\.(.*)/;
    }

=head1 BUGS

none. you write this yourself.

=head1 SEE ALSO

    AC::Yenta

=head1 AUTHOR

    You!

=cut
