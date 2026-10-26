#!/usr/bin/env perl
# ex:ts=8 sw=4:
# App::FuguWeb::Fragment: the outline of a fragment, the ids of a
# translation, the fit of a fragment of mandoc(1), and the fit of a
# body of the top-level 404.html.
#
# The fit of a manual reads the real output of mandoc(1) and of
# pod2man(1) when the two are on the path. mandoc 1.14.6 and the mandoc
# of OpenBSD write another frame, so a test of the real output holds no
# form that one version alone writes. A recorded output of the mandoc
# of OpenBSD holds its form on each platform.

use v5.36;
use Test::More;
use FindBin qw($RealBin);
use lib "$RealBin/../../lib";
use Digest::SHA qw(sha256_hex);
use File::Temp qw(tempdir);

use_ok('App::FuguWeb::Fragment');

# have($tool):
#	Report whether the program is on the path.
sub have ($tool)
{
	return system("command -v $tool >/dev/null 2>&1") == 0;
}

# levels($outline):
#	An outline as one line of text: each heading as its level and
#	its id, or its level and a hyphen when it has no id.
sub levels ($outline)
{
	return join ' ', map { "$_->[0]:" . ( $_->[1] // '-' ) } @$outline;
}

# output($program, $source, @args):
#	The output of one program over a source file, as characters.
sub output ( $program, $source, @args )
{
	my $dir = tempdir( CLEANUP => 1 );
	open my $fh, '>', "$dir/source" or die "Cannot write: $!";
	print {$fh} $source;
	close $fh;

	open my $pipe, '-|', $program, @args, "$dir/source"
	    or die "Cannot run $program: $!";
	my $bytes = do { local $/; <$pipe> };
	close $pipe or die "$program failed";

	my $reason;
	my $text = App::FuguWeb::decode( $bytes, $program, \$reason )
	    // die "$reason\n";

	return $text;
}

subtest 'the outline holds the level and the id of each heading' => sub {
	# WEB-OUTLINE. An id takes one of three forms, and a name such
	# as data-id is no id.
	my $html = <<'HTML';
<h1>Title</h1>
<p>Text.</p>
<h2 id="one">One</h2>
<H3 class="x" ID='two'>Two</H3>
<h2 id=three>Three</h2>
<h3 data-id="no">No id</h3>
<h2 title="a" id='say "hi"'>Quote</h2>
<hr>
<header>Not a heading</header>
HTML
	is( levels( App::FuguWeb::Fragment::outline($html) ),
		'1:- 2:one 3:two 2:three 3:- 2:say &quot;hi&quot;',
		'each heading, in order, with its level and its id' );
	is( levels( App::FuguWeb::Fragment::outline("<p>Text.</p>\n") ),
		'', 'a fragment with no heading has an empty outline' );
};

subtest 'a translation takes the ids of the default outline' => sub {
	# WEB-OUTLINE-2. lowdown(1) makes each id from the Latin letters
	# of the heading, so a heading of Han text takes the id
	# "section". The fit gives each heading the id of the heading
	# at the same position of the default page.
	my $outline = App::FuguWeb::Fragment::outline( <<'HTML' );
<h1>Install</h1>
<h2 id="build">Build</h2>
<h2 lang="en" id="test" class="x">Test</h2>
<h3>Notes</h3>
HTML

	my $fitted = App::FuguWeb::Fragment::follow( <<"HTML", $outline, \my $at );
<h1 id="section">\x{5b89}\x{88c5}</h1>
<h2 id="section-1">\x{6784}\x{5efa}</h2>
<h2 lang="en" id="test" class="x">Test</h2>
<h3 id='cto'>\x{9762}\x{5411} CTO</h3>
HTML
	is( $fitted, <<"HTML", 'each heading takes the id at its position' );
<h1>\x{5b89}\x{88c5}</h1>
<h2 id="build">\x{6784}\x{5efa}</h2>
<h2 lang="en" id="test" class="x">Test</h2>
<h3>\x{9762}\x{5411} CTO</h3>
HTML
	is( $at, undef, 'and the position stays unset' );

	$fitted =
	    App::FuguWeb::Fragment::follow( "<h1>x</h1>\n<h2 title=\"t\">y</h2>\n",
		App::FuguWeb::Fragment::outline("<h1>a</h1>\n<h2 id=\"b\">c</h2>\n"),
		\$at );
	is( $fitted, qq{<h1>x</h1>\n<h2 title="t" id="b">y</h2>\n},
		'a heading with no id takes the id at the end' );
};

subtest 'the text of a value is no attribute' => sub {
	# An id= or an href= inside the quoted value of another attribute
	# is text, and each function steps over it. A name in upper case,
	# such as HREF, is the same attribute.
	my $html = <<'HTML';
<h2 title="see id=x" id="real">A</h2>
<p><a title='see href="#real"' href="#real">A</a></p>
<h3 title='href=#a id=y'>B</h3>
<H2 TITLE="see ID=x" ID="UP">C</H2>
<p><A TITLE='see HREF="#real"' HREF="#UP">C</A></p>
HTML
	is( levels( App::FuguWeb::Fragment::outline($html) ),
		'2:real 3:- 2:UP', 'the outline reads the id attribute alone' );

	my $outline = App::FuguWeb::Fragment::outline(
		qq{<h2 id="one">A</h2>\n<h3 id="two">B</h3>\n<h2 id="three">C</h2>\n});
	is( App::FuguWeb::Fragment::follow( $html, $outline, \my $at ),
		<<'HTML', 'follow sets the id and the link attribute alone' );
<h2 title="see id=x" id="one">A</h2>
<p><a title='see href="#real"' href="#one">A</a></p>
<h3 title='href=#a id=y' id="two">B</h3>
<H2 TITLE="see ID=x" id="three">C</H2>
<p><A TITLE='see HREF="#real"' HREF="#three">C</A></p>
HTML

	is( App::FuguWeb::Fragment::not_found( <<'HTML', 'zh-hans' ), <<'HTML',
<p title="see id=x" id="p"><a title="see href=x" href="index.html">A</a></p>
<P TITLE="see ID=x" ID="q"><A TITLE="see HREF=x" HREF="index.html">A</A>
<IMG SRC="img/a.png" ALT="a"></P>
HTML
<p title="see id=x"><a title="see href=x" href="zh-hans/index.html">A</a></p>
<P TITLE="see ID=x"><A TITLE="see HREF=x" HREF="zh-hans/index.html">A</A>
<IMG SRC="zh-hans/img/a.png" ALT="a"></P>
HTML
		'not_found removes the id and rebases the link attribute alone' );

	# The fit of a manual reads the class of a heading, and not a
	# class in the text of another value.
	is( App::FuguWeb::Fragment::manual( qq{<h1 title=' class="Ss"'>Words</h1>\n}, 't(1)' ),
		qq{<h1>t(1)</h1>\n<h1 title=' class="Ss"'>Words</h1>\n},
		'manual reads the class attribute alone' );
};

subtest 'a link to a heading names the id that the heading takes' => sub {
	# WEB-OUTLINE-4. mandoc(1) writes .Sx BESCHREIBUNG as a link to
	# #BESCHREIBUNG, and .Sx of Han text as a link to an id that no
	# heading holds. A link of the class Sx names the heading of the
	# same text, and each other link the heading of its old id. So a
	# link with the text of one heading and the old id of another
	# names the heading of its old id.
	my $outline = App::FuguWeb::Fragment::outline( <<'HTML' );
<h1>tool(1)</h1>
<h2 class="Sh" id="DESCRIPTION">DESCRIPTION</h2>
<h2 class="Sh" id="INSTALL">INSTALL</h2>
<h3 class="Ss" id="From_source">From source</h3>
<h2 id="build">Build</h2>
<h2>Notes</h2>
HTML

	my $fitted = App::FuguWeb::Fragment::follow( <<"HTML", $outline, \my $at );
<h1>tool(1)</h1>
<h2 class="Sh" id="BESCHREIBUNG">BESCHREIBUNG</h2>
<p><a class="Sx" href="#BESCHREIBUNG">BESCHREIBUNG</a>
<a class="Sx" href="#__u5B89___u88C5_">\x{5b89}\x{88c5}</a>
<a class="Sx" href="#Aus_der_Quelle">Aus der Quelle</a>
<a href="#section-1">\x{6784}\x{5efa}</a>
<a href="#section-1">BESCHREIBUNG</a>
<a href="#notizen">Notizen</a>
<a href="#v">v</a> <a href="other.html#BESCHREIBUNG">other</a></p>
<h2 class="Sh">\x{5b89}\x{88c5}</h2>
<h3 class="Ss" id="Aus_der_Quelle">Aus
  der Quelle</h3>
<h2 id="section-1">\x{6784}\x{5efa}</h2>
<h2 id="notizen">Notizen</h2>
HTML
	is( $fitted, <<"HTML", 'each link to a heading names its new id' );
<h1>tool(1)</h1>
<h2 class="Sh" id="DESCRIPTION">BESCHREIBUNG</h2>
<p><a class="Sx" href="#DESCRIPTION">BESCHREIBUNG</a>
<a class="Sx" href="#INSTALL">\x{5b89}\x{88c5}</a>
<a class="Sx" href="#From_source">Aus der Quelle</a>
<a href="#build">\x{6784}\x{5efa}</a>
<a href="#build">BESCHREIBUNG</a>
<a href="#notizen">Notizen</a>
<a href="#v">v</a> <a href="other.html#BESCHREIBUNG">other</a></p>
<h2 class="Sh" id="INSTALL">\x{5b89}\x{88c5}</h2>
<h3 class="Ss" id="From_source">Aus
  der Quelle</h3>
<h2 id="build">\x{6784}\x{5efa}</h2>
<h2>Notizen</h2>
HTML
};

subtest 'an outline that differs names the first heading' => sub {
	# WEB-OUTLINE-1. The position counts from 1.
	my $outline = App::FuguWeb::Fragment::outline(
		"<h1>a</h1>\n<h2 id=\"b\">b</h2>\n<h3>c</h3>\n");

	my %case = (
		'a heading of another level' =>
		    [ "<h1>a</h1>\n<h3>b</h3>\n<h3>c</h3>\n", 2 ],
		'a heading that the outline does not hold' =>
		    [ "<h1>a</h1>\n<h2>b</h2>\n<h3>c</h3>\n<h3>d</h3>\n", 4 ],
		'a heading of the outline that the page does not hold' =>
		    [ "<h1>a</h1>\n<h2>b</h2>\n", 3 ],
		'a page with no heading' => [ "<p>a</p>\n", 1 ],
	);
	for my $name ( sort keys %case ) {
		my ( $html, $position ) = @{ $case{$name} };
		my $fitted =
		    App::FuguWeb::Fragment::follow( $html, $outline, \my $at );
		is( $fitted, undef, "$name fails" );
		is( $at, $position, "and names the heading $position" );
	}
};

# An mdoc page with a heading of Han text, a subsection, a heading that
# holds a cross-reference, a tag of a list with a link to itself, and
# characters outside ASCII.
my $MDOC = <<"MDOC";
.Dd October 25, 2026
.Dt TOOL 1
.Os
.Sh NAME
.Nm tool
.Nd a tool with voil\xc3\xa0 and \xe7\xae\x80\xe4\xbd\x93\xe4\xb8\xad\xe6\x96\x87
.Sh DESCRIPTION
A & B < C, a\\~b.
.Bl -tag -width Ds
.It Fl v
Verbose.
.El
.Ss Sub section
Words.
.Sh \xe5\xae\x89\xe8\xa3\x85
Han.
.Sh SEE Xr ls 1 PART
More.
MDOC

# fitted_manual($html, $what):
#	The assertions that each fitted manual must pass, whatever the
#	version of mandoc that wrote it.
sub fitted_manual ( $html, $what )
{
	unlike( $html, qr{class="(?:head|foot)}, "$what: no head and no foot" );
	unlike( $html, qr{<main\b}, "$what: and no main" );
	like( $html, qr{\A<h1>tool\(1\)</h1>\n<div class="manual-text">\n},
		"$what: the title opens the fragment" );
	is( scalar( () = $html =~ /<h1\b/g ), 1, "$what: in the one h1" );
	unlike( $html, qr{<h[1-6][^>]*>(?:(?!</h).)*permalink}s,
		"$what: no heading links itself" );
	my @wide = grep { hex $_ > 0x7F } $html =~ /&#x([0-9A-Fa-f]+);/g;
	is( scalar @wide, 0,
		"$what: no reference to a character outside ASCII" );
}

# fitted_mdoc($raw, $what):
#	The assertions over the fit of the output of mandoc(1) for $MDOC,
#	per WEB-MANUALS-9 to WEB-MANUALS-11. Each run of $MDOC uses this
#	one set, so the runs cannot drift. mandoc 1.14.6 writes the head
#	and the foot as a table, and the mandoc of OpenBSD 7.8 as a div.
#	The mandoc of OpenBSD 7.8 also writes an aria-label on a link of
#	.Xr, and breaks the line of .Nd at another word. The two versions
#	write the same ids, and no id on a heading of Han text.
sub fitted_mdoc ( $raw, $what )
{
	like( $raw, qr{<[a-z]+ class="head"}, "$what: mandoc writes a head" );
	like( $raw, qr{<[a-z]+ class="foot"}, "$what: and a foot" );
	like( $raw, qr{&#x00E0;},
		"$what: and a reference for each character" );

	my $html = App::FuguWeb::Fragment::manual( $raw, 'tool(1)' );
	fitted_manual( $html, $what );

	like( $html, qr{<h2 class="Sh" id="NAME">NAME</h2>},
		"$what: a section heading is an h2, with its text and its id" );
	like( $html, qr{<h3 class="Ss" id="Sub_section">Sub\s+section</h3>},
		"$what: a subsection heading is an h3" );
	like( $html, qr{<h2 class="Sh">\x{5b89}\x{88c5}</h2>},
		"$what: a heading of Han text holds the characters and no id" );
	like( $html,
		qr{<h2 class="Sh" id="SEE_ls_1_PART">SEE\s+<a class="Xr"(?: aria-label="ls, section 1")?>ls\(1\)</a>\s+PART</h2>},
		"$what: a heading keeps a link of its text" );
	like( $html, qr{voil\x{e0} and\s+\x{7b80}\x{4f53}\x{4e2d}\x{6587}},
		"$what: each character outside ASCII is text" );
	like( $html, qr{<code class="Nm">tool</code> \x{2014}},
		"$what: and so is the dash of the name line" );
	like( $html, qr{A &amp; B &lt; C, a\x{a0}b},
		"$what: an escape of markup stays" );
	like( $html, qr{<a class="permalink" href="#v">},
		"$what: and a tag of a list keeps its link" );
	is_deeply(
		[ map { $_->[0] } @{ App::FuguWeb::Fragment::outline($html) } ],
		[ 1, 2, 2, 3, 2, 2 ],
		"$what: the outline starts with the title, then the sections"
	);
}

SKIP: {
	skip 'mandoc not found', 1 unless have('mandoc');

	subtest 'a fragment of the mandoc on the path fits the page' => sub {
		fitted_mdoc( output( 'mandoc', $MDOC, '-Thtml', '-O', 'fragment' ),
			'mandoc' );
	};
}

subtest 'the same page of the mandoc of OpenBSD 7.8 fits the page' => sub {
	# The fragment below is the output of the base mandoc of OpenBSD
	# 7.8 GENERIC.MP#38 arm64, with -T html -O fragment, for $MDOC.
	# The first assertion holds the SHA-256 of that input.
	is( sha256_hex($MDOC),
		'3376025c2ea7008cf97d2b050fb1c289c484c18631b6024f68d0871e7996b592',
		'the record is of this $MDOC' );
	fitted_mdoc( <<'HTML', 'OpenBSD 7.8' );
<div class="head" role="doc-pageheader" aria-label="Manual header
  line"><span class="head-ltitle">TOOL(1)</span> <span class="head-vol">General
  Commands Manual</span> <span class="head-rtitle">TOOL(1)</span></div>
<main class="manual-text">
<section class="Sh">
<h2 class="Sh" id="NAME"><a class="permalink" href="#NAME">NAME</a></h2>
<p class="Pp"><code class="Nm">tool</code> &#x2014;
    <span class="Nd" role="doc-subtitle">a tool with voil&#x00E0; and
    &#x7B80;&#x4F53;&#x4E2D;&#x6587;</span></p>
</section>
<section class="Sh">
<h2 class="Sh" id="DESCRIPTION"><a class="permalink" href="#DESCRIPTION">DESCRIPTION</a></h2>
<p class="Pp">A &amp; B &lt; C, a&#x00A0;b.</p>
<dl class="Bl-tag">
  <dt id="v"><a class="permalink" href="#v"><code class="Fl">-v</code></a></dt>
  <dd>Verbose.</dd>
</dl>
<section class="Ss">
<h3 class="Ss" id="Sub_section"><a class="permalink" href="#Sub_section">Sub
  section</a></h3>
<p class="Pp">Words.</p>
</section>
</section>
<section class="Sh">
<h2 class="Sh">&#x5B89;&#x88C5;</h2>
<p class="Pp">Han.</p>
</section>
<section class="Sh">
<h2 class="Sh" id="SEE_ls_1_PART"><a class="permalink" href="#SEE_ls_1_PART">SEE
  <a class="Xr" aria-label="ls, section 1">ls(1)</a> PART</a></h2>
<p class="Pp">More.</p>
</section>
</main>
<div class="foot" role="doc-pagefooter" aria-label="Manual footer
  line"><span class="foot-left">OpenBSD 7.8</span>
  <span class="foot-date">October 25, 2026</span>
  <span class="foot-right">TOOL(1)</span></div>
HTML
};

SKIP: {
	skip 'pod2man or mandoc not found', 1
	    unless have('pod2man') && have('mandoc');

	subtest 'a fragment of pod2man and mandoc fits the page' => sub {
		my $man = output( 'pod2man', <<"POD", '--utf8' );
=encoding utf8

=head1 NAME

Thing::Depot - der Vertrag f\xc3\xbcr \xe7\xae\x80\xe4\xbd\x93

=head1 DESCRIPTION

Worte.

=head2 Teil

Mehr.
POD
		my $raw = output( 'mandoc', App::FuguWeb::encode($man), '-Thtml',
			'-O', 'fragment' );
		my $html = App::FuguWeb::Fragment::manual( $raw, 'Thing::Depot(3p)' );

		unlike( $html, qr{class="(?:head|foot)},
			'the sidecar takes no head and no foot' );
		unlike( $html, qr{User Contributed Perl Documentation|perl v5},
			'and no word of pod2man around it' );
		like( $html, qr{\A<h1>Thing::Depot\(3p\)</h1>\n},
			'the title opens it' );
		like( $html, qr{<h2 class="Sh" id="NAME">NAME</h2>},
			'a section heading is an h2' );
		like( $html, qr{<h3 class="Ss" id="Teil">Teil</h3>},
			'and a subsection heading an h3' );
		like( $html, qr{der Vertrag f\x{fc}r \x{7b80}\x{4f53}},
			'each character outside ASCII is text' );
	};
}

subtest 'a fragment of the mandoc of OpenBSD fits the page' => sub {
	# The mandoc of OpenBSD writes the head and the foot as a div,
	# the element of the text as a main, and each heading one level
	# down. The fragment below is the output of man.openbsd.org for
	# mdoc(7), cut short.
	my $raw = <<'HTML';
<div class="head" role="doc-pageheader" aria-label="Manual header
  line"><span class="head-ltitle">MDOC(7)</span>
  <span class="head-vol">Miscellaneous Information Manual</span>
  <span class="head-rtitle">MDOC(7)</span></div>
<main class="manual-text">
<section class="Sh">
<h2 class="Sh" id="NAME"><a class="permalink" href="#NAME">NAME</a></h2>
<p class="Pp"><code class="Nm">mdoc</code> &#x2014;
    <span class="Nd" role="doc-subtitle">semantic markup language for formatting
    manual pages</span></p>
<section class="Ss">
<h3 class="Ss" id="Sections_and_cross_references"><a class="permalink" href="#Sections_and_cross_references">Sections
  and cross references</a></h3>
</section>
</section>
</main>
<div class="foot" role="doc-pagefooter" aria-label="Manual footer
  line"><span class="foot-left">OpenBSD-current</span>
  <span class="foot-date">September 19, 2026</span>
  <span class="foot-right">MDOC(7)</span></div>
HTML

	my $html = App::FuguWeb::Fragment::manual( $raw, 'tool(1)' );
	fitted_manual( $html, 'OpenBSD' );
	like( $html, qr{<h2 class="Sh" id="NAME">NAME</h2>},
		'a section heading stays an h2' );
	like( $html,
		qr{<h3 class="Ss" id="Sections_and_cross_references">Sections\n  and cross references</h3>},
		'and a subsection heading an h3' );
	like( $html, qr{</section>\n</div>\n\z},
		'the element of the text ends the fragment' );
	like( $html, qr{<code class="Nm">mdoc</code> \x{2014}},
		'each character outside ASCII is text' );
};

subtest 'a fragment of Han text of the mandoc of OpenBSD 7.8 fits the page' => sub {
	# WEB-MANUALS-9 to WEB-MANUALS-11 and WEB-OUTLINE-4. The fragment
	# below is the output of the base mandoc of OpenBSD 7.8
	# GENERIC.MP#38 arm64. A heading of Han text takes no id and no
	# link to itself. The .Sx of Han text names an id that no heading
	# holds.
	my $raw = <<'HTML';
<div class="head" role="doc-pageheader" aria-label="Manual header
  line"><span class="head-ltitle">TOOL(1)</span> <span class="head-vol">General
  Commands Manual</span> <span class="head-rtitle">TOOL(1)</span></div>
<main class="manual-text">
<section class="Sh">
<h2 class="Sh" id="NAME"><a class="permalink" href="#NAME">NAME</a></h2>
<p class="Pp"><code class="Nm">tool</code> &#x2014;
    <span class="Nd" role="doc-subtitle">&#x5DE5;&#x5177;</span></p>
</section>
<section class="Sh">
<h2 class="Sh">&#x5B89;&#x88C5;</h2>
<p class="Pp">&#x6587;&#x672C;&#x3002;</p>
</section>
<section class="Sh">
<h2 class="Sh">&#x7528;&#x6CD5;</h2>
<p class="Pp">&#x89C1;
    <a class="Sx" href="#__u5B89___u88C5_">&#x5B89;&#x88C5;</a>.</p>
</section>
</main>
<div class="foot" role="doc-pagefooter" aria-label="Manual footer
  line"><span class="foot-left">OpenBSD 7.8</span>
  <span class="foot-date">October 25, 2026</span>
  <span class="foot-right">TOOL(1)</span></div>
HTML

	my $html = App::FuguWeb::Fragment::manual( $raw, 'tool(1)' );
	fitted_manual( $html, 'OpenBSD 7.8' );
	is( levels( App::FuguWeb::Fragment::outline($html) ),
		'1:- 2:NAME 2:- 2:-', 'each section heading is an h2' );
	like( $html, qr{<h2 class="Sh">\x{5b89}\x{88c5}</h2>\n<p class="Pp">\x{6587}\x{672c}\x{3002}</p>},
		'each character outside ASCII is text' );

	my $outline = App::FuguWeb::Fragment::outline( <<'HTML' );
<h1>tool(1)</h1>
<h2 class="Sh" id="NAME">NAME</h2>
<h2 class="Sh" id="INSTALL">INSTALL</h2>
<h2 class="Sh" id="USAGE">USAGE</h2>
HTML
	my $fitted = App::FuguWeb::Fragment::follow( $html, $outline, \my $at );
	is( levels( App::FuguWeb::Fragment::outline($fitted) ),
		'1:- 2:NAME 2:INSTALL 2:USAGE',
		'each heading takes the id of the default outline' );
	like( $fitted, qr{<a class="Sx" href="#INSTALL">\x{5b89}\x{88c5}</a>},
		'the link of .Sx names the id of its heading' );
};

subtest 'a body of the top-level 404.html' => sub {
	# WEB-TOP-6. Each id goes, and each relative link resolves
	# against the 404.html of its tree.
	my $html = <<'HTML';
<h1 id="gone">Not found</h1>
<p id='p' class="x"><a href="index.html">Home</a>
<a href="#gone">Here</a>
<a href='../style.css?v=1#top'>Sheet</a>
<img src=img/a.png alt="a">
<a href="?q=1">Query</a>
<a href="https://example.org/">Out</a>
<a href="mailto:a@example.org">Mail</a>
<a href="/root.html">Root</a>
<a href="../../up.html">Up</a>
<span data-id="k">The id = x</span></p>
HTML

	is( App::FuguWeb::Fragment::not_found( $html, 'zh-hans' ), <<'HTML',
<h1>Not found</h1>
<p class="x"><a href="zh-hans/index.html">Home</a>
<a href="zh-hans/404.html#gone">Here</a>
<a href="style.css?v=1#top">Sheet</a>
<img src="zh-hans/img/a.png" alt="a">
<a href="zh-hans/404.html?q=1">Query</a>
<a href="https://example.org/">Out</a>
<a href="mailto:a@example.org">Mail</a>
<a href="/root.html">Root</a>
<a href="../../up.html">Up</a>
<span data-id="k">The id = x</span></p>
HTML
		'each id goes, and each relative link names its file from the root'
	);
};

done_testing();
