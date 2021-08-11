package DNS::Unbound::Result;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

DNS::Unbound::Result

=head1 DESCRIPTION

This class represents a DNS query result from L<DNS::Unbound>.

=head1 ACCESSORS

This class includes an accessor for most members of C<struct ub_result>
(cf. L<libunbound(3)|https://nlnetlabs.nl/documentation/unbound/libunbound/>).

The following all return scalars:

=over

=item * C<qname()>, C<qtype()>, C<qclass()>, C<ttl()>

=item * C<rcode()>, C<nxdomain()>, C<havedata()>, C<canonname()>

=item * C<secure()>, C<bogus()>, C<why_bogus()>, C<answer_packet>

=back

C<data()> returns an array reference of byte strings that contain the query
result in DNS-native RDATA encoding.

=cut

use Class::XSAccessor {
    constructor => 'new',

    getters => {
        qname => 'qname',
        qtype => 'qtype',
        qclass => 'qclass',
        data => 'data',
        canonname => 'canonname',
        rcode => 'rcode',
        havedata => 'havedata',
        nxdomain => 'nxdomain',
        secure => 'secure',
        bogus => 'bogus',
        why_bogus => 'why_bogus',
        ttl => 'ttl',
        answer_packet => 'answer_packet',
    },
};

=head1 ADDITIONAL METHODS

=head2 $objs_ar = I<OBJ>->to_net_dns_rrs()

B<IMPORTANT:> This method is DEPRECATED and will be withdrawn in a
forthcoming version. Please migrate to the following logic instead
(assuming an instance of this class in C<$result>):

    my $packet = Net::DNS::Packet->new( \$result->answer_packet() );

… which will yield a L<Net::DNS::Packet> instance.

The DEPRECATED method’s documentation follows:

The C<data()> accessor’s return values are raw RDATA. Your application
likely prefers to work with parsed DNS data, though. This method facilitates
that by loading L<Net::DNS::RR> and returning a reference to an array of
instances of that class (i.e., probably a subclass of it like
L<Net::DNS::RR::NS>).

So, for example, to get a TXT query result’s value as a list of
character strings, you could do:

    @cstrings = map { $_->txtdata() } @{ $result->to_net_dns_rrs() }

=cut

sub to_net_dns_rrs {
    my ($self) = @_;

    local ($@, $!);
    require Net::DNS::RR;

    my @rrset = map {
        Net::DNS::RR->new(
            owner => $self->{'qname'},
            type => $self->{'qtype'},
            class => $self->{'qclass'},
            ttl => $self->{'ttl'},
            rdata => $_,
        );
    } @{ $self->{'data'} };

    return \@rrset;
}

1;
