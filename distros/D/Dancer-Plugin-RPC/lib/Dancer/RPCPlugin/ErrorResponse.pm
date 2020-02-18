package Dancer::RPCPlugin::ErrorResponse;
use warnings;
use strict;

use Exporter 'import';
our @EXPORT = qw/register_error_responses error_response/;

use Dancer::RPCPlugin::PluginNames;

use Params::Validate ':all';

my $_error_code_to_status_map = {
    xmlrpc  => {default => 200},
    jsonrpc => {default => 200},
    restrpc => {default => 500},
};

sub register_error_responses {
    shift if $_[0] eq __PACKAGE__;
    my $plugin_re = Dancer::RPCPlugin::PluginNames->new->regex;
    my ($plugin, $status_map, $handler_name, $error_handler) = validate_pos(
        @_,
        {type => SCALAR,  optional => 0, regex => $plugin_re },
        {type => HASHREF, optional => 0 },
        {type => SCALAR,  optional => 1 },
        {type => CODEREF, optional => 1 },
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

sub error_response {
    __PACKAGE__->new(@_);
}

sub new {
    my $class = shift;
    my %self = validate(
        @_,
        {
            error_code    => {optional => 0},
            error_message => {optional => 0},
            error_data    => {optional => 1},
        },
    );

    return bless(\%self, $class);
}

sub error_code    { $_[0]->{error_code} }
sub error_message { $_[0]->{error_message} }
sub error_data    { exists $_[0]->{error_data} ? $_[0]->{error_data} : undef  }

sub return_status {
    my $self = shift;
    my $check_plugins = Dancer::RPCPlugin::PluginNames->new->regex;
    my ($plugin) = validate_pos(
        @_, { regex => $check_plugins, optional => 0 }
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
            code    => $self->error_code,
            message => $self->error_message,
            ($data ? (data => $data) : ()),
        }
    };
}

1;

=head1 NAME

Dancer::RPCPlugin::ErrorResponse - Interface to pass error-responses without knowlage of the protocol

=head1 SYNOPSIS

    use Dancer::RPCPlugin::ErrorResponse;

    sub handle_rpc_call {
        ...
        return error_response(
            error_code => 42,
            error_message => 'That went belly-up',
        );
    }

=head1 DESCRIPTION

=head2 error_response(%parameters)

Factory function that retuns an instantiated L<Dancer::RPCPlugin::ErrorResponse>.

=head3 Parameters

=over

=item error_code => $error_code [required]

=item error_message => $error_message [required]

=item error_data => $error_data [optional]

=back

=head3 Responses

An instance or an exception from L<Params::ValidationCompiler>.

=head2 register_error_responses($protocol => \%error_code_to_status_map)

    register_error_responses(
        xmlrpc => {
            default => 200,
        }
    )

    register_error_responses(
        restish => {
            default => 500,
            -32700 => 400,
            -32701 => 400,
            -32702 => 400,
            -32600 => 400,
            ...
        }
    );

=cut

=head2 Dancer::RPCPlugin::ErrorResponse->new(%parameters)

=head3 Parameters

=over

=item error_code => $error_code [required]

=item error_message => $error_message [required]

=item error_data => $error_data [optional]

=back

=head3 Responses

An instance or an exception from L<Params::ValidationCompiler>.

=head2 $er->return_status

Method that returns the HTTP status code from the map provided in
C<Dancer::RPCPlugin::ErrorResponse::register_error_responses()>

=head2 $er->error_code

Getter for the C<error_code> attribute.

=head2 $er->error_message

Getter for the C<error_message> attribute.

=head2 $er->error_data

Getter for the C<error_data> attribute.

=head2 $er->as_jsonrpc_error

Returns a data-structure for the use in the C<error> field of a jsonrpc response.

=head2 $er->as_restrpc_error

Returns a data-structure like the C<error-field> in a JSONRPC2 error response.

=head2 $er->as_xmlrpc_fault

Returns a data-structure for the use as a C<fault> response in XMLRPC.

=head1 COPYRIGHT

(c) MMXVII - Abe Timmerman <abetim@cpan.org>

=cut
