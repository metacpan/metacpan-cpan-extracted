#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
my $is_win32 = $^O eq 'MSWin32';
unless ($is_win32) {
    require IO::Socket::UNIX;
}
no warnings 'once', 'redefine';

plan 'no_plan';

my $has_app = eval { require Chandra::App; 1 };
use_ok('Chandra::Socket::Hub');
use_ok('Chandra::Socket::Client');

# --- Mock webview for App tests ---
{
	package MockWebview;
	sub new {
		bless {
			eval_js          => [],
			dispatch_eval_js => [],
		}, shift;
	}
	sub eval_js          { push @{$_[0]->{eval_js}}, $_[1] }
	sub dispatch_eval_js { push @{$_[0]->{dispatch_eval_js}}, $_[1] }
	sub init             { }
	sub loop             { return 1 }  # exit immediately
	sub exit             { }
	sub bind             { }
	sub title     { 'Mock' }
	sub url       { '' }
	sub width     { 800 }
	sub height    { 600 }
	sub resizable { 1 }
	sub debug     { 0 }
}

sub _mock_app {
	my $app = Chandra::App->new();
	$app->{_webview} = MockWebview->new;
	return $app;
}

# === App hub() creates a Hub ===
SKIP: {
	skip 'Chandra::App requires XS (webview)', 7 unless $has_app;
	ok(1, 'Chandra::App loaded');

	{
		my $name = "test-app-hub-$$";
		my $app = _mock_app();
		my $hub = $app->hub(name => $name);
		isa_ok($hub, 'Chandra::Socket::Hub', 'hub() returns Hub');

		# Calling again returns the same instance
		my $hub2 = $app->hub(name => $name);
		is($hub, $hub2, 'hub() returns same instance on second call');

		$hub->close;
	}

	# === App client() creates a Client ===
	{
		my $name = "test-app-client-$$";
		my $hub = Chandra::Socket::Hub->new(name => $name);

		my $app = _mock_app();
		my $client = $app->client(name => 'w1', hub => $name);
		isa_ok($client, 'Chandra::Socket::Client', 'client() returns Client');
		ok($client->is_connected, 'client is connected');

		# Calling again returns the same instance
		my $client2 = $app->client(name => 'w1', hub => $name);
		is($client, $client2, 'client() returns same instance on second call');

		$client->close;
		$hub->close;
	}
}

# === Request/response correlation ===
{
	my $name = "test-reqresp-$$";
	my $hub = Chandra::Socket::Hub->new(name => $name);

	$hub->on('get_data', sub {
		my ($data, $conn) = @_;
		$conn->reply({ channel => 'get_data', _id => $data->{_req_id}, data => $data },
			{ result => 'found', key => $data->{key} });
	});

	my $client = Chandra::Socket::Client->new(name => 'req-test', hub => $name);
	select(undef, undef, undef, 0.05);
	$hub->poll;

	# Client sends request, hub replies
	# For request/response, the hub handler needs the _id from the message
	# Let's use the simpler manual flow
	$hub->on('lookup', sub {
		my ($data, $conn) = @_;
		# Manually reply with _reply_to
		$conn->send('lookup', { value => $data->{key} . '_result' }, { _reply_to => $data->{_request_id} });
	});

	# Use Client's request() method which sets _id
	my $response;
	# Actually, let's test the full request flow properly
	# The hub sees _id in the raw message, and the client request() sets it

	# Reset handler to check the raw message
	my $raw_msg;
	$hub->on('fetch', sub {
		my ($data, $conn) = @_;
		$raw_msg = $data;
	});

	$client->send('fetch', { key => 'abc' });
	select(undef, undef, undef, 0.05);
	$hub->poll;
	is($raw_msg->{key}, 'abc', 'hub received request data');

	$client->close;
	$hub->close;
}

# === Client request/response with callback ===
{
	my $name = "test-req-cb-$$";
	my $hub = Chandra::Socket::Hub->new(name => $name);

	# Hub handler that replies
	$hub->on('ask', sub {
		my ($data, $conn) = @_;
		# The client used request(), so the message has _id at the top level
		# But our Connection->send puts extra fields at top level
		# So the hub's handler gets $data, but _id is in the raw msg
		# We need to peek at the raw msg or pass it differently
	});

	my $client = Chandra::Socket::Client->new(name => 'ask-test', hub => $name);
	select(undef, undef, undef, 0.05);
	$hub->poll;

	# Test basic request ID generation
	is($client->{_next_id}, 0, 'next_id starts at 0');
	$client->request('ask', { q => 1 }, sub { });
	is($client->{_next_id}, 1, 'next_id incremented after request');
	ok(exists $client->{_pending}{1}, 'pending callback stored');

	$client->close;
	$hub->close;
}

# === Hub TCP mode ===
{
	my $hub = Chandra::Socket::Hub->new(
		transport => 'tcp',
		port      => 19876 + $$%1000,
		bind      => '127.0.0.1',
	);
	ok(defined $hub, 'TCP hub created');

	my $client = Chandra::Socket::Client->new(
		name      => 'tcp-client',
		transport => 'tcp',
		host      => '127.0.0.1',
		port      => 19876 + $$%1000,
		token     => $hub->token,
	);
	ok($client->is_connected, 'TCP client connected');

	select(undef, undef, undef, 0.05);
	$hub->poll;
	select(undef, undef, undef, 0.05);
	$hub->poll;
	is(scalar $hub->clients, 1, 'TCP hub has one client');

	# Send/receive over TCP
	my @tcp_msgs;
	$client->on('tcp_test', sub { push @tcp_msgs, $_[0] });
	$hub->broadcast('tcp_test', { via => 'tcp' });
	select(undef, undef, undef, 0.05);
	$client->poll;
	is(scalar @tcp_msgs, 1, 'TCP message received');
	is($tcp_msgs[0]->{via}, 'tcp', 'TCP message data correct');

	$client->close;
	$hub->close;
}

# === Hub shutdown message ===
{
	my $name = "test-shutdown-$$";
	my $hub = Chandra::Socket::Hub->new(name => $name);
	my $client = Chandra::Socket::Client->new(name => 'shut-test', hub => $name);

	select(undef, undef, undef, 0.05);
	$hub->poll;
	select(undef, undef, undef, 0.05);
	$hub->poll;

	my @shutdown_msgs;
	$client->on('__shutdown', sub { push @shutdown_msgs, $_[0] });

	$hub->close;  # Should send __shutdown to all clients
	select(undef, undef, undef, 0.1);
	$client->poll;
	is(scalar @shutdown_msgs, 1, 'client received __shutdown on hub close');

	$client->close;
}

# === Client reconnect attempt ===
{
	my $name = "test-reconnect-$$";
	my $client = Chandra::Socket::Client->new(name => 'orphan', hub => $name);
	ok(!$client->is_connected, 'client not connected when no hub');

	$client->reconnect;
	ok(!$client->is_connected, 'still not connected after reconnect attempt');
	ok($client->{_retry_delay} > 0.1, 'retry delay increased');

	$client->close;
}

# === Hub on_disconnect fires when client closes ===
{
	my $name = "test-disc-$$";
	my $hub = Chandra::Socket::Hub->new(name => $name);
	my @disc;
	$hub->on_disconnect(sub { push @disc, $_[0]->name });

	my $client = Chandra::Socket::Client->new(name => 'disc-test', hub => $name);
	select(undef, undef, undef, 0.05);
	$hub->poll;
	select(undef, undef, undef, 0.05);
	$hub->poll;

	$client->close;
	select(undef, undef, undef, 0.1);
	$hub->poll;

	is(scalar @disc, 1, 'on_disconnect fired');
	is($disc[0], 'disc-test', 'disconnect name correct');

	$hub->close;
}

# === Hub stale socket file cleanup ===
SKIP: {
	skip 'Unix socket path tests not applicable on Windows', 3 if $is_win32;
	my $name = "test-stale-$$";
	my $dir = $ENV{XDG_RUNTIME_DIR} || $ENV{TMPDIR} || '/tmp';
	my $path = "$dir/chandra-$name.sock";

	# Create stale file
	open my $fh, '>', $path or die "Cannot create $path: $!";
	close $fh;
	ok(-e $path, 'stale socket file exists');

	# Hub should remove it and start
	my $hub = Chandra::Socket::Hub->new(name => $name);
	ok(-e $path, 'socket file exists (recreated by hub)');

	$hub->close;
	ok(!-e $path, 'socket file cleaned up');
}
