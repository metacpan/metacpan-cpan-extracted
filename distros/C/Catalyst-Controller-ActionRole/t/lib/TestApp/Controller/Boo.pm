package TestApp::Controller::Boo;

use Moose;

BEGIN { extends 'Catalyst::Controller::ActionRole'; }

__PACKAGE__->config(
    action_args => {
        foo => { boo => 'hello' },
    },
);

sub foo : Local Does('Boo') {
    my ($self, $ctx) = @_;
    my $boo = $ctx->stash->{action_boo};
    $ctx->response->body($boo);
}

1;
