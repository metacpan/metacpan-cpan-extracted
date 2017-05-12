package App::CamelPKI::View::JSON;

use strict;
use base 'Catalyst::View::JSON';

=head1 NAME

App::CamelPKI::View::JSON - the view used to throw data to an AJAX client
or any other RPC client.

=head1 SYNOPSIS

=head1 DESCRIPTION

This package is a (trivial for now) subclass of L<Catalyst::View>.
It allow to send a Perl data structure to an HTTP client, using
L<JSON> encoding format.

=cut

1;
