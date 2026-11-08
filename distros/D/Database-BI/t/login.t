#!/usr/bin/env perl

# The login: off unless password_hash is set; with it, every page but the
# login, the share and embed links asks for the password first.
#
#   prove -l t/login.t

use strict;
use warnings;

use Test::Most;
use Test::Mojo;

use File::Spec;
use File::Temp qw(tempdir);
use IPC::Open3 qw(open3);
use Mojo::URL;
use Mojo::Util qw(url_escape);
use Symbol qw(gensym);

use Database::BI::Password qw(hash_password verify_password is_password_hash);

my $PASSWORD = 'correct horse';
my $HASH     = hash_password($PASSWORD, rounds => 10_000);
my $HTML     = { Accept => 'text/html' };

# A password needs export_dirs (see 'a password keeps exports to their
# folders'), so an app with one gets a folder unless the test names its own.
sub app_with {
	my (%config) = @_;
	$config{export_dirs} //= [ tempdir(CLEANUP => 1) ] if $config{password_hash} && !exists $config{export_dirs};
	return Test::Mojo->new('Database::BI', { model_dir => tempdir(CLEANUP => 1), %config });
}

sub log_in {
	my ($t, $password, $return) = @_;
	return $t->post_ok('/login' => form => { password => $password, (defined $return ? (return => $return) : ()) });
}

subtest 'the hash' => sub {
	# RFC 7914 section 11 and the usual PBKDF2-HMAC-SHA256 vectors.
	my $pbkdf2 = \&Database::BI::Password::_pbkdf2;
	is unpack('H*', $pbkdf2->('password', 'salt', 1, 32)),
		'120fb6cffcf8b32c43e7225256c4f837a86548c92ccc35480805987cb70be17b', 'one round';
	is unpack('H*', $pbkdf2->('password', 'salt', 4096, 32)),
		'c5e478d59288c841aa530db6845c4c8d962893a001ce4e11a4963873aa98134a', '4096 rounds';
	is unpack('H*', $pbkdf2->('passwordPASSWORDpassword', 'saltSALTsaltSALTsaltSALTsaltSALTsalt', 4096, 40)),
		'348c89dbcbd32b2f32d814b8116e84cf2b17347ebc1800181c4e2a1fb8dd53e1c635518c7dac47e9', 'a key longer than one block';

	like $HASH, qr{\Apbkdf2-sha256\$10000\$[A-Za-z0-9+/]{22}\$[A-Za-z0-9+/]{43}\z}, 'the stored form';
	like hash_password('x'), qr{\Apbkdf2-sha256\$200000\$}, '200_000 rounds by default';
	isnt hash_password('x', rounds => 10_000), hash_password('x', rounds => 10_000), 'a new salt each time';
	is hash_password('x', rounds => 10_000, salt => 'a' x 16), hash_password('x', rounds => 10_000, salt => 'a' x 16),
		'the same salt gives the same hash';

	ok verify_password($PASSWORD, $HASH), 'the password matches';
	ok !verify_password('correct horsE', $HASH), 'one letter different does not';
	ok !verify_password('', $HASH), 'nor does none';
	ok !verify_password(undef, $HASH), 'nor undef';
	ok !verify_password($PASSWORD, 'pbkdf2-sha256$10000$x$y'), 'nor a broken hash';

	my $accented = "caf\x{e9} \x{10D}";
	my $h = hash_password($accented, rounds => 10_000);
	ok verify_password($accented, $h), 'a password past ASCII';
	ok !verify_password('cafe c', $h), '... is not its ASCII look-alike';

	ok is_password_hash($HASH), 'is_password_hash knows one';
	ok !is_password_hash($_ // 'undef'), "is_password_hash refuses $_"
		for ('secret', 'pbkdf2-sha256$999$' . ('a' x 22) . '$' . ('b' x 43), '', [$HASH]);

	throws_ok { hash_password('') } qr/password is required/, 'no empty password';
	throws_ok { hash_password('x', rounds => 9_999) } qr/rounds/, 'not too few rounds';
	throws_ok { hash_password('x', salt => 'short') } qr/salt/, 'a salt is 16 bytes';
};

subtest 'off unless password_hash is set' => sub {
	my $t = app_with();
	$t->get_ok('/', $HTML)->status_is(200)->element_exists_not('#site-nav-logout', 'no Log out button');
	$t->get_ok('/calc/list?l=table:sales')->status_is(200);
	$t->get_ok('/login', $HTML)->status_is(200)->element_exists('#login-off')->element_exists_not('#login-password',
		'/login says there is no password, and offers no form');
	$t->post_ok('/login' => form => { password => 'x' })->status_is(302)->header_is(Location => '/');
	$t->post_ok('/logout')->status_is(302)->header_is(Location => '/');
	app_with(password_hash => '')->get_ok('/calc/list?l=table:sales')->status_is(200, "'' is off too");
};

subtest 'every page asks for the password' => sub {
	my $t = app_with(password_hash => $HASH);

	$t->get_ok('/view/sales?f=region:eq:North', $HTML)->status_is(302, 'a browser asking for a page');
	my $to = Mojo::URL->new($t->tx->res->headers->location);
	is $to->path->to_string, '/login', 'is sent to log in';
	is(Mojo::URL->new($to->query->param('return'))->query->param('f'), 'region:eq:North', 'then back to that page, filter and all');
	for my $url ('/', '/canvases', '/preferences', '/tutorial', '/browse', '/bar?l=table:sales&cat=region&val=amount') {
		$t->get_ok($url, $HTML)->status_is(302, "$url too")->header_like(Location => qr{\A/login\?return=});
	}
	$t->get_ok('/calc/list?l=table:sales')->status_is(401, 'a script or a page script')
		->json_is('/error' => 'Log in first: this server asks for a password.');
	$t->get_ok('/api/dirs', $HTML)->status_is(401, 'an /api/ route, even from a browser');
	$t->get_ok('/export?l=table:sales&format=csv')->status_is(401, 'a download');
	my $dir = tempdir(CLEANUP => 1);
	$t->post_ok('/export' => form => { l => 'table:sales', dir => $dir, filename => 'x.csv' })->status_is(401, 'a write');
	ok !-e "$dir/x.csv", '... which writes nothing';
	$t->post_ok('/uploads/clear')->status_is(401);
	$t->get_ok('/no/such/page', $HTML)->status_is(404, 'a page that is not there is a 404, which shows no data');

	$t->get_ok('/login?return=/view/sales', $HTML)->status_is(200)
		->element_exists('#login-password[type="password"][autocomplete="current-password"]')
		->element_exists('input[name="return"][value="/view/sales"]', 'the form carries where to go next')
		->element_exists_not('#site-nav-logout', 'no Log out before logging in');
};

subtest 'logging in and out' => sub {
	my $t = app_with(password_hash => $HASH);

	log_in($t, 'wrong', '/view/sales')->status_is(401)->element_exists('#login-error')
		->text_like('#login-error' => qr/not the password/);
	ok !(grep { $_->name eq 'database_bi' } @{ $t->tx->res->cookies }), 'no session for a wrong password';

	log_in($t, $PASSWORD, '/view/sales?f=region:eq:North')->status_is(302)
		->header_is(Location => '/view/sales?f=region:eq:North', 'the right one goes where it was going');
	my ($cookie) = grep { $_->name eq 'database_bi' } @{ $t->tx->res->cookies };
	ok $cookie, 'and starts a session';
	ok $cookie->httponly, 'which page scripts cannot read';
	is lc($cookie->samesite // ''), 'lax', 'and another site cannot send';
	ok !$cookie->secure, 'over http it cannot be Secure, or the browser would drop it';
	unlike $cookie->value, qr/\Q$HASH\E/, 'the cookie does not carry the hash';

	$t->get_ok('/view/sales', $HTML)->status_is(200)->element_exists('#site-nav-logout', 'Log out is offered');
	$t->get_ok('/calc/list?l=table:sales')->status_is(200);
	$t->get_ok('/login?return=/canvases', $HTML)->status_is(302)->header_is(Location => '/canvases',
		'the login page sends a logged-in reader on');

	$t->post_ok('/logout')->status_is(302)->header_is(Location => '/login');
	$t->get_ok('/view/sales', $HTML)->status_is(302, 'logged out');
	$t->get_ok('/calc/list?l=table:sales')->status_is(401);

	log_in($t, $PASSWORD)->status_is(302)->header_is(Location => '/', 'with no return=, the home page');
};

subtest 'only to a page of this site' => sub {
	my $t = app_with(password_hash => $HASH);
	for my $return ('//evil.example/', '/\\evil.example', 'https://evil.example/', 'evil.example', "/x\r\nSet-Cookie: a=b",
			'/login', '/logout', '') {
		log_in($t, $PASSWORD, $return)->status_is(302)->header_is(Location => '/', "return=$return goes home");
		$t->post_ok('/logout');
		$t->get_ok('/login?return=' . url_escape($return), $HTML)
			->element_exists('input[name="return"][value="/"]', "... and the form never carries it");
	}
};

subtest 'a new password logs everyone out' => sub {
	my $t = app_with(password_hash => $HASH);
	log_in($t, $PASSWORD)->status_is(302);
	$t->get_ok('/calc/list?l=table:sales')->status_is(200);
	$t->app->config->{password_hash} = hash_password('another', rounds => 10_000);
	$t->get_ok('/calc/list?l=table:sales')->status_is(401, 'the old session is not logged in');
	log_in($t, $PASSWORD)->status_is(401, 'nor is the old password');
	log_in($t, 'another')->status_is(302);
	$t->get_ok('/calc/list?l=table:sales')->status_is(200, 'the new one is');
};

subtest 'guessing' => sub {
	my $t = app_with(password_hash => $HASH);
	log_in($t, "wrong $_")->status_is(401) for 1 .. 10;
	log_in($t, $PASSWORD)->status_is(429, 'after ten wrong passwords even the right one waits')
		->text_like('#login-error' => qr/Too many wrong passwords from this address\. Try again in 15 minutes\./);
	$t->get_ok('/calc/list?l=table:sales')->status_is(401, 'and nothing is let in');
};

subtest 'from another site' => sub {
	my $t = app_with(password_hash => $HASH);
	$t->post_ok('/login' => { Origin => 'https://evil.example' } => form => { password => $PASSWORD })
		->status_is(403, 'a login posted from another site is refused');
	ok !(grep { $_->name eq 'database_bi' } @{ $t->tx->res->cookies }), '... and starts no session';
	log_in($t, $PASSWORD);
	$t->post_ok('/logout' => { 'Sec-Fetch-Site' => 'cross-site' })->status_is(403, 'so is a logout');
	$t->get_ok('/calc/list?l=table:sales')->status_is(200, '... which left the reader logged in');
};

subtest 'over https the cookie is Secure' => sub {
	local $ENV{MOJO_REVERSE_PROXY} = 1;
	my $t = app_with(password_hash => $HASH);
	$t->post_ok('/login' => { 'X-Forwarded-Proto' => 'https' } => form => { password => $PASSWORD })->status_is(302);
	my ($cookie) = grep { $_->name eq 'database_bi' } @{ $t->tx->res->cookies };
	ok $cookie && $cookie->secure, 'Secure, so it is never sent over http';
};

subtest 'Secure is decided per request, and a whole-app secure still holds' => sub {
	local $ENV{MOJO_REVERSE_PROXY} = 1;
	my $t = app_with(password_hash => $HASH);
	my $secure = sub {
		my (%headers) = @_;
		$t->post_ok('/login' => \%headers => form => { password => $PASSWORD })->status_is(302);
		my ($cookie) = grep { $_->name eq 'database_bi' } @{ $t->tx->res->cookies };
		return $cookie ? ($cookie->secure ? 1 : 0) : undef;
	};
	is $secure->('X-Forwarded-Proto' => 'https'), 1, 'over https: Secure';
	is $secure->(), 0, 'then over http on the same server: not, as it was only for that request';
	ok !$t->app->sessions->secure, 'and the setting itself is left as it was';
	$t->app->sessions->secure(1);
	is $secure->(), 1, 'with secure set for the whole application, Secure over http too';
};

subtest 'share and embed links need no login' => sub {
	my $t = app_with(password_hash => $HASH);
	log_in($t, $PASSWORD);
	$t->post_ok('/api/analyses' => json => {
		name     => 'Report',
		datasets => [ { spec => 'table:sales' } ],
		visuals  => [ { kind => 'bar', encode => { cat => 'region', value => 'amount' } } ],
	})->status_is(201);
	my $id = $t->tx->res->json->{id};
	my $token = $t->post_ok("/api/analyses/$id/share")->status_is(200)->tx->res->json->{token};
	$t->post_ok('/logout');

	my $q = '?token=' . url_escape($token);
	$t->get_ok("/share/$id$q", $HTML)->status_is(200, 'a share link opens logged out');
	$t->get_ok("/embed/$id$q", $HTML)->status_is(200, 'so does an embed link');
	$t->get_ok("/share/$id", $HTML)->status_is(401, 'not without its token');
	$t->get_ok("/share/$id?token=x", $HTML)->status_is(403, 'nor with a wrong one');
	$t->get_ok("/a/$id", $HTML)->status_is(302, 'the canvas itself asks for the password');
	$t->get_ok("/share/$id$q", $HTML)->element_exists_not('#site-nav-logout');
};

subtest 'a share link cannot be made without the key' => sub {
	require Digest::SHA;
	require MIME::Base64;
	my $sign = sub {
		my ($id, $key) = @_;
		my $payload = "$id|" . (time() + 86_400 * 3650);
		return url_escape(MIME::Base64::encode_base64url("$payload|" . Digest::SHA::hmac_sha256_hex($payload, $key)));
	};
	for my $config ([], [ secrets => ['a long secret for the tests'] ]) {
		my $t = app_with(password_hash => $HASH, @{$config});
		log_in($t, $PASSWORD);
		$t->post_ok('/api/analyses' => json => {
			name     => 'Private',
			datasets => [ { spec => 'table:sales' } ],
			visuals  => [ { kind => 'bar', encode => { cat => 'region', value => 'amount' } } ],
		})->status_is(201);
		my $id = $t->tx->res->json->{id};
		my $reply = $t->post_ok("/api/analyses/$id/share")->tx->res->json;
		is !!$reply->{lasts_restart}, !!@{$config}, @{$config}
			? 'with secrets set, a link outlives a restart' : 'without, the panel is told a restart ends it';
		$t->post_ok('/logout');
		# Versions before 0.021.0 signed with this, the same on every install.
		$t->get_ok("/share/$id?token=" . $sign->($id, 'BI_DEFAULT_INSECURE_SECRET'), $HTML)
			->status_is(403, 'a token signed with the old fixed key is refused');
		$t->get_ok("/embed/$id?token=" . $sign->($id, 'BI_DEFAULT_INSECURE_SECRET'), $HTML)->status_is(403, '... by embed too');
		$t->get_ok("/share/$id?token=" . $sign->($id, $t->app->secrets->[0]), $HTML)
			->status_is(403, 'and so is one signed with the session key itself');
		$t->get_ok('/share/' . $id . '?token=' . url_escape($reply->{token}), $HTML)->status_is(200, 'the real one works');
		unlike $t->tx->res->body, qr/share_secret not configured/, 'and nothing is said about a default';
	}

	my $u = app_with(password_hash => $HASH, share_secret => 'sixteen chars ok');
	log_in($u, $PASSWORD);
	$u->post_ok('/api/analyses' => json => {
		name => 'Keyed', datasets => [ { spec => 'table:sales' } ],
		visuals => [ { kind => 'bar', encode => { cat => 'region', value => 'amount' } } ],
	});
	my $id = $u->tx->res->json->{id};
	ok $u->post_ok("/api/analyses/$id/share")->tx->res->json->{lasts_restart}, 'share_secret keeps links too';
	$u->post_ok('/logout');
	$u->get_ok("/share/$id?token=" . $sign->($id, 'sixteen chars ok'), $HTML)
		->status_is(200, 'share_secret is the key, as before, so links made with it still work');
};

subtest 'a password keeps exports to their folders' => sub {
	throws_ok { app_with(password_hash => $HASH, export_dirs => undef) }
		qr/export_dirs: with password_hash set, other people can save exports.*add export_dirs =>/,
		'a password without export_dirs stops the start, saying what to add';
	throws_ok { app_with(password_hash => $HASH, export_dirs => []) } qr/export_dirs: with password_hash/, 'so does an empty list';
	my $exports = tempdir(CLEANUP => 1);
	my $t = app_with(password_hash => $HASH, export_dirs => [$exports]);
	log_in($t, $PASSWORD);
	$t->post_ok('/export' => form => { l => 'table:sales', dir => $exports, filename => 'a.csv' })->status_is(200);
	$t->post_ok('/export' => form => { l => 'table:sales', dir => tempdir(CLEANUP => 1), filename => 'a.csv' })
		->status_is(403, 'and anywhere else is refused');
	lives_ok { app_with(export_dirs => undef) } 'without a password, nothing changes';
};

subtest 'startup' => sub {
	throws_ok { app_with(password_hash => 'secret') } qr/password_hash: not a hash made by "script\/database-bi password"/,
		'a plain password is refused, not used';
	throws_ok { app_with(password_hash => [$HASH]) } qr/password_hash/, 'so is a list';
	throws_ok { app_with(share_secret => 'BI_DEFAULT_INSECURE_SECRET') } qr/share_secret: that is the default/,
		'share_secret as the old default, which is in the source';
	throws_ok { app_with(share_secret => 'short') } qr/share_secret: give at least 16/, 'share_secret too short to resist guessing';
	throws_ok { app_with(share_secret => ['a list of secrets']) } qr/share_secret/, 'share_secret as a list';
	lives_ok { app_with(share_secret => '') } 'share_secret empty is as unset';
	for my $bad ('ten', 59, -1, [3600]) {
		throws_ok { app_with(login_expiration => $bad) } qr/login_expiration/, 'login_expiration ' . (ref $bad ? 'list' : $bad);
	}
	my $t = app_with(password_hash => $HASH, login_expiration => 600);
	is $t->app->sessions->default_expiration, 600, 'login_expiration sets how long a session lasts';
	is app_with()->app->sessions->default_expiration, 8 * 3600, 'a working day by default';

	# A server other machines can reach must have a password.
	my $plain   = app_with()->app;
	my $guarded = app_with(password_hash => $HASH)->app;
	my $starts = sub {
		my ($listen, %opts) = @_;
		my $app = $opts{password_hash} ? $guarded : $plain;
		my $hypnotoad = $opts{hypnotoad} // { listen => ['http://127.0.0.1:8080'] };
		return eval { Database::BI::_require_password_if_open($app, $listen, $hypnotoad); 1 } ? '' : $@;
	};
	like $starts->('http://*:3000'), qr/\Alisten: http:\/\/\*:3000 can be reached from other machines, and there is no password/,
		'every interface, no password: no start';
	like $starts->('http://127.0.0.1:3000,http://192.168.1.2:3000'), qr/192\.168\.1\.2/, 'one address that is not loopback is enough';
	like $starts->('http://*:3000?fd=3'), qr/http:\/\/\*:3000 can/, "morbo's handed-on socket is named without its fd";
	is $starts->('http://127.0.0.1:3000,http://[::1]:3000,http://localhost:3000,http://127.0.0.2:3000'), '', 'loopback only: it starts';
	is $starts->('http://*:3000', password_hash => $HASH), '', 'with a password: it starts';
	{
		local $ENV{HYPNOTOAD_APP} = 'script/database-bi';
		is $starts->('http://*:3000'), '', "under hypnotoad, its own listen (the default is loopback)";
		like $starts->('http://127.0.0.1:3000', hypnotoad => { listen => ['http://*:8080'] }), qr/\*:8080/,
			'and one on every interface does not start';
	}
	{
		local $ENV{MOJO_LISTEN} = 'http://*:3000';
		throws_ok { app_with() } qr/can be reached from other machines/, 'startup itself refuses it';
		lives_ok { app_with(password_hash => $HASH) } '... unless there is a password';
	}
};

# Startup cannot see a reverse proxy on this machine that forwards other
# machines' requests, so each request is checked too.
subtest 'no password: this machine only' => sub {
	local $ENV{MOJO_REVERSE_PROXY} = 1;
	my $t = app_with();
	$t->get_ok('/preferences', $HTML)->status_is(200, 'from this machine');
	for my $from ('127.0.0.1', '127.0.0.5', '::1', '::ffff:127.0.0.1') {
		$t->get_ok('/preferences', { %{$HTML}, 'X-Forwarded-For' => $from })->status_is(200, "from $from through the proxy");
	}
	for my $from ('192.168.1.20', '203.0.113.9', '::ffff:192.168.1.20', 'fe80::1', '10.0.0.1') {
		$t->get_ok('/preferences', { %{$HTML}, 'X-Forwarded-For' => $from })->status_is(403, "not from $from")
			->content_like(qr/no password, so it answers only the machine it runs on/);
	}
	$t->post_ok('/export', { 'X-Forwarded-For' => '192.168.1.20' } => form => { l => 'table:sales' })
		->status_is(403, 'a write neither')->json_like('/error' => qr/no password/);
	$t->get_ok('/login', { %{$HTML}, 'X-Forwarded-For' => '192.168.1.20' })->status_is(403, 'nor the login page');

	my $tp = app_with(password_hash => $HASH);
	$tp->get_ok('/preferences', { %{$HTML}, 'X-Forwarded-For' => '192.168.1.20' })->status_is(302,
		'with a password, another machine is asked for it');
	log_in($tp, $PASSWORD)->status_is(302);
	$tp->get_ok('/preferences', { %{$HTML}, 'X-Forwarded-For' => '203.0.113.9' })->status_is(200, '... and let in');
};

subtest 'script/database-bi password' => sub {
	my $run = sub {
		my ($input, @args) = @_;
		my $err = gensym;
		my $pid = open3(my $in, my $out, $err, $^X, 'script/database-bi', 'password', @args);
		print {$in} $input if defined $input;
		close $in;
		my $stdout = do { local $/; <$out> } // '';
		my $stderr = do { local $/; <$err> } // '';
		waitpid $pid, 0;
		# On Windows the child writes its lines in text mode, ending \r\n.
		s/\r\n/\n/g for $stdout, $stderr;
		return ($? >> 8, $stdout, $stderr);
	};

	my ($status, $out) = $run->("s3cret pass\n");
	is $status, 0, 'reads the password from a pipe';
	my ($hash) = $out =~ /\A\s*password_hash => '([^']+)',\n\z/;
	ok $hash, 'prints the line for database_bi.conf, and nothing else when not at a terminal' or diag $out;
	ok $hash && verify_password('s3cret pass', $hash), 'a hash of that password';
	unlike $out, qr/s3cret/, 'not the password itself';
	my $t = app_with(password_hash => $hash);
	log_in($t, 's3cret pass')->status_is(302, 'and the server takes it');

	# On Windows a child started by open3 can inherit the write end of its
	# own STDIN pipe, so closing it here never ends its input: a command
	# waiting for end-of-file waits for ever (the Windows CI jobs hung here
	# until their 60-minute limit).  An empty line is the same "no password"
	# without needing end-of-file; elsewhere the empty pipe itself is tried.
	($status, undef, my $err) = $run->($^O eq 'MSWin32' ? "\n" : '');
	isnt $status, 0, 'no password: an error';
	like $err, qr/no password given/, '... that says so';
	($status, undef, $err) = $run->("x\n", 'extra');
	isnt $status, 0, 'arguments: an error';
};

done_testing();
