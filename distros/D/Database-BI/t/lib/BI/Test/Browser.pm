package BI::Test::Browser;

# A repeatable browser fixture for the tests that drive the real pages.
#
# One call starts the application in a child process, on an ephemeral port,
# with a throwaway model directory and with the data directory it names, then
# starts a headless Firefox with its own profile and a Marionette connection to
# it.  A test file gets the app's base
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
# Everything a test names as configuration - data_dir, model_dir, platform,
# language and the keys of app_config - is written into the config file the
# application reads during startup, and nothing is applied to the app after it
# exists.  A value handed over afterwards would be invisible to any reader that
# ran in startup(), and a constructor argument would be invisible to everything:
# the app declares platform and language as config keys, not attributes.  So a
# directory a test fills is the directory the app reads, and a value a test
# names is the value the app has.
#
# A test that needs its own data files passes data_dir => $dir: the app reads
# that directory from the home page through /view, the table: specs and the
# canvas.  A test that needs other config values, or fixture files served on
# the app's origin, passes app_config => {...} and static_paths => [...].  The latter are
# extra static roots, so a test can serve the libraries a deployment would
# self-host without putting them in the application's public directory.  A test
# that has to change the application itself - replacing a method, to reach a
# state this machine cannot produce - passes app_setup => sub { my $app = shift;
# ... }, which runs in the child before the server starts.
#
# A test that names a language other than the default also gets a home for the
# app: the controller resolves a language code and then renders
# templates/<platform>/<code>/, so a code with no template directory behind it
# is not a translation but a page that cannot be found, and the distribution
# ships templates/web/en only.  The fixture copies the checkout's templates and
# the default language as the named one, so the app runs in that language;
# nothing is written into the checkout.  See _home_for_language for what the
# copies say about themselves.
#
# language_templates => 0 asks for the opposite state: the config still names
# the language, and there is no template directory behind it, because the app
# runs against the templates the distribution ships.  That is the state an
# operator reaches by setting language => 'de' before adding templates/web/de/,
# and the documented answer is the default language, so the fixture has to be
# able to produce it without building a home.  See _language_home.
#
# A job that has to say what its run covered sets BI_BROWSER_REPORT_DIR, and
# the fixture writes one report file per test file there: the pages that file
# loaded, the canvas cards on them, and whatever the test said with proved().
# One file per test file because the keyboard job runs the glob with -j2, where
# a single shared file would interleave two tests' lines; a test file that opens
# more than one application writes one file per application, since each has its
# own pages to report.  Nothing is written when the variable is unset, so a local
# run behaves exactly as it did.
#
#   my $browser = BI::Test::Browser->new(record_patches => 1);
#   $browser->navigate('/view/sales');
#   $browser->focus('#btn-bar');
#   $browser->press('Enter');
#   $browser->proved('GET /view/sales: Enter on the bar button opens the chart');
#
# Skips are the test file's decision: skip_reason() says why there is no point
# starting, and is undef when there is.

use strict;
use warnings;

use Exporter 'import';
our @EXPORT_OK = qw(find_firefox map_renderer_state geocoder_state);

use File::Copy      ();
use File::Path      ();
use File::Spec      ();
use File::Temp      qw(tempdir);
use IO::Socket::INET ();
use JSON::MaybeXS   qw(encode_json decode_json);
use Mojo::File       qw(path);
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

# map_renderer_state($path) -> $app_setup_coderef
#
# A stand-in for the optional map renderer, answering from a file the test
# writes: "missing", "old" (an HTML::OSM older than 0.12) or "current" (a
# usable one).  Pass the result as app_setup, and the file's contents decide
# what the next request sees, so one server and one browser session can show
# every state without installing or removing the module.
#
# The real probe loads HTML::OSM as a side effect, and the stand-in does too
# when the state says the renderer is usable: without the require, the caller's
# HTML::OSM->new would be sent to a package that was never loaded.
sub map_renderer_state {
	my ($state_file) = @_;

	return sub {
		my $app = shift;

		no warnings 'redefine';
		*Database::BI::Controller::Dashboard::_map_renderer_version = sub {
			my $state = path($state_file)->slurp;
			$state =~ s/\s+\z//;

			if ($state eq 'current') {
				# The floor, not just installation: a copy below it is the
				# "too old" state, which is what the real probe reports.
				return (1, '0.12')
					if eval { require HTML::OSM; HTML::OSM->VERSION(0.12); 1 };

				my $installed = eval { HTML::OSM->VERSION };
				return (0, $installed)
					if defined($installed) && length($installed);

				return (0, undef);
			}

			return (0, undef)  if $state eq 'missing';
			return (0, '0.11') if $state eq 'old';
			die "unknown renderer state '$state'\n";
		};
	};
}

# geocoder_state($path) -> $app_setup_coderef
#
# A stand-in for the optional geocoder, answering from a file the test writes:
# "missing" (Geo::Coder::Free is not installed) or "old" (a copy below the
# floor the application asks for, quoted back as 0.47).  Pass the result as
# app_setup, and the file's contents decide what the next request sees, so one
# server and one browser session show both states without installing or
# removing the module.
#
# The reason is fabricated, as it is in map_renderer_state: the real probe asks
# the installed module for a version, which a test cannot make fail on a
# machine whose copy is new enough.  What is not fabricated is the sentence the
# page shows - the model builds that from _unavailable - so a note read here
# says what it says on a machine in the state the file names.
sub geocoder_state {
	my ($state_file) = @_;

	return sub {
		my $app = shift;

		require Database::BI::Model::Geocode;

		no warnings 'redefine';
		*Database::BI::Model::Geocode::_load_geocoder = sub {
			my $self  = shift;
			my $state = path($state_file)->slurp;
			$state =~ s/\s+\z//;

			die "unknown geocoder state '$state'\n"
				unless $state eq 'missing' || $state eq 'old';

			$self->{'_unavailable'} = $state eq 'missing'
				? 'it is not installed'
				: '0.47 is installed';

			return;
		};
	};
}

# Why not to start at all, or undef to start.  required_files are relative to
# the distribution root, which is where prove runs a test from.
sub skip_reason {
	my ($class, %arg) = @_;

	return 'Not running author tests' unless $ENV{AUTHOR_TESTING};
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

# Fixtures made by this process, so each report file can be named for one of
# them.  A test that opens three applications (t/browser-language.t: the
# configured language, the control and the fallback) would otherwise have each
# write the same file and the last one would erase the rest.
my $INSTANCES = 0;

sub new {
	my ($class, %arg) = @_;

	my $self = bless {
		report_index    => ++$INSTANCES,
		data_dir        => File::Spec->rel2abs($arg{data_dir} || 'data'),
		platform        => $arg{platform} || 'web',
		language        => $arg{language} || 'en',
		# Whether a template tree is built for that language.  On by default, so
		# naming a language runs in it; off means the language has no directory
		# and the default language is what the app falls back to.
		language_templates => defined $arg{language_templates}
			? ($arg{language_templates} ? 1 : 0) : 1,
		record_patches  => $arg{record_patches} ? 1 : 0,
		app_config      => $arg{app_config} || {},
		static_paths    => $arg{static_paths} || [],
		app_setup       => $arg{app_setup},
		stopped         => 0,
	}, $class;

	# No CLEANUP: stop() removes it after the children are dead, which is the
	# only time a directory the browser is still writing to can be removed.
	$self->{tmp} = tempdir();
	$self->{model_dir}  = File::Spec->catdir($self->{tmp}, 'models');
	$self->{patch_file} = File::Spec->catfile($self->{tmp}, 'patches.log');
	$self->{port_file}  = File::Spec->catfile($self->{tmp}, 'server.port');
	$self->{server_log} = File::Spec->catfile($self->{tmp}, 'server.log');

	# Configuration reaches the app through the file MOJO_CONFIG names - the door
	# a deployment uses, which the Config plugin reads inside startup() and
	# merges over the application's own defaults.  Everything the test names goes
	# in there: startup() works out the directory open_table opens by default and
	# where the home page scans once, so a value applied to the app afterwards
	# would be invisible where it mattered, and platform and language as
	# constructor arguments would be invisible to everything, because the app
	# declares them as config keys rather than attributes.  The plugin evals the
	# file as Perl whatever it is called, so the file is Perl returning a hash
	# reference.
	$self->{config_file} = File::Spec->catfile($self->{tmp}, 'config.conf');
	path($self->{config_file})->spurt($self->_config_source);

	# Naming a language is not enough to run in it: the controller resolves a
	# code and then renders templates/<platform>/<code>/, and there is no such
	# directory for anything but the default.  A test that names another one
	# gets a home for the app holding the templates it has plus a copy of them
	# as that language; _start_server passes it through MOJO_HOME.  A test that
	# asks for no tree gets no home, which is how the app is left with the
	# shipped templates and a language it cannot serve.
	$self->{home} = _language_home($self);

	$self->_start_server;
	$self->_start_browser(
		extra_prefs => $arg{prefs} || {},
		headless    => defined $arg{headless} ? $arg{headless} : 1,
	);

	return $self;
}

# The configuration file's contents: one Perl hash reference holding every
# value the test named.  app_config comes last, so it can override any of them -
# it did when the fixture copied it onto the app directly, and a test that says
# both data_dir => $dir and app_config => { data_dir => $other } is asking for
# $other.
sub _config_source {
	my ($self) = @_;

	my %config = (
		data_dir  => $self->{data_dir},
		model_dir => $self->{model_dir},
		platform  => $self->{platform},
		language  => $self->{language},
		%{ $self->{app_config} },
	);

	my @pair;
	for my $key (sort keys %config) {
		# Bare keys, as the application's own config file writes them; a key
		# that is not an identifier is a mistake worth naming here, because
		# the file would otherwise fail to compile in a child process whose
		# error the test only sees as "the app did not start".
		die "BI::Test::Browser: config key '$key' is not an identifier; the app's own keys all are\n"
			unless $key =~ /\A[A-Za-z_][A-Za-z0-9_]*\z/;

		push @pair, "$key => " . _config_value($config{$key}, $key);
	}

	return ("{ " . join(', ', @pair) . " }\n");
}

# One configuration value as Perl source.  A string is always quoted: a bare 007
# would be read as octal, 1.10 as a number and TRUE as a bareword, and a config
# value is whatever the test wrote.  An array or hash reference is a structure
# the app may expect - a list of sources, a per-table override - so it is
# rendered recursively.  Anything else is a code reference or an object, which
# cannot cross to another process; that is refused by name rather than written
# out as something that would not work.
sub _config_value {
	my ($value, $key) = @_;

	return 'undef' unless defined $value;

	if (my $ref = ref $value) {
		return '[' . join(', ', map { _config_value($_, $key) } @{$value}) . ']'
			if $ref eq 'ARRAY';

		return '{ ' . join(', ',
			map { _config_value($_, $key) . ' => ' . _config_value($value->{$_}, $key) }
			sort keys %{$value}
		) . ' }' if $ref eq 'HASH';

		die "BI::Test::Browser: config value '$key' is a $ref; a config file can carry only plain values, arrays and hashes\n";
	}

	# A single-quoted literal needs a backslash or a quote escaped and nothing
	# else: unlike a double-quoted one it gives no meaning to \n or \t, so a
	# newline is written as itself and cannot be turned into two characters by
	# trying to escape it.
	(my $source = $value) =~ s/([\\'])/\\$1/g;

	return "'$source'";
}

# ---------------------------------------------------------------------------
# The app, in a child.  It binds port 0 and writes down the port it was given:
# asking for a free port and then binding it would leave a window in which
# something else takes it, and a test that fails when the machine is busy is
# not testing the app.
# ---------------------------------------------------------------------------
# ---------------------------------------------------------------------------
# A home for a language the distribution does not ship
# ---------------------------------------------------------------------------

# The home the app is started with: one built for the named language, or undef
# to leave the app on the templates the distribution ships.
#
# Undef is a state, not a default: with no home the app resolves the language it
# was configured with, finds no directory for it and answers in the default
# language, which is the documented fallback and the thing a test of that
# fallback has to be able to reach.  Deciding it here rather than inline in new()
# is what lets t/browser-fixture.t check it without starting a browser.
sub _language_home {
	my ($self) = @_;

	return undef if $self->{language} eq 'en'; # the language the distribution ships
	return undef unless $self->{language_templates};

	return _home_for_language($self);
}

# The application home the fixture builds for a non-default language.
#
# templates/ is a copy of the checkout's; under each platform directory the
# default language is copied as the requested one, with two changes.  The
# copy's WRAPPER lines name their own language directory, as a real
# translation's would, so a page is not quietly rendered with the default
# language's layout whatever was resolved.  And the copy's layout marks the
# <html> element with data-language-dir, so a page says which directory it came
# from.  The mark matters because the copies are copies: they say exactly what
# the originals say, and without it a test could not tell a page rendered from
# templates/web/fr from one rendered from templates/web/en - the directory the
# app chose is the thing being tested.
sub _home_for_language {
	my ($self) = @_;

	my $language  = $self->{language};
	my $home      = File::Spec->catdir($self->{tmp}, 'home');
	my $templates = File::Spec->catdir($home, 'templates');

	_copy_tree('templates', $templates);

	for my $platform_dir (glob "$templates/*") {
		next unless -d $platform_dir;

		my $default = File::Spec->catdir($platform_dir, 'en');
		next unless -d $default;

		my $platform = Mojo::File->new($platform_dir)->basename;
		my $target   = File::Spec->catdir($platform_dir, $language);

		_copy_tree($default, $target);
		_own_language_templates($target, $platform, $language);
	}

	return $home;
}

sub _copy_tree {
	my ($source, $target) = @_;

	File::Path::make_path($target) unless -d $target;

	opendir my $dh, $source or die "opendir $source: $!\n";
	my @entries = sort grep { $_ ne '.' && $_ ne '..' } readdir $dh;
	closedir $dh;

	for my $entry (@entries) {
		my $from = File::Spec->catfile($source, $entry);
		my $to   = File::Spec->catfile($target, $entry);

		if (-d $from) {
			_copy_tree($from, $to);
			next;
		}

		File::Copy::copy($from, $to) or die "copy $from to $to: $!\n";
	}

	return $target;
}

# Point one language's copied templates at themselves, and mark the layout.
sub _own_language_templates {
	my ($dir, $platform, $language) = @_;

	opendir my $dh, $dir or die "opendir $dir: $!\n";
	my @entries = sort grep { $_ ne '.' && $_ ne '..' } readdir $dh;
	closedir $dh;

	for my $entry (@entries) {
		my $path = File::Spec->catfile($dir, $entry);

		if (-d $path) {
			_own_language_templates($path, $platform, $language);
			next;
		}
		next unless $path =~ /\.tt\z/;

		open my $in, '<', $path or die "read $path: $!\n";
		my $source = do { local $/; <$in> };
		close $in;

		$source =~ s{(\Q$platform\E)/en/}{$1/$language/}g;
		$source =~ s{<html\b}{<html data-language-dir="$language"}
			if $path =~ m{layouts[\\/]default\.html\.tt\z};

		open my $out, '>', $path or die "write $path: $!\n";
		print {$out} $source;
		close $out;
	}

	return;
}

sub _start_server {
	my ($self) = @_;

	my $pid = fork;
	die "fork: $!" unless defined $pid;

	if (!$pid) {
		open STDOUT, '>', $self->{server_log} or _exit(1);
		open STDERR, '>&', \*STDOUT             or _exit(1);

		# Read by the Config plugin inside startup(), so it has to be in the
		# environment before the application is built.  It carries every value
		# the test named - both directories, the platform and language, and its
		# own app_config keys - so the app is built with no arguments and
		# nothing is set on it afterwards.  A value applied later would have
		# been invisible to whatever startup() read, and platform and language
		# as constructor arguments would have been invisible to everything:
		# Database::BI declares them as config keys, not attributes.
		$ENV{MOJO_CONFIG} = $self->{config_file};

		# A home built for a language has to be the app's home from the start:
		# Mojo::Home->detect() reads MOJO_HOME before it looks at where the class
		# was loaded from, so the renderer's template path, the static path and
		# the controller's template-directory checks all see the same tree.
		$ENV{MOJO_HOME} = $self->{home} if $self->{home};

		require Database::BI;
		my $app = Database::BI->new;

		# A test can serve fixture assets, such as the libraries a deployment
		# self-hosts, from its own temporary directory on the app's origin.
		push @{ $app->static->paths }, @{ $self->{static_paths} }
			if @{ $self->{static_paths} };

		# A test that has to change the application itself, rather than its
		# configuration, gets the app here - in the child, before the server
		# starts.  It is how a test reaches a state this machine cannot
		# produce, such as an optional module that is not installed: replacing
		# one method reaches the same branch the missing module would.
		if (my $setup = $self->{app_setup}) {
			$setup->($app);
		}

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

	my $res = $self->{client}->cmd('WebDriver:Navigate' => { url => $self->uri($path) });

	$self->_record_page($path);

	return $res;
}

# ---------------------------------------------------------------------------
# What this run covered, for the browser jobs to publish
# ---------------------------------------------------------------------------
# A browser job that goes green says the files passed, not which pages they
# opened: t/browser-chart-keys.t and t/browser-language.t both pass, and their
# TAP output looks alike whether one page or five were driven.  So a test can
# say what it established with proved(), and the fixture records the pages it
# loaded, and both go into a report file per test file - per file because the
# keyboard job runs the glob with -j2, where one shared file would interleave
# two tests' lines.
#
# The report is a file rather than a log line because the job turns it into the
# run's summary; the path comes from BI_BROWSER_REPORT_DIR, so a local run that
# does not set it writes nothing and behaves exactly as before.

# What this test established, in a line of its own: a page, a card, the state
# it needed and the thing that proved it.  The line is written when the test
# finishes, so it can be said where the assertions are rather than collected up
# at the end.
sub proved {
	my ($self, $what) = @_;

	push @{ $self->{proved} }, $what;

	return;
}

sub _record_page {
	my ($self, $path) = @_;

	# The directory is created when the report is written, at the end, so it
	# does not exist yet: the switch is the variable, not the directory.
	return unless defined $ENV{BI_BROWSER_REPORT_DIR} && length $ENV{BI_BROWSER_REPORT_DIR};

	# The path alone: the query is the test's data - a temporary file, a language
	# - and the page is what the report is about.  A page loaded twice is
	# recorded once, which is what a reader wants from a coverage list.
	my ($page) = split /\?/, (defined $path ? $path : ''), 2;
	$page = '/' unless defined $page && length $page;

	my $cards = $self->_cards_on_page;
	$self->{pages}{$page} = $cards;

	return;
}

# The canvas cards on the page just loaded, as "title (kind)".  A canvas renders
# its cards in the template, so they are there as soon as navigation returns; a
# page that is not a canvas has none, and the probe answers [] for it.  The kind
# is read from what the card's body actually contains - a table's wrapper, a
# map's summary or notes, a chart's svg - so a card that failed to render is
# reported as 'card' rather than claimed as a chart.
sub _cards_on_page {
	my ($self) = @_;

	my $json = eval {
		$self->js(<<'JS');
return JSON.stringify(Array.prototype.map.call(document.querySelectorAll('.visual-card'), function (card) {
	var body  = card.querySelector('.visual-card-body');
	var title = card.querySelector('.visual-card-title');
	/* Map before chart: a Leaflet pane can hold an svg of vector overlays, and a
	   map card that drew nothing is still a map card because its notes are
	   there - which is the state the absent-renderer jobs are about. */
	var kind  = !body                                        ? 'card'
		: body.querySelector('.visual-table-wrap')           ? 'table'
		: body.querySelector('.map-summary, .map-notes, .leaflet-container') ? 'map'
		: body.querySelector('svg')                          ? 'chart'
		: 'card';

	return (title ? title.textContent.replace(/\s+/g, ' ').trim() : 'untitled') + ' (' + kind + ')';
}));
JS
	};
	return [] unless defined $json;

	my $cards = eval { decode_json($json) };
	return ref $cards eq 'ARRAY' ? $cards : [];
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

# _js_string($string) -> $javascript_literal
#
# A Perl string as a double-quoted JavaScript string literal.  Selectors are
# code, not data, so the fixture quotes them itself rather than asking a JSON
# encoder what a bare string is.
#
# That is not a hypothetical: the keyboard job on CI died six times with
# "hash- or arrayref expected (not a simple scalar, use allow_nonref to allow
# this)" at the line below, because encode_json here is re-exported by
# JSON::MaybeXS from whichever backend it found - Cpanel::JSON::XS, JSON::XS or
# JSON::PP - and a coder without allow_nonref refuses a scalar.  The default has
# moved across their releases (JSON::XS and JSON::PP only enabled it in 4.0 and
# 3.99_01), so a machine with a lenient backend passed while the runner did not.
# Escaping the handful of characters that would end the literal early removes
# the question.
sub _js_string {
	my ($string) = @_;

	my $quoted = q{};
	for my $char (split //, "$string") {
		if    ($char eq '\\') { $quoted .= '\\\\' }
		elsif ($char eq '"')  { $quoted .= '\\"' }
		elsif ($char eq "\n") { $quoted .= '\\n' }
		elsif ($char eq "\r") { $quoted .= '\\r' }
		elsif ($char eq "\t") { $quoted .= '\\t' }
		elsif ($char =~ /[\x00-\x1f\x7f]/ || $char eq "\x{2028}" || $char eq "\x{2029}") {
			$quoted .= sprintf '\\u%04x', ord $char;
		}
		else { $quoted .= $char }
	}

	return qq{"$quoted"};
}

# Focus an element without a key press.  The presses that follow are real; a
# test that has to put focus somewhere first should not depend on the Tab order
# of an unrelated part of the page.
sub focus {
	my ($self, $selector) = @_;
	my $quoted = _js_string($selector);
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

# Write what this file covered, when the job asked for a report.  Called from
# stop and, through it, from DESTROY, so a test that dies still leaves what it
# reached; the guard makes the second call a no-op.
sub _write_report {
	my ($self) = @_;

	return if $self->{report_written}++;

	my $dir = $ENV{BI_BROWSER_REPORT_DIR};
	return unless defined $dir && length $dir;

	File::Path::make_path($dir) unless -d $dir;

	(my $name = $0) =~ s{\A\./}{};
	$name =~ s{.*/}{};

	my @lines = (
		'### ' . $name . ($self->{report_index} > 1 ? " (fixture $self->{report_index})" : ''),
		'',
	);
	push @lines,
		@{ $self->{proved} || [] }
			? map { "- proved: $_" } @{ $self->{proved} }
			: '- proved: no claim made - the pages below are what this file loaded';

	my @pages = sort keys %{ $self->{pages} || {} };
	push @lines, @pages
		? '- pages loaded: ' . join(', ', @pages)
		: '- pages loaded: none';

	for my $page (@pages) {
		my @cards = @{ $self->{pages}{$page} };
		push @lines, "- cards on $page: " . join(', ', @cards) if @cards;
	}
	push @lines, '';

	my $file = File::Spec->catfile(
		$dir,
		$self->{report_index} > 1 ? "$name.$self->{report_index}.md" : "$name.md",
	);
	open(my $fh, '>:raw', $file) or die "Cannot write $file: $!";
	print {$fh} map { "$_\n" } @lines;
	close($fh) or die "Cannot close $file: $!";

	return;
}

# ---------------------------------------------------------------------------
# Stopping: the browser first, since nothing after it needs the app.
# ---------------------------------------------------------------------------
sub stop {
	my ($self) = @_;

	return if $self->{stopped}++;
	local $?;

	$self->_write_report;

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
