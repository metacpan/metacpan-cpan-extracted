package MyApp::Calculator;

use strict;
use warnings;

use Beekeeper::Client;


sub new {
    my $class = shift;

    my $self = {};

    $self->{client} = Beekeeper::Client->instance(
        bus_id     => 'frontend', 
        forward_to => 'backend',
    );

    bless $self, $class;
}

sub client {
    my $self = shift;

    return $self->{client};
}

sub eval_expr {
    my ($self, $str) = @_;

    my $resp = $self->client->do_job(
        method => 'myapp.calculator.eval_expr',
        params => { expr => $str },
    );

    return $resp->result;
}

1;
