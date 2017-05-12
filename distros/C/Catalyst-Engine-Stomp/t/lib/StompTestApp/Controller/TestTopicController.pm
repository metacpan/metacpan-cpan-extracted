package # Hide from PAUSE
  StompTestApp::Controller::TestTopicController;
use Moose;
use namespace::autoclean;
use Encode;

BEGIN { extends 'Catalyst::Controller::MessageDriven' };

sub action_namespace { 'topic/testcontroller' }

=head1 testutf8()

Return a datastructure containing a string that has a character that
needs to be encoded into utf-8 when sent via STOMP

=cut

sub testutf8 : Local {
    my ($self, $c, $request) = @_;

    my $new_string   = "Maria van Bourgondiëlaan";
    Encode::_utf8_on($new_string); # this is now how we get things from XML::Compile which deals with XML in utf-8 encoding

    # Reply with a minimal response message
    my $response = {
        type   => 'testutf8_response',
        struct => [
            { foo         => 'bar' },
            { new_string  => $new_string },
        ],
    };
    $c->stash->{response} = $response;
}


sub testaction : Local {
    my ($self, $c, $request) = @_;

    # Reply with a minimal response message
    my $response = { type => 'testaction_response' };
    $c->stash->{response} = $response;
}

sub badaction : Local {
    my ($self, $c, $request) = @_;
    die "oh noes";
}

sub throwerror : Local {
    my ($self, $c, $request) = @_;
    my $obj = bless {error => 'oh noes'}, 'StompTestApp::Error';
    die $obj;
}

sub ping : Local {
    my ($self, $c, $request) = @_;
    if ($request->{type} eq 'ping') {
	    $c->stash->{response} = { status => 'PONG' };
	    return;
    }
    die "not a ping request?";
}

1;
