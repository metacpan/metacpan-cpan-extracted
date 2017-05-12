package TestApp2::Controller::Root;

use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' }

# Load status messages into stash before every request
sub auto :Private {
    my ($self, $c) = @_;

    # Load status messages
    $c->load_status_msgs;

    return 1;
}


# Save status message in $msg
sub save_status_msg :Path('/save_status_msg') :Args() {
    my ($self, $c, $msg) = @_;
    $c->response->redirect($c->uri_for($self->action_for('show'),
        { my_mid => $c->set_status_msg($msg) }));
}


# Save error message in $msg
sub save_error_msg :Path('/save_error_msg') :Args() {
    my ($self, $c, $msg) = @_;
    $c->response->redirect($c->uri_for($self->action_for('show'),
        { my_mid => $c->set_error_msg($msg) }));
}


# Return status/error messages in body
sub show : Path('/show') {
    my ($self, $c) = @_;

    # Return in response body
    $c->response->body(
        "status: " . ($c->stash->{my_status_msg} || 'na') . "\n" .
        "error: "  . ($c->stash->{my_error_msg}  || 'na')
    );
}

1;
