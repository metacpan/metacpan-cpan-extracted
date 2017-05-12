package # Hide from PAUSE
  StompTestApp::Controller::TestKeyController;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller::MessageDriven' };

has '+type_key' => (
    default => undef,
);
has '+trust_jmstype' => (
    default => 1,
);

sub my_type : Local {
    my ($self, $c, $body, $headers) = @_;

    # Reply with a minimal response message
    my $response = {
        I_got => $headers->header('I_sent'),
    };
    $c->response->headers->header(type => 'my_type_response');
    $c->stash->{response} = $response;
}

1;
