package DNS::Unbound;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

DNS::Unbound - libunbound in Perl

=head1 SYNOPSIS

    my $dns = DNS::Unbound->new()->set_option( verbosity => 2 );

    my $verbosity = $dns->get_option( 'verbosity' );

    $dns->set_option( verbosity => 1 + $verbosity );

Synchronous queries:

    my $res_hr = $dns->resolve( 'cpan.org', 'NS' );

    # See below about encodings in “data”.
    my @ns = map { $dns->decode_name($_) } @{ $res_hr->{'data'} };

Asynchronous queries use L<the “Promise” pattern|https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Using_promises>:

    my $query1 = $dns->resolve_async( 'usa.gov', 'A' )->then(
        sub { my $data = shift()->{'data'}; ... },  # success handler
        sub { ... },                                # failure handler
    );

    my $query2 = $dns->resolve_async( 'in-addr.arpa', 'NS' )->then(
        sub { ... },
        sub { ... },
    );

    # As an alternative to wait(), see below for documentation on
    # the fd(), poll(), and process() methods.

    $dns->wait();

=cut

=head1 DESCRIPTION

This library is a Perl interface to NLNetLabs’s widely-used
L<Unbound|https://nlnetlabs.nl/projects/unbound/> recursive DNS resolver.

=cut

#----------------------------------------------------------------------

use XSLoader ();

use DNS::Unbound::X ();

our ($VERSION);

BEGIN {
    $VERSION = '0.07';
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
    return bless {
        _ub => _create_context(),
        _pid => $$,
    }, shift();
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

Also B<NOTE:> libunbound’s facilities for timing out a synchronous query
are rather lackluster. If that’s relevant for you, you probably want
to use C<resolve_async()> instead.

=cut

sub resolve {
    my $type = $_[2] || die 'Need type!';
    $type = RR()->{$type} || $type;

    my $result = _resolve( $_[0]->{'_ub'}, $_[1], $type, $_[3] || () );

    if (!ref($result)) {
        die DNS::Unbound::X->create('ResolveError', number => $result, string => _ub_strerror($result));
    }

    return $result;
}

#----------------------------------------------------------------------

=head2 $query = I<OBJ>->resolve_async( $NAME, $TYPE [, $CLASS ] );

Like C<resolve()> but starts an asynchronous query rather than a
synchronous one.

This returns an instance of C<DNS::Unbound::AsyncQuery>, which
subclasses L<Promise::ES6>. You may C<cancel()> this promise object.
The promise resolves with either the same hash reference as
C<resolve()> returns, or it rejects with a L<DNS::Unbound::X> instance
that describes the failure.

=cut

sub resolve_async {
    my $type = $_[2] || die 'Need type!';
    $type = RR()->{$type} || $type;

    # Prevent memory leaks.
    my $ctx = $_[0]->{'_ub'};
    my $name = $_[1];
    my $class = $_[3] || 1;

    my ($res, $rej);

    my $query = DNS::Unbound::AsyncQuery->new( sub {
        ($res, $rej) = @_;
    } );

    # This hash maintains the query state across all related promise objects.
    my %dns = (
        res => $res,
        rej => $rej,
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
        die DNS::Unbound::X->create('ResolveError', number => $err, string => _ub_strerror($err));
    }

    my $query_id = $async_ar->[1];

    $dns{'id'} = $query_id;

    $query->_set_dns(\%dns);

    $_[0]->{'_queries_hr'}{ $query_id } = $query;

    return $query;
}

#----------------------------------------------------------------------

=head2 I<OBJ>->enable_threads()

Sets I<OBJ>’s asynchronous queries to use threads rather than forking.
Off by default. Throws an exception if called after an asynchronous query has
already been sent.

Returns I<OBJ>.

B<NOTE:> Perl’s relationship with threads is … complicated.
This option is not well-tested. If in doubt, just skip it.

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

=cut

sub set_option {
    my $err = _ub_ctx_set_option( $_[0]->{'_ub'}, "$_[1]:", $_[2] );

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
    my $got = _ub_ctx_get_option( $_[0]->{'_ub'}, $_[1] );

    if (!ref($got)) {
        my $str = _ctx_err()->{$got} || "Unknown error code: $got";
        die "Failed to get “$_[1]”: $str";
    }

    return $$got;
}

#----------------------------------------------------------------------

=head2 I<OBJ>->debuglevel( $LEVEL )

Sets the debug level (an integer). Returns I<OBJ>.

As of libunbound v1.9.2, this is just a way to set the C<verbosity>
option after configuration is finalized.

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

=head1 METHODS FOR DEALING WITH ASYNCHRONOUS QUERIES

The following methods correspond to their equivalents in libunbound:

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

#----------------------------------------------------------------------

sub _check_promises {
    my ($self) = @_;

    if ( my $asyncs_hr = $self->{'_queries_hr'} ) {
        for (values %$asyncs_hr) {
            my $dns_hr = $_->_get_dns();

            if (defined $dns_hr->{'value'}) {
                delete $asyncs_hr->{ $dns_hr->{'id'} };

                my $key;

                if ( ref $dns_hr->{'value'} ) {
                    $key = 'res';
                }
                else {
                    $key = 'rej';

                    $dns_hr->{'value'} = DNS::Unbound::X->create('ResolveError', number => $dns_hr->{'value'}, string => _ub_strerror($dns_hr->{'value'}));
                }

                $dns_hr->{'fulfilled'} ||= do {
                    eval { $dns_hr->{$key}->($dns_hr->{'value'}) };
                    1;
                };
            }
        }
    }

    return;
}

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
    $_[0]->{'_destroyed'} ||= $_[0]->{'_ub'} && do {
        if ($$ == $_[0]->{'_pid'}) {
            if (my $queries_hr = $_[0]->{'_queries_hr'}) {
                $_->_forget_dns() for values %$queries_hr;
                %$queries_hr = ();
            }
        }

        _destroy_context( delete $_[0]->{'_ub'} );

        1;
    };
}

#----------------------------------------------------------------------
{
    package DNS::Unbound::AsyncQuery;

    use parent qw( Promise::ES6 );

    sub then {
        my $self = shift;

        my $new = $self->SUPER::then(@_);

        $new->{'_dns'} = $self->{'_dns'};

        return $new;
    }

    sub cancel {
        my ($self) = @_;

        my $dns_hr = $self->{'_dns'};

        if (!$dns_hr->{'fulfilled'}) {
            if (my $ctx = delete $dns_hr->{'ctx'}) {
                DNS::Unbound::_ub_cancel( $ctx, $dns_hr->{'id'} );
            }
        }

        return;
    }

    # ----------------------------------------------------------------------
    # Interfaces for DNS::Unbound to interact with the query’s DNS state:

    sub _set_dns {
        my ($self, $dns_hr) = @_;
        $self->{'_dns'} = $dns_hr;
        return $self;
    }

    sub _get_dns {
        return $_[0]->{'_dns'};
    }

    sub _forget_dns {
        delete $_[0]->{'_dns'};
        return $_[0];
    }
}

#----------------------------------------------------------------------

1;

=head1 REPOSITORY

L<https://github.com/FGasper/p5-DNS-Unbound>

=head1 THANK YOU

Special thanks to L<ATOOMIC|https://metacpan.org/author/ATOOMIC> for
making some helpful review notes.
