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

Asynchronous queries use L<the “Promise” pattern|https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Using_promises>. Assuming you’re using
an off-the-shelf event loop, you can do something like:

    my $dns = DNS::Unbound::AnyEvent->new();

    my $query1 = $dns->resolve_async( 'usa.gov', 'A' )->then(
        sub { my $data = shift()->data(); ... },  # success handler
        sub { ... },                              # failure handler
    );

    my $query2 = $dns->resolve_async( 'in-addr.arpa', 'NS' )->then(
        sub { ... },
        sub { ... },
    );

You can also integrate with a custom event loop; see L</"EVENT LOOPS"> below.

=cut

=head1 DESCRIPTION

This library is a Perl interface to the libary component of NLNetLabs’s
widely-used L<Unbound|https://nlnetlabs.nl/projects/unbound/> recursive
DNS resolver.

=head1 CHARACTER ENCODING

DNS doesn’t know about character encodings, so neither does Unbound.
Thus, all strings given to this module must be B<byte> B<strings>.
All returned strings will be byte strings as well.

=head1 EVENT LOOPS

This distribution includes the classes L<DNS::Unbound::AnyEvent>,
L<DNS::Unbound::IOAsync>, and L<DNS::Unbound::Mojo>, which provide
out-of-the-box compatibility with those popular event loop interfaces.
You should probably use one of these.

You can also integrate with a custom event loop via the C<fd()> method
of this class: wait for that file descriptor to be readable, then
call this class’s C<perform()> method.

=head1 MEMORY LEAK DETECTION

Objects in this namespace will, if left alive at global destruction,
throw a warning about memory leaks. To silence these warnings, either
allow all queries to complete, or cancel queries you no longer care about.

=cut

#----------------------------------------------------------------------

use XSLoader ();

use DNS::Unbound::Result ();
use DNS::Unbound::X      ();

# Load the default async query implementation.
# This may change when non-default implementations
# leave experimental status.
use DNS::Unbound::AsyncQuery::PromiseES6 ();

our ($VERSION);

BEGIN {
    $VERSION = '0.26';
    XSLoader::load( __PACKAGE__, $VERSION );
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
        _ub  => DNS::Unbound::Context::create(),
        _pid => $$,
      },
      shift();
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
    my ($self, $name, $type, $class) = @_;

    die 'Need type!' if !$type;

    $type = _normalize_type_to_number($type);

    my $result = $self->{'_ub'}->_resolve( $name, $type, $class || () );

    if ( !ref($result) ) {
        die _create_resolve_error($result);
    }

    return DNS::Unbound::Result->new(%$result);
}

sub _normalize_type_to_number {
    my ($type) = @_;

    if ( $type =~ tr<0-9><>c ) {
        return _COMMON_RR()->{$type} || do {
            local ( $@, $! );

            require Net::DNS::Parameters;
            Net::DNS::Parameters::typebyname($type);
        };
    }

    return $type;
}

sub _create_resolve_error {
    my ($number) = @_;

    return DNS::Unbound::X->create( 'ResolveError', number => $number, string => _ub_strerror($number) );
}

#----------------------------------------------------------------------

=head2 $query = I<OBJ>->resolve_async( $NAME, $TYPE [, $CLASS ] );

Like C<resolve()> but starts an asynchronous query rather than a
synchronous one.

This returns an instance of L<DNS::Unbound::AsyncQuery> (a subclass
thereof, to be precise).

If you’re using one of the special event interface subclasses
(e.g., L<DNS::Unbound::IOAsync>) then the returned promise will resolve
on its own. Otherwise, L<see below|/"CUSTOM EVENT LOOP INTEGRATION">
for the methods you’ll need to use in tandem with this one.

=cut

sub resolve_async {
    my ($self, $name, $type, $class) = @_;

    die 'Need type!' if !$type;

    $type = _normalize_type_to_number($type);

    $class ||= 1;

    my $ctx = $self->{'_ub'};

    my ( $promise, $res, $rej, $deferred );

    my $query_class = $self->_load_asyncquery_if_needed();

    if ( my $deferred_cr = $query_class->_DEFERRED_CR() ) {
        $deferred = $deferred_cr->();

        $res = sub { $deferred->resolve(@_) };
        $rej = sub { $deferred->reject(@_) };

        $promise = $deferred->promise();
        bless $promise, $query_class;
    }
    else {
        $promise = $query_class->new( sub { ( $res, $rej ) = @_ } );
    }

    # We have to store this with the promise chain so that
    # the query can be canceled.
    my %dns = (
        ctx => $ctx,
        fulfilled => 0,
    );

    my $fulfilled_sr = \$dns{'fulfilled'};

    my $async_ar = $ctx->_resolve_async(
        $name, $type, $class,
        sub {
            my ($payload) = @_;

            $$fulfilled_sr = 1;

            if ( ref $payload ) {
                $res->( DNS::Unbound::Result->new( %$payload ) );
            }
            else {
                $rej->( _create_resolve_error( $payload ) );
            }
        },
    );

    if ( my $err = $async_ar->[0] ) {
        die _create_resolve_error($err);
    }

    $dns{'id'} = $async_ar->[1];

    $promise->_set_dns(\%dns);

    return $promise;
}

my $installed_cancel_cr;

sub _load_asyncquery_if_needed {

    # Not documented because it’s not yet meant for public consumption.
    my $engine = $ENV{'DNS_UNBOUND_PROMISE_ENGINE'} || $_[0]->_DEFAULT_PROMISE_ENGINE();
    $engine =~ tr<:><>d;

    my $ns = "DNS::Unbound::AsyncQuery::$engine";

    if ( !$ns->can('cancel') ) {
        local ( $@, $! );
        die if !eval "require DNS::Unbound::AsyncQuery::$engine";
    }

    $installed_cancel_cr ||= do {
        $DNS::Unbound::AsyncQuery::CANCEL_CR = \&DNS::Unbound::Context::_ub_cancel;
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

=cut

sub enable_threads {
    my ($self) = @_;

    $self->{'_ub'}->_ub_ctx_async(1);

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
    my ($self, $name, $value) = @_;

    my $err = $self->{'_ub'}->_ub_ctx_set_option( "$name:", $value );

    if ($err) {
        my $str = _get_error_string_from_number($err);
        die "Failed to set “$name” option ($value): $str";
    }

    return $self;
}

=head2 $value = I<OBJ>->get_option( $NAME )

Gets a configuration option’s value.

=cut

sub get_option {
    my ($self, $name) = @_;

    my $got = $self->{'_ub'}->_ub_ctx_get_option( $name );

    if ( !ref($got) ) {
        my $str = _get_error_string_from_number($got);
        die "Failed to get “$name” option: $str";
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
    my ($self, $level) = @_;

    $self->{'_ub'}->_ub_ctx_debuglevel( $level );

    return $self;
}

=head2 I<OBJ>->debugout( $FD_OR_FH )

Accepts a file descriptor or Perl filehandle and designates that
as the destination for libunbound diagnostic information.

Returns I<OBJ>.

=cut

sub debugout {
    my ( $self, $fd_or_fh ) = @_;

    my $fd = ref($fd_or_fh) ? fileno($fd_or_fh) : $fd_or_fh;

    my $mode = _get_fd_mode_for_fdopen($fd) or do {
        die DNS::Unbound::X->create( 'BadDebugFD', $fd, $! );
    };

    $self->{'_ub'}->_ub_ctx_debugout( $fd, $mode );

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
    my ($self, $path) = @_;

    my $err = $self->{'_ub'}->_ub_ctx_hosts( $path );

    if ($err) {
        my $str = _get_error_string_from_number($err);
        die "Failed to set hosts file: $str";
    }

    return $self;
}

sub resolvconf {
    my ($self, $path) = @_;

    my $err = $self->{'_ub'}->_ub_ctx_resolvconf( $path );

    if ($err) {
        my $str = _get_error_string_from_number($err);
        die "Failed to set stub nameservers: $str";
    }

    return $self;
}

#----------------------------------------------------------------------

=head1 CUSTOM EVENT LOOP INTEGRATION

Unless otherwise noted, the following methods correspond to their
equivalents in libunbound. They return the same values as the
libunbound equivalents.

You don’t need these if you use one of the event loop subclasses
(which is recommended).

=head2 I<OBJ>->poll()

Z<>

=cut

sub poll {
    return $_[0]->{'_ub'}->_ub_poll();
}

=head2 I<OBJ>->fd()

Z<>

=cut

sub fd {
    return $_[0]->{'_ub'}->_ub_fd();
}

=head2 I<OBJ>->wait()

Z<>

=cut

sub wait {
    return $_[0]->{'_ub'}->_ub_wait();
}

=head2 I<OBJ>->process()

Z<>

=cut

sub process {
    return $_[0]->{'_ub'}->_ub_process();
}

sub _create_process_cr {
    my $ctx = $_[0]->{'_ub'};
    return sub { $ctx->_ub_process() };
}

=head2 I<OBJ>->count_pending_queries()

Returns the number of outstanding asynchronous queries.

=cut

sub count_pending_queries {
    my ($self) = @_;

    return $self->{'_ub'}->_count_pending_queries();
}

#----------------------------------------------------------------------

=head1 METHODS FOR DEALING WITH DNSSEC

The following correspond to their equivalents in libunbound
and will only work if the underlying libunbound version supports them.

They return I<OBJ> and throw errors on failure.

=head2 I<OBJ>->add_ta( $TA )

Z<>

=cut

sub add_ta {
    my ($self, $ta) = @_;

    my $err = $self->{'_ub'}->_ub_ctx_add_ta( $ta );

    if ($err) {
        my $str = _get_error_string_from_number($err);
        die "Failed to add trust anchor: $str";
    }

    return $self;
}

=head2 I<OBJ>->add_ta_autr( $PATH )

Z<>

=cut

sub add_ta_autr {
    my ($self, $path) = @_;

    my $err = $self->{'_ub'}->_ub_ctx_add_ta_autr( $path );

    if ($err) {
        my $str = _get_error_string_from_number($err);
        die "Failed to add managed trust anchor file: $str";
    }

    return $self;
}

=head2 I<OBJ>->add_ta_file( $PATH )

Z<>

=cut

sub add_ta_file {
    my ($self, $path) = @_;

    my $err = $self->{'_ub'}->_ub_ctx_add_ta_file( $path );

    if ($err) {
        my $str = _get_error_string_from_number($err);
        die "Failed to add zone-style trust anchor file: $str";
    }

    return $self;
}

=head2 I<OBJ>->trustedkeys( $PATH )

Z<>

=cut

sub trustedkeys {
    my ($self, $path) = @_;

    my $err = $self->{'_ub'}->_ub_ctx_trustedkeys( $path );

    if ($err) {
        my $str = _get_error_string_from_number($err);
        die "Failed to add BIND-style trust anchor file: $str";
    }

    return $self;
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
    shift if ( ref $_[0] ) && ( ref $_[0] )->isa(__PACKAGE__);
    return join( '.', @{ decode_character_strings( $_[0] ) } );
}

=head2 $strings_ar = decode_character_strings($encoded)

Decodes a list of character-strings into component strings,
returned as an array reference. Useful for C<TXT> query results.

=cut

sub decode_character_strings {
    shift if ( ref $_[0] ) && ( ref $_[0] )->isa(__PACKAGE__);
    return [ unpack( '(C/a)*', $_[0] ) ];
}

#----------------------------------------------------------------------

sub DESTROY {
    my $self = shift;

    if ($$ != $self->{'_pid'}) {
        my $is_gd = ${^GLOBAL_PHASE};
        $is_gd &&= ($is_gd eq 'DESTRUCT');

        if ($is_gd) {
            warn "$self DESTROYed at global destruction; memory leak likely!";
        }
    }
}

sub _get_error_string_from_number {
    my ($err) = @_;

    if ($err) {
        return _ctx_err()->{$err} || "Unknown error code: $err";
    }

    return undef;
}

1;

=head1 LICENSE & COPYRIGHT

Copyright 2019-2021 Gasper Software Consulting.

This library is licensed under the same terms as Perl itself.

=head1 REPOSITORY

L<https://github.com/FGasper/p5-DNS-Unbound>

=head1 THANK YOU

Special thanks to L<ATOOMIC|https://metacpan.org/author/ATOOMIC> for
making some helpful review notes.
