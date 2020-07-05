package Data::Radius::Constants;
use strict;
use warnings;

my %RFC_TYPES;

BEGIN {
    %RFC_TYPES = (
        # RADIUS Codes
        ACCESS_REQUEST      => 1,
        ACCESS_ACCEPT       => 2,
        ACCESS_REJECT       => 3,
        ACCOUNTING_REQUEST  => 4,
        ACCOUNTING_RESPONSE => 5,
        ACCOUNTING_STATUS   => 6,
        ACCESS_CHALLENGE    => 11,
        # unused - not exported
        STATUS_SERVER       => 12,
        STATUS_CLIENT       => 13,
        # rfc3576
        DISCONNECT_REQUEST  => 40,
        DISCONNECT_ACCEPT   => 41,
        DISCONNECT_REJECT   => 42,
        COA_REQUEST         => 43,
        COA_ACCEPT          => 44,
        COA_REJECT          => 45,
    );
}
use constant \%RFC_TYPES;

use Exporter qw(import);

our @EXPORT_OK = (keys (%RFC_TYPES), '%RADIUS_PACKET_TYPES', 'accepting_packet_type');
our %EXPORT_TAGS = ( all => [ @EXPORT_OK ] );

use Const::Fast;

# include all canonical type names and some aliases
const our %RADIUS_PACKET_TYPES => (
    %RFC_TYPES,
    # and aliases
    'COA' => COA_REQUEST,
    'DM' => DISCONNECT_REQUEST,
    'POD' => DISCONNECT_REQUEST,
    'ACCT' => ACCOUNTING_REQUEST,
    'AUTH' => ACCESS_REQUEST,
);

const my %accepting_types => (
    &ACCESS_REQUEST => {
        &ACCESS_ACCEPT => 1,
        &ACCESS_REJECT => 0,
        &ACCESS_CHALLENGE => undef, # this requires explicit handling
    },
    &ACCOUNTING_REQUEST => {
        &ACCOUNTING_RESPONSE => 1,
    },
    &ACCOUNTING_STATUS => {
        &ACCOUNTING_RESPONSE => 1,
    },
    &DISCONNECT_REQUEST => {
        &DISCONNECT_ACCEPT => 1,
        &DISCONNECT_REJECT => 0,
    },
    &COA_REQUEST => {
        &COA_ACCEPT => 1,
        &COA_REJECT => 0,
    },
);

sub accepting_packet_type {
    my ($req_type, $response_type) = @_;
    $req_type = $RADIUS_PACKET_TYPES{$req_type}
        if exists $RADIUS_PACKET_TYPES{$req_type};
    return undef unless exists $accepting_types{$req_type};
    my $atr = $accepting_types{$req_type};
    $response_type = $RADIUS_PACKET_TYPES{$response_type}
        if exists $RADIUS_PACKET_TYPES{$response_type};
    return undef unless exists $atr->{$response_type};
    return $atr->{$response_type};
}

1;

__END__

=head1 NAME

Data::Radius::Constants - export constants for Data::Radius::Packet

=head1 SYNOPSIS

    use Data::Radius::Constants qw(:all);

or

    use Data::Radius::Constants qw(ACCESS_REQUEST ACCESS_ACCEPT ACCESS_REJECT %RADIUS_PACKET_TYPES);


=head1 DESCRIPTION

Exports RADIUS RFC established constants and utilities for easy packet handling.

In addition to RFC packet type constants enables following aliases:

    'COA' => COA_REQUEST,

    'DM' => DISCONNECT_REQUEST,

    'POD' => DISCONNECT_REQUEST,

    'ACCT' => ACCOUNTING_REQUEST,

    'AUTH' => ACCESS_REQUEST,

    my $type = ACCESS_REQUEST;

... is equivalent to

    my $type = $RADIUS_PACKET_TYPES{AUTH}; # using aliases


=head1 METHODS

=over


=item accepting_packet_type($request_type, $response_type)

Convenience method to test if a request was accepted by received response.

Returns true if the response type is the accepting type for the given request type.
Returns 0 for corresponding rejections, undef for everything else

You can use packet type ids or its aliases as arguments

Example:

($response_type) = $response_packet->parse();

print "Accepted\n"
    if accepting_packet_type(ACCESS_REQUEST, $response_type);

but also

print "Accepted\n"
    if accepting_packet_type('AUTH', ACCESS_ACCEPT);

print "Accepted\n"
    if accepting_packet_type('AUTH', 'ACCESS_ACCEPT'); # same

=back


=head1 SEE ALSO

L<Data::Radius::Packet>

=head1 AUTHOR

Sergey Leschenko <sergle.ua at gmail.com>

PortaOne Development Team <perl-radius at portaone.com> is the current module's maintainer at CPAN.

=cut

