#!/usr/bin/env perl
# ex:ts=8 sw=4:
# App::FuguWeb::Status: the record of the translations, each part of
# a language that does not follow its source, and the state of each
# part.
#
# The test reads a site of three languages in a File::Temp directory.
# It needs no renderer, and it never reads the repository.
# t/fuguweb/cli.t holds the two verbs and their exit codes.

use v5.36;
use Test::More;
use FindBin qw($RealBin);
use lib "$RealBin/../../lib";
use Digest::SHA qw(sha256_hex);
use File::Path qw(make_path);
use File::Temp qw(tempdir);

use_ok('App::FuguWeb::Config');
use_ok('App::FuguWeb::Status');

# The words of zh-Hans and pt-BR, as the UTF-8 bytes of the file.
my $CHINESE = "\xe7\xae\x80\xe4\xbd\x93\xe4\xb8\xad\xe6\x96\x87";
my $EXAMPLE = "\xe7\xa4\xba\xe4\xbe\x8b";
my $HOME    = "\xe9\xa6\x96\xe9\xa1\xb5";
my $HEADING = "\xe5\x91\xbd\xe4\xbb\xa4";

# A source path of pt-BR in UTF-8 bytes. The last byte of the a with
# grave is 0xA0, which a Latin-1 reading of \s takes for white space.
my $VOILA = "voil\xc3\xa0.md";

# Three languages. zh-Hans translates most parts, and pt-BR translates
# one page. The index page of zh-Hans takes a body that opens it, and
# the default index page takes none.
my $RC = <<"RC";
site   = Example
url    = https://example.org/
footer = footer.body.html

language en {
	name = English
}

language zh-Hans {
	name   = $CHINESE
	site   = $EXAMPLE
	footer = zh-hans/footer.body.html
}

language pt-BR {
	name = Portugu\xc3\xaas
}

nav "index.html" {
	label = Home
}

nav "readme.html" {
	label = Readme
}

nav zh-Hans "index.html" {
	label = $HOME
}

page "index.html" {
	title = Home
	body  = index.body.html
}

page zh-Hans "index.html" {
	title = $HOME
	body  = zh-hans/index.body.html
}

page "readme.html" {
	title    = Readme
	markdown = README.md
}

page zh-Hans "readme.html" {
	markdown = README.zh-Hans.md
}

page pt-BR "readme.html" {
	title    = Leia-me
	markdown = $VOILA
}

page "manuals.html" {
	title = Manuals
	index = yes
}

page zh-Hans "manuals.html" {
	body = zh-hans/manuals.body.html
}

manuals commands {
	heading = Commands
	dir     = man/en
}

manuals zh-Hans commands {
	heading = $HEADING
	dir     = man/zh-hans
}
RC

my $MDOC = <<'MDOC';
.Dd $Mdocdate: October 25 2026 $
.Dt TOOL 1
.Os
.Sh NAME
.Nm tool
.Nd a tool
MDOC

# project(%more):
#	Write the project, and each more file, and return its root.
sub project (%more)
{
	my $root = tempdir( CLEANUP => 1 );

	my %file = (
		'.fuguwebrc'                   => $RC,
		'web/index.body.html'          => "<h1>Home</h1>\n",
		'web/footer.body.html'         => "<p>ISC.</p>\n",
		'web/zh-hans/index.body.html'  => "<h1>$HOME</h1>\n",
		'web/zh-hans/footer.body.html' => "<p>ISC.</p>\n",
		'web/zh-hans/manuals.body.html' => "<p>$HEADING</p>\n",
		'README.md'                    => "# Readme\n",
		'README.zh-Hans.md'            => "# $HOME\n",
		$VOILA                         => "# Leia-me\n",
		'man/en/tool.1'                => $MDOC,
		'man/en/other.8'               => $MDOC =~ s/TOOL 1/OTHER 8/r,
		'man/zh-hans/tool.1'           => $MDOC,
		%more,
	);

	for my $relative ( sort keys %file ) {
		write_file( "$root/$relative", $file{$relative} );
	}

	return $root;
}

# write_file($path, $bytes):
#	Write the bytes, and make each directory on the way.
sub write_file ( $path, $bytes )
{
	make_path( $path =~ s{/[^/]+$}{}r );

	open my $fh, '>', $path or die "Cannot write $path: $!";
	print {$fh} $bytes;
	close $fh;

	return;
}

# read_file($path):
#	The bytes of a file, or the empty string with no file. A test
#	that expects a file then fails, and the next test runs.
sub read_file ($path)
{
	return '' unless -e $path;

	open my $fh, '<', $path or die "Cannot read $path: $!";
	my $bytes = do { local $/; <$fh> };
	close $fh;

	return $bytes;
}

# status($root):
#	A new status over the description of the project.
sub status ($root)
{
	my $reason;
	my $config =
	    App::FuguWeb::Config->load( root => $root, error => \$reason )
	    or BAIL_OUT("the fixture does not load: $reason");

	return App::FuguWeb::Status->new( config => $config );
}

# lines($root):
#	The report of the project, as a list.
sub lines ($root)
{
	my $status = status($root);
	my $lines  = $status->report;
	ok( $lines, 'the report reads the project' ) or diag $status->error;

	return @{ $lines // [] };
}

# keys_of($root):
#	The path of each line of the record, in the order of the file.
sub keys_of ($root)
{
	return map { /^SHA256 \((.+)\) = / } split /\n/,
	    read_file("$root/TRANSLATIONS");
}

# translated_lines(@lines):
#	The lines of a report that name a translated file.
sub translated_lines (@lines)
{
	return grep { !/\tfallback\t/ } @lines;
}

# The parts of the two languages that do not follow their source, with
# no record. zh-Hans names its own site name, the label and the title
# of its index page, the heading of the group and the footer. The index
# page of zh-Hans takes a body with no default source, so it follows
# nothing and takes no line.
my @UNRECORDED = (
	"zh-Hans\tfallback\tlabel\treadme.html",
	"zh-Hans\tunrecorded\tpage\tindex.html",
	"zh-Hans\tfallback\ttitle\treadme.html",
	"zh-Hans\tunrecorded\tpage\treadme.html",
	"zh-Hans\tfallback\ttitle\tmanuals.html",
	"zh-Hans\tunrecorded\tmanual\ttool.1.html",
	"zh-Hans\tfallback\tmanual\tother.8.html",
	"zh-Hans\tunrecorded\tfooter\tzh-Hans",
	"pt-BR\tfallback\tsite\tpt-BR",
	"pt-BR\tfallback\tlabel\tindex.html",
	"pt-BR\tfallback\tlabel\treadme.html",
	"pt-BR\tfallback\ttitle\tindex.html",
	"pt-BR\tfallback\tpage\tindex.html",
	"pt-BR\tunrecorded\tpage\treadme.html",
	"pt-BR\tfallback\ttitle\tmanuals.html",
	"pt-BR\tfallback\theading\tcommands",
	"pt-BR\tfallback\tmanual\ttool.1.html",
	"pt-BR\tfallback\tmanual\tother.8.html",
	"pt-BR\tfallback\tfooter\tpt-BR",
);

# The translated file of each unrecorded part.
my @TRANSLATED = (
	'web/zh-hans/index.body.html', 'README.zh-Hans.md',
	'man/zh-hans/tool.1',          'web/zh-hans/footer.body.html',
	$VOILA,
);

subtest 'the record is TRANSLATIONS at the project root' => sub {

	# WEB-STATUS-1. Beside the description, and not below the
	# source directory, where the build publishes each plain file.
	is( App::FuguWeb::Status::RECORD(), 'TRANSLATIONS', 'the name' );

	my $root = project();
	ok( status($root)->record('README.zh-Hans.md'), 'a record succeeds' );
	ok( -f "$root/TRANSLATIONS", 'and writes the file at the root' );
	ok( !-e "$root/web/TRANSLATIONS", 'and not in the source directory' );
};

subtest 'with no record, each part reports its coverage' => sub {

	# WEB-STATUS-3 and WEB-STATUS-4. One line for each part of a
	# language other than the default that does not follow its
	# source, in the order of the languages and of the description.
	my $root = project();
	is_deeply( [ lines($root) ], \@UNRECORDED,
		'each fallback part and each unrecorded file' );
	ok( !-e "$root/TRANSLATIONS", 'and the report writes no record' );
};

subtest 'a record holds the digest of each default source' => sub {
	my $root = project();

	my $status = status($root);
	ok( $status->record(@TRANSLATED), 'the record succeeds' )
	    or diag $status->error;

	# WEB-STATUS-1 and WEB-STATUS-2. The manifest form, with the
	# path of the translated file and the digest of its default
	# source. The lines sort by the bytes of the path.
	my %source = (
		'README.zh-Hans.md'            => 'README.md',
		'man/zh-hans/tool.1'           => 'man/en/tool.1',
		$VOILA                         => 'README.md',
		'web/zh-hans/footer.body.html' => 'web/footer.body.html',
		'web/zh-hans/index.body.html'  => 'web/index.body.html',
	);
	my $expected = join '', map {
		"SHA256 ($_) = " . sha256_hex( read_file("$root/$source{$_}") ) . "\n"
	} sort keys %source;
	is( read_file("$root/TRANSLATIONS"), $expected,
		'one line for each file, sorted, with the default digest' );

	# WEB-STATUS-5. Each translated file follows its source now, and
	# the fallback parts stay.
	is_deeply(
		[ lines($root) ],
		[ grep { /\tfallback\t/ } @UNRECORDED ],
		'the report keeps the fallback parts alone'
	);
};

subtest 'a change to a default source makes its translation stale' => sub {
	my $root = project();
	ok( status($root)->record(@TRANSLATED), 'the record succeeds' );

	write_file( "$root/web/index.body.html", "<h1>Home, again</h1>\n" );
	write_file( "$root/man/en/tool.1",       $MDOC . "Words.\n" );

	# WEB-STATUS-4. The line names a digest other than the one that
	# the default source has now.
	my @stale = grep { !/\tfallback\t/ } lines($root);
	is_deeply(
		\@stale,
		[ "zh-Hans\tstale\tpage\tindex.html",
		    "zh-Hans\tstale\tmanual\ttool.1.html" ],
		'the page and the manual are stale'
	);

	# WEB-STATUS-2. A new record of one file keeps each other line.
	my $before = read_file("$root/TRANSLATIONS");
	ok( status($root)->record('web/zh-hans/index.body.html'),
		'a record of the page succeeds' );
	is_deeply(
		[ grep { !/\tfallback\t/ } lines($root) ],
		["zh-Hans\tstale\tmanual\ttool.1.html"],
		'and the page follows, and the manual stays stale'
	);

	my @before = split /\n/, $before;
	my @after  = split /\n/, read_file("$root/TRANSLATIONS");
	is( scalar @after, scalar @before, 'the record holds each line' );
	is_deeply(
		[ grep { !/zh-hans\/index/ } @after ],
		[ grep { !/zh-hans\/index/ } @before ],
		'and each other line is the same'
	);
};

subtest 'a file that translates no source is rejected' => sub {
	my $root = project();
	ok( status($root)->record('README.zh-Hans.md'), 'a first record' );
	my $before = read_file("$root/TRANSLATIONS");

	# WEB-STATUS-2. A default source, a file of no part, and a
	# translation whose default part names no source.
	for my $file ( 'web/index.body.html', 'nonesuch.md',
		'web/zh-hans/manuals.body.html' )
	{
		my $status = status($root);
		ok( !$status->record($file), "$file is rejected" );
		like(
			$status->error,
			qr/\Q$file\E translates no source of the description/,
			'and the message names it'
		);
		ok( !$status->fault, 'and it is no fault of the project files' );
	}

	# One file that is rejected rejects the whole call.
	my $status = status($root);
	ok( !$status->record( 'web/zh-hans/index.body.html', 'nonesuch.md' ),
		'a call with one rejected file fails' );
	is( read_file("$root/TRANSLATIONS"), $before,
		'and the record does not change' );
};

subtest 'a record or a source that does not read fails' => sub {
	my $root = project( 'TRANSLATIONS' => "not a manifest\n" );

	my $status = status($root);
	ok( !$status->report, 'a malformed record fails the report' );
	like( $status->error, qr{\Q$root\E/TRANSLATIONS: .*not a manifest},
		'and the message names the record and the line' );
	ok( $status->fault, 'and it is a fault of the project files' );

	$status = status($root);
	ok( !$status->record('README.zh-Hans.md'), 'and the record' );
	ok( $status->fault, 'with a fault' );
	is( read_file("$root/TRANSLATIONS"), "not a manifest\n",
		'which stays as it was' );

	$root = project();
	ok( status($root)->record('README.zh-Hans.md'), 'a record' );
	unlink "$root/README.md" or die "Cannot remove: $!";
	$status = status($root);
	ok( !$status->report, 'a default source that is gone fails' );
	like( $status->error, qr{Cannot read \Q$root\E/README\.md},
		'and the message names it' );
	ok( $status->fault, 'and it is a fault of the project files' );
};

subtest 'each path setting gives one path of the record' => sub {

	# WEB-STATUS-1. A path holds no ./ step, no empty step and no
	# final solidus, so each form of a setting gives one path.
	my %form = (
		'source_dir = ./web' =>
		    $RC =~ s{^(url .*\n)}{${1}source_dir = ./web\n}mr,
		'source_dir = web/' =>
		    $RC =~ s{^(url .*\n)}{${1}source_dir = web/\n}mr,
		'dir = man/zh-hans/' =>
		    $RC =~ s{= man/zh-hans$}{= man/zh-hans/}mr,
	);

	for my $form ( sort keys %form ) {
		isnt( $form{$form}, $RC, "the description takes $form" );

		my $root   = project( '.fuguwebrc' => $form{$form} );
		my $status = status($root);
		ok( $status->record(@TRANSLATED), "$form: the record succeeds" )
		    or diag $status->error;
		is_deeply( [ keys_of($root) ], [ sort @TRANSLATED ],
			"$form: and each path is the one form" );
		is_deeply( [ translated_lines( lines($root) ) ],
			[], "$form: and each translated file follows its source" );
	}
};

subtest 'each form of a file names one path of the record' => sub {
	my $root = project();

	# WEB-STATUS-2. The method changes each file to the form of
	# WEB-STATUS-1.
	my $status = status($root);
	ok(
		$status->record(
			'./web/zh-hans/index.body.html',
			'web//zh-hans/footer.body.html',
			'man/zh-hans/tool.1/',
			'./README.zh-Hans.md', $VOILA
		),
		'the record takes a ./ step, an empty step and a final solidus'
	) or diag $status->error;
	is_deeply( [ keys_of($root) ], [ sort @TRANSLATED ],
		'and names each file in the one form' );
	is_deeply( [ translated_lines( lines($root) ) ],
		[], 'and each translated file follows its source' );
};

subtest 'an empty record holds no line' => sub {

	# WEB-STATUS-1. Fugu::Signify refuses a manifest of no line, and
	# an empty record is no fault.
	my $root = project( 'TRANSLATIONS' => '' );
	is_deeply( [ lines($root) ], \@UNRECORDED, 'the report reads it' );

	my $status = status($root);
	ok( $status->record('README.zh-Hans.md'), 'and the record writes it' )
	    or diag $status->error;
	is_deeply( [ keys_of($root) ], ['README.zh-Hans.md'],
		'with the one line' );
};

subtest 'one translated file over two default sources is a fault' => sub {

	# Two pages of de name one body. The second default page takes
	# the body of the first, and then a body of its own.
	my $rc = <<'RC';
site = Example
url  = https://example.org/

language en {
	name = English
}

language de {
	name = Deutsch
}

page "a.html" {
	body = a.body.html
}

page de "a.html" {
	body = de/one.body.html
}

page "b.html" {
	body = %s
}

page de "b.html" {
	body = de/one.body.html
}
RC

	my $root = tempdir( CLEANUP => 1 );
	write_file( "$root/web/a.body.html",      "<h1>A</h1>\n" );
	write_file( "$root/web/b.body.html",      "<h1>B</h1>\n" );
	write_file( "$root/web/de/one.body.html", "<h1>Eins</h1>\n" );

	# One default source for the two parts is no fault.
	write_file( "$root/.fuguwebrc", sprintf $rc, 'a.body.html' );
	my $status = status($root);
	ok( $status->record('web/de/one.body.html'), 'one source is fine' )
	    or diag $status->error;
	is_deeply( [ translated_lines( lines($root) ) ],
		[], 'and the file follows it' );
	unlink "$root/TRANSLATIONS" or die "Cannot remove: $!";

	# WEB-STATUS-7. The record holds one digest for each file.
	write_file( "$root/.fuguwebrc", sprintf $rc, 'b.body.html' );
	my $two = join ' ', 'web/de/one.body.html translates web/a.body.html',
	    'and web/b.body.html';
	$two = qr/\A\Q$two\E/;

	$status = status($root);
	ok( !$status->report, 'two sources fail the report' );
	like( $status->error, $two, 'and the message names the three files' );
	ok( $status->fault, 'and it is a fault of the project files' );

	$status = status($root);
	ok( !$status->record('web/de/one.body.html'), 'and the record' );
	like( $status->error, $two, 'with the same message' );
	ok( $status->fault,                 'and a fault' );
	ok( !-e "$root/TRANSLATIONS", 'and no record' );
};

subtest 'a modules group gives the sidecar and each module' => sub {

	# The umbrella sidecar lib/Example.pod sits beside the dir of
	# the group, and the name of each module drops the module root.
	my $root = tempdir( CLEANUP => 1 );
	write_file( "$root/.fuguwebrc", <<"RC" );
site = Example
url  = https://example.org/

language en {
	name = English
}

language zh-Hans {
	name = $CHINESE
}

modules api {
	heading = API
	dir     = lib/Example
}

modules zh-Hans api {
	heading = $HEADING
	dir     = doc/zh-hans/Example
}
RC

	my %pod = (
		'lib/Example.pod'               => 'Example - the umbrella',
		'lib/Example/Other.pod'         => 'Example::Other - other',
		'lib/Example/Thing.pod'         => 'Example::Thing - a thing',
		'doc/zh-hans/Example.pod'       => "Example - $HEADING",
		'doc/zh-hans/Example/Thing.pod' => "Example::Thing - $HOME",
	);
	write_file( "$root/$_", "=head1 NAME\n\n$pod{$_}\n\n=cut\n" )
	    for keys %pod;

	# WEB-STATUS-3. The parts of the group, in the order of the
	# index, with the page of each module as the name.
	is_deeply(
		[ lines($root) ],
		[
			"zh-Hans\tfallback\tsite\tzh-Hans",
			"zh-Hans\tunrecorded\tmanual\tExample.3p.html",
			"zh-Hans\tfallback\tmanual\tExample::Other.3p.html",
			"zh-Hans\tunrecorded\tmanual\tExample::Thing.3p.html",
		],
		'the sidecar and the module of zh-Hans are unrecorded'
	);

	# WEB-STATUS-1 and WEB-STATUS-2. The path of each translated
	# file from the project root, and the digest of its default
	# source.
	my %source = (
		'doc/zh-hans/Example.pod'       => 'lib/Example.pod',
		'doc/zh-hans/Example/Thing.pod' => 'lib/Example/Thing.pod',
	);
	my $status = status($root);
	ok( $status->record( sort keys %source ), 'the record succeeds' )
	    or diag $status->error;
	is(
		read_file("$root/TRANSLATIONS"),
		join( '',
			map {
				"SHA256 ($_) = "
				    . sha256_hex( read_file("$root/$source{$_}") )
				    . "\n"
			} sort keys %source ),
		'one line for each file, with the digest of its default source'
	);
	is_deeply( [ translated_lines( lines($root) ) ],
		[], 'and each module follows its source' );
};

subtest 'a site of one language reports nothing' => sub {
	my $root = tempdir( CLEANUP => 1 );
	write_file( "$root/.fuguwebrc", <<'RC' );
site = Example
url  = https://example.org/

page "index.html" {
	body = index.body.html
}
RC
	write_file( "$root/web/index.body.html", "<h1>Home</h1>\n" );

	# WEB-STATUS-5. No language other than the default holds a part.
	is_deeply( [ lines($root) ], [], 'the report is empty' );
};

done_testing();
