# vim:ts=4:sw=4:expandtab
package App::AllKnowingDNS::Handler;

use strict;
use warnings;
use base 'Exporter';
use Net::DNS;
use NetAddr::IP::Util qw(ipv6_aton);
use App::AllKnowingDNS::Config;
use App::AllKnowingDNS::Zone;
use POSIX qw(strftime);
use v5.10;

=head1 NAME

App::AllKnowingDNS::Handler - main code of AllKnowingDNS

=head1 DESCRIPTION

Note: User documentation is in L<all-knowing-dns>(1).

This module contains the C<Net::DNS::Nameserver> handler function.

=head1 FUNCTIONS

=cut

our @EXPORT = qw(reply_handler);

sub handle_ptr_query {
    my ($querylog, $zone, $qname, $qclass, $qtype) = @_;

    # Forward this query to our upstream DNS first, if any.
    if (defined($zone->upstream_dns) &&
        $zone->upstream_dns ne '') {
        my $resolver = Net::DNS::Resolver->new(
            nameservers => [ $zone->upstream_dns ],
            recurse => 0,
        );
        my $result = $resolver->query($qname . '.upstream', 'PTR');

        # If the upstream query was successful, relay the response, otherwise
        # generate a reply.
        if (defined($result) && $result->header->rcode eq 'NOERROR') {
            if ($querylog) {
                say strftime('%x %X %z', localtime) . " - Relaying upstream answer for $qname";
            }
            my @answer = $result->answer;
            for my $answer (@answer) {
                my $name = $answer->name;
                $name =~ s/\.upstream$//;
                $answer->name($name);
            }
            return ('NOERROR', [ $result->answer ], [], [], { aa => 1 });
        }
    }

    my $ttl = 3600;
    my $fullname = $qname;
    substr($fullname, -1 * length($zone->ptrzone)) = '';
    my $hostpart = join '', reverse split /\./, $fullname;
    my $rdata = $zone->resolves_to;
    $rdata =~ s/%DIGITS%/$hostpart/i;
    my $rr = Net::DNS::RR->new("$qname $ttl $qclass $qtype $rdata");
    return ('NOERROR', [ $rr ], [], [], { aa => 1 });
}

sub handle_aaaa_query {
    my ($zone, $qname, $qclass, $qtype) = @_;

    my $ttl = 3600;
    my $block = '([a-z0-9]{4})';
    my $regexp = quotemeta($zone->resolves_to);
    my ($address, $mask) = ($zone->network =~ m,^([^/]+)/([0-9]+),);
    my @components = unpack("n8", ipv6_aton($address));

    my $numdigits = (128 - $mask) / 4;
    $regexp =~ s/\\%DIGITS\\%/([a-z0-9]{$numdigits})/i;
    my ($digits) = ($qname =~ /$regexp/);
    return ('NXDOMAIN', undef, undef, undef) unless defined($digits);

    if ($qtype ne 'AAAA') {
        return ('NOERROR', [ ], [], [], { aa => 1 });
    }

    # Pad with zeros so that we can match 4 digits each.
    $digits = "0$digits" while (length($digits) % 4) != 0;

    # Collect blocks with 4 digits each
    my $numblocks = length($digits) / 4;
    for (my $c = 0; $c < $numblocks; $c++) {
        $components[8 - $numblocks + $c] |= hex(substr($digits, $c * 4, 4));
    }

    my $rdata = sprintf("%04x:" x 7 . "%04x", @components);
    my $rr = Net::DNS::RR->new("$qname $ttl $qclass $qtype $rdata");
    return ('NOERROR', [ $rr ], [], [], { aa => 1 });
}

=head2 reply_handler($config, $qname, $qclass, $qtype, $peerhost)

Handler to be used for Net::DNS::Nameserver.

Returns DNS RRs for PTR and AAAA queries of zones which are configured in
C<$config>.

=cut

sub reply_handler {
    my ($config, $querylog, $qname, $qclass, $qtype, $peerhost) = @_;

    if ($querylog) {
        say strftime('%x %X %z', localtime) . " - $peerhost - query for $qname ($qtype)";
    }

    if ($qtype eq 'PTR' &&
        defined(my $zone = $config->zone_for_ptr($qname))) {
        return handle_ptr_query($querylog, $zone, $qname, $qclass, $qtype);
    }

    if (defined(my $zone = $config->zone_for_aaaa($qname))) {
        return handle_aaaa_query($zone, $qname, $qclass, $qtype);
    }

    return ('NXDOMAIN', undef, undef, undef);
}

1

__END__

=head1 VERSION

Version 1.7

=head1 AUTHOR

Michael Stapelberg, C<< <michael at stapelberg.de> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Michael Stapelberg.

This program is free software; you can redistribute it and/or modify it
under the terms of the BSD license.

=cut
