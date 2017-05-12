package TestApp::ActionRole::First;

use Moose::Role;

after execute => sub {
    my ($self, $controller, $c) = @_;

    my @current_body = $c->response->body ?
        split(/,/, $c->response->body) : ();

    push @current_body, __PACKAGE__;

    $c->response->body( join(',', sort @current_body) );

    my $times_executed = $c->response->header('X-Executed-Times') || 0;
    $c->response->header( 'X-Executed-Times' => ++$times_executed );
};

1;
