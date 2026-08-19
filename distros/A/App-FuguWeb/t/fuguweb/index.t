#!/usr/bin/env perl
# ex:ts=8 sw=4:
# App::FuguWeb::Index and the manual groups of App::FuguWeb::Config:
# the group order, the two sort rules, the './' prefix, the escaping,
# an empty group, a missing directory, and the optional opening.
#
# The test builds its sources in a File::Temp directory. It never reads
# the repository, so a change under man/ or lib/ cannot break it.

use v5.36;
use Test::More;
use FindBin qw($RealBin);
use lib "$RealBin/../../lib";
use File::Path qw(make_path);
use File::Temp qw(tempdir);

use_ok('App::FuguWeb::Config');
use_ok('App::FuguWeb::Index');

# The sources that every subtest below shares. The names are chosen so
# that a C sort and a case-insensitive sort disagree: MQTT comes before
# Mdnsd only when the comparison is by byte.
my %SOURCES = (
	'man/tool/tool.1'        => 'the tool',
	'man/tool/tool.conf.5'   => 'the configuration',
	'man/tool/toolctl.8'     => 'the control utility',
	'man/lib/MQTT.3p'        => 'an MQTT client',
	'man/lib/Mdnsd.3p'       => 'an mdnsd client',
	'man/all/every.1'        => 'section one',
	'man/all/every.3p'       => 'section three p',
	'man/all/every.5'        => 'section five',
	'man/all/every.8'        => 'section eight',
	'lib/Thing/Store.pod'    => 'the persistence contract',
	'lib/Thing/Store/Memory.pod' => 'the memory store',
	'lib/Thing.pod'          => 'the umbrella',
);

# build_root($rc):
#	Write the shared sources and one description, and return the
#	project root.
sub build_root ( $rc, $root = undef )
{
	$root //= tempdir( CLEANUP => 1 );
	make_path($root);

	for my $relative ( sort keys %SOURCES ) {
		my $path = "$root/$relative";
		make_path( $path =~ s{/[^/]+$}{}r );

		open my $fh, '>', $path or die "Cannot write $path: $!";
		if ( $relative =~ /\.pod$/ ) {
			my $name = $relative =~ s{^lib/}{}r;
			$name =~ s/\.pod$//;
			$name =~ s{/}{::}g;
			print {$fh} "=head1 NAME\n\n$name - "
			    . "$SOURCES{$relative}\n";
		}
		else {
			print {$fh} ".Sh NAME\n.Nd $SOURCES{$relative}\n";
		}
		close $fh;
	}
	make_path("$root/web");

	open my $fh, '>', "$root/.fuguwebrc"
	    or die "Cannot write the description: $!";
	print {$fh} $rc;
	close $fh;

	return $root;
}

# load($rc):
#	Load a description over the shared sources. Return
#	($config, $reason, $root).
sub load ($rc)
{
	my $root = build_root($rc);
	my $config =
	    App::FuguWeb::Config->load( root => $root, error => \my $reason );

	return ( $config, $reason, $root );
}

my $RC = <<'RC';
site        = Example
module_root = lib

page "manuals.html" {
	title = Manuals
	index = yes
}

manuals "Tool" {
	dir    = man/tool
	anchor = tool
}

modules "Thing modules" {
	dir    = lib/Thing
	anchor = thing
}

manuals "Library" {
	dir       = man/lib
	anchor    = library
	namespace = "Fugu::"
}

manuals "Every section" {
	dir    = man/all
	anchor = every
}
RC

subtest 'the groups keep the order of the description' => sub {
	my ( $config, $reason ) = load($RC);
	ok( $config, 'the description loads' ) or diag $reason;

	my @groups = $config->groups;
	is( scalar @groups, 4, 'four groups' );

	# The two block types interleave as the file wrote them. A
	# reader that took one type and then the other would put
	# Library second.
	is_deeply(
		[ map { $_->heading } @groups ],
		[ 'Tool', 'Thing modules', 'Library', 'Every section' ],
		'manuals and modules interleave in file order'
	);
	is_deeply( [ map { $_->kind } @groups ],
		[ 'manuals', 'modules', 'manuals', 'manuals' ], 'the kinds' );
	is( $groups[2]->namespace, 'Fugu::', 'the namespace' );
	is( $groups[0]->anchor,    'tool',   'the anchor' );
};

subtest 'a manuals group sorts by section and then by byte' => sub {
	my ( $config, $reason ) = load($RC);
	ok( $config, 'the description loads' ) or diag $reason;

	my ($tool) = grep { $_->heading eq 'Tool' } $config->groups;
	is_deeply(
		[ map { $_->page } $tool->manuals ],
		[
			'tool.1.html', 'tool.conf.5.html',
			'toolctl.8.html'
		],
		'the sections come in the order 1, 3p, 5, 8'
	);

	my ($library) = grep { $_->heading eq 'Library' } $config->groups;
	is_deeply(
		[ map { $_->name } $library->manuals ],
		[ 'Fugu::MQTT', 'Fugu::Mdnsd' ],
		'a byte sort puts MQTT before Mdnsd'
	);

	# One group that holds every section. Without it the 3p rung of
	# the ladder is never compared against 5 or 8, and a wrong
	# order there would pass.
	my ($every) = grep { $_->heading eq 'Every section' } $config->groups;
	is_deeply(
		[ map { $_->section } $every->manuals ],
		[qw(1 3p 5 8)],
		'the whole section order, 3p included'
	);
};

subtest 'a directory is not a manual' => sub {
	my $root = build_root($RC);
	mkdir "$root/man/all/sub.1" or die "Cannot create the directory: $!";

	my $config =
	    App::FuguWeb::Config->load( root => $root, error => \my $reason );
	ok( $config, 'the description loads' ) or diag $reason;

	my ($every) = grep { $_->heading eq 'Every section' } $config->groups;
	is_deeply( [ map { $_->section } $every->manuals ],
		[qw(1 3p 5 8)], 'the directory is not among the manuals' );
};

subtest 'a project path with a glob metacharacter still finds them' => sub {
	# Perl's glob splits on whitespace and reads [ ] { } ? ~, so a
	# reader that globbed would lose these manuals or collect a
	# sibling directory's.
	my $parent = tempdir( CLEANUP => 1 );

	for my $awkward ( 'a b', 'c[d]', 'e{f}', 'g?h', '~i' ) {
		my $root = build_root( $RC, "$parent/$awkward" );

		my $config = App::FuguWeb::Config->load( root => $root,
			error => \my $reason );
		ok( $config, "a root named '$awkward' loads" ) or next;

		my ($tool) = grep { $_->heading eq 'Tool' } $config->groups;
		is( scalar $tool->manuals, 3, 'and still finds its manuals' );
	}
};

subtest 'a modules group sorts by path and holds the umbrella' => sub {
	my ( $config, $reason ) = load($RC);
	ok( $config, 'the description loads' ) or diag $reason;

	my ($thing) = grep { $_->kind eq 'modules' } $config->groups;

	# A dot sorts before a slash, so the umbrella comes first and
	# Store.pod stays before Store/Memory.pod.
	is_deeply(
		[ map { $_->name } $thing->manuals ],
		[ 'Thing', 'Thing::Store', 'Thing::Store::Memory' ],
		'the sidecars come in path order'
	);
};

subtest 'the body lists every group and every manual' => sub {
	my ( $config, $reason ) = load($RC);
	ok( $config, 'the description loads' ) or diag $reason;

	my $body = App::FuguWeb::Index->new( config => $config )->body;

	like( $body, qr{^<h1>Manuals</h1>\n}, 'the title of the page block' );
	like( $body, qr{<a href="https://man\.openbsd\.org/">},
		'the opening names the manual host' );

	like( $body, qr{<h2 id="tool">Tool</h2>\n<dl>\n},
		'a heading carries the anchor' );
	my $entry = qq{<dt><a href="./tool.1.html">tool(1)</a></dt>\n}
	    . "<dd>the tool</dd>\n";
	like( $body, qr/\Q$entry\E/,
		'an entry carries the page, the name and the description' );
	like( $body, qr{</dl>\n\n}, 'a blank line closes a group' );

	# A browser reads a relative URL whose first segment holds a
	# colon as a scheme, so every local link keeps its './'.
	my @hrefs = $body =~ m{href="([^"]+)"}g;
	my @bad =
	    grep { /^[A-Za-z][A-Za-z0-9.+-]*:/ && !m{^https?:} } @hrefs;
	is( scalar @bad, 0, 'no link reads as a URL scheme' )
	    or diag "offenders: @bad";
};

subtest 'a page name reaches the href escaped' => sub {
	my $root = build_root($RC);

	# A quote in a manual name would end the attribute early and
	# everything after it would become markup.
	open my $fh, '>', "$root/man/tool/od\"d.1"
	    or plan skip_all => 'this filesystem takes no quote in a name';
	print {$fh} ".Sh NAME\n.Nd a quoted name\n";
	close $fh;

	my $config =
	    App::FuguWeb::Config->load( root => $root, error => \my $reason );
	ok( $config, 'the description loads' ) or diag $reason;

	my $body = App::FuguWeb::Index->new( config => $config )->body;
	like( $body, qr/href="\.\/od&quot;d\.1\.html"/,
		'the quote is escaped in the attribute' );
	unlike( $body, qr/href="\.\/od"d/, 'and the attribute is not broken' );
};

subtest 'a description is escaped' => sub {
	my $root = build_root($RC);
	open my $fh, '>', "$root/man/tool/tool.1"
	    or die "Cannot rewrite the source: $!";
	print {$fh} ".Sh NAME\n.Nd a & b < c\n";
	close $fh;

	my $config =
	    App::FuguWeb::Config->load( root => $root, error => \my $reason );
	ok( $config, 'the description loads' ) or diag $reason;

	my $body = App::FuguWeb::Index->new( config => $config )->body;
	like( $body, qr{<dd>a &amp; b &lt; c</dd>}, 'the entities' );
};

subtest 'an empty group leaves no heading behind' => sub {
	my ( $config, $reason ) = load( <<'RC' );
site = Example

page "manuals.html" {
	title = Manuals
	index = yes
}

manuals "Empty" {
	dir    = web
	anchor = empty
}
RC
	ok( $config, 'the description loads' ) or diag $reason;

	my $body = App::FuguWeb::Index->new( config => $config )->body;
	unlike( $body, qr/Empty/, 'no heading and no list' );
	like( $body, qr/<h1>Manuals<\/h1>/,
		'the opening still has the title' );
};

subtest 'two manuals may not become the same page' => sub {
	# Two sources that render to one name overwrite each other in
	# the staging directory and in the output, and the index then
	# shows two entries that lead to one page.
	my $root = build_root( <<'RC' );
site = Example

manuals "One" {
	dir    = man/tool
	anchor = one
}

manuals "Two" {
	dir    = man/copy
	anchor = two
}
RC
	make_path("$root/man/copy");
	open my $fh, '>', "$root/man/copy/tool.1"
	    or die "Cannot write the second source: $!";
	print {$fh} ".Sh NAME\n.Nd the other tool\n";
	close $fh;

	my $config =
	    App::FuguWeb::Config->load( root => $root, error => \my $reason );
	is( $config, undef, 'the load fails' );
	like( $reason, qr/both become tool\.1\.html/,
		'and names both sources and the page' );
};

subtest 'a group whose directory is absent fails the load' => sub {
	my ( $config, $reason ) = load( <<'RC' );
site = Example

manuals "Gone" {
	dir    = man/gone
	anchor = gone
}
RC
	is( $config, undef, 'the load fails' );
	like( $reason, qr{manuals "Gone" names man/gone},
		'the message names the block and the directory' );

	( $config, $reason ) = load( <<'RC' );
site = Example

modules "No anchor" {
	dir = lib/Thing
}
RC
	is( $config, undef, 'a group with no anchor fails the load' );
	like( $reason, qr{has no anchor}, 'the message says which' );
};

subtest 'a project fragment replaces the opening' => sub {
	my $root = build_root($RC);
	open my $fh, '>', "$root/web/manuals.body.html"
	    or die "Cannot write the fragment: $!";
	print {$fh} "<h1>The manuals</h1>\n\n<p>Read them.</p>\n\n";
	close $fh;

	my $config =
	    App::FuguWeb::Config->load( root => $root, error => \my $reason );
	ok( $config, 'the description loads' ) or diag $reason;

	my $body = App::FuguWeb::Index->new( config => $config )->body;
	like( $body, qr{^<h1>The manuals</h1>\n}, 'the fragment opens' );
	unlike( $body, qr/These pages come from/, 'and replaces the prose' );
	like( $body, qr{<h2 id="tool">Tool</h2>}, 'the groups still follow' );
};

done_testing();
