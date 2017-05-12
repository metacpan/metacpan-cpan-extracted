#!perl

use strict;
use warnings;

use FindBin::libs;
use Test::More;

use Catalyst::Test 'TestApp';

open STDERR, '>/dev/null';

# test that a normal action executes ok
{
    ok( my $res = request('http://localhost/foo/ok'), 'request ok' );
    is( $res->content, 'ok', 'response ok' );
}

# test that a crashed action prints the appropriate debug screen
{
    ok( my $res = request('http://localhost/foo/not_ok'), 'request ok' );
    like( $res->content, qr{Caught exception.+TestApp::Controller::Foo::three}, 'error ok' );
    like( $res->content, qr{Stack Trace}, 'trace ok' );
    like( $res->content, qr{<td>30</td>}, 'line number ok' );
    like( $res->content, qr{<strong class="line">   30:     three\(\);}, 'context ok' );
}

TestApp->config->{stacktrace}{enable} = 0;
{
    ok( my $res = request('http://localhost/foo/not_ok'), 'request ok' );
    like( $res->content, qr{Caught exception.+TestApp::Controller::Foo::three}, 'error ok' );
    unlike( $res->content, qr{Stack Trace}, 'trace disable' );
}

# check output with stacktrace
TestApp->config->{stacktrace}{enable} = 1;
TestApp->config->{"Plugin::ErrorCatcher"}{enable} = 1;
{
    ok( my ($res,$c) = ctx_request('http://localhost/foo/not_ok'), 'request ok' );
    my $ec_msg;
    eval{ $ec_msg = $c->_errorcatcher_msg };
    ok( defined $ec_msg, 'parsed error message ok' );

    # everything should start with 'Exception caught'
    like (
        $ec_msg,
        qr{\AException caught:},
        'parsed error starts correctly'
    );

    # make sure the parsed error looks sane
    like(
        $ec_msg,
        qr{Error: Undefined subroutine &TestApp::Controller::Foo::three called},
        'parsed error content ok'
    );

    # the caller stacktrace frame
    like(
        $ec_msg,
        qr{Package: TestApp::Controller::Foo\n\s+Line:\s+18},
        'caller Package/Line ok'
    );
    like( $ec_msg, qr{-->\s+18:\s+\$c->forward\( 'crash' \);}, 'caller line number ok' );

    # the actual error stacktrace frame
    like(
        $ec_msg,
        qr{Package: TestApp::Controller::Foo\n\s+Line:\s+30},
        'error Package/Line ok'
    );
    like( $ec_msg, qr{-->\s+30:\s+three\(\);}, 'error line number ok' );

    # RT-72781 - we shouldn't have any referer information in this stacktrace
    unlike(
        $ec_msg,
        qr{Referer: },
        'no referer information in stacktrace'
    );
    # RT-72781 - we shouldn't be seeing any QUERY/BODY sections
    unlike(
        $ec_msg,
        qr{Params \(QUERY\): },
        'no QUERY params information in stacktrace'
    );
    unlike(
        $ec_msg,
        qr{Params \(BODY\): },
        'no BODY params information in stacktrace'
    );
}

# check output with no stacktrace
TestApp->config->{stacktrace}{enable} = 0;
TestApp->config->{"Plugin::ErrorCatcher"}{enable} = 1;
{
    ok( my ($res,$c) = ctx_request('http://localhost/foo/not_ok'), 'request ok' );
    my $ec_msg;
    eval{ $ec_msg = $c->_errorcatcher_msg };
    ok( defined $ec_msg, 'parsed error message ok' );

    # make sure the parsed error looks sane
    like(
        $ec_msg,
        qr{Error: Undefined subroutine &TestApp::Controller::Foo::three called},
        'parsed error content ok'
    );

    # the caller stacktrace frame
    unlike(
        $ec_msg,
        qr{Package: TestApp::Controller::Foo\n\s+Line:\s+18},
        'caller Package/Line ok'
    );
    unlike( $ec_msg, qr{-->\s+18:\s+\$c->forward\( 'crash' \);}, 'caller line number ok' );

    # the actual error stacktrace frame
    unlike(
        $ec_msg,
        qr{Package: TestApp::Controller::Foo\n\s+Line:\s+30},
        'error Package/Line ok'
    );
    unlike( $ec_msg, qr{-->\s+30:\s+three\(\);}, 'error line number ok' );

    # we should have a note about lack of stacktrace
    like(
        $ec_msg,
        qr{Stack trace unavailable - use and enable Catalyst::Plugin::StackTrace},
        'stacktrace hint ok'
    );
}


# check output with stacktrace
TestApp->config->{stacktrace}{enable} = 1;
TestApp->config->{"Plugin::ErrorCatcher"}{enable} = 1;
{
    ok( my ($res,$c) = ctx_request('http://localhost/foo/crash_user'), 'request ok' );
    my $ec_msg;
    eval{ $ec_msg = $c->_errorcatcher_msg };
    ok( defined $ec_msg, 'parsed error message ok' );

    # we should have some user information
    like(
        $ec_msg,
        qr{User: buffy \[id\] \(Catalyst::Authentication::User::Hash\)},
        'user details ok'
    );

    like(
        $ec_msg,
        qr{Error: Vampire\n},
        'Buffy staked the vampire'
    );
}

# RT-64492 - check no session data in default report
TestApp->config->{stacktrace}{enable} = 1;
TestApp->config->{"Plugin::ErrorCatcher"}{enable} = 1;
{
    ok( my ($res,$c) = ctx_request('http://localhost/foo/not_ok'), 'request ok' );
    my $ec_msg;
    eval{ $ec_msg = $c->_errorcatcher_msg };
    ok( defined $ec_msg, 'parsed error message ok' );
    foreach my $session_key (qw/__created __updated/) {
        unlike(
            $ec_msg,
            qr{__created},
            "no instances of '$session_key' in report"
        );
    }
}


# RT-72781 - show the parameters that were sent with the request and where the request came from
TestApp->config->{stacktrace}{enable} = 1;
TestApp->config->{"Plugin::ErrorCatcher"}{enable} = 1;
# test referer information is output
{
    ok( my ($res,$c) = ctx_request('http://localhost/foo/referer'), 'request ok' );
    my $ec_msg;
    eval{ $ec_msg = $c->_errorcatcher_msg };
    ok( defined $ec_msg, 'parsed error message ok' );

    # we should have some referer information
    _has_referer_ok($ec_msg);
}
# test output with QUERY params
{
    # make a request with params
    ok( my ($res,$c) =
        ctx_request('http://localhost/foo/referer?one=man&went=to&mow=1&long_thingy=2'), 'request ok' );
    my $ec_msg;
    eval{ $ec_msg = $c->_errorcatcher_msg };
    ok( defined $ec_msg, 'parsed error message ok' );

    # we should have some referer information
    _has_referer_ok($ec_msg);
    # we should have the get header and lines with the key-value pairs
    _has_QUERY_output($ec_msg);
    # we should have keys and values for each query param
    _has_keys_for_section('QUERY', [qw(one went long_thingy)], $ec_msg);
}
# test output with BODY params
{
    # we still need to get to $c
    ok ( my (undef,$c) = ctx_request('http://localhost/ok'), 'setup $c for BODY');
    # make a request with BODY data
    use HTTP::Request::Common;
    my $response = request POST '/foo/referer', [
        bar         => 'baz',
        something   => 'else'
    ];

    my $ec_msg;
    eval{ $ec_msg = $c->_errorcatcher_msg };
    ok( defined $ec_msg, 'parsed error message ok' );

    # we should have some referer information
    _has_referer_ok($ec_msg);
    # we should have the get header and lines with the key-value pairs
    _has_BODY_output($ec_msg);
    # we should have keys and values for each query param
    _has_keys_for_section('BODY', [qw(bar something)], $ec_msg);
}
# test output with both QUERY and BODY params
{
    # we still need to get to $c; this appears to be the only way
    ok ( my (undef,$c) = ctx_request('http://localhost/ok'), 'setup $c for BODY');
    # make a request with BODY data
    use HTTP::Request::Common;
    my $response = request POST '/foo/referer?fruit=banana&animal=kangaroo', [
        vampire     => 'joe random',
        slayer      => 'kendra'
    ];

    my $ec_msg;
    eval{ $ec_msg = $c->_errorcatcher_msg };
    ok( defined $ec_msg, 'parsed error message ok' );

    # we should have some referer information
    _has_referer_ok($ec_msg);

    # QUERY
    # we should have the get header and lines with the key-value pairs
    _has_QUERY_output($ec_msg);
    # we should have keys and values for each query param
    _has_keys_for_section('QUERY', [qw(fruit animal)], $ec_msg);

    # BODY
    # we should have the get header and lines with the key-value pairs
    _has_BODY_output($ec_msg);
    # we should have keys and values for each query param
    _has_keys_for_section('BODY', [qw(vampire slayer)], $ec_msg);
}
# test output with both QUERY and BODY params
# - test with a case where we don't set the referer
{
    # we still need to get to $c; this appears to be the only way
    ok ( my (undef,$c) = ctx_request('http://localhost/ok'), 'setup $c for POST');
    # make a request with BODY data
    use HTTP::Request::Common;
    my $response = request POST '/foo/not_ok?fruit=banana&animal=kangaroo', [
        vampire     => 'joe random',
        slayer      => 'kendra'
    ];

    my $ec_msg;
    eval{ $ec_msg = $c->_errorcatcher_msg };
    ok( defined $ec_msg, 'parsed error message ok' );

    # we should have some referer information
    _has_no_referer_ok($ec_msg);

    # QUERY
    # we should have the get header and lines with the key-value pairs
    _has_QUERY_output($ec_msg);
    # we should have keys and values for each query param
    _has_keys_for_section('QUERY', [qw(fruit animal)], $ec_msg);

    # BODY
    # we should have the get header and lines with the key-value pairs
    _has_BODY_output($ec_msg);
    # we should have keys and values for each query param
    _has_keys_for_section('BODY', [qw(vampire slayer)], $ec_msg);
}
# test output with long values in parameters
{
    # we still need to get to $c; this appears to be the only way
    ok ( my (undef,$c) = ctx_request('http://localhost/ok'), 'setup $c for POST');
    # make a request with BODY data
    use HTTP::Request::Common;
    my $response = request POST '/foo/not_ok?integer=69&fruit=' . 'banana' x 10, [
        long_text => 'kangaroo' x 8,
        normal    => 'short_thing',
        evil      => "two\nlines",
        # pad out the file types we're fakng so we aren't short enough to just
        # return
        image_gif => 'GIF87a'   . 'Z' x 100,
        image_png => "\x89PNG"  . 'Z' x 100,
        pdf_file  => '%PDF-'    . 'Z' x 100,
    ];

    my $ec_msg;
    eval{ $ec_msg = $c->_errorcatcher_msg };
    ok( defined $ec_msg, 'parsed error message ok' );

    # we should have some referer information
    _has_no_referer_ok($ec_msg);

    # QUERY
    # we should have the get header and lines with the key-value pairs
    _has_QUERY_output($ec_msg);
    # we should have keys and values for each query param
    _has_keys_for_section('QUERY', [qw(fruit integer)], $ec_msg);

    # BODY
    # we should have the get header and lines with the key-value pairs
    _has_BODY_output($ec_msg);
    # we should have keys and values for each query param
    _has_keys_for_section('BODY', [qw(image_gif image_png long_text pdf_file normal evil)], $ec_msg);

    # check the values look sane
    _has_value_for_key( 'BODY', 'image_gif', qr{image/gif}, $ec_msg);
    _has_value_for_key( 'BODY', 'image_png', qr{image/x-png}, $ec_msg);
    _has_value_for_key( 'BODY', 'pdf_file',  qr{application/pdf}, $ec_msg);
    _has_value_for_key( 'BODY', 'normal',    qr{short_thing}, $ec_msg);
    _has_value_for_key( 'BODY', 'long_text', qr{kangarookangarookangarookangarookangaroo\.\.\.\[truncated\]}, $ec_msg);
    _has_value_for_key('QUERY', 'fruit',     qr{bananabananabananabananabananabananabana\.\.\.\[truncated\]}, $ec_msg);
    _has_value_for_key('QUERY', 'integer',   qr{69}, $ec_msg);
    _has_value_for_key('QUERY', 'evil',      qr{two(?:\\r)?\\nlines}, $ec_msg);
}

# helper methods for RT-72781 testing
sub _has_referer_ok {
    # we should have some referer information
    like(
        shift,
        qr{\s+Referer:\s+http://garlic-weapons.tv},
        'referer information exists'
    );
}
sub _has_no_referer_ok {
    # we should have some referer information
    unlike(
        shift,
        qr{\s+Referer:\s+},
        'referer information exists'
    );
}
sub _has_QUERY_output {
    _has_param_section('QUERY',@_);
}
sub _has_BODY_output {
    SKIP: {
        skip 'RT#75607 body_parameters overwritten', 1
            if _skip_for_RT75607();

        _has_param_section('BODY',@_);
    }
}
sub _has_param_section {
    my $type = shift;
    like(
        shift,
        qr{Params \(${type}\):},
        "$type params block exists"
    ) if 0; # XXX see https://github.com/chiselwright/catalyst-plugin-errorcatcher/issues/3
}
sub _has_keys_for_section {
    my ($type, $keys, $msg) = @_;
    return
        unless (ref $keys eq 'ARRAY');
    SKIP: {
        skip 'RT#75607 body_parameters overwritten', scalar @{$keys}
            if _skip_for_RT75607();

        foreach my $key (@{$keys}) {
            like(
                $msg,
                qr{
                    Params\s+\(\Q$type\E\): # section header
                    .+?                     # non-greedy anything-ness
                    ^\s+\Q$key\E:.+?$       # the line with our key on it
                    .+?                     # non-greedy anything-ness
                    ^$                      # blank line at end of section
                }xms,
                "'$key' exists in $type section"
            ) if 0; # XXX see https://github.com/chiselwright/catalyst-plugin-errorcatcher/issues/3
        }
    }
}
sub _has_value_for_key {
    my ($type, $key, $value, $msg) = @_;
    SKIP: {
        skip 'RT#75607 body_parameters overwritten', 1
            if _skip_for_RT75607();

        like(
            $msg,
            qr{
                Params\s+\(\Q$type\E\): # section header
                .+?                     # non-greedy anything-ness
                ^\s+\Q$key\E:           # the line with our key on it
                \s+                     # whitespace after the key label
                $value                  # a specific value for the key
                \s*$                    # optional whitespace up to the end of the line
                .+?                     # non-greedy anything-ness
                ^$                      # blank line at end of section
            }xms,
            "'$key' has value '$value' in $type section"
        ) if 0; # XXX see https://github.com/chiselwright/catalyst-plugin-errorcatcher/issues/3
    }
}

# see here for details:
#  https://rt.cpan.org/Public/Bug/Display.html?id=75607
sub _skip_for_RT75607 {
    use version;
    my $version = version->declare(Catalyst->VERSION);
    return ($version >= qv("v5.90009") and $version <= qv("v5.90011"));
}

done_testing;
