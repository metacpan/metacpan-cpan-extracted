package BI::Test::Browser;

# A repeatable browser fixture for the tests that drive the real pages.
#
# One call starts the application in a child process, on an ephemeral port and
# with a throwaway model directory, then starts a headless Firefox with its own
# profile and a Marionette connection to it.  A test file gets the app's base
# URL, a user agent pointed at it, and a browser session it can navigate, run
# scripts in and press keys in.  Everything is stopped in stop(), and in
# DESTROY for the paths that leave without reaching it.
#
# The keys are real: press() sends WebDriver key actions, so the browser's own
# input stack dispatches them to whatever has focus - native select typeahead,
# form submission from Enter, a page's keydown handler, Tab moving focus.
# Nothing here fabricates a KeyboardEvent in the page.
#
# The app is the application the user runs, started the same way
# (Mojo::Server::Daemon), not a Test::Mojo mock: the point of these tests is the
# HTTP conversation between a browser and the real routes.  The proxy prefs
# point at a closed port, so a page's CDN script fails at once instead of
# waiting on a network the test does not need.
#
# A test that needs its own config values, or fixture files served on the app's
# origin, passes app_config => {...} and static_paths => [...].  The latter are
# extra static roots, so a test can serve the libraries a deployment would
# self-host without putting them in the application's public directory.
#
#   my $browser = BI::Test::Browser->new(record_patches => 1);
#   $browser->navigate('/view/sales');
#   $browser->focus('#btn-bar');
#   $browser->press('Enter');
#
# Skips are the test file's decision: skip_reason() says why there is no point
# starting, and is undef when there is.

use strict;
use warnings;

use Exporter 'import';
our @EXPORT_OK = qw(find_firefox);

use File::Path      ();
use File::Spec      ();
use File::Temp      qw(tempdir);
use IO::Socket::INET ();
use JSON::MaybeXS   qw(encode_json decode_json);
use Mojo::Server::Daemon ();
use Mojo::UserAgent      ();
use POSIX qw(_exit WNOHANG);
use Time::HiRes qw(sleep);

use BI::Test::Marionette ();

# The WebDriver key values for the keys a test names.  A single character is
# passed through as itself; these are the ones with no printable form.
my %KEY = (
	null       => "\x{E000}",
	cancel     => "\x{E001}",
	help       => "\x{E002}",
	backspace  => "\x{E003}",
	tab        => "\x{E004}",
	clear      => "\x{E005}",
	return     => "\x{E006}",
	enter      => "\x{E007}",
	shift      => "\x{E008}",
	control    => "\x{E009}",
	alt        => "\x{E00A}",
	pause      => "\x{E00B}",
	escape     => "\x{E00C}",
	space      => "\x{E00D}",
	pageup     => "\x{E00E}",
	pagedown   => "\x{E00F}",
	end        => "\x{E010}",
	home       => "\x{E011}",
	arrowleft  => "\x{E012}",
	arrowup    => "\x{E013}",
	arrowright => "\x{E014}",
	arrowdown  => "\x{E015}",
	insert     => "\x{E016}",
	delete     => "\x{E017}",
	meta       => "\x{E03D}",
);

# A Firefox on PATH, or the one BI_FIREFOX names.  firefox-esr is the Debian
# package name; both are the same --marionette browser these tests need.
sub find_firefox {
	return $ENV{BI_FIREFOX}
		if defined $ENV{BI_FIREFOX} && length $ENV{BI_FIREFOX} && -x $ENV{BI_FIREFOX};

	for my $dir (File::Spec->path) {
		next unless defined $dir && length $dir;
		for my $name (qw(firefox firefox-esr)) {
			my $path = File::Spec->catfile($dir, $name);
			return $path if -x $path && !-d $path;
		}
	}

	return undef;
}

# Why not to start at all, or undef to start.  required_files are relative to
# the distribution root, which is where prove runs a test from.
sub skip_reason {
	my ($class, %arg) = @_;

	return 'Not running Not running author tests' unless $ENV{AUTHOR_TESTING};
	return 'BI_SKIP_BROWSER_TESTS is set' if $ENV{BI_SKIP_BROWSER_TESTS};
	return 'no Firefox found (set BI_FIREFOX to one)' unless find_firefox();

	for my $file (@{ $arg{required_files} || [] }) {
		return "$file not found" unless -f $file;
	}

	return undef;
}

# Plan a browser test file: skip it when there is no usable browser, or die
# when this run is the one that is supposed to be checking the browser.  A CI
# job that skipped every test would otherwise report success without testing
# anything, so BI_REQUIRE_BROWSER turns a missing browser into a failure.  The
# test file calls this after Test::Most has loaded Test::More.
sub plan_browser_tests {
	my ($class, %arg) = @_;

	my $why = $class->skip_reason(%arg);
	return 1 unless defined $why;

	die "BI_REQUIRE_BROWSER is set but the browser tests cannot run: $why\n"
		if $ENV{BI_REQUIRE_BROWSER};

	Test::More::plan(skip_all => $why);
	return 0;
}

sub new {
	my ($class, %arg) = @_;

	my $self = bless {
		data_dir        => $arg{data_dir} || File::Spec->rel2abs('data'),
		platform        => $arg{platform} || 'web',
		language        => $arg{language} || 'en',
		record_patches  => $arg{record_patches} ? 1 : 0,
		app_config      => $arg{app_config} || {},
		static_paths    => $arg{static_paths} || [],
		stopped         => 0,
	}, $class;

	# No CLEANUP: stop() removes it after the children are dead, which is the
	# only time a directory the browser is still writing to can be removed.
	$self->{tmp} = tempdir();
	$self->{model_dir}  = File::Spec->catdir($self->{tmp}, 'models');
	$self->{patch_file} = File::Spec->catfile($self->{tmp}, 'patches.log');
	$self->{port_file}  = File::Spec->catfile($self->{tmp}, 'server.port');
	$self->{server_log} = File::Spec->catfile($self->{tmp}, 'server.log');

	$self->_start_server;
	$self->_start_browser(
		extra_prefs => $arg{prefs} || {},
		headless    => defined $arg{headless} ? $arg{headless} : 1,
	);

	return $self;
}

# ---------------------------------------------------------------------------
# The app, in a child.  It binds port 0 and writes down the port it was given:
# asking for a free port and then binding it would leave a window in which
# something else takes it, and a test that fails when the machine is busy is
# not testing the app.
# ---------------------------------------------------------------------------
sub _start_server {
	my ($self) = @_;

	my $pid = fork;
	die "fork: $!" unless defined $pid;

	if (!$pid) {
		open STDOUT, '>', $self->{server_log} or _exit(1);
		open STDERR, '>&', \*STDOUT             or _exit(1);

		require Database::BI;
		my $app = Database::BI->new(
			data_dir  => $self->{data_dir},
			model_dir => $self->{model_dir},
			platform  => $self->{platform},
			language  => $self->{language},
		);

		# Constructor arguments are app attributes, not config values; the
		# Config plugin builds config in startup(), so apply test overrides
		# after the app exists.
		$app->config->{$_} = $self->{app_config}{$_}
			for sort keys %{ $self->{app_config} };

		# A test can serve fixture assets, such as the libraries a deployment
		# self-hosts, from its own temporary directory on the app's origin.
		push @{ $app->static->paths }, @{ $self->{static_paths} }
			if @{ $self->{static_paths} };

		# Every layout PATCH, body and all, recorded before the controller can
		# reject or store it.  This is the test's only view of what the page
		# sent; the page's own claim is not evidence.
		if ($self->{record_patches}) {
			my $record = $self->{patch_file};
			$app->hook(before_dispatch => sub {
				my $c = shift;
				return unless $c->req->method eq 'PATCH';
				my $path = $c->req->url->path->to_string;
				return unless $path =~ m{\A/api/analyses/};
				open my $fh, '>>', $record or return;
				print {$fh} encode_json({ path => $path, body => $c->req->body // '' }), "\n";
				close $fh;
			});
		}

		my $daemon = Mojo::Server::Daemon->new(
			app    => $app,
			listen => ['http://127.0.0.1:0'],
			silent => 1,
		);
		$daemon->start;

		open my $pfh, '>', $self->{port_file} or _exit(1);
		print {$pfh} $daemon->ports->[0], "\n";
		close $pfh;

		$daemon->run;
		_exit(0);
	}

	$self->{server_pid} = $pid;

	my $base;
	for (1 .. 200) {
		if (-s $self->{port_file}) {
			open my $pfh, '<', $self->{port_file} or last;
			chomp(my $port = <$pfh>);
			close $pfh;
			$base = "http://127.0.0.1:$port" if defined $port && $port =~ /\A\d+\z/;
			last if $base;
		}
		last if waitpid($pid, WNOHANG) == $pid;
		sleep 0.1;
	}

	unless ($base) {
		my $log = $self->_read_text($self->{server_log});
		$self->stop;
		die "the app did not start on a loopback port\nserver log: $log\n";
	}
	$self->{base} = $base;

	$self->{ua} = Mojo::UserAgent->new;
	$self->{ua}->request_timeout(10);

	my $ready;
	for (1 .. 100) {
		my $tx = $self->{ua}->get("$base/");
		if (($tx->res->code // 0) == 200) { $ready = 1; last }
		sleep 0.1;
	}

	unless ($ready) {
		my $log = $self->_read_text($self->{server_log});
		$self->stop;
		die "the app did not answer HTTP\nserver log: $log\n";
	}

	return;
}

# ---------------------------------------------------------------------------
# A headless Firefox with its own profile, and Marionette on a port the browser
# is told about in user.js.  Port 0 is not available in a preference, so a
# listener is opened and closed to ask the kernel for one.
# ---------------------------------------------------------------------------
sub _start_browser {
	my ($self, %arg) = @_;

	my $firefox = find_firefox()
		or die "no Firefox found (set BI_FIREFOX to one)\n";

	my $listener = IO::Socket::INET->new(
		LocalAddr => '127.0.0.1',
		LocalPort => 0,
		Listen    => 5,
		Proto     => 'tcp',
		ReuseAddr => 1,
	) or die "could not reserve a Marionette port: $!\n";

	my $port = $listener->sockport;
	close $listener;
	$self->{marionette_port} = $port;

	my $profile = File::Spec->catdir($self->{tmp}, 'profile');
	mkdir $profile or die "mkdir $profile: $!\n";
	$self->{profile} = $profile;

	my $prefs = {
		'marionette.port'                        => $port,
		'browser.shell.checkDefaultBrowser'      => 'false',
		'browser.startup.page'                   => 0,
		'datareporting.policy.dataSubmissionEnabled' => 'false',
		'toolkit.telemetry.reportingpolicy.firstRun' => 'false',
		'browser.startup.homepage_override.mstone'   => '"ignore"',
		# Nothing outside loopback is needed, and a page's CDN script should
		# fail at once rather than wait for a network this test does not have.
		'network.proxy.type'      => 1,
		'network.proxy.http'      => '"127.0.0.1"',
		'network.proxy.http_port' => 1,
		'network.proxy.ssl'       => '"127.0.0.1"',
		'network.proxy.ssl_port'  => 1,
		'network.proxy.no_proxies_on' => '"localhost, 127.0.0.1"',
		%{ $arg{extra_prefs} },
	};

	my $userjs = File::Spec->catfile($profile, 'user.js');
	open my $fh, '>', $userjs or die "could not write the Firefox profile: $!\n";
	for my $name (sort keys %$prefs) {
		my $value = $prefs->{$name};
		$value = $value =~ /\A-?\d+\z/ ? $value : '"' . $value . '"'
			unless $value =~ /\A"/;
		print {$fh} qq{user_pref("$name", $value);\n};
	}
	close $fh;

	my $log = File::Spec->catfile($self->{tmp}, 'firefox.log');
	$self->{firefox_log} = $log;

	my $pid = fork;
	die "fork: $!" unless defined $pid;

	if (!$pid) {
		open STDOUT, '>', $log or _exit(1);
		open STDERR, '>&', \*STDOUT or _exit(1);

		my @args = ('--no-remote', '--profile', $profile, '--marionette');
		unshift @args, '--headless' if $arg{headless};
		exec($firefox, @args) or _exit(127);
	}

	$self->{firefox_pid} = $pid;

	my $client;
	for (1 .. 160) {
		$client = eval { BI::Test::Marionette->new(port => $port) };
		last if $client;
		last if waitpid($pid, WNOHANG) == $pid;
		sleep 0.25;
	}

	unless ($client) {
		my $text = $self->_read_text($log);
		$self->stop;
		die "Firefox did not answer on its Marionette port\nfirefox log: $text\n";
	}
	$self->{client} = $client;

	my $session = eval { $client->cmd('WebDriver:NewSession' => {}) };
	unless ($session && $session->{sessionId}) {
		$self->stop;
		die "Firefox did not start a WebDriver session\n";
	}
	$self->{session} = $session->{sessionId};

	return;
}

# ---------------------------------------------------------------------------
# What a test asks of the fixture
# ---------------------------------------------------------------------------
sub base    { return $_[0]->{base} }
sub ua      { return $_[0]->{ua} }
sub client  { return $_[0]->{client} }
sub session { return $_[0]->{session} }
sub tmp     { return $_[0]->{tmp} }

sub uri {
	my ($self, $path) = @_;
	return $path if $path =~ m{\Ahttps?://};
	return $self->{base} . ($path =~ m{\A/} ? $path : "/$path");
}

sub navigate {
	my ($self, $path) = @_;
	return $self->{client}->cmd('WebDriver:Navigate' => { url => $self->uri($path) });
}

# Run a script in the page and return its value.
sub js {
	my ($self, $script) = @_;
	my $result = $self->{client}->js($script);
	return $result ? $result->{value} : undef;
}

# Find an element by CSS selector and return its WebDriver id, or undef when
# there is no such element.  element() is the version that dies.
sub find {
	my ($self, $selector) = @_;
	my $res = eval {
		$self->{client}->cmd('WebDriver:FindElement' => {
			using => 'css selector',
			value => $selector,
		});
	};
	return undef unless $res && ref $res->{value} eq 'HASH';
	return $res->{value}{'element-6066-11e4-a52e-4f735466cecf'};
}

sub element {
	my ($self, $selector) = @_;
	my $id = $self->find($selector);
	die "no element matches $selector\n" unless $id;
	return $id;
}

sub click {
	my ($self, $selector) = @_;
	my $id = ref $selector ? $selector : $self->element($selector);
	return $self->{client}->cmd('WebDriver:ElementClick' => { id => $id });
}

# Focus an element without a key press.  The presses that follow are real; a
# test that has to put focus somewhere first should not depend on the Tab order
# of an unrelated part of the page.
sub focus {
	my ($self, $selector) = @_;
	my $quoted = encode_json($selector);
	return $self->js(
		"var e = document.querySelector($quoted); if (e) { e.focus(); } "
		. "return e ? (e.id || e.getAttribute('class') || e.tagName) : null;"
	);
}

# Press keys through the browser's input stack.  A modifier holds for the keys
# in this call, which is how Shift+ArrowRight is one press.  Each call releases
# its keys afterwards so a failed assertion cannot leave Shift down for the
# next one.
sub press {
	my ($self, $keys, %opt) = @_;

	my @keys = ref $keys eq 'ARRAY' ? @$keys : ($keys);
	my @actions;

	my @modifiers = grep { $opt{$_} } qw(shift control alt meta);
	my @held      = map { $KEY{$_} } @modifiers;
	push @actions, map { { type => 'keyDown', value => $_ } } @held;

	for my $key (@keys) {
		my $value = _key_value($key);
		push @actions,
			{ type => 'keyDown', value => $value },
			{ type => 'keyUp',   value => $value };
	}

	push @actions, map { { type => 'keyUp', value => $_ } } reverse @held;

	$self->{client}->cmd('WebDriver:PerformActions' => {
		actions => [ { type => 'key', id => 'keyboard', actions => \@actions } ],
	});
	$self->{client}->cmd('WebDriver:ReleaseActions' => {});

	return;
}

sub _key_value {
	my ($key) = @_;
	return $KEY{ lc $key } if defined $KEY{ lc $key };
	return $key;
}

# Send text to an element, as a real keyboard would, one character at a time
# by the browser's own send-keys implementation.  Typing into a text field is
# not the same as setting its value: the page's input and change handlers run.
sub send_keys {
	my ($self, $selector, $text) = @_;
	my $id = ref $selector ? $selector : $self->element($selector);
	return $self->{client}->cmd('WebDriver:ElementSendKeys' => { id => $id, text => $text });
}

# What has focus, in a form a test can assert on: its id, its class, its text.
sub active {
	my ($self) = @_;
	return $self->js(<<'JS');
var e = document.activeElement;
if (!e) return null;
/* The body's text is the whole page, which no test wants back; a control's is
 * the label it is known by. */
var text = (e.textContent || '').replace(/\s+/g, ' ').trim().slice(0, 120);
var json = JSON.stringify({
	id    : e.id || '',
	tag   : e.tagName || '',
	class : e.getAttribute('class') || '',
	text  : text,
	value : e.value === undefined ? '' : String(e.value),
});
/* The label may be an emoji or an accented word.  Escape it here, so the string
 * the test decodes is ASCII: the browser has already decoded the page's
 * characters, and decoding them a second time is an error. */
return json.replace(/[^\x20-\x7e]/g, function (c) {
	return '\\u' + ('0000' + c.charCodeAt(0).toString(16)).slice(-4);
});
JS
}

# Poll a coderef until it returns something true.  Returns that value, or the
# last value seen when the timeout runs out.
sub wait_for {
	my ($self, $code, %opt) = @_;

	my $timeout  = defined $opt{timeout}  ? $opt{timeout}  : 10;
	my $interval = defined $opt{interval} ? $opt{interval} : 0.05;
	my $tries    = int($timeout / $interval) + 1;

	my $last;
	for (1 .. $tries) {
		$last = eval { $code->() };
		return $last if $last;
		sleep $interval;
	}

	return $last;
}

# The PATCHes the app recorded before routing, when record_patches was asked
# for.  Anything recorded after the setup PATCH was sent by the page.
sub patches {
	my ($self) = @_;

	return () unless $self->{record_patches} && -s $self->{patch_file};

	open my $fh, '<', $self->{patch_file} or return ();
	my @rows;
	while (my $line = <$fh>) {
		chomp $line;
		next unless length $line;
		my $row = eval { decode_json($line) };
		push @rows, $row if $row;
	}
	close $fh;

	return @rows;
}

sub patch_count {
	my ($self) = @_;
	my @rows = $self->patches;
	return scalar @rows;
}

sub _read_text {
	my ($self, $path) = @_;

	open my $fh, '<', $path or return "(no $path)";
	local $/;
	my $text = <$fh>;
	close $fh;

	$text = '' unless defined $text;
	$text = substr($text, -2000) if length $text > 2000;

	return $text;
}

sub server_log  { return $_[0]->_read_text($_[0]->{server_log}) }
sub firefox_log { return $_[0]->_read_text($_[0]->{firefox_log}) }

# ---------------------------------------------------------------------------
# Stopping: the browser first, since nothing after it needs the app.
# ---------------------------------------------------------------------------
sub stop {
	my ($self) = @_;

	return if $self->{stopped}++;
	local $?;

	$self->{client}->close if $self->{client};
	$self->{client} = undef;

	_stop_process($self->{firefox_pid});
	_stop_process($self->{server_pid});

	$self->{firefox_pid} = undef;
	$self->{server_pid}  = undef;

	# Best effort: a helper the browser left behind can still be writing, and
	# a test that has finished is not the place to complain about it.
	if ($self->{tmp}) {
		File::Path::remove_tree($self->{tmp}, { error => \my $err });
		$self->{tmp} = undef;
	}

	return;
}

sub _stop_process {
	my ($pid) = @_;

	return unless defined $pid && $pid > 0;
	kill 'TERM', $pid or return;

	for (1 .. 50) {
		return if waitpid($pid, WNOHANG) == $pid;
		sleep 0.1;
	}

	kill 'KILL', $pid;
	waitpid($pid, 0);

	return;
}

sub DESTROY {
	my ($self) = @_;
	return if $self->{stopped};
	$self->stop;
	return;
}

1;
