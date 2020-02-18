package SOMERPC;
use warnings;
use strict;

use Dancer::RPCPlugin::PluginNames;
use Dancer::RPCPlugin::ErrorResponse;

my $pn = Dancer::RPCPlugin::PluginNames->new();
$pn->add_names('somerpc');

Dancer::RPCPlugin::ErrorResponse->register_error_responses(
    somerpc => {
        default => 500,
        -32700  => 400,
        -32600  => 400,
        -32601  => 403,
    },
    as_somerpc_fault => sub {
        my $self = shift;
        return { error_message => $self->error_message };
    },
);

1;
