package DNS::Unbound;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

DNS::Unbound - A Perl interface to NLNetLabs’s L<Unbound|https://nlnetlabs.nl/projects/unbound/> recursive DNS resolver

=head1 SYNOPSIS

    my $dns = DNS::Unbound->new()->set_option( verbosity => 2 );

    my $verbosity = $dns->get_option( 'verbosity' );

    $dns->set_option( verbosity => 1 + $verbosity );

    my $res_hr = $dns->resolve( 'cpan.org', 'NS' );

    # See below about encodings in “data”.
    my @ns = map { $dns->decode_name($_) } @{ $res_hr->{'data'} };

=cut

#----------------------------------------------------------------------

use XSLoader ();

use DNS::Unbound::X ();

our ($VERSION);

BEGIN {
    $VERSION = '0.02';
    XSLoader::load();
}

use constant RR => {
    A => 1,
    AAAA => 28,
    AFSDB => 18,
    ANY => 255,
    APL => 42,
    CAA => 257,
    CDNSKEY => 60,
    CDS => 59,
    CERT => 37,
    CNAME => 5,
    DHCID => 49,
    DLV => 32769,
    DNAME => 39,
    DNSKEY => 48,
    DS => 43,
    HIP => 55,
    HINFO => 13,
    IPSECKEY => 45,
    KEY => 25,
    KX => 36,
    LOC => 29,
    MX => 15,
    NAPTR => 35,
    NS => 2,
    NSEC => 47,
    NSEC3 => 50,
    NSEC3PARAM => 51,
    OPENPGPKEY => 61,
    PTR => 12,
    RRSIG => 46,
    RP => 17,
    SIG => 24,
    SMIMEA => 53,
    SOA => 6,
    SRV => 33,
    SSHFP => 44,
    TA => 32768,
    TKEY => 249,
    TLSA => 52,
    TSIG => 250,
    TXT => 16,
    URI => 256,
};

# Copied from libunbound
use constant _ctx_err => {
    -1 => 'socket error',
    -2 => 'alloc failure',
    -3 => 'syntax error',
    -4 => 'DNS service failed',
    -5 => 'fork() failed',
    -6 => 'cfg change after finalize()',
    -7 => 'initialization failed (bad settings)',
    -8 => 'error in pipe communication with async bg worker',
    -9 => 'error reading from file',
    -10 => 'async_id does not exist or result already been delivered',
};

#----------------------------------------------------------------------

=head1 METHODS

=head2 I<CLASS>->new()

Instantiates this class.

=cut

sub new {
    bless [ _create_context() ], shift;
}

=head2 $result_hr = I<OBJ>->resolve( $NAME, $TYPE [, $CLASS ] )

Runs a synchronous query for a given $NAME and $TYPE. $TYPE may be
expressed numerically or, for convenience, as a string. $CLASS is
optional and defaults to 1 (C<IN>), which is probably what you want.

Returns a reference to a hash that corresponds
to a libunbound C<struct ub_result>
(cf. L<libunbound(3)|https://nlnetlabs.nl/documentation/unbound/libunbound/>),
excluding C<len>, C<answer_packet>, and C<answer_len>.

B<NOTE:> Members of C<data> are in their DNS-native RDATA encodings.
(libunbound doesn’t track which record type uses which encoding, so
neither does DNS::Unbound.)
To decode some common record types, see L</CONVENIENCE FUNCTIONS> below.

=cut

sub resolve {
    my $type = $_[2] || die 'Need type!';
    $type = RR()->{$type} || $type;

    my $result = _resolve( $_[0][0], $_[1], $type, $_[3] || () );

    if (!ref($result)) {
        die DNS::Unbound::X->create('ResolveError', number => $result, string => _ub_strerror($result));
    }

    return $result;
}

=head2 I<OBJ>->set_option( $NAME => $VALUE )

Sets a configuration option. Returns I<OBJ>.

=cut

sub set_option {
    my $err = _ub_ctx_set_option( $_[0][0], "$_[1]:", $_[2] );

    if ($err) {
        my $str = _ctx_err()->{$err} || "Unknown error code: $err";
        die "Failed to set “$_[1]” ($_[2]): $str";
    }

    return $_[0];
}

=head2 $value = I<OBJ>->get_option( $NAME )

Gets a configuration option’s value.

=cut

sub get_option {
    my $got = _ub_ctx_get_option( $_[0][0], $_[1] );

    if (!ref($got)) {
        my $str = _ctx_err()->{$got} || "Unknown error code: $got";
        die "Failed to get “$_[1]”: $str";
    }

    return $$got;
}

=head2 I<CLASS>->unbound_version()

Gives the libunbound version string.

=cut

#----------------------------------------------------------------------

=head1 CONVENIENCE FUNCTIONS

Note that L<Socket> provides the C<inet_ntoa()> and C<inet_ntop()>
functions for decoding C<A> and C<AAAA> records.

The following may be called either as object methods or as static
functions (but not as class methods):

=head2 $decoded = decode_name($encoded)

Decodes a DNS name. Useful for, e.g., C<NS> query results.

Note that this will normally include a trailing C<.> because of the
trailing NUL byte in an encoded DNS name.

=cut

sub decode_name {
    shift if (ref $_[0]) && (ref $_[0])->isa(__PACKAGE__);
    return join( '.', @{ decode_character_strings($_[0]) } );
}

=head2 $strings_ar = decode_character_strings($encoded)

Decodes a list of character-strings into component strings,
returned as an array reference. Useful for C<TXT> query results.

=cut

sub decode_character_strings {
    shift if (ref $_[0]) && (ref $_[0])->isa(__PACKAGE__);
    return [ unpack( '(C/a)*', $_[0] ) ];
}

#----------------------------------------------------------------------

sub DESTROY {
    _destroy_context( $_[0][0] );
}

#----------------------------------------------------------------------

1;

=head1 REPOSITORY

L<https://github.com/FGasper/p5-DNS-Unbound>

=head1 THANK YOU

Special thanks to L<ATOOMIC|https://metacpan.org/author/ATOOMIC> for
making some helpful review notes.
