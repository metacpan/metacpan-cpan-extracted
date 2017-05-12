package Ark::Plugin::Session::State::URI::ExtendContext;
use strict;
use warnings;
use Ark::Plugin;

around uri_for => sub {
    my $next      = shift;
    my ($context) = @_;

    my $session = $context->session;

    if ($session->uri_for_override && (my $sid = $session->uri_session_id)) {
        my $uri = $next->(@_);

        my %p = $uri->query_form;
        $p{ $session->uri_query } = $sid;

        $uri->query_form(%p);

        return $uri;
    }

    $next->(@_);
};

1;
