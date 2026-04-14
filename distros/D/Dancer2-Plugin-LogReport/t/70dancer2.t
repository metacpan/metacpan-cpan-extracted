#!/usr/bin/env perl
use strict;
use warnings;
use version;

use JSON::MaybeXS;
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

	eval "require Dancer2::Session::Sereal";
	$@ and plan skip_all => 'Unable to load Dancer2::Session::Sereal';

	plan tests => 4;
}

{
	package TestApp;
	use Dancer2;

	use Dancer2::Plugin::LogReport 'test_app';

	# Default Sereal session config is to refuse objects
	set engines => {
		session => {
		    Sereal => {
		        encoder_args => {
		            croak_on_bless => 0,
		            # Messages from later versions of Log::Report do not
		            # serialize cleanly. Therefore use the object's freeze and
		            # thaw methods.
		            freeze_callbacks => 1,
		        },
		        decoder_args => {
		            refuse_objects => 0,
		        },
		    },
		},
	};

	# Check that messages can be serialized as objects. Use the Sereal session
	# serializer, as it's the easiest to configure to enable blessed objects in
	# its serialization
	set session => 'Sereal';
	set logger  => 'LogReport';

	# Configure at least 2 dispatchers so that the message domain becomes an
	# object. Don't use the default dispatcher though, to prevent noise being
	# printed during the tests
	dispatcher close => 'default';
	dispatcher FILE => 'stderr', to => '/dev/null';

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

	get '/write_message/:level/:text/:param?' => sub {
		# Allow a message to be raised with a level, text and optional
		# parameter
		my $level = param('level');
		my $text  = param('text');
		my $param = param('param');
		$text    .= " {param}" if $param;
		my $eval  = qq($level __x"$text");
		$eval    .= qq(, param => "$param") if $param;
		eval $eval;
	};

	get '/read_message' => sub {
		my $all  = session 'messages';
		my $last = $all->[-1] or return;
		my $msg  = Dancer2::Plugin::LogReport::Message->thaw($last);

		encode_json {
		    text            => $msg->toString,
		    msgid           => $msg->msgid,
		    reason          => $msg->reason,
		    bootstrap_color => $msg->bootstrap_color,
		};
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

sub read_message
{   my $res = shift;
	$jar->extract_cookies($res);
	my $req = GET "$url/read_message";
	$jar->add_cookie_header($req);
	my $content = $test->request($req)->content or return;
	my $m = decode_json($content);
	$jar->clear;
	$m;
}

# Basic tests to log messages and read from session
subtest 'Basic messages' => sub {

	# Log a notice message
	{
		# Use a message with a parameter to check interpolation
		my $req = GET "$url/write_message/notice/notice_text/foo";
		$jar->add_cookie_header($req);
		my $res = $test->request( $req );
		ok $res->is_success, "get /write_message";

		# Get the message
		my $m = read_message($res);
		is ($m->{text}, 'notice_text foo');
		is ($m->{bootstrap_color}, 'info');
	}

	# Log a success message
	{
		my $req = GET "$url/write_message/success/success_text/bar";
		$jar->add_cookie_header($req);
		my $res = $test->request( $req );
		ok $res->is_success, "get /write_message";

		# Get the message
		my $m = read_message($res);
		is ($m->{text}, 'success_text bar');
		is ($m->{bootstrap_color}, 'success');
	}

	# Log a trace message
	{
		my $req = GET "$url/write_message/trace/trace_text/";
		$jar->add_cookie_header($req);
		my $res = $test->request( $req );
		ok $res->is_success, "get /write_message";

		# This time it shouldn't make it to the messages session
		my $m = read_message($res);
		is ($m, undef);
	}
};

# Tests to check fatal errors, and catching with process()
subtest 'Throw error' => sub {

	# Throw an uncaught error. Should redirect.
	{
		my $req = GET "$url/write_message/error/error_text/";
		my $res = $test->request($req);
		ok $res->is_redirect, "get /write_message";
	}

	# The same, this time caught and displayed
	{
		my $req = GET "$url/process";
		$jar->add_cookie_header($req);
		my $res = $test->request($req);
		ok $res->is_success, "get /write_message";
		is $res->content, '0';

		# Check caught message is in session
		my $m = read_message($res);
		is $m->{text}, 'Fatal error text';
		is $m->{bootstrap_color}, 'danger';
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
		my $res = $test->request($req);
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
		my $m = read_message($res);
		is ($m->{text}, 'An unexpected error has occurred');
		is ($m->{bootstrap_color}, 'danger');
	}
	{
		my $req = GET "$url/?hook_after_exception=1";
		$jar->add_cookie_header($req);
		my $res = $test->request( $req );
		ok $res->is_redirect, "get /write_message";
		my $m = read_message($res);
		is ($m->{text}, 'An unexpected error has occurred');
		is ($m->{bootstrap_color}, 'danger');
	}
	{
		local $TestApp::always_bork_before = 1;
		my $req = GET "$url/";
		$jar->add_cookie_header($req);
		my $res = $test->request( $req );
		ok !$res->is_redirect, "get /write_message";
		like $res->content, qr/An unexpected error has occurred/;
		local $TestApp::always_bork_before = 0;
		my $m = read_message($res);
		is ($m->{text}, 'An unexpected error has occurred');
		is ($m->{bootstrap_color}, 'danger');
	}
	{
		local $TestApp::always_bork_after = 1;
		my $req = GET "$url/";
		$jar->add_cookie_header($req);
		my $res = $test->request( $req );
		ok !$res->is_redirect, "get /write_message";
		like $res->content, qr/An unexpected error has occurred/;
		local $TestApp::always_bork_after = 0;
		my $m = read_message($res);
		is ($m->{text}, 'An unexpected error has occurred');
		is ($m->{bootstrap_color}, 'danger');
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
		my $req = GET "$url/write_message/error/api_text/";
		my $res = $test->request($req);
		ok $res->is_success, "get /write_message";
		is $res->content, '{"message":"api_text"}';
	}

	# HTML without redirect
	{
		my $req = GET "$url/write_message/error/html_text/";
		my $res = $test->request($req);
		ok $res->is_success, "get /write_message";
		is $res->content, '<p>html_text</p>';
	}

	# And default (redirect)
	{
		my $req = GET "$url/write_message/error/error_text/";
		my $res = $test->request($req);
		ok $res->is_redirect, "get /write_message";
	}
};

done_testing;

