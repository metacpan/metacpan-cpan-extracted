package MyApp::Service::Calculator::Worker;

use strict;
use warnings;

use Beekeeper::Worker ':log';
use base 'Beekeeper::Worker';


sub authorize_request {
    my ($self, $req) = @_;

    return BKPR_REQUEST_AUTHORIZED;
}

sub on_startup {
    my $self = shift;

    $self->accept_remote_calls(
        'myapp.calculator.eval_expr' => 'eval_expr',
    );

    log_info "Ready";
}

sub on_shutdown {
    my $self = shift;

    log_info "Stopped";
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
        die "Died while processing '$expr': $@";
    }

    return $result;
}

1;
