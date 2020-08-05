package DNS::Unbound;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

DNS::Unbound - libunbound in Perl

=head1 SYNOPSIS

    my $dns = DNS::Unbound->new()->set_option( verbosity => 2 );

    # This appears to be safe:
    $dns->enable_threads();

    my $verbosity = $dns->get_option( 'verbosity' );

    $dns->set_option( verbosity => 1 + $verbosity );

Synchronous queries:

    my $res_hr = $dns->resolve( 'cpan.org', 'NS' );

    # See below about encodings in “data”.
    my @ns = map { $dns->decode_name($_) } @{ $res_hr->data() };

Asynchronous queries use L<the “Promise” pattern|https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Using_promises>:

    my $query1 = $dns->resolve_async( 'usa.gov', 'A' )->then(
        sub { my $data = shift()->data(); ... },  # success handler
        sub { ... },                              # failure handler
    );

    my $query2 = $dns->resolve_async( 'in-addr.arpa', 'NS' )->then(
        sub { ... },
        sub { ... },
    );

    # As an alternative to wait(), see below for documentation on
    # the fd(), poll(), and process() methods.

    $dns->wait();

See F<examples/> in the distribution for demonstrations of
making this module interface with L<AnyEvent> or L<IO::Async>.

=cut

=head1 DESCRIPTION

This library is a Perl interface to NLNetLabs’s widely-used
L<Unbound|https://nlnetlabs.nl/projects/unbound/> recursive DNS resolver.

=cut

#----------------------------------------------------------------------

use XSLoader ();

use DNS::Unbound::Result ();
use DNS::Unbound::X ();

# Load the default async query implementation.
# This may change when non-default implementations
# leave experimental status.
use DNS::Unbound::AsyncQuery::PromiseES6 ();

our ($VERSION);

BEGIN {
    $VERSION = '0.20';
    XSLoader::load();
}

# Retain this to avoid having to load Net::DNS::Parameters
# except in unusual cases.
use constant _COMMON_RR => {
    A          => 1,
    AAAA       => 28,
    AFSDB      => 18,
    ANY        => 255,
    APL        => 42,
    CAA        => 257,
    CDNSKEY    => 60,
    CDS        => 59,
    CERT       => 37,
    CNAME      => 5,
    DHCID      => 49,
    DLV        => 32769,
    DNAME      => 39,
    DNSKEY     => 48,
    DS         => 43,
    HIP        => 55,
    HINFO      => 13,
    IPSECKEY   => 45,
    KEY        => 25,
    KX         => 36,
    LOC        => 29,
    MX         => 15,
    NAPTR      => 35,
    NS         => 2,
    NSEC       => 47,
    NSEC3      => 50,
    NSEC3PARAM => 51,
    OPENPGPKEY => 61,
    PTR        => 12,
    RRSIG      => 46,
    RP         => 17,
    SIG        => 24,
    SMIMEA     => 53,
    SOA        => 6,
    SRV        => 33,
    SSHFP      => 44,
    TA         => 32768,
    TKEY       => 249,
    TLSA       => 52,
    TSIG       => 250,
    TXT        => 16,
    URI        => 256,
};

# Copied from libunbound
use constant _ctx_err => {
    -1  => 'socket error',
    -2  => 'alloc failure',
    -3  => 'syntax error',
    -4  => 'DNS service failed',
    -5  => 'fork() failed',
    -6  => 'cfg change after finalize()',
    -7  => 'initialization failed (bad settings)',
    -8  => 'error in pipe communication with async bg worker',
    -9  => 'error reading from file',
    -10 => 'async_id does not exist or result already been delivered',
};

use constant _DEFAULT_PROMISE_ENGINE => 'Promise::ES6';

#----------------------------------------------------------------------

=head1 METHODS

=head2 I<CLASS>->new()

Instantiates this class.

=cut

sub new {
    return bless {
        _ub => _create_context(),
        _pid => $$,
    }, shift();
}

=head2 $result_hr = I<OBJ>->resolve( $NAME, $TYPE [, $CLASS ] )

Runs a synchronous query for a given $NAME and $TYPE. $TYPE may be
expressed numerically or, for convenience, as a string. $CLASS is
optional and defaults to 1 (C<IN>), which is probably what you want.

Returns a L<DNS::Unbound::Result> instance.

B<NOTE:> libunbound doesn’t seem to offer effective controls for
timing out a synchronous query.
If timeouts are relevant for you, you probably need
to use C<resolve_async()> instead.

=cut

sub resolve {
    my $type = $_[2] || die 'Need type!';

    $type = _normalize_type_to_number($type);

    my $result = _resolve( $_[0]->{'_ub'}, $_[1], $type, $_[3] || () );

    if (!ref($result)) {
        die _create_resolve_error($result);
    }

    return DNS::Unbound::Result->new( %$result );
}

sub _normalize_type_to_number {
    my ($type) = @_;

    if ($type =~ tr<0-9><>c) {
        return _COMMON_RR()->{$type} || do {
            local ($@, $!);

            require Net::DNS::Parameters;
            Net::DNS::Parameters::typebyname($type);
        };
    }

    return $type;
}

sub _create_resolve_error {
    my ($number) = @_;

    return DNS::Unbound::X->create('ResolveError', number => $number, string => _ub_strerror($number));
}

#----------------------------------------------------------------------

=head2 $query = I<OBJ>->resolve_async( $NAME, $TYPE [, $CLASS ] );

Like C<resolve()> but starts an asynchronous query rather than a
synchronous one.

This returns an instance of L<DNS::Unbound::AsyncQuery> (a subclass
thereof, to be precise).

L<See below|/"METHODS FOR DEALING WITH ASYNCHRONOUS QUERIES"> for
the methods you’ll need to use in tandem with this one.

=cut

sub resolve_async {
    my $type = $_[2] || die 'Need type!';
    $type = $type = _normalize_type_to_number($type);

    # Prevent memory leaks.
    my $ctx = $_[0]->{'_ub'};
    my $name = $_[1];
    my $class = $_[3] || 1;

    my ($promise, $res, $rej, $deferred);

    my $query_class = _load_asyncquery_if_needed();

    if (my $deferred_cr = $query_class->_DEFERRED_CR()) {
        $deferred = $deferred_cr->();
        $promise = $deferred->promise();
        bless $promise, $query_class;
    }
    else {
        $promise = $query_class->new( sub { ($res, $rej) = @_ } );
    }

    # This hash maintains the query state across all related promise objects.
    # It must NOT contain $self, or else we’ll have a circular reference
    # that will prevent this class’s DESTROY method from firing.
    my %dns = (
        res => $res,
        rej => $rej,

        deferred => $deferred,

        ctx => $ctx,

        # It’s important that this be the _same_ scalar as what XS gets.
        # libunbound’s async callback will receive a pointer to this SV
        # and populate it as appropriate.
        value => undef,
    );

    my $async_ar = _resolve_async(
        $ctx, $name, $type, $class,
        $dns{'value'},
    );

    if (my $err = $async_ar->[0]) {
        die _create_resolve_error($err);
    }

    my $query_id = $async_ar->[1];

    $_[0]->{'_queries_dns'}{ $query_id } = \%dns;
    $_[0]->{'_queries_lookup'}{ $query_id } = undef;

    # NB: If %dns referenced $query it would be a circular reference.
    @dns{'id', 'queries_lookup'} = ($query_id, $_[0]->{'_queries_lookup'});

    $promise->_set_dns(\%dns);

    return $promise;
}

my $installed_cancel_cr;

sub _load_asyncquery_if_needed {

    # Not documented because it’s not yet meant for public consumption.
    my $engine = $ENV{'DNS_UNBOUND_PROMISE_ENGINE'} || _DEFAULT_PROMISE_ENGINE();
    $engine =~ tr<:><>d;

    my $ns = "DNS::Unbound::AsyncQuery::$engine";

    if (!$ns->can('cancel')) {
        local ($@, $!);
        die if !eval "require DNS::Unbound::AsyncQuery::$engine";
    }

    $installed_cancel_cr ||= do {
        $DNS::Unbound::AsyncQuery::CANCEL_CR = \&DNS::Unbound::_ub_cancel;
        1;
    };

    return $ns;
}

#----------------------------------------------------------------------

=head2 I<OBJ>->enable_threads()

Sets I<OBJ>’s asynchronous queries to use threads rather than forking.
Off by default. Throws an exception if called after an asynchronous query has
already been sent.

Returns I<OBJ>.

B<NOTE:> Despite Perl’s iffy relationship with threads, this appears
to work without issue.

=cut

sub enable_threads {
    my ($self) = @_;

    _ub_ctx_async( $self->{'_ub'}, 1 );

    return $self;
}

#=head2 I<OBJ>->disable_threads()
#
#Sets asynchronous queries to fork rather than using threads. On by default.
#Throws an exception if called after an asynchronous query has
#already been sent.
#
#Returns I<OBJ>.
#
#You probably don’t need to call this unless for some reason you want to
#disable threads after having enabled them without actually starting a query.
#
#=cut
#
#sub disable_threads {
#    my ($self) = @_;
#
#    _ub_ctx_async( $self->[0], 0 );
#
#    return $self;
#}

#----------------------------------------------------------------------

=head2 I<OBJ>->set_option( $NAME => $VALUE )

Sets a configuration option. Returns I<OBJ>.

Note that this is basically just a passthrough to the underlying
C<ub_ctx_set_option()> function and is thus subject to the same limitations
as that function; for example, you can’t set C<verbosity> after the
configuration has been “finalized”. (So use C<debuglevel()> for that
instead.)

=cut

sub set_option {
    my $err = _ub_ctx_set_option( $_[0]->{'_ub'}, "$_[1]:", $_[2] );

    if ($err) {
        my $str = _get_error_string_from_number($err);
        die "Failed to set “$_[1]” option ($_[2]): $str";
    }

    return $_[0];
}

=head2 $value = I<OBJ>->get_option( $NAME )

Gets a configuration option’s value.

=cut

sub get_option {
    my $got = _ub_ctx_get_option( $_[0]->{'_ub'}, $_[1] );

    if (!ref($got)) {
        my $str = _get_error_string_from_number($got);
        die "Failed to get “$_[1]” option: $str";
    }

    return $$got;
}

#----------------------------------------------------------------------

=head2 I<OBJ>->debuglevel( $LEVEL )

Sets the debug level (an integer). Returns I<OBJ>.

As of libunbound v1.9.2, this is just a way to set the C<verbosity>
option regardless of whether the configuration is finalized.

=cut

sub debuglevel {
    _ub_ctx_debuglevel( $_[0]{'_ub'}, $_[1] );
    return $_[0];
}

=head2 I<OBJ>->debugout( $FD_OR_FH )

Accepts a file descriptor or Perl filehandle and designates that
as the destination for libunbound diagnostic information.

Returns I<OBJ>.

=cut

sub debugout {
    my ($self, $fd_or_fh) = @_;

    my $fd = ref($fd_or_fh) ? fileno($fd_or_fh) : $fd_or_fh;

    my $mode = _get_fd_mode_for_fdopen($fd) or do {
        die DNS::Unbound::X->create('BadDebugFD', $fd, $!);
    };

    _ub_ctx_debugout( $self->{'_ub'}, $fd, $mode );

    return $self;
}

#----------------------------------------------------------------------

=head2 $str = I<CLASS>->unbound_version()

Gives the libunbound version string.

=cut

#----------------------------------------------------------------------

=head1 METHODS FOR ALTERING RESOLVER LOGIC

The following parallel their equivalents in libunbound.
They return I<OBJ> and throw errors on failure.

=head2 I<OBJ>->hosts( $FILENAME )

Z<>

=head2 I<OBJ>->resolveconf( $FILENAME )

Z<>

=cut

sub hosts {
    my $err = _ub_ctx_hosts( $_[0]->{'_ub'}, $_[1] );

    if ($err) {
        my $str = _get_error_string_from_number($err);
        die "Failed to set hosts file: $str";
    }

    return $_[0];
}

sub resolvconf {
    my $err = _ub_ctx_resolvconf( $_[0]->{'_ub'}, $_[1] );

    if ($err) {
        my $str = _get_error_string_from_number($err);
        die "Failed to set stub nameservers: $str";
    }

    return $_[0];
}

#----------------------------------------------------------------------

=head1 METHODS FOR DEALING WITH ASYNCHRONOUS QUERIES

Unless otherwise noted, the following methods correspond to their
equivalents in libunbound. They return the same values as the
libunbound equivalents.

=head2 I<OBJ>->poll()

Z<>

=cut

sub poll {
    return _ub_poll( $_[0]->{'_ub'} );
}

=head2 I<OBJ>->fd()

Z<>

=cut

sub fd {
    return _ub_fd( $_[0]->{'_ub'} );
}

=head2 I<OBJ>->wait()

Z<>

=cut

sub wait {
    my $ret = _ub_wait( $_[0]->{'_ub'} );

    $_[0]->_check_promises();

    return $ret;
}

=head2 I<OBJ>->process()

Z<>

=cut

sub process {
    my $ret = _ub_process( $_[0]->{'_ub'} );

    $_[0]->_check_promises();

    return $ret;
}

=head2 I<OBJ>->count_pending_queries()

Returns the number of outstanding asynchronous queries.

=cut

sub count_pending_queries {
    my ($self) = @_;

    return $self->{'_queries_lookup'} ? 0 + keys %{ $self->{'_queries_lookup'} } : 0;
}

#----------------------------------------------------------------------

=head1 METHODS FOR DEALING WITH DNSSEC

The following correspond to their equivalents in libunbound
and will only work if the underlying libunbound version supports them.

They return I<OBJ> and throw errors on failure.

=head2 I<OBJ>->add_ta()

Z<>

=cut

sub add_ta {
    my $err = _ub_ctx_add_ta( $_[0]->{'_ub'}, $_[1] );

    if ($err) {
        my $str = _get_error_string_from_number($err);
        die "Failed to add trust anchor: $str";
    }

    return $_[0];
}

=head2 I<OBJ>->add_ta_autr()

Z<>

=cut

sub add_ta_autr {
    my $err = _ub_ctx_add_ta_autr( $_[0]->{'_ub'}, $_[1] );

    if ($err) {
        my $str = _get_error_string_from_number($err);
        die "Failed to add managed trust anchor file: $str";
    }

    return $_[0];
}

=head2 I<OBJ>->add_ta_file()

Z<>

=cut

sub add_ta_file {
    my $err = _ub_ctx_add_ta_file( $_[0]->{'_ub'}, $_[1] );

    if ($err) {
        my $str = _get_error_string_from_number($err);
        die "Failed to add zone-style trust anchor file: $str";
    }

    return $_[0];
}

=head2 I<OBJ>->trustedkeys()

Z<>

=cut

sub trustedkeys {
    my $err = _ub_ctx_trustedkeys( $_[0]->{'_ub'}, $_[1] );

    if ($err) {
        my $str = _get_error_string_from_number($err);
        die "Failed to add BIND-style trust anchor file: $str";
    }

    return $_[0];
}

#----------------------------------------------------------------------

sub _check_promises {
    my ($self) = @_;

    if ( my $asyncs_hr = $self->{'_queries_dns'} ) {
        for my $dns_hr (values %$asyncs_hr) {
            if (defined $dns_hr->{'value'}) {
                delete $asyncs_hr->{ $dns_hr->{'id'} };
                delete $self->{'_queries_lookup'}{ $dns_hr->{'id'} };

                my ($succeeded, $settlement);

                if ( ref $dns_hr->{'value'} ) {
                    $succeeded = 1;
                    $settlement = DNS::Unbound::Result->new( %{ $dns_hr->{'value'} } );
                }
                else {
                    $settlement = _create_resolve_error($dns_hr->{'value'});
                }

                if (my $deferred = $dns_hr->{'deferred'}) {
                    my $fn = $succeeded ? 'resolve' : 'reject';
                    $deferred->$fn($settlement);
                }

                # Promise::ES6
                else {
                    $dns_hr->{$succeeded ? 'res' : 'rej'}->($settlement);
                }
            }
        }
    }

    return;
}

#----------------------------------------------------------------------

# In case I decide to expose these:
#
# sub decode_ipv4 {
#     shift if (ref $_[0]) && (ref $_[0])->isa(__PACKAGE__);
#     return join('.', unpack('C4', $_[0]));
# }
#
# sub decode_ipv6 {
#     shift if (ref $_[0]) && (ref $_[0])->isa(__PACKAGE__);
#     return join(':', unpack('(H4)8', $_[0]));
# }

=head1 CONVENIENCE FUNCTIONS

The following may be called either as object methods or as static
functions (but not as class methods). In addition to these,
L<Socket> provides the C<inet_ntoa()> and C<inet_ntop()>
functions for decoding the values of C<A> and C<AAAA> records.

B<NOTE:> Consider parsing L<DNS::Unbound::Result>’s C<answer_packet()>
with L<Net::DNS::Packet> as a more robust, albeit heavier, way to
parse query result data.

=head2 $decoded = decode_name($encoded)

Decodes a DNS name. Useful for, e.g., C<NS>, C<CNAME>, and C<PTR> query
results.

Note that this function’s return will normally include a trailing C<.>
because of the trailing NUL byte in an encoded DNS name. This is normal
and expected.

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
    $_[0]->{'_destroyed'} ||= $_[0]->{'_ub'} && do {
        if ($$ == $_[0]->{'_pid'}) {
            if (my $queries_hr = $_[0]->{'_queries_dns'}) {
                %$queries_hr = ();
            }
        }

        my $ub = delete $_[0]->{'_ub'};

        # If DESTROY fires at global destruction the internal libunbound
        # context object might already have been garbage-collected, in
        # which case we don’t want to try to clean up that object since
        # it’ll throw an unhelpfully-worded “(in cleanup)” warning
        # (as of perl 5.30, anyhow).
        _destroy_context($ub) if $ub;

        1;
    };
}

#----------------------------------------------------------------------

sub _get_error_string_from_number {
    my ($err) = @_;

    if ($err) {
        return _ctx_err()->{$err} || "Unknown error code: $err";
    }

    return undef;
}

1;

=head1 LICENSE & COPYRIGHT

Copyright 2019 Gasper Software Consulting.

This library is licensed under the same terms as Perl itself.

=head1 REPOSITORY

L<https://github.com/FGasper/p5-DNS-Unbound>

=head1 THANK YOU

Special thanks to L<ATOOMIC|https://metacpan.org/author/ATOOMIC> for
making some helpful review notes.
