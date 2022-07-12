package Dancer2::RPCPlugin::ErrorResponse;
use Moo;

with qw(
    Dancer2::RPCPlugin::ValidationTemplates
    MooX::Params::CompiledValidators
);

our $VERSION = '2.00';

use Dancer2::RPCPlugin::PluginNames;

use Exporter 'import';
our @EXPORT = qw/error_response/;

my $_error_code_to_status_map = {
    xmlrpc  => {default => 200},
    jsonrpc => {default => 200},
    restrpc => {default => 500},
};

sub error_response { __PACKAGE__->new(@_) }

has error_code => (
    is       => 'ro',
    required => 1
);
has error_message => (
    is       => 'ro',
    required => 1
);
has error_data => (
    is       => 'ro',
    required => 0
);

sub register_error_responses {
    my $self = $_[0] eq __PACKAGE__
        ? shift
        : __PACKAGE__;
    $self->validate_positional_parameters(
        [
            $self->parameter(protocol      => $self->Required, {store => \my $plugin}),
            $self->parameter(status_map    => $self->Required, {store => \my $status_map}),
            $self->parameter(handler_name  => $self->Optional, {store => \my $handler_name}),
            $self->parameter(error_handler => $self->Optional, {store => \my $error_handler}),
        ],
        \@_
    );

    # maybe this is an update, so only touch the values mentioned
    for my $error_code (keys %$status_map) {
        $_error_code_to_status_map->{$plugin}{$error_code} = $status_map->{$error_code};
    }

    if (@_ > 2 && ref($error_handler) eq 'CODE') {
        no strict 'refs';
        *{"$handler_name"} = $error_handler;
    }
}

sub return_status {
    my $self = shift;
    my $check_plugins = Dancer2::RPCPlugin::PluginNames->new->regex;
    $self->validate_positional_parameters(
        [ $self->parameter(protocol => $self->Required, {store => \my $plugin}) ],
        \@_
    );

    my $default = $_error_code_to_status_map->{$plugin}{default} // 200;
    my $http_status = $_error_code_to_status_map->{$plugin}
                    ->{ $self->error_code } // $default;

    return $http_status;
}

sub as_xmlrpc_fault {
    my $self = shift;
    return {
        faultCode   => $self->error_code,
        faultString => $self->error_message,
    };
}

sub as_jsonrpc_error {
    my $self = shift;

    my $data = $self->error_data;
    return {
        error => {
            code    => $self->error_code,
            message => $self->error_message,
            ($data ? (data => $data) : ()),
        }
    };
}

sub as_restrpc_error {
    my $self = shift;

    my $data = $self->error_data;
    return {
        error => {
            code => $self->error_code,
            message => $self->error_message,
            ($data ? (data => $data) : ()),
        }
    };
}


1;

=head1 NAME

Dancer2::RPCPlugin::ErrorResponse - Interface to pass error-responses without knowlage of the protocol

=head1 SYNOPSIS

    use Dancer2::RPCPlugin::ErrorResponse;

    sub handle_rpc_call {
        ...
        return error_response(
            error_code => 42,
            error_message => 'That went belly-up',
        );
    }

=head1 DESCRIPTION

=head2 error_response(%parameters) [EXPORTED]

Factory function that retuns an instantiated L<Dancer2::RPCPlugin::ErrorResponse>.

=head3 Parameters

=over

=item error_code => $error_code [required]

=item error_message => $error_message [required]

=item error_data => $error_data [optional]

=back

=head3 Responses

An instance or an exception from L<Moo>.

=head2 register_error_responses(@parameters)

This method makes it posible to extend the RPC-plugin system with ones own error handlers.

=head3 Parameters

Positional:

=over

=item 1. $plugin [Required]

One the registered RPC-plugins.

=item 2. $status_map [Required]

A hashref with a mapping between error-codes produced by this RPC-prototcol and
the HTTP-return status codes. There is a special code value C<default> that is
used for unregistered error-codes.

=item 3. $handler_name [Optional]

This is the name of the error handler one wants to add to this class.

=item 4. $error_handler [Optional]

This is a C<CodeRef> for the error handler one wants to add for the new RPC-protocol.

=back

=head2 Dancer2::RPCPlugin::ErrorResponse->new(%parameters)

=head3 Parameters

=over

=item error_code => $error_code [required]

=item error_message => $error_message [required]

=item error_data => $error_data [optional]

=back

=head3 Responses

An instance or an exception from L<Moo>.

=head2 $er->error_code

Getter for the C<error_code> attribute.

=head2 $er->error_message

Getter for the C<error_message> attribute.

=head2 $er->error_data

Getter for the C<error_data> attribute.

=head2 $er->return_status

Returns the HTTP return status code for this error-code.

=head2 $er->as_jsonrpc_error

Returns a data-structure for the use in the C<error> field of a jsonrpc response.

=head2 $er->as_xmlrpc_fault

Returns a data-structure for the use as a C<fault> response in XMLRPC.

=head2 $er->as_restrpc_error

Returns a data-structure like the C<error-field> in a JSONRPC2 error response.

=head1 COPYRIGHT

(c) MMXVII - Abe Timmerman <abetim@cpan.org>

=cut
