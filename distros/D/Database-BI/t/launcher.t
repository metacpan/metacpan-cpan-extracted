#!/usr/bin/env perl

# No script in the distribution may be started by anything but perl.
#
# This is not cosmetic.  perl hands a script whose #! line does not mention perl
# to the interpreter that line names (see perlrun).  With a server there - the
# launcher's shebang was "#!/usr/bin/env morbo" in 0.017.0 - morbo started the
# application as "perl script/database-bi daemon", perl passed it back to
# morbo, and every worker became another morbo: a process a second, each one
# exporting the whole of @INC as PERL5LIB until exec failed with "Argument list
# too long", with every generation keeping the listening socket.  The failure
# takes a minute to appear and then looks like a resource limit, so the shebangs
# are checked here instead.
#
# The scripts are every executable file in MANIFEST plus everything under
# script/ and bin/ - MANIFEST is what a distribution ships, so a script added
# without an entry is caught by t/manifest.t rather than silently skipped here.
# The shebang checks only read the files.  The rest of this file runs the
# launcher, to check what it does with a database named on the command line.
#
#   prove -l t/launcher.t

use strict;
use warnings;

use Test::Most;

use Config;
use File::Basename ();
use File::Spec;
use File::Temp qw(tempdir);
use IPC::Open3 qw(open3);
use Mojo::IOLoop::Server;
use Mojo::UserAgent;
use Mojo::Util qw(url_escape);
use POSIX qw(WNOHANG);
use Symbol qw(gensym);
use Test::Mojo;

my $launcher = 'script/database-bi';

# ---------------------------------------------------------------------------
# Every script starts with a perl shebang
# ---------------------------------------------------------------------------

sub _distribution_scripts {
	my @found;

	open my $mfh, '<', 'MANIFEST' or BAIL_OUT("cannot read MANIFEST: $!");
	while (my $line = <$mfh>) {
		chomp $line;
		next unless length $line;
		my ($file) = split /\s+/, $line;
		next unless defined($file) && -f $file;
		next unless $file =~ m{\A(?:script|bin)/} || -x $file;
		push @found, $file;
	}
	close $mfh;

	return sort @found;
}

my @scripts = _distribution_scripts();

ok(scalar(@scripts), 'the distribution has scripts to check')
	or BAIL_OUT('the MANIFEST scan found no scripts, so it is not testing anything');

ok(scalar(grep { $_ eq $launcher } @scripts), "$launcher is among them")
	or BAIL_OUT("$launcher is missing from the MANIFEST scan");

for my $script (@scripts) {
	open my $fh, '<', $script or BAIL_OUT("cannot read $script: $!");
	my $shebang = <$fh>;
	close $fh;

	like $shebang // '', qr{\A#![^\n]*\bperl\b},
		"$script is started by perl"
		or diag("a non-perl shebang hands the script to that interpreter, "
			. "which restarts it if it is a server");
}

# ---------------------------------------------------------------------------
# The launcher itself, with no arguments, is the reloading development server
# ---------------------------------------------------------------------------

ok(-f $launcher, "$launcher exists") or BAIL_OUT("no $launcher to check");

open my $fh, '<', $launcher or BAIL_OUT("cannot read $launcher: $!");
my $source = do { local $/; <$fh> };
close $fh;

# morbo runs the script as "perl <script> daemon", so a launcher that answered
# with the command list when it has no arguments would not start a server.
like $source // '', qr{Mojo::Server::Morbo},
	'the launcher starts the reloading server itself';
like $source // '', qr{Mojolicious::Commands->start_app},
	'and still hands a command word to the application';

# ---------------------------------------------------------------------------
# Refusals: these exit before any server starts
# ---------------------------------------------------------------------------

# Returns the exit status and everything the launcher printed.
sub _run_launcher {
	my @args = @_;

	local $ENV{MOJO_LISTEN} = 'http://127.0.0.1:' . Mojo::IOLoop::Server->generate_port;
	my $out = gensym;
	my $pid = open3(my $in, $out, undef, $^X, $launcher, @args);
	close $in;
	my $output = do { local $/; <$out> } // '';
	waitpid $pid, 0;

	return ($? >> 8, $output);
}

my $tmp = tempdir(CLEANUP => 1);
my $not_data = File::Spec->catfile($tmp, 'notes.txt');
open my $nfh, '>', $not_data or BAIL_OUT("cannot write $not_data: $!");
print {$nfh} "not a database\n";
close $nfh;

for my $case (
	[ 'two databases',      [ 'data/store.db', 'data/sales.csv' ],       qr/only one database/ ],
	[ 'three databases',    [ 'data/store.db', 'data/sales.csv', 'data/cats.csv' ], qr/only one database/ ],
	[ 'one missing of two', [ 'data/no-such.db', 'data/sales.csv' ],     qr/only one database/ ],
	[ 'a database, then a command', [ 'data/store.db', 'daemon' ],       qr/only one database/ ],
	[ 'a missing file',     [ 'data/no-such.db' ],                       qr/cannot open data\/no-such\.db: no such file/ ],
	[ 'a directory',        [ 'data' ],                                  qr/cannot open data: not a file/ ],
	[ 'an unsupported file', [ $not_data ],                              qr/not a supported file type/ ],
) {
	my ($name, $args, $expected) = @{$case};
	my ($status, $output) = _run_launcher(@{$args});
	is $status, 2, "$name: exits with status 2";
	like $output, $expected, "$name: says why";
}

# ---------------------------------------------------------------------------
# Command words still reach Mojolicious
# ---------------------------------------------------------------------------

{
	my ($status, $output) = _run_launcher('routes');
	is $status, 0, 'a command word still runs';
	like $output, qr{/preferences}, 'and it is the command that ran';

	($status, $output) = _run_launcher('no-such-command');
	isnt $status, 0, 'an unknown word still fails';
	like $output, qr/Unknown command/, 'as an unknown command, not as a missing file';
}

# ---------------------------------------------------------------------------
# GET / with a database named, in-process
# ---------------------------------------------------------------------------

{
	my $file = File::Spec->rel2abs('data/sales.csv');
	my $t    = Test::Mojo->new('Database::BI');

	$t->get_ok('/')->status_is(200, 'with nothing named, / is the list')
		->text_like('title', qr/Choose a Database/);

	local $ENV{BI_OPEN} = $file;

	$t->get_ok('/')->status_is(302, 'a visitor from outside is sent to the database')
		->header_is(Location => '/open?path=' . url_escape($file));

	$t->get_ok('/' => { Referer => 'http://elsewhere.example/page' })
		->status_is(302, 'a link from another site counts as outside');

	$t->get_ok('/' => { Referer => 'not a url' })
		->status_is(302, 'and so does a Referer that is not a URL');

	my $here = $t->ua->server->url->to_abs;
	$t->get_ok('/' => { Referer => $here->clone->path('/open')->to_string })
		->status_is(200, 'the Home link from within the application reaches the list')
		->text_like('title', qr/Choose a Database/);
}

# ---------------------------------------------------------------------------
# The whole way through: the launcher, morbo, the worker, then the browser's view
# ---------------------------------------------------------------------------

SKIP: {
	skip 'morbo does not support fork emulation', 1 if $Config{d_pseudofork};

	# Starts a server on the port, hands the base URL to the code, and always stops it.
	my $with_server = sub {
		my ($port, $command, $code) = @_;

		local $ENV{MOJO_LOG_LEVEL} = 'fatal';

		my $pid = fork // BAIL_OUT("cannot fork: $!");
		if (!$pid) {
			open STDOUT, '>', File::Spec->devnull or POSIX::_exit(1);
			open STDERR, '>', File::Spec->devnull or POSIX::_exit(1);
			exec(@{$command}) or POSIX::_exit(1);
		}

		my $ua = Mojo::UserAgent->new(max_redirects => 3, connect_timeout => 1, inactivity_timeout => 60);
		my $up;
		for (1 .. 60) {
			$up = eval { $ua->head("http://127.0.0.1:$port/preferences")->res->code };
			last if $up;
			select undef, undef, undef, 0.5;
		}

		my $ok = eval { $code->($ua, "http://127.0.0.1:$port", $up); 1 };
		my $error = $@;

		kill 'TERM', $pid;
		for (1 .. 40) {
			last if waitpid($pid, WNOHANG) == $pid;
			select undef, undef, undef, 0.25;
		}
		kill 'KILL', $pid if kill 0, $pid;
		BAIL_OUT("server test died: $error") unless $ok;
		return;
	};

	# Each call has a port of its own; the launcher's server takes it from MOJO_LISTEN.
	my $with_launcher = sub {
		my ($database, $code) = @_;
		my $port = Mojo::IOLoop::Server->generate_port;
		local $ENV{MOJO_LISTEN} = "http://127.0.0.1:$port";
		return $with_server->($port, [ $^X, $launcher, $database ], $code);
	};

	$with_launcher->('data/sales.csv', sub {
		my ($ua, $base, $up) = @_;
		ok $up, 'the server started with a file named';
		my $tx = $ua->get("$base/");
		is $tx->res->code, 200, 'a single table is shown';
		like $tx->res->dom->at('title')->text, qr/sales\.csv/, 'and it is the file named';
		like $tx->req->url->path, qr{\A/open\z}, 'by way of /open';
	});

	$with_launcher->('data/store.db', sub {
		my ($ua, $base, $up) = @_;
		ok $up, 'the server started with a database named';
		my $tx = $ua->get("$base/");
		is $tx->res->code, 200, 'store.db is shown';
		unlike $tx->res->dom->at('title')->text, qr/Choose a Database|not found/i,
			'rather than the list or a 404';
		like $tx->res->body, qr/store/, 'and it is the database named';
	});

	# hypnotoad loads the launcher rather than running it.  With no arguments the
	# launcher starts the development server, which never returns, so this hung;
	# and the file's last value must be the application, or hypnotoad refuses it.
	my ($hypnotoad) = grep { -x $_ } map { File::Spec->catfile($_, 'hypnotoad') }
		grep { defined && length } $Config{installsitescript}, $Config{installscript},
		File::Basename::dirname($^X), File::Spec->path;

	SKIP: {
		skip 'no hypnotoad to run', 1 unless $hypnotoad;

		my $port   = Mojo::IOLoop::Server->generate_port;
		my $config = File::Spec->catfile($tmp, 'hypnotoad.conf');
		my $pid    = File::Spec->catfile($tmp, 'hypnotoad.pid');
		open my $cfh, '>', $config or BAIL_OUT("cannot write $config: $!");
		print {$cfh} "{ hypnotoad => { listen => ['http://127.0.0.1:$port'], workers => 1, pid_file => '$pid' } }\n";
		close $cfh;

		local $ENV{MOJO_CONFIG} = $config;
		delete local @ENV{qw(MOJO_LISTEN MOJO_MODE HYPNOTOAD_REV HYPNOTOAD_APP HYPNOTOAD_EXE BI_OPEN)};

		$with_server->($port, [ $^X, $hypnotoad, '-f', $launcher ], sub {
			my ($ua, $base, $up) = @_;
			ok $up, 'hypnotoad starts the application from the launcher';
			like $ua->get("$base/")->res->dom->at('title')->text, qr/Choose a Database/,
				'and serves the home page';
			ok -s $pid, 'and it is hypnotoad: it wrote its pid file';
		});

		$port = Mojo::IOLoop::Server->generate_port;
		open $cfh, '>', $config or BAIL_OUT("cannot write $config: $!");
		print {$cfh} "{ hypnotoad => { listen => ['http://127.0.0.1:$port'], workers => 1, pid_file => '$pid' } }\n";
		close $cfh;

		local $ENV{BI_OPEN} = File::Spec->rel2abs('data/sales.csv');
		$with_server->($port, [ $^X, $hypnotoad, '-f', $launcher ], sub {
			my ($ua, $base) = @_;
			like $ua->get("$base/")->res->dom->at('title')->text, qr/sales\.csv/,
				'BI_OPEN shows a database under hypnotoad too';
		});
	}
}

# ---------------------------------------------------------------------------
# A server that loads the launcher gets the application, not a server of its own
# ---------------------------------------------------------------------------

{
	# In a child with an alarm: a launcher that starts morbo here never returns.
	my $out = gensym;
	my $pid = open3(my $in, $out, undef, $^X, '-MMojo::Server', '-e',
		'alarm 30; print ref(Mojo::Server->new->load_app(shift)), qq{\n}', $launcher);
	close $in;
	my $output = do { local $/; <$out> } // '';
	waitpid $pid, 0;
	is $?, 0, 'loading the launcher returns';
	like $output, qr/\bDatabase::BI\b/, 'and gives the application';
}

# ---------------------------------------------------------------------------
# Only this machine can reach a server unless the configuration says otherwise
# ---------------------------------------------------------------------------

# Mojolicious listens on every interface by default, which put an application
# with no login on the local network.  Startup now fills MOJO_LISTEN from config
# listen (default http://127.0.0.1:3000) when it is unset, and hypnotoad's
# listen from http://127.0.0.1:8080.
subtest 'where a server listens' => sub {
	my $listen_of = sub {
		my ($config) = @_;
		delete local $ENV{MOJO_LISTEN};
		my $t = Test::Mojo->new('Database::BI', $config);
		return ($ENV{MOJO_LISTEN}, $t->app->config->{hypnotoad});
	};

	my ($env, $hypnotoad) = $listen_of->({});
	is $env, 'http://127.0.0.1:3000', 'morbo, daemon and prefork: this machine only, port 3000';
	is_deeply $hypnotoad, { listen => ['http://127.0.0.1:8080'] }, 'hypnotoad: this machine only, port 8080';

	# Every interface needs a password (t/login.t checks the refusal).
	my $hash = do { require Database::BI::Password; Database::BI::Password::hash_password('pw', rounds => 10_000) };
	($env) = $listen_of->({ listen => 'http://*:3000', password_hash => $hash, export_dirs => [$tmp] });
	is $env, 'http://*:3000', 'listen opens it to every machine';
	($env) = $listen_of->({ listen => ['http://127.0.0.1:4000', 'http://[::1]:4000'] });
	is $env, 'http://127.0.0.1:4000,http://[::1]:4000', 'or names several places';
	($env) = $listen_of->({ listen => 'http://127.0.0.1:4000,http://[::1]:4000' });
	is $env, 'http://127.0.0.1:4000,http://[::1]:4000', 'separated by commas, as MOJO_LISTEN is';

	(undef, $hypnotoad) = $listen_of->({ hypnotoad => { listen => ['http://*:8080'], workers => 2 } });
	is_deeply $hypnotoad, { listen => ['http://*:8080'], workers => 2 }, "hypnotoad's own listen is kept";
	(undef, $hypnotoad) = $listen_of->({ hypnotoad => { workers => 2 } });
	is_deeply $hypnotoad, { listen => ['http://127.0.0.1:8080'], workers => 2 },
		'and the rest of its settings with the default';

	{
		local $ENV{MOJO_LISTEN} = 'http://127.0.0.1:4001';
		Test::Mojo->new('Database::BI', { listen => 'http://*:3000', password_hash => $hash, export_dirs => [$tmp] });
		is $ENV{MOJO_LISTEN}, 'http://127.0.0.1:4001', 'MOJO_LISTEN beats the configuration';
	}

	for my $case (['ftp://example.com', 'another scheme'], ['http://*:3000 junk', 'a space'], ['', 'empty'],
			[[], 'an empty list'], [[undef], 'an undefined place'], [{ port => 3000 }, 'a hash'],
			[['http://*:3000', \1], 'a reference in the list']) {
		my ($bad, $name) = @{$case};
		delete local $ENV{MOJO_LISTEN};
		throws_ok { Test::Mojo->new('Database::BI', { listen => $bad }) } qr/\Alisten: /,
			"listen as $name stops the start";
		ok !defined $ENV{MOJO_LISTEN}, '... and listens nowhere';
	}
};

# The address another machine would reach this one by, if it has one.
# Connecting a UDP socket sends nothing: it only picks the interface.
sub _non_loopback_address {
	require IO::Socket::INET;
	my $socket = IO::Socket::INET->new(Proto => 'udp', PeerAddr => '192.0.2.1', PeerPort => 9) or return;
	my $address = $socket->sockhost;
	return (defined $address && $address !~ /\A(?:127\.|0\.)/) ? $address : undef;
}

SKIP: {
	skip 'morbo does not support fork emulation', 1 if $Config{d_pseudofork};
	my $address = _non_loopback_address();
	skip 'this machine has no address but loopback', 1 unless $address;

	# Started with no -l and no MOJO_LISTEN; the configuration names the port.
	my $hash = do { require Database::BI::Password; Database::BI::Password::hash_password('pw', rounds => 10_000) };
	my $reaches = sub {
		my ($command, $where, $password) = @_;
		my $port   = Mojo::IOLoop::Server->generate_port;
		my $config = File::Spec->catfile($tmp, 'listen.conf');
		open my $cfh, '>', $config or BAIL_OUT("cannot write $config: $!");
		print {$cfh} "{ listen => ['http://$where:$port']", ($password ? ", password_hash => '$hash', export_dirs => ['$tmp']" : ''), " }\n";
		close $cfh;

		local $ENV{MOJO_CONFIG}    = $config;
		local $ENV{MOJO_LOG_LEVEL} = 'fatal';
		delete local @ENV{qw(MOJO_LISTEN BI_OPEN)};
		my $pid = fork // BAIL_OUT("cannot fork: $!");
		if (!$pid) {
			open STDOUT, '>', File::Spec->devnull or POSIX::_exit(1);
			open STDERR, '>', File::Spec->devnull or POSIX::_exit(1);
			exec($^X, $launcher, @{$command}) or POSIX::_exit(1);
		}

		my $ua = Mojo::UserAgent->new(connect_timeout => 1, inactivity_timeout => 30);
		my ($local, $remote, $exited);
		for (1 .. 60) {
			$local = eval { $ua->head("http://127.0.0.1:$port/preferences")->res->code };
			last if $local;
			if (waitpid($pid, WNOHANG) == $pid) { $exited = 1; last }
			select undef, undef, undef, 0.5;
		}
		return (undef, undef, 1) if $exited;
		$remote = eval { $ua->head("http://$address:$port/preferences")->res->code };

		kill 'TERM', $pid;
		for (1 .. 40) {
			last if waitpid($pid, WNOHANG) == $pid;
			select undef, undef, undef, 0.25;
		}
		kill 'KILL', $pid if kill 0, $pid;
		return ($local, $remote);
	};

	for my $command ([], ['daemon']) {
		my $name = @{$command} ? 'daemon' : 'the launcher (morbo)';
		my ($local, $remote) = $reaches->($command, '127.0.0.1');
		is $local, 200, "$name on 127.0.0.1 answers this machine";
		ok !$remote, "and not $address";

		# Every interface needs a password: without one the server does not start.
		my $exited;
		($local, $remote, $exited) = $reaches->($command, '*');
		ok $exited && !$local, "$name on * with no password does not start";

		($local, $remote) = $reaches->($command, '*', 1);
		is $local,  401, "$name on * with a password answers this machine, and asks for the password";
		is $remote, 401, "and $address, the same way";
	}
}

done_testing();
