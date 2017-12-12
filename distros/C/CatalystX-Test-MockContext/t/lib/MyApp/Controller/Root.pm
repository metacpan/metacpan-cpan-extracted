package MyApp::Controller::Root;
use Moose;

BEGIN { extends 'Catalyst::Controller' }

my $Count = 1;

sub root :Chained('/') PathPart('') Args(0) {
    my ($self, $c) = @_;
    $c->stash(
        count => $Count++,
    );
    $c->res->body('root');
}

1;
