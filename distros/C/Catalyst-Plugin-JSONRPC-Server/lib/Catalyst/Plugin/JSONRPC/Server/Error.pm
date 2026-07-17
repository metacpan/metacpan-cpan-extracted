package Catalyst::Plugin::JSONRPC::Server::Error;
use v5.36;
use Moo;
use namespace::clean;

our $VERSION = '0.003';

has code    => ( is => 'ro', required => 1 );
has message => ( is => 'ro', required => 1 );
has data    => ( is => 'ro' );

sub throw ( $class, %args ) {
    die $class->new(%args);
}

=head1 NAME

Catalyst::Plugin::JSONRPC::Server::Error - a structured JSON-RPC error

=head1 DESCRIPTION

A handler may throw one of these to return a specific JSON-RPC error from
L<Catalyst::Plugin::JSONRPC::Server::Dispatcher>.

=head1 ATTRIBUTES

=head2 code

Required. The JSON-RPC error code (an integer). The spec reserves -32768 through
-32000 for pre-defined errors, of which -32099 through -32000 are set aside for
implementation-defined server errors. Codes outside the reserved block are free
for application-defined errors.

=head2 message

Required. A short, single-sentence description of the error.

=head2 data

Optional. Any additional information about the error, as a JSON-serializable
value. Omitted from the response envelope entirely when not set.

=head1 METHODS

=head2 throw( code => $n, message => $str, data => $any )

Convenience constructor that C<die>s a new instance.

=cut

1;
