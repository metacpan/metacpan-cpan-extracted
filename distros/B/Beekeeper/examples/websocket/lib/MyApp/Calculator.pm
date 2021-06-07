package MyApp::Calculator;

use strict;
use warnings;

use AnyEvent::Impl::Perl;
use Beekeeper::Client;
use Beekeeper::Config;


sub new {
    my $class = shift;

    my $self = {};

    my $config = Beekeeper::Config->read_config_file('client.config.json');

    # Connect to bus 'frontend', wich will forward requests to 'backend'
    $self->{client} = Beekeeper::Client->instance(
        bus_role   => "frontend",
        forward_to => 'backend',
        %$config,
    );

    bless $self, $class;
}

sub client {
    my $self = shift;

    return $self->{client};
}

sub eval_expr {
    my ($self, $str) = @_;

    my $resp = $self->client->call_remote(
        method => 'myapp.calculator.eval_expr',
        params => { expr => $str },
    );

    return $resp->result;
}

1;
