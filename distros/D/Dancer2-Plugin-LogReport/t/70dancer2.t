#!/usr/bin/env perl
use strict;
use warnings;
use version;

use Test::More;

BEGIN {
    eval "require Dancer2";
    plan skip_all => 'Dancer2 is not installed'
        if $@;

    plan skip_all => "Dancer2 is too old: $Dancer2::VERSION"
        if version->parse($Dancer2::VERSION) <= 0.207;   # for to_app()

    warn "Dancer2 version $Dancer2::VERSION\n";

    eval "require Plack::Test";
    $@ and plan skip_all => 'Unable to load Plack::Test';

    eval "require HTTP::Cookies";
    $@ and plan skip_all => 'Unable to load HTTP::Cookies';

    eval "require HTTP::Request::Common";
    $@ and plan skip_all => 'Unable to load HTTP::Request::Common';
    HTTP::Request::Common->import;

    plan tests => 4;
}

{
    package TestApp;
    use Dancer2;

     # Import options can be passed to Log::Report.
     use Dancer2::Plugin::LogReport 'test_app', import => 'dispatcher';
     # or you can just use the plugin to get syntax => 'LONG'
     # use Dancer2::Plugin::LogReport;

    set session => 'Simple';
    set logger  => 'LogReport';

    dispatcher close => 'default';

    # Whether to bork on the root URL
    our $always_bork_before;
    our $always_bork_after;

    hook before => sub {
        if ($always_bork_before || query_parameters->get('hook_before_exception'))
        {
            my $foo;
            $foo->bar;
        }
    };

    hook after => sub {
        if ($always_bork_after || query_parameters->get('hook_after_exception'))
        {
            my $foo;
            $foo->bar;
        }
    };

    # Unhandled exception in default route
    get '/' => sub {
        my $foo;
        $foo->bar;
    };

    get '/write_message/:level/:text' => sub {
        my $level = param('level');
        my $text  = param('text');
        eval qq($level "$text");
    };

    get '/read_messages' => sub {
        my $all = session 'messages';
        join "", map "$_", @$all;
    };

    get '/process' => sub {
        process(sub { error "Fatal error text" });
    };

    get '/show_error/:show_error' => sub {
        set show_errors => route_parameters->get('show_error');
    };

    # Route to add custom handlers during later tests
    get '/add_fatal_handler/:type' => sub {

        my $type = param 'type';

        if ($type eq 'json') {
            fatal_handler sub {
                my ($dsl, $msg, $reason) = @_;
                return unless $dsl->app->request->uri =~ /api/;
                $dsl->send_as(JSON => {message => $msg->toString});
            };
        }
        elsif ($type eq 'html')
        {
            fatal_handler sub {
                my ($dsl, $msg, $reason) = @_;
                return unless $dsl->app->request->uri =~ /html/;
                $dsl->send_as(html => "<p>".$msg->toString."</p>");
            };
        }
    };

}

my $url = 'http://localhost';
my $jar  = HTTP::Cookies->new();
my $test = Plack::Test->create( TestApp->to_app );

sub read_messages
{   my $res = shift;
    $jar->extract_cookies($res);
    my $req = GET "$url/read_messages";
    $jar->add_cookie_header($req);
    $res = $test->request( $req );
    my $m = $res->content;
    $jar->clear;
    $m;
}

# Basic tests to log messages and read from session
subtest 'Basic messages' => sub {

    # Log a notice message
    {
        my $req = GET "$url/write_message/notice/notice_text";
        $jar->add_cookie_header($req);
        my $res = $test->request( $req );
        ok $res->is_success, "get /write_message";

        # Get the message
        is (read_messages($res), 'notice_text');
    }

    # Log a trace message
    {
        my $req = GET "$url/write_message/trace/trace_text";
        $jar->add_cookie_header($req);
        my $res = $test->request( $req );
        ok $res->is_success, "get /write_message";

        # This time it shouldn't make it to the messages session
        is (read_messages($res), '');
    }
};

# Tests to check fatal errors, and catching with process()
subtest 'Throw error' => sub {

    # Throw an uncaught error. Should redirect.
    {
        my $req = GET "$url/write_message/error/error_text";
        my $res = $test->request( $req );
        ok $res->is_redirect, "get /write_message";
    }

    # The same, this time caught and displayed
    {
        my $req = GET "$url/process";
        $jar->add_cookie_header($req);
        my $res = $test->request( $req );
        ok $res->is_success, "get /write_message";
        is $res->content, '0';

        # Check caught message is in session
        is (read_messages($res), 'Fatal error text');
    }
};

# Tests to check unexpected exceptions
subtest 'Unexpected exception default page' => sub {

    plan skip_all => "Dancer2 v2.0 needed for handling exceptions in hooks"
        if version->parse($Dancer2::VERSION) < 2;

    # An exception generated from the default route which cannot redirect to
    # the default route, so it throws a plain text error
    {
        my $req = GET "$url/";
        my $res = $test->request( $req );
        ok !$res->is_redirect, "No redirect for exception on default route";
        is $res->content, "An unexpected error has occurred", "Plain text exception text correct";
    }

    # The same as previous, but this time we enable the development setting
    # show_error, which means that the content returned is the actual Perl
    # error string
    {
        # First set show_error parameter
        $test->request(GET "$url/show_error/1");
        my $req = GET "$url/";
        my $res = $test->request( $req );
        ok !$res->is_redirect, "get /write_message";
        like $res->content, qr/Can't call method "bar" on an undefined value/;
        # Then set show_error back to disabled
        $test->request(GET "$url/show_error/0");
    }

    # This time the exception occurs in an early hook and we are not able to do
    # anything as the request hasn't been populated yet. Therefore we should
    # expect Dancer's default error handling
    {
        my $req = GET "$url/?hook_before_exception=1";
        $jar->add_cookie_header($req);
        my $res = $test->request( $req );
        ok $res->is_redirect, "get /write_message";
        is (read_messages($res), 'An unexpected error has occurred');
    }
    {
        my $req = GET "$url/?hook_after_exception=1";
        $jar->add_cookie_header($req);
        my $res = $test->request( $req );
        ok $res->is_redirect, "get /write_message";
        is (read_messages($res), 'An unexpected error has occurred');
    }
    {
        local $TestApp::always_bork_before = 1;
        my $req = GET "$url/";
        $jar->add_cookie_header($req);
        my $res = $test->request( $req );
        ok !$res->is_redirect, "get /write_message";
        like $res->content, qr/An unexpected error has occurred/;
        local $TestApp::always_bork_before = 0;
        is (read_messages($res), 'An unexpected error has occurred');
    }
    {
        local $TestApp::always_bork_after = 1;
        my $req = GET "$url/";
        $jar->add_cookie_header($req);
        my $res = $test->request( $req );
        ok !$res->is_redirect, "get /write_message";
        like $res->content, qr/An unexpected error has occurred/;
        local $TestApp::always_bork_after = 0;
        is (read_messages($res), 'An unexpected error has occurred');
    }
};

# Tests to check custom fatal error handlers
subtest 'Custom handler' => sub {

    # Add 2 custom fatal handlers - shoudl only match relevant URLs
    $test->request(GET "$url/add_fatal_handler/json");
    $test->request(GET "$url/add_fatal_handler/html");

    # Throw uncaught errors to see if correct handlers are called.
    # JSON (for API)
    {
        my $req = GET "$url/write_message/error/api_text";
        my $res = $test->request( $req );
        ok $res->is_success, "get /write_message";
        is $res->content, '{"message":"api_text"}';
    }

    # HTML without redirect
    {
        my $req = GET "$url/write_message/error/html_text";
        my $res = $test->request( $req );
        ok $res->is_success, "get /write_message";
        is $res->content, '<p>html_text</p>';
    }

    # And default (redirect)
    {
        my $req = GET "$url/write_message/error/error_text";
        my $res = $test->request( $req );
        ok $res->is_redirect, "get /write_message";
    }
};

done_testing;

