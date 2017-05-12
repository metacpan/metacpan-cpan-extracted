package # Hide from PAUSE
  StompTestApp::Controller::TestJsonController;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller::MessageDriven' };

__PACKAGE__->config( serializer => 'JSON' );

sub testaction : Local {
    my ($self, $c, $request) = @_;

    # Reply with a minimal response message
    my $response = { type => 'testaction_response' };
    $c->stash->{response} = $response;
}

1;
