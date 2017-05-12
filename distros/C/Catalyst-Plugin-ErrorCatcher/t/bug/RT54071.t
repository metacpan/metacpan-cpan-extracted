#!perl
# vim: ts=8 sts=4 et sw=4 sr sta
use strict;
use warnings;

BEGIN {
    use FindBin::libs;
}

use Test::More 0.92;
use Sys::Hostname;

# hacky, but this stops us actually trying to send emails
use MIME::Lite;
*MIME::Lite::send = *MIME::Lite::as_string;

BEGIN {
    $ENV{ NOAUTH_CONFIG } = "$FindBin::Bin/../lib/testapp.conf";
}

use Catalyst::Test 'NoAuth';

# testing RT#54071
# if the patch is not applied we don't get any error cather message
# if it is, we do, and all is well
{
    eval "require Catalyst::Plugin::ErrorCatcher::Email";
    is( $@, q{}, "no require errors" );

    # make a request; we need an error to get the stacktrace
    open STDERR, '>/dev/null'; # hide errors
    ok( my ($res,$c) = ctx_request('http://localhost/foo/not_ok'), 'request ok' );

    my $ec_msg;
    eval{ $ec_msg = $c->_errorcatcher_msg };
    ok( defined $ec_msg, 'parsed error message ok' );
}


done_testing;
