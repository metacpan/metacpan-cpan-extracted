package Dancer::RPCPlugin::DefaultRoute;

use Dancer ':syntax';
use Dancer::RPCPlugin::ErrorResponse;
use RPC::XML;
use RPC::XML::ParserFactory;

use Exporter 'import';
our @EXPORT = qw(setup_default_route);

my $parser = RPC::XML::ParserFactory->new();

=head1 NAME

Dancer::RPCPlugin::DefaultRoute - Catch bad-requests and send error-response

=head1 SYNOPSIS

    use Dancer::RPCPlugin::DefaultRoute;
    setup_default_route();

=head1 DESCRIPTION

Implements default endpoint to generate -32601 'method not found'
or 'path not found' error_response for non existing endpoints

=head2 setup_default_route

Installs a Dancer route-handler for C<< any qr{.+} >> which tries to return an
appropriate error response to the requestor.

=head3 Responses

All responeses will have B<status: 200 OK>

The B<content-type> (and B<body>) of the request determine the error-response:

=over

=item B<text/xml>

If the B<body> is valid XMLRPC, the response is an XMLRPC-fault:

    faultCode   => -32601
    faultString => "Method '%s' not found"

If the B<body> is I<not> valid XMLRPC, the response is an XMLRPC-fault:

    faultCode   => -32600
    faultString => "Invaild xml-rpc. Not configming to spec: $@"

=item B<application/json>

If the B<body> is valid JSONRPC (ie. is has a I<'jsonrpc': '2.0'> field/value),
the response is a JSONRPC-error:

    code => -32601
    message => "Method '%s' not found"

If the B<body> is I<not> valid JSONRPC, the response is a generic json struct:

    'error': {
        'code':  -32601,
        'message': "Method '$request->path' not found"
    }

=item B<other/content-type>

Any other content-type is outside the scope of the service. We can respond in
any way we like. For the moment it will be:

    status(404)
    content_type('text/plain')
    body => "Error! '$request->path' was not found for '$request->content_type'"

=back

=cut

sub setup_default_route {
    any qr{.+} => sub {
        my $content_type = request->content_type =~ m{(?<ct> [\w-]+ / [\w-]+ )}x
            ? $+{ct}
            : 'text/plain';

        my ($error_code, $error_message);
        if ( $content_type =~ m{^ (application|text) / xml $}x ) {
            content_type('text/xml'); # Always respond as XMLRPC

            my $request = eval { $parser->parse(request->body) };

            if ( my $error = $@ ) { # Invalid request
                $error_code = -32600;
                $error_message = "Invalid xml-rpc. Not conforming to spec: $error"
            }
            else {
                $error_code = -32601;
                $error_message = sprintf("Method '%s' not found", $request->name);
            }
            halt(
                RPC::XML::response->new(
                    RPC::XML::fault->new(
                        faultCode   => $error_code,
                        faultString => $error_message,
                    )
                )->as_string()
            );
        }
        elsif ( $content_type eq 'application/json' ) {
            content_type('application/json');

            my $request = request->body
                ? from_json(request->body, {allow_nonref => 1})
                : undef;

            if (    defined($request) and ref($request) eq 'HASH'
                and (exists $request->{jsonrpc} && $request->{jsonrpc} eq '2.0') )
            {
                $error_code = -32601;
                $error_message = sprintf("Method '%s' not found",  $request->{method});

                halt(
                    to_json(
                        {
                            jsonrpc => '2.0',
                            id      => $request->{id},
                            error   => {
                                code    => $error_code,
                                message => $error_message,
                            },
                        }
                    )
                );
            }
            else {
                halt(
                    to_json(
                        {
                            error => {
                                code    => -32601,
                                message => sprintf("Method '%s' not found", request->path)
                            }
                        }
                    )
                );
            }
        }
        status(404);
        content_type('text/plain');
        halt(
            sprintf(
                "Error! '%s' was not found for '%s'",
                request->path, request->content_type
            )
        );
    };
}

1;

=head1 COPYRIGHT

(c) MMXX - Abe Timmerman <abetim@cpan.org>

=cut
