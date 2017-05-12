package RewritingTestApp;

use strict;
use Catalyst qw/
    Session
    Session::Store::Dummy
    Session::State::URI
    Session::State::Cookie
/;

__PACKAGE__->config(
    name => __PACKAGE__,
    home => "/",
    session => {
        rewrite_body => 1,
        rewrite_redirect => 1,
        no_rewrite_if_cookie => 1, # FIXME better name
        rewrite_types => [qw{ text/html }],
    }
);

__PACKAGE__->setup;

1;
