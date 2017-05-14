# vim:ts=4:sw=4:expandtab
package App::AllKnowingDNS::Config;

use Mouse;
use App::AllKnowingDNS::Zone;
use App::AllKnowingDNS::Util;
use Data::Dumper;

=head1 NAME

App::AllKnowingDNS::Config - configuration object

=head1 DESCRIPTION

Note: User documentation is in L<all-knowing-dns>(1).

This module defines an object which holds the parsed version of the
AllKnowingDNS configuration file.

=head1 FUNCTIONS

=cut

has 'listen_addresses' => (
    traits => [ 'Array' ],
    is => 'ro',
    isa => 'ArrayRef[Str]',
    default => sub { [] },
    handles => {
        add_listen_address => 'push',
        all_listen_addresses => 'elements',
        count_listen_addresses => 'count',
    },
);

has 'zones' => (
    traits => [ 'Array' ],
    is => 'ro',
    isa => 'ArrayRef[App::AllKnowingDNS::Zone]',
    default => sub { [] },
    handles => {
        all_zones => 'elements',
        has_zones => 'count',
        count_zones => 'count',
    },
);

sub add_zone {
    my ($self, $zone) = @_;

    my $aaaazone = quotemeta($zone->resolves_to);
    $aaaazone =~ s/\\%DIGITS\\%/([a-z0-9]+)/i;
    $zone->aaaazone(qr/^$aaaazone$/);

    $zone->ptrzone(App::AllKnowingDNS::Util::netmask_to_ptrzone($zone->network));

    push @{$self->zones}, $zone;
}

=head2 zone_for_ptr($zone)

Returns the appropriate zone for the given PTR query or undef if there is no
appropriate zone.

Example:

    my $query = '7.c.e.2.3.4.e.f.f.f.b.d.9.1.2.0.' .
                '0.c.c.c.e.0.0.1.8.8.d.4.1.0.0.2.ip6.arpa';
    my $zone = $config->zone_for_ptr($query);
    return 'NXDOMAIN' unless defined($zone);
    ...

=cut

sub zone_for_ptr {
    my ($self, $query) = @_;

    for my $zone ($self->all_zones) {
        my $suffix = $zone->ptrzone;
        return $zone if substr($query, -1 * length($suffix)) eq $suffix;
    }

    return undef;
}

=head2 zone_for_aaaa($zone)

Returns the appropriate zone for the given AAAA query or undef if there is no
appropriate zone.

Example:

    my $query = 'ipv6-foo.nutzer.raumzeitlabor.de';
    my $zone = $config->zone_for_aaaa($query);
    return 'NXDOMAIN' unless defined($zone);
    ...

=cut

sub zone_for_aaaa {
    my ($self, $query) = @_;

    for my $zone ($self->all_zones) {
        return $zone if $query =~ $zone->aaaazone;
    }

    return undef;
}

__PACKAGE__->meta->make_immutable();

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
