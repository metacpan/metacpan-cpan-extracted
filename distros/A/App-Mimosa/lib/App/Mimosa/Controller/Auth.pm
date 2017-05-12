package App::Mimosa::Controller::Auth;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' }

sub authentication :Path('/authenticate') {
    my ( $self, $c ) = @_;

    my $user     = $c->req->params->{user};
    my $password = $c->req->params->{password};

    if ( $user && $password ) {
        if ( $c->authenticate( { username => $user,
                                password => $password } ) ) {
            $c->forward('/show_grid');
        } else {
            $c->stash->{error} = 'Incorrect username/password. Please <a href="/">try again</a>.';
            $c->detach('/input_error');
        }
    } else {
        $c->stash->{error} = 'You must provide both a username and password. Please <a href="/">try again</a>.';
        $c->detach('/input_error');
    }
}

1;
