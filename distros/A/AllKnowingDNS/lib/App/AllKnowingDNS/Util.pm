# vim:ts=4:sw=4:expandtab
package App::AllKnowingDNS::Util;

use strict;
use warnings;
use Exporter 'import';
use App::AllKnowingDNS::Config;
use App::AllKnowingDNS::Zone;
use NetAddr::IP::Util qw(ipv6_aton);
use v5.10;

=head1 NAME

App::AllKnowingDNS::Util - utility functions

=head1 DESCRIPTION

Note: User documentation is in L<all-knowing-dns>(1).

=head1 FUNCTIONS

=cut

our @EXPORT = qw(parse_config netmask_to_ptrzone);

=head2 parse_config($lines)

Parses a block of text as configfile.

Returns a corresponding App::AllKnowingDNS::Config object.

=cut

sub parse_config {
    my ($input) = @_;
    my $config = App::AllKnowingDNS::Config->new;

    my @lines = split("\n", $input);
    my $current_zone;
    for my $line (@lines) {
        # Strip whitespace.
        $line =~ s/^\s+//;

        # Ignore comments.
        next if substr($line, 0, 1) eq '#';

        # Skip empty lines
        next if length($line) == 0;

        # If we are not currently parsing a zone, only the 'network' keyword is
        # appropriate.
        if (!defined($current_zone) &&
            !($line =~ /^network/i) && !($line =~ /^listen/i)) {
            say STDERR qq|all-knowing-dns: CONFIG: Expected 'network' or 'listen' keyword in line "$line"|;
            next;
        }

        if (my ($address) = ($line =~ /^listen (.*)/i)) {
            $config->add_listen_address(lc $address);
            next;
        }

        if (my ($network) = ($line =~ /^network (.*)/i)) {
            # The current zone is done now, if any.
            $config->add_zone($current_zone) if defined($current_zone);
            $current_zone = App::AllKnowingDNS::Zone->new(
                network => lc $network,
            );
            next;
        }

        if (my ($resolves_to) = ($line =~ /^resolves to (.*)/i)) {
            # We explicitly don’t lowercase the DNS names to which PTR entries
            # will resolve, since some universities seem to have a fetish for
            # uppercase DNS names… :)
            $current_zone->resolves_to($resolves_to);
            next;
        }

        if (my ($upstream_dns) = ($line =~ /^with upstream (.*)/i)) {
            $current_zone->upstream_dns(lc $upstream_dns);
            next;
        }
    }

    $config->add_zone($current_zone) if defined($current_zone);
    return $config;
}

=head2 netmask_to_ptrzone($netmask)

Converts the given netmask to a PTR zone.

Example:

    my $ptrzone = netmask_to_ptrzone('2001:4d88:100e:ccc0::/64');
    say $ptrzone; # 0.c.c.c.e.0.0.1.8.8.d.4.1.0.0.2.ip6.arpa

=cut

sub netmask_to_ptrzone {
    my ($netmask) = @_;

    my ($address, $mask) = ($netmask =~ m,^([^/]+)/([0-9]+),);
    if (($mask % 16) != 0) {
        say STDERR "all-knowing-dns: ERROR: Only netmasks which " .
                   "are dividable by 16 are supported!";
        exit 1;
    }

    my @components = unpack("n8", ipv6_aton($address));
    # A nibble is a 4-bit aggregation, that is, one "hex digit".
    my @nibbles = map { ((($_ & 0xF000) >> 12),
                         (($_ & 0x0F00) >> 8),
                         (($_ & 0x00F0) >> 4),
                         (($_ & 0x000F) >> 0)) } @components;
    # Only keep ($mask / 4) digits. E.g., for a /64 network, keep 16 nibbles.
    splice(@nibbles, ($mask / 4));
    return join('.', map { sprintf('%x', $_) } reverse @nibbles) . '.ip6.arpa';
}

1
