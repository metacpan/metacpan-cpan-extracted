#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 18;

BEGIN {
    $ENV{PERL_ANYEVENT_VERBOSE} = 1;
    $ENV{PERL_ANYEVENT_STRICT} = 1;
    $ENV{PERL_ANYEVENT_MODEL} = 'EV';
    $ENV{PERL_ANYEVENT_AVOID_ASYNC_INTERRUPT} = 1;
}

use AnyEvent;
use AnyEvent::Handle;
use AnyEvent::Util;

use AnyEvent::SCGI;

my $ticker = AE::timer 1,1,sub { diag "tick\n" };
my $z = "\0"; # to prevent interpolation

run_test(
    "CONTENT_LENGTH${z}27${z}SCGI${z}1${z}". # headers
    "REQUEST_METHOD${z}POST${z}".
    "REQUEST_URI${z}/deepthought${z}",

    "What is the answer to life?", # content

    { # expected env
        SCGI => 1,
        REQUEST_METHOD => 'POST',
        CONTENT_LENGTH => 27,
        REQUEST_URI => '/deepthought',
    },
);

run_test(
    "CONTENT_LENGTH${z}0${z}SCGI${z}1${z}". # headers
    "REQUEST_METHOD${z}GET${z}".
    "REQUEST_URI${z}/deepthought${z}",

    undef, # content empty since C-L is zero

    { # expected env
        SCGI => 1,
        REQUEST_METHOD => 'GET',
        CONTENT_LENGTH => 0,
        REQUEST_URI => '/deepthought',
    },
);

sub run_test {
    my $headers = shift;
    my $content = shift;
    my $expected_env = shift;

    my ($server_fh,$scgi_fh) = portable_socketpair();

    ok $server_fh && $scgi_fh, 'set up socketpair';

    my $server_done = AE::cv;
    my $server = AnyEvent::Handle->new(
        fh => $server_fh,
        no_delay => 1,
        on_error => sub { 
            $server_done->croak("server error $_[1]");
        },
        on_eof => sub { $server_done->send },
    );
    ok $server, 'made a server handle';

    {
        my $netstring = length($headers).":$headers,";
        $netstring .= $content if $content;
        $server->push_write($netstring);
    }

    {
        $server->push_read(line => "\r\n", sub {
            is $_[1], 'any old response', 'expected response';
            $server_done->send;
        });
        pass 'set up server read';
    }

    {
        AnyEvent::SCGI::handle_scgi($scgi_fh, "foo", "666", sub {
            my ($h, $env, $content_ref, $fatal, $error) = @_;

            ok (!$error, 'no error') or diag "server got error '$error'";

            is_deeply $env, $expected_env, 'correctly decoded env';
            is $$content_ref, $content, 'correct content';

            $h->push_write("any old response\r\n");
            $h->push_shutdown;
        });
        pass 'set up callback';
    }

    $server_done->recv;
    pass 'all finished';

}

exit 0;
