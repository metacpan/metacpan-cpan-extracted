package TestApp2::Controller::Root;

use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' }


# Save status message in $msg
sub with_session :Path('/with_session') :Args() {
    my ($self, $c) = @_;
    
    my $redir = $c->request->params->{redir} || 'show';
    
    $c->response->redirect($c->uri_for($self->action_for($redir),
        { $c->sm_get_token_param() => $c->sm_session({ message => 'Test message', type => 'success'},{ message => 'Test message', type => 'danger'}) }));
}


# Save error message in $msg
sub with_stash :Path('/with_stash') :Args() {
    my ($self, $c, $msg) = @_;
    
    $c->sm_stash({ message => 'Test message', type => 'info'},{ message => 'Test message', type => 'warning'});
    
    $c->detach(qw/Controller::Root show/)
}


# Return status/error messages in body
sub show : Path('/show') {
    my ($self, $c) = @_;

    # Return in response body
    my $body = '';
    foreach my $msg (@{ $c->sm_get() }) {
        $body .= 'message: ' . ( $msg->{message} || 'na') . "\n" .
            'type: ' . ( $msg->{type} || 'na') . "\n\n";        
    }
    $c->response->body($body || 'NA');
}

1;
