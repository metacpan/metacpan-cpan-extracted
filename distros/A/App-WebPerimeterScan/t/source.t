use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";

use File::Temp qw(tempdir);
use Test::More;

use App::WebPerimeterScan::Source;

sub _write
{
	my ($path, $content) = @_;

	open my $fh, '>', $path or die "Cannot write $path: $!";
	print $fh $content;
	close $fh;

	return;
}

my $docroot = tempdir(CLEANUP => 1);
mkdir "$docroot/.git" or die $!;
_write("$docroot/.git/config", "[core]\n\trepositoryformatversion = 0\n");
_write("$docroot/.env", 'DB_PASSWORD=x');
_write("$docroot/index.html", '<html></html>');

my $source = App::WebPerimeterScan::Source->new(docroots => [ $docroot ]);

my $hit = $source->file_for('/.git/config');
ok($hit, 'a file under the docroot is resolved');
like($hit->{path}, qr{\.git/config\z}, 'resolved to the real file');
ok(-f $hit->{path}, 'the resolved path exists on disk');
is($hit->{relative}, '.git/config', 'the relative path is reported');

ok(!defined $source->file_for('/../etc/passwd'), 'plain traversal is refused');
ok(!defined $source->file_for('/%2e%2e/%2e%2e/etc/passwd'), 'percent-encoded traversal is refused');
ok(!defined $source->file_for('/missing.txt'), 'a missing file has no entry');
ok(!defined $source->file_for('/'), 'the docroot itself is not a file');
ok(!defined $source->file_for('/.git'), 'a directory is not a file');

my $sensitive = $source->sensitive_on_disk([
	{ path => '/.git/config', id => 'git-exposed',      severity => 'critical' },
	{ path => '/.env',        id => 'env-exposed',      severity => 'critical' },
	{ path => '/.htpasswd',   id => 'htpasswd-exposed', severity => 'critical' },
]);
is(scalar @{$sensitive}, 2, 'only files that really exist are reported');
is_deeply([ map { $_->{probe}{id} } @{$sensitive} ],
	[ qw(git-exposed env-exposed) ], 'the probe ids are carried through');

my $missing = App::WebPerimeterScan::Source->new(docroots => [ '/nonexistent-' . $$ ]);
is_deeply($missing->docroots, [], 'a docroot that does not exist is ignored');

my $srcdir = tempdir(CLEANUP => 1);
mkdir "$srcdir/lib" or die $!;
_write("$srcdir/lib/App.pm", join "\n",
	'package App;',
	"\$r->get('/')->to('X#y');",
	"\$r->get('/view/:table')->to('X#v');",
	"\$r->post('/api/dirs')->to('X#d');",
	"\$r->get('/file.txt')->to('X#f');",
	"my \$v = \$cache->get('key');",
	"\$ua->get(\"http://example.com/\");",
	"\$r->any('/files/*rest')->to('X#r');",
	'',
);
mkdir "$srcdir/.git" or die $!;
_write("$srcdir/.git/hook.pl", "\$r->get('/from-git');\n");

my $index = App::WebPerimeterScan::Source->new(source_dirs => [ $srcdir ]);

my $route = $index->route_for('/view/dogs');
ok($route, 'a parameterised route is matched');
is($route->{pattern}, '/view/:table', 'the right route matched');
is($route->{line}, 3, 'the line number is recorded');
is($route->{method}, 'GET', 'the method is recorded');
like($route->{file}, qr{lib/App\.pm\z}, 'the file is recorded');

ok($index->route_for('/'), 'the root route is matched');
ok($index->route_for('/file.txt'), 'a literal route is matched');
ok(!defined $index->route_for('/view/a/b'), 'one parameter matches one segment only');
ok(!defined $index->route_for('/nothing'), 'an unknown path has no route');
ok(!defined $index->route_for('/fileXtxt'), 'a dot in a route is matched literally');

my $post = $index->route_for('/api/dirs');
is($post->{method}, 'POST', 'the HTTP method of the route is reported');

ok(!(grep { $_->{pattern} eq 'key' } @{ $index->routes }), 'a cache lookup is not a route');
ok(!(grep { $_->{pattern} =~ /^http/ } @{ $index->routes }), 'an HTTP client call is not a route');
ok(!defined $index->route_for('/from-git'), 'files under .git are not indexed');
is($index->route_for('/files/a/b/c')->{pattern}, '/files/*rest', 'a wildcard placeholder matches the rest of the path');
is($index->route_for('/view/dogs?x=1#y')->{pattern}, '/view/:table', 'a query and fragment are ignored');
is(scalar @{ $index->routes }, 5, 'exactly the five real routes');

ok(!defined $source->file_for(undef), 'undef has no file');
ok(!defined $source->file_for('/.git/../.env'), 'a traversal that stays inside is still refused');
is($source->file_for('/%2egit/config')->{relative}, '.git/config', 'percent-encoding is decoded before lookup');

SKIP: {
	skip 'symlinks are not available', 1 unless eval { symlink('', ''); 1 };
	my $outside = tempdir(CLEANUP => 1);
	_write("$outside/secret", 'x');
	symlink("$outside/secret", "$docroot/link") or skip "cannot symlink: $!", 1;
	ok(!defined $source->file_for('/link'), 'a symlink out of the docroot is refused');
}

ok(!eval { App::WebPerimeterScan::Source->new(bogus => 1); 1 }, 'an unknown argument is refused');

done_testing();
