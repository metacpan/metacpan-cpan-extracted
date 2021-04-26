package MyApp::Service::Calculator;

use strict;
use warnings;

use Beekeeper::Worker;
use base 'Beekeeper::Worker';


sub on_startup {
    my $self = shift;

    $self->accept_jobs(
        'myapp.calculator.eval_expr' => 'eval_expr',
    );
}

sub authorize_request {
    my ($self, $req) = @_;

    return REQUEST_AUTHORIZED;
}

sub eval_expr {
    my ($self, $params) = @_;

    my $expr = $params->{"expr"};

    unless (defined $expr) {
        # Explicit error response. It will be not logged
        return Beekeeper::JSONRPC->error( message => 'No expression given' );
    }

    ($expr) = $expr =~ m/^([ \d \. \+\-\*\/ ]*)$/x;

    unless (defined $expr) {
        # Throw a handled exception. It will be not logged
        die Beekeeper::JSONRPC->error( message => 'Invalid expression' );
    }

    my $result = eval $expr;

    if ($@) {
        # Throw an unhandled exception which will be automatically logged
        # The client will receive a generic error response (try division by zero)
        die $@;
    }

    return $result;
}

1;
