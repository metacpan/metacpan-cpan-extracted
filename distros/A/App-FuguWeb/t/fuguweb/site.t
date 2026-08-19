#!/usr/bin/env perl
# ex:ts=8 sw=4:
# App::FuguWeb::Site: a small site builds, holds what the description
# names and nothing else, drops the staging directory, and builds a
# second time to the same bytes.
#
# The test builds its site in a File::Temp directory. It never reads
# the repository; t/web/site.t covers the real site.

use v5.36;
use Test::More;
use FindBin qw($RealBin);
use lib "$RealBin/../../lib";
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);

# have($tool):
#	Report whether the program is on the path.
sub have ($tool)
{
	return system("command -v $tool >/dev/null 2>&1") == 0;
}

# The whole file drives the renderers, so the skip comes before the
# first assertion. A plan that arrives after one is not a plan.
plan skip_all => 'mandoc not found'  unless have('mandoc');
plan skip_all => 'lowdown not found' unless have('lowdown');
plan skip_all => 'pod2man not found' unless have('pod2man');

use_ok('App::FuguWeb::Config');
use_ok('App::FuguWeb::Render');
use_ok('App::FuguWeb::Site');
use_ok('Fugu::Log');

my $RC = <<'RC';
site       = Example
source_dir = web
out_dir    = out

nav "index.html" {
	label = Home
}

page "index.html" {
	title = Home
	body  = index.body.html
}

page "readme.html" {
	title    = Readme
	markdown = README.md
}

page "manuals.html" {
	title = Manuals
	index = yes
}

manuals "Manuals" {
	dir    = man
	anchor = manuals
}

modules "Modules" {
	dir    = lib/Thing
	anchor = modules
}
RC

# project():
#	Write a whole small project and return its root.
sub project ()
{
	my $root = tempdir( CLEANUP => 1 );

	my %file = (
		'.fuguwebrc'          => $RC,
		'README.md'           => "# Readme\n\nA paragraph.\n",
		'web/index.body.html' => "<h1>Home</h1>\n",
		'web/footer.body.html' => "<p>ISC.</p>\n",
		'web/robots.txt'      => "User-agent: *\n",

		# Not an asset: a note for the maintainers, not content
		'web/CLAUDE.md' => "# web/\n\nNotes.\n",

		'man/tool.1' => <<'MDOC',
.Dd $Mdocdate: July 27 2026 $
.Dt TOOL 1
.Os
.Sh NAME
.Nm tool
.Nd a tool
.Sh DESCRIPTION
Words.
MDOC
		'lib/Thing/Depot.pod' => <<'POD',
=head1 NAME

Thing::Depot - the persistence contract

=head1 DESCRIPTION

Words.
POD
	);

	for my $relative ( sort keys %file ) {
		my $path = "$root/$relative";
		make_path( $path =~ s{/[^/]+$}{}r );

		open my $fh, '>', $path or die "Cannot write $path: $!";
		print {$fh} $file{$relative};
		close $fh;
	}

	return $root;
}

# site($root, $out):
#	A site over the project, with a quiet log.
sub site ( $root, $out )
{
	my $config =
	    App::FuguWeb::Config->load( root => $root, error => \my $reason );
	die "$reason\n" unless $config;

	return App::FuguWeb::Site->new(
		config => $config,
		out    => $out,
		log    => Fugu::Log->new( mode => Fugu::Log::MODE_QUIET() ),
	);
}

my $ROOT = project();
my $OUT  = tempdir( CLEANUP => 1 ) . '/out';

subtest 'the build makes the site and nothing else' => sub {
	my $site = site( $ROOT, $OUT );
	ok( $site->build, 'the build succeeds' );
	is( $site->missing_tool, undef, 'and records no missing tool' );

	# The probe is the first step, so the failure names the tool
	# that is missing. Without it the build reaches the lint and
	# reports that a manual source was rejected, which sends the
	# reader to the wrong place.
	my $absent = tempdir( CLEANUP => 1 ) . '/out';
	my $config = site( $ROOT, $absent )->config;
	my $said   = '';

	open my $saved, '>&', \*STDERR or die "Cannot save stderr: $!";
	close STDERR;
	open STDERR, '>', \$said or die 'Cannot capture stderr';

	my $broken = App::FuguWeb::Site->new(
		config => $config,
		out    => $absent,
		render => App::FuguWeb::Render->new(
			config => $config,
			mandoc => '/nonexistent/mandoc',
		),
	);
	my $failed = $broken->build;

	close STDERR;
	open STDERR, '>&', $saved or die "Cannot restore stderr: $!";

	ok( !$failed, 'a build with no mandoc fails' );
	is( $broken->missing_tool, '/nonexistent/mandoc',
		'and the build records the missing tool' );
	like( $said, qr{/nonexistent/mandoc is not installed},
		'and names the tool that is missing' );
	unlike( $said, qr/rejected a manual source/,
		'and does not blame a manual for it' );
	ok( !-e $absent, 'and writes nothing' );

	# The pages of the description, one page per manual, the base
	# stylesheet, and the assets.
	my @expected = qw(
	    index.html readme.html manuals.html
	    tool.1.html Thing::Depot.3p.html
	    style.css robots.txt
	);
	ok( -s "$OUT/$_", "$_ exists and is not empty" ) for @expected;

	# Staging is a build detail and never part of the published
	# tree.
	ok( !-e "$OUT/.man", 'the staging directory is gone' );

	opendir my $dh, $OUT or die "Cannot read $OUT: $!";
	my @entries = grep { $_ ne '.' && $_ ne '..' } readdir $dh;
	closedir $dh;

	my %expected = map { $_ => 1 } @expected;
	my @extra = grep { !$expected{$_} } sort @entries;
	is( scalar @extra, 0, 'the output holds the site only' )
	    or diag "unexpected: @extra";
};

subtest 'each source reaches its page' => sub {
	open my $fh, '<', "$OUT/readme.html" or die "Cannot read: $!";
	my $readme = do { local $/; <$fh> };
	close $fh;
	like( $readme, qr/A paragraph\./, 'lowdown rendered the Markdown' );

	open $fh, '<', "$OUT/manuals.html" or die "Cannot read: $!";
	my $index = do { local $/; <$fh> };
	close $fh;
	like( $index, qr{href="\./tool\.1\.html"}, 'the index lists the page' );
	like( $index, qr/a tool/, 'with the description of its source' );
	like( $index, qr{href="\./Thing::Depot\.3p\.html"},
		'and the sidecar' );

	open $fh, '<', "$OUT/Thing::Depot.3p.html" or die "Cannot read: $!";
	my $module = do { local $/; <$fh> };
	close $fh;
	like( $module, qr/the persistence contract/,
		'pod2man and mandoc rendered the sidecar' );
	like( $module, qr{<title>Thing::Depot\(3p\) },
		'and the chrome carries the title' );
};

subtest 'the site is a pure function of the project' => sub {
	my $second = tempdir( CLEANUP => 1 ) . '/out';
	ok( site( $ROOT, $second )->build, 'the second build succeeds' );

	my $diff = `diff -r '$OUT' '$second' 2>&1`;
	is( $diff, '', 'two builds are byte-identical' );
};

subtest 'a second build over the same directory succeeds' => sub {
	my $site = site( $ROOT, $OUT );
	ok( $site->build, 'the build is idempotent' );
	ok( !-e "$OUT/.man", 'and leaves no staging behind' );
};

subtest 'a stylesheet that is not found fails the build' => sub {
	my $root = project();
	open my $fh, '>>', "$root/.fuguwebrc"
	    or die "Cannot append to the description: $!";
	print {$fh} "stylesheet = web/absent.css\n";
	close $fh;

	my $out = tempdir( CLEANUP => 1 ) . '/out';

	# A site with no stylesheet must not look like a success.
	ok( !site( $root, $out )->build, 'the build fails' );
};

subtest 'clean removes the output directory' => sub {
	my $site = site( $ROOT, $OUT );
	ok( -d $OUT, 'the output is there' );
	ok( $site->clean, 'clean succeeds' );
	ok( !-e $OUT, 'and the directory is gone' );

	ok( $site->clean, 'clean is idempotent' );
};

subtest 'pod_date is the date of the last commit' => sub {
	my $site = site( project(), tempdir( CLEANUP => 1 ) . '/out' );

	# A temporary project is no git checkout, so the fallback
	# answers. Either way the answer is a date and not a file time.
	like( $site->pod_date, qr/^\d{4}-\d{2}-\d{2}$/,
		'the date is an ISO date' );

	SKIP: {
		skip 'git not found', 1 unless have('git');

		# git does not preserve file times, so a build that read
		# one would give different bytes on every checkout. The
		# value has to be the commit date and not merely a date.
		my $root = project();
		my $quiet = '>/dev/null 2>&1';
		my $env = 'GIT_AUTHOR_DATE="2001-02-03T04:05:06 +0000"'
		    . ' GIT_COMMITTER_DATE="2001-02-03T04:05:06 +0000"'
		    . ' GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@example.org'
		    . ' GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@example.org';
		system("cd '$root' && git init -q $quiet") == 0
		    or skip 'git init failed', 1;
		system("cd '$root' && git add -A $quiet") == 0
		    or skip 'git add failed', 1;
		system("cd '$root' && $env git commit -qm one $quiet") == 0
		    or skip 'git commit failed', 1;

		is( site( $root, tempdir( CLEANUP => 1 ) . '/out' )->pod_date,
			'2001-02-03', 'the date of the last commit' );
	}
};

subtest 'a stale staging directory does not reach the next build' => sub {
	my $root = project();
	my $out  = tempdir( CLEANUP => 1 ) . '/out';

	# mandoc reads a cross-reference as a local link when a file of
	# that name sits in its working directory. A stale source left
	# by an interrupted build would therefore turn a reference that
	# belongs on the manual host into a link that leads nowhere.
	open my $fh, '>>', "$root/man/tool.1"
	    or die "Cannot extend the source: $!";
	print {$fh} ".Sh SEE ALSO\n.Xr ghost 1\n";
	close $fh;

	make_path("$out/.man");
	open my $ghost, '>', "$out/.man/ghost.1"
	    or die "Cannot write the stale source: $!";
	print {$ghost} ".Dd \$Mdocdate: July 27 2026 \$\n.Dt GHOST 1\n.Os\n"
	    . ".Sh NAME\n.Nm ghost\n.Nd a source no group names\n";
	close $ghost;

	ok( site( $root, $out )->build, 'the build succeeds' );
	ok( !-e "$out/.man",         'and the staging directory is gone' );
	ok( !-e "$out/ghost.1.html", 'the stale source rendered nothing' );

	open my $page, '<', "$out/tool.1.html" or die "Cannot read: $!";
	my $html = do { local $/; <$page> };
	close $page;

	like( $html, qr{href="https://man\.openbsd\.org/ghost\.1"},
		'and the cross-reference still leaves for the manual host' );
};

subtest 'a page the site no longer holds is removed' => sub {
	my $root = project();
	my $out  = tempdir( CLEANUP => 1 ) . '/out';

	ok( site( $root, $out )->build, 'the first build succeeds' );
	ok( -e "$out/tool.1.html", 'the manual has a page' );

	rename "$root/man/tool.1", "$root/man/renamed.1"
	    or die "Cannot rename the source: $!";

	ok( site( $root, $out )->build, 'the second build succeeds' );
	ok( -e "$out/renamed.1.html", 'the new page is there' );
	ok( !-e "$out/tool.1.html",   'and the old one is gone' );
};

subtest 'the build refuses an output directory it must not own' => sub {
	my $root = project();

	# --out reaches build and clean alike, and the setting it
	# overrides is checked in the description.
	for my $bad ( $root, '/', "$root/..", File::Spec->rootdir ) {
		ok( !site( $root, $bad )->build,
			"the build refuses $bad" );
		ok( !site( $root, $bad )->clean,
			"and the clean refuses it too" );
	}

	ok( -e "$root/.fuguwebrc", 'the project is untouched' );
};

subtest 'clean refuses a directory that no build made' => sub {
	my $root = project();
	my $out  = tempdir( CLEANUP => 1 ) . '/out';
	make_path("$out/deep");

	open my $fh, '>', "$out/deep/keep.txt" or die "Cannot write: $!";
	print {$fh} "important\n";
	close $fh;

	ok( !site( $root, $out )->clean, 'clean fails' );
	ok( -e "$out/deep/keep.txt",     'and removes nothing' );
};

done_testing();
