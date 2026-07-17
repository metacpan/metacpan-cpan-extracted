package Catalyst::Plugin::JSONRPC::Server::Dispatcher;
use v5.36;
use Moo;
use JSON::MaybeXS ();
use Try::Tiny;
use Carp qw/croak/;
use Scalar::Util qw/blessed/;
use Catalyst::Plugin::JSONRPC::Server::Error;
use namespace::clean;

our $VERSION = '0.003';

=encoding utf8

=head1 NAME

Catalyst::Plugin::JSONRPC::Server::Dispatcher - pure JSON-RPC 2.0 protocol engine

=head1 DESCRIPTION

The Catalyst-free engine behind L<Catalyst::Plugin::JSONRPC::Server>: it parses
and validates JSON-RPC 2.0 envelopes (single and batch), routes to registered
handlers, and produces spec-compliant result/error responses. It has no
knowledge of Catalyst or of any application domain.

=cut

has _handlers => ( is => 'ro', default => sub { {} } );
has _json => (
    is      => 'lazy',
    builder => sub { JSON::MaybeXS->new( utf8 => 1, canonical => 1 ) },
);

# Maximum number of elements accepted in a batch array; 0 = unlimited. A finite
# default caps the trivial amplification of a huge batch in one small body,
# while staying generous enough for any realistic client.
has max_batch => ( is => 'ro', default => 1000 );

sub register ( $self, $method, $code ) {
    croak "JSON-RPC method must be a non-empty string"
        if !defined $method || ref $method || !length $method;
    croak "JSON-RPC handler must be a CODE ref"
        unless ref $code eq 'CODE';
    $self->_handlers->{$method} = $code;
    return $self;
}

sub encode ( $self, $data ) {
    return $self->_json->encode($data);
}

# Like encode(), but never dies on a non-serializable value. A handler that
# returns something the JSON codec can't encode (a blessed object without
# TO_JSON, a coderef, a cyclic structure) would otherwise die here, outside the
# per-handler try/catch, and 500 the whole request/batch. Instead, salvage: any
# response element that won't encode is replaced by a -32603 (its id preserved),
# so one bad result can't take down the others.
sub encode_safe ( $self, $data ) {
    my $text = try { $self->_json->encode($data) } catch { undef };
    return $text if defined $text;
    my $safe = ref $data eq 'ARRAY'
        ? [ map { $self->_encodable_or_error($_) } @$data ]
        : $self->_encodable_or_error($data);
    return $self->_json->encode($safe);
}

sub _encodable_or_error ( $self, $resp ) {
    return $resp if try { $self->_json->encode($resp); 1 } catch { 0 };
    my $id = ref $resp eq 'HASH' ? $resp->{id} : undef;
    return { jsonrpc => '2.0',
        error => { code => -32603, message => 'Internal error' }, id => $id };
}

# Returns: hashref (single), arrayref (batch), or undef (nothing to send).
sub dispatch ( $self, $json_text ) {
    my $decoded;
    my $parsed = try { $decoded = $self->_json->decode($json_text); 1 }
                 catch { 0 };
    return $self->_error( undef, -32700, 'Parse error' ) unless $parsed;

    if ( ref $decoded eq 'ARRAY' ) {
        return $self->_error( undef, -32600, 'Invalid Request' )
            unless @$decoded;
        return $self->_error( undef, -32600, 'Batch too large' )
            if $self->max_batch && @$decoded > $self->max_batch;
        my @out = grep { defined } map { $self->_handle_one($_) } @$decoded;
        return @out ? \@out : undef;
    }

    return $self->_handle_one($decoded);
}

# One already-decoded request element -> response hashref or undef (notification)
sub _handle_one ( $self, $req ) {
    return $self->_error( undef, -32600, 'Invalid Request' )
        unless ref $req eq 'HASH';

    my $is_note = !exists $req->{id};
    my $id      = $req->{id};    # undef for notifications; may be a JSON null

    # Envelope validation. `id`, if present, must be a scalar (String/Number/
    # Null): a structured id is malformed. `params`, if present, must be a
    # structured value OR an explicit null (which we treat as "no params",
    # passing undef to the handler).
    my $valid =
           defined $req->{jsonrpc} && $req->{jsonrpc} eq '2.0'
        && defined $req->{method}  && !ref $req->{method}
        && ( $is_note || !ref $id )
        && ( !exists $req->{params}
             || !defined $req->{params}
             || ref $req->{params} eq 'ARRAY'
             || ref $req->{params} eq 'HASH' );
    unless ($valid) {
        # A structurally-invalid element is NOT a notification even when it has
        # no id, so it still gets a -32600 (per the JSON-RPC 2.0 examples). The
        # reply id is the request id when that is a usable scalar, else null (a
        # structured or absent id can't be echoed).
        return $self->_error( ( ref $id ? undef : $id ), -32600, 'Invalid Request' );
    }

    my $handler = $self->_handlers->{ $req->{method} };
    unless ($handler) {
        return undef if $is_note;
        return $self->_error( $id, -32601, 'Method not found' );
    }

    my ( $result, $err );
    try   { $result = $handler->( $req->{params} ) }
    catch { $err = $_ };

    if ( defined $err ) {
        return undef if $is_note;
        my ( $code, $message, $data ) = $self->_normalize_error($err);
        return $self->_error( $id, $code, $message, $data );
    }

    return undef if $is_note;
    return { jsonrpc => '2.0', result => $result, id => $id };
}

sub _error ( $self, $id, $code, $message, $data = undef ) {
    my %err = ( code => $code, message => $message );
    $err{data} = $data if defined $data;
    return { jsonrpc => '2.0', error => \%err, id => $id };
}

# Map a thrown value to (code, message, data). A plain die, or any unrecognised
# blessed object, becomes -32603 and the original text is NOT leaked to the
# client (only a typed ::Error or a { code, ... } hashref sets a specific code).
sub _normalize_error ( $self, $err ) {
    if ( blessed $err && $err->isa('Catalyst::Plugin::JSONRPC::Server::Error') ) {
        return ( $err->code, $err->message, $err->data );
    }
    if ( ref $err eq 'HASH' && defined $err->{code} ) {
        return ( $err->{code}, $err->{message} // 'Error', $err->{data} );
    }
    return ( -32603, 'Internal error', undef );
}

=head1 METHODS

=head2 register( $method => $coderef )

Register a handler for a JSON-RPC method name (a non-empty string). The handler
is invoked as C<< $coderef->($params) >>. Return the result; to signal a
JSON-RPC error throw a L<Catalyst::Plugin::JSONRPC::Server::Error> (or C<die>
with a C<< { code, message, data } >> hashref). A plain C<die>, or any
unrecognised exception, becomes C<-32603> and its text is not leaked. Croaks on
a bad method name or non-coderef handler. Returns the dispatcher (chainable).

=head2 dispatch( $json_text )

Parse and dispatch a JSON-RPC 2.0 request (a single object or a batch array).
Returns a response hashref for a single call, an arrayref for a batch, or
C<undef> when there is nothing to send (a lone notification or an
all-notification batch). Never dies: malformed JSON yields a C<-32700>
parse-error response.

=head2 encode( $data )

Encode a response data structure to canonical UTF-8 JSON text. Dies if C<$data>
contains a value the JSON codec cannot serialize; prefer
L<< C<encode_safe>|/"encode_safe( $data )" >> for
untrusted handler output.

=head2 encode_safe( $data )

Like L<< C<encode>|/"encode( $data )" >>, but never dies: any response element
that will not serialize
(a blessed object without C<TO_JSON>, a coderef, a cyclic structure) is replaced
by a C<-32603> "Internal error" (its id preserved), so one bad handler result
cannot 500 the whole request or corrupt a batch.

=head1 ATTRIBUTES

=head2 max_batch

Maximum number of elements accepted in a batch array (default 1000; C<0> =
unlimited). A batch beyond this is rejected with a single C<-32600> "Batch too
large".

=cut

1;
