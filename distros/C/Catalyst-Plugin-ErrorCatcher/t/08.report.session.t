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
    $ENV{ TESTAPP_CONFIG } = "$FindBin::Bin/lib/testapp-session.conf";
}

use Catalyst::Test 'TestApp';

# RT-64492 - check no session data in default report
TestApp->config->{stacktrace}{enable} = 1;
TestApp->config->{"Plugin::ErrorCatcher"}{enable} = 1;
{
    my ($res,$c);

    ok( ($res,$c) = ctx_request('http://localhost/foo/ok'), 'request ok' );
    ok( ($res,$c) = ctx_request('http://localhost/foo/not_ok'), 'request ok' );
    my $ec_msg;
    eval{ $ec_msg = $c->_errorcatcher_msg };
    ok( defined $ec_msg, 'parsed error message ok' );
    foreach my $session_key (qw/__created __updated/) {
        like(
            $ec_msg,
            qr{__created},
            "found instances of '$session_key' in report"
        );
    }
}



done_testing;
