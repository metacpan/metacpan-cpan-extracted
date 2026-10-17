#!/usr/bin/env perl
# ex:ts=8 sw=4:
# App::FuguWeb::Index and the manual groups of App::FuguWeb::Config:
# the group order, the two sort rules, the './' prefix, the escaping,
# an empty group, a missing directory, the group name, the heading of
# each language, and the body that opens the index.
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
#
# The dot-named source of man/all proves the dot rule: a group must
# not take a name that starts with a dot.
my %SOURCES = (
	'man/tool/tool.1'        => 'the tool',
	'man/tool/tool.conf.5'   => 'the configuration',
	'man/tool/toolctl.8'     => 'the control utility',
	'man/lib/MQTT.3p'        => 'an MQTT client',
	'man/lib/Mdnsd.3p'       => 'an mdnsd client',
	'man/all/every.1'        => 'section one',
	'man/all/every.3p'       => 'section three p',
	'man/all/every.5'        => 'section five',
	'man/all/every.7'        => 'section seven',
	'man/all/every.8'        => 'section eight',
	'man/all/.hidden.1'      => 'a hidden source',
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

manuals tool {
	heading = Tool
	dir     = man/tool
}

modules thing {
	heading = Thing modules
	dir     = lib/Thing
}

manuals library {
	heading   = Library
	dir       = man/lib
	namespace = "Fugu::"
}

manuals every {
	heading = Every section
	dir     = man/all
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
	is_deeply( [ map { $_->name } @groups ],
		[qw(tool thing library every)], 'the name of each group' );
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
		'the sections come in the order 1, 5, 8'
	);

	my ($library) = grep { $_->heading eq 'Library' } $config->groups;
	is_deeply(
		[ map { $_->name } $library->manuals ],
		[ 'Fugu::MQTT', 'Fugu::Mdnsd' ],
		'a byte sort puts MQTT before Mdnsd'
	);

	# One group that holds every section. Without it the 3p rung of
	# the ladder is never compared against 5, 7 or 8, and a wrong
	# order there would pass.
	my ($every) = grep { $_->heading eq 'Every section' } $config->groups;
	is_deeply(
		[ map { $_->section } $every->manuals ],
		[qw(1 3p 5 7 8)],
		'the whole section order, 3p and 7 included'
	);

	# The same group holds '.hidden.1'. A reader that took it would
	# add a second page of section 1 here.
	is_deeply(
		[ map { $_->page } $every->manuals ],
		[
			'every.1.html', 'every.3p.html',
			'every.5.html', 'every.7.html',
			'every.8.html'
		],
		'a name that starts with a dot is not a manual'
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
		[qw(1 3p 5 7 8)], 'the directory is not among the manuals' );
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

	my $body = App::FuguWeb::Index->new( config => $config )->body('Manuals');

	like( $body, qr{^<h1>Manuals</h1>\n\n<h2 id="tool">},
		'the title of the page block, and then the first group' );

	# WEB-LANG-13. The index writes no prose of its own.
	unlike( $body, qr{<p>|man\.openbsd\.org}, 'and no opening of its own' );

	like( $body, qr{<h2 id="tool">Tool</h2>\n<dl>\n},
		'a heading carries the name as its anchor, and its heading' );
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

	my $body = App::FuguWeb::Index->new( config => $config )->body('Manuals');
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

	my $body = App::FuguWeb::Index->new( config => $config )->body('Manuals');
	like( $body, qr{<dd>a &amp; b &lt; c</dd>}, 'the entities' );
};

subtest 'an empty group leaves no heading behind' => sub {
	my ( $config, $reason ) = load( <<'RC' );
site = Example

page "manuals.html" {
	title = Manuals
	index = yes
}

manuals empty {
	heading = Empty
	dir     = web
}
RC
	ok( $config, 'the description loads' ) or diag $reason;

	my $body = App::FuguWeb::Index->new( config => $config )->body('Manuals');
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

manuals one {
	heading = One
	dir     = man/tool
}

manuals two {
	heading = Two
	dir     = man/copy
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

manuals gone {
	heading = Gone
	dir     = man/gone
}
RC
	is( $config, undef, 'the load fails' );
	like( $reason, qr{manuals "gone" names man/gone},
		'the message names the block and the directory' );
};

subtest 'the body of the page opens the index' => sub {
	# WEB-MANUALS-8. The heading comes from the title, then the
	# body of the page as it stands, then the groups.
	my ( $config, $reason ) = load($RC);
	ok( $config, 'the description loads' ) or diag $reason;

	my $body = App::FuguWeb::Index->new( config => $config )
	    ->body( 'Manuals', "<p>Read them.</p>\n" );
	like( $body, qr{^<h1>Manuals</h1>\n\n<p>Read them\.</p>\n\n<h2 id="tool">},
		'the heading, the body, and then the groups' );

	$body = App::FuguWeb::Index->new( config => $config )
	    ->body( 'Tags < & >', undef );
	like( $body, qr{^<h1>Tags &lt; &amp; &gt;</h1>\n\n<h2 },
		'the title is escaped, and no body adds nothing' );
};

subtest 'a group block takes a name and a heading' => sub {
	# WEB-MANUALS-7. The block of an older description named its
	# heading and set an anchor. Each failure names the block to
	# write in its place.
	my %case = (
		'an anchor' => [
			qq{manuals "Commands" {\n\tdir = man/tool\n\tanchor = commands\n}\n},
qr/manuals "Commands" sets anchor, and a group takes its anchor from the block name: write manuals commands with heading = Commands, and no anchor/
		],
		'an anchor beside a heading' => [
			qq{modules things {\n\theading = Thing modules\n\tdir = lib/Thing\n\tanchor = thing\n}\n},
qr/modules "things" sets anchor, and a group takes its anchor from the block name: write modules thing with heading = Thing modules, and no anchor\z/
		],
		'an anchor outside the shape of a group name' => [
			qq{manuals library {\n\theading = Library\n\tdir = man/lib\n\tanchor = Lib_X\n}\n},
qr/manuals "library" sets anchor, and a group takes its anchor from the block name: write manuals lib-x with heading = Library, and no anchor; a group name is one word of lowercase letters, digits and hyphens\z/
		],
		'a heading as the name' => [
			qq{manuals "Every section" {\n\tdir = man/all\n}\n},
qr/manuals "Every section" has no group name: a group name is one word of lowercase letters, digits and hyphens, and it is the anchor of the heading; write manuals every-section with heading = Every section/
		],
		'no heading' => [
			qq{modules thing {\n\tdir = lib/Thing\n}\n},
			qr/modules "thing" has no heading/
		],
		'one name for two groups' => [
			qq{manuals tool {\n\theading = Tool\n\tdir = man/tool\n}\n}
			    . qq{modules tool {\n\theading = Modules\n\tdir = lib/Thing\n}\n},
qr/manuals "tool" and modules "tool" share one name, and a group name is the anchor of one heading/
		],
	);

	for my $name ( sort keys %case ) {
		my ( $block, $expected ) = @{ $case{$name} };
		my ( $config, $reason ) = load( "site = Example\n\n" . $block );
		is( $config, undef, "$name fails the load" );
		like( $reason, $expected, "and the message says what to write" );
	}

	my ( $config, $reason ) =
	    load( qq{site = Example\n\nmanuals tool-2 {\n\theading = Tool\n}\n} );
	unlike( $reason // '', qr/group name/,
		'a name of letters, digits and a hyphen is a group name' );

	( $config, $reason ) = load(
		qq{site = Example\n\nmanuals lib-x {\n\theading = Library\n\tdir = man/lib\n}\n}
	);
	ok( $config, 'the block that the message names for Lib_X loads' )
	    or diag $reason;
};

# The description of the shared sources in two languages. The tool
# group of de takes a heading and a dir, and the library group takes
# a heading alone.
my $DE = $RC . <<'RC';

manuals de tool {
	heading = Werkzeug
	dir     = man/de/tool
}

manuals de library {
	heading = Bibliothek
}
RC

subtest 'a group takes the heading and the sources of a language' => sub {
	my $root = build_root($DE);
	make_path("$root/man/de/tool");
	open my $fh, '>', "$root/man/de/tool/tool.1"
	    or die "Cannot write the translation: $!";
	print {$fh} ".Sh NAME\n.Nd das Werkzeug\n";
	close $fh;

	my $config =
	    App::FuguWeb::Config->load( root => $root, error => \my $reason );
	ok( $config, 'the description loads' ) or diag $reason;

	my ($tool) = grep { $_->name eq 'tool' } $config->groups;
	is( $tool->heading,       'Tool',     'the default heading' );
	is( $tool->heading('de'), 'Werkzeug', 'the heading of de' );

	# WEB-LANG-5. The namesake comes from the dir of de, and each
	# other manual from the default dir.
	my @de = $tool->manuals('de');
	is_deeply( [ map { $_->page } @de ], [ map { $_->page } $tool->manuals ],
		'each language holds the same pages' );
	is_deeply( [ map { $_->lang } @de ], [qw(de en en)],
		'and the language of each source' );
	is( $de[0]->path, "$root/man/de/tool/tool.1", 'the source of de' );

	# WEB-LANG-6. A part of the default source carries lang="en"
	# on its own element, and a part of de carries no marker.
	my $body = App::FuguWeb::Index->new( config => $config, lang => 'de' )
	    ->body('Handbuch');
	like( $body, qr{^<h1>Handbuch</h1>\n}, 'the title of de' );
	like( $body, qr{<h2 id="tool">Werkzeug</h2>},
		'the index of de takes the heading of de, and the same anchor' );
	like( $body, qr{<dd>das Werkzeug</dd>},
		'and the description of the source of de' );
	like( $body, qr{<dd lang="en">the configuration</dd>},
		'and the default description of a manual with no namesake' );
	like( $body, qr{<h2 id="library">Bibliothek</h2>},
		'a translation with no dir changes the heading alone' );
	like( $body, qr{<h2 id="thing" lang="en">Thing modules</h2>},
		'and a group with no translation keeps its own' );

	# A title and an opening of the default source carry the marker
	# as well. The caller names the language of each.
	$body = App::FuguWeb::Index->new( config => $config, lang => 'de' )
	    ->body( 'Manuals', "<p>Read them.</p>\n",
		title_lang => 'en', body_lang => 'en' );
	like( $body,
		qr{^<h1 lang="en">Manuals</h1>\n\n<div lang="en">\n<p>Read them\.</p>\n</div>\n\n<h2 id="tool">},
		'a title and an opening of en, each in its own element' );

	$body = App::FuguWeb::Index->new( config => $config )->body('Manuals');
	like( $body, qr{<h2 id="tool">Tool</h2>}, 'the index of en stays' );
	like( $body, qr{<dd>the tool</dd>}, 'with its own description' );
	unlike( $body, qr/ lang=/, 'and carries no marker' );
};

subtest 'a translation of a group keeps the rules of a group' => sub {
	my ( $config, $reason ) = load($DE);
	is( $config, undef, 'a translation dir that is absent fails' );
	like( $reason, qr{manuals de "tool" names man/de/tool, which is not a directory},
		'and names the translation' );

	( $config, $reason ) = load( $RC . <<'RC' );

manuals de tool {
	heading = ""
}
RC
	is( $config, undef, 'an empty heading fails' );
	like( $reason, qr{manuals de "tool" has no heading}, 'and says which' );

	( $config, $reason ) = load( $RC . <<'RC' );

modules de thing {
	dir = ../elsewhere
}
RC
	is( $config, undef, 'a dir that leaves the project fails' );
	like( $reason, qr{modules de "thing" dir is \.\./elsewhere, which leaves the project},
		'and says which' );
};

done_testing();
