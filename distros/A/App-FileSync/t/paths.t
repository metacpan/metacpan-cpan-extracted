use strict;
use warnings;
use Test::Most;

use App::FileSync qw(validate_relpath validate_repo_name validate_client_id);
use App::FileSync::Transport::SSH;

# --- relative paths -------------------------------------------------------

for my $good ('a.txt', 'a/b/c.txt', 'dir with space/x', "caf\xc3\xa9.txt",
			  'x' x 255, join('/', ('a') x 100)) {
	my ($ok, $reason) = validate_relpath($good);
	ok($ok, "accepts '$good'") or diag($reason);
}

my %bad = (
	''                => 'empty path',
	'/etc/passwd'     => 'absolute path',
	'C:autoexec.bat'  => 'drive-relative path',
	'a\\b'            => 'backslash in path',
	"a\0b"            => 'NUL in path',
	"a\nb"            => 'control character in path',
	"a\tb"            => 'control character in path',
	'a//b'            => 'empty path component',
	'a/./b'           => 'dot path component',
	'../etc/passwd'   => 'parent path component',
	'a/../../b'       => 'parent path component',
	'a/'              => 'empty path component',
	'/'               => 'absolute path',
	'x' x 4097        => 'path is too long',
	(join '/', 'x' x 256) => 'path component is too long',
);

is((validate_relpath(undef))[1], 'missing path', 'undef is not a path');

for my $path (sort keys %bad) {
	my ($ok, $reason) = validate_relpath($path);
	ok(!$ok, "rejects '$path'") or diag("accepted $path");
	is($reason, $bad{$path}, "  reason for $path");
}

is((validate_relpath([]))[1], 'path is not text', 'a reference is not a path');
is((validate_relpath({}))[0], 0, 'a hash is not a path');

# A NUL must never survive: joining a validated path cannot smuggle one in.
is((validate_relpath("ok/\0../x"))[0], 0, 'NUL anywhere is fatal');

# --- repo and client ids --------------------------------------------------

for my $good ('docs', 'notes-2024', 'a.b_c', 'A1', 'x' x 64) {
	ok((validate_repo_name($good))[0], "accepts repo name '$good'");
	ok((validate_client_id($good))[0], "accepts client id '$good'");
}

for my $bad ('', '-leading', '.hidden', '../escape', 'a/b', 'a b', 'x' x 65,
			 "a\0b", 'a;rm -rf /') {
	my ($ok, $reason) = validate_repo_name($bad);
	ok(!$ok, "rejects repo name '$bad'") or diag("accepted '$bad'");
	ok(defined $reason && length $reason, '  with a reason');
}

is((validate_repo_name(undef))[1], 'missing repo name', 'undef repo name');
is((validate_repo_name([]))[1], 'repo name is not text', 'a reference is not a name');

# --- ssh arguments --------------------------------------------------------

for my $good ('host', 'filesync@host', 'filesync@files.example.com',
			  'user@10.0.0.1', 'user@[2001:db8::1]') {
	ok(App::FileSync::Transport::SSH::valid_server($good), "accepts server '$good'");
}

for my $bad ('', '-oProxyCommand=sh', 'host with space', "host\nother",
			 'host;rm -rf /', 'user@@host', '@host', 'user@',
			 # A leading '-' in the user part would reach ssh as an option.
			 '-v@host', '-oProxyCommand=x@host', '.user@host') {
	ok(!App::FileSync::Transport::SSH::valid_server($bad),
		'rejects server ' . (length $bad ? "'$bad'" : '(empty)'));
}

ok(App::FileSync::Transport::SSH::valid_program('/usr/local/bin/filesync-server'),
	'accepts an absolute server command');
ok(!App::FileSync::Transport::SSH::valid_program('filesync-server; id'),
	'rejects a shell metacharacter in the server command');
ok(!App::FileSync::Transport::SSH::valid_program('filesync-server --root /'),
	'rejects spaces in the server command');
ok(!App::FileSync::Transport::SSH::valid_program('-oProxyCommand=sh'),
	'rejects a server command that looks like an option');
ok(!App::FileSync::Transport::SSH::valid_program(undef), 'rejects a missing server command');

done_testing();
