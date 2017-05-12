# vim:ts=4:sw=4:expandtab
package App::AllKnowingDNS::Config;

use Mouse;
use App::AllKnowingDNS::Zone;
use App::AllKnowingDNS::Util;
use Data::Dumper;

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

    my $aaaazone = $zone->resolves_to;
    $aaaazone =~ s/^.*?%DIGITS%[^.]*//;
    $zone->aaaazone($aaaazone);

    $zone->ptrzone(App::AllKnowingDNS::Util::netmask_to_ptrzone($zone->network));

    push $self->zones, $zone;
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
        my $suffix = $zone->aaaazone;
        return $zone if substr($query, -1 * length($suffix)) eq $suffix;
    }

    return undef;
}

__PACKAGE__->meta->make_immutable();

1
