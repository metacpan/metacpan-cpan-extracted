#!/usr/bin/env perl
# ex:ts=8 sw=4:
# App::FuguWeb::Page: each link from the path of its page, the chrome
# of a tree page, of the key page and of a page of the top level, the
# escaping, the optional footer fragment, the list of the languages,
# the current page, the lang and the dir of each page, and the marks of
# each part of another language.
#
# The test builds each site in a File::Temp directory. It never reads
# the repository, so a change to web/ cannot break it.

use v5.36;
use Test::More;
use FindBin qw($RealBin);
use lib "$RealBin/../../lib";
use File::Path qw(make_path);
use File::Temp qw(tempdir);

use_ok('App::FuguWeb::Config');
use_ok('App::FuguWeb::Page');

# site($rc, %files):
#	Build a project with the description $rc and the named files
#	in its source directory. Return the loaded configuration.
sub site ( $rc, %files )
{
	my $root = tempdir( CLEANUP => 1 );
	open my $fh, '>', "$root/.fuguwebrc"
	    or die "Cannot write the description: $!";
	print {$fh} $rc;
	close $fh;

	make_path("$root/web");
	for my $name ( sort keys %files ) {
		make_path( "$root/web/$name" =~ s{/[^/]+\z}{}r );
		open my $out, '>', "$root/web/$name"
		    or die "Cannot write $name: $!";
		print {$out} $files{$name};
		close $out;
	}

	my $config =
	    App::FuguWeb::Config->load( root => $root, error => \my $reason );
	die "$reason\n" unless $config;

	return $config;
}

# render($page, $path, $title, $fragment, %page):
#	Write one page at the path below a scratch output directory,
#	and return its bytes. The test reads back what write wrote.
#	The page arguments go to write as they stand.
sub render ( $page, $path, $title, $fragment, %page )
{
	my $out = tempdir( CLEANUP => 1 );
	make_path( "$out/$path" =~ s{/[^/]+\z}{}r );
	$page->write( $out, $path, $title, $fragment, %page )
	    or die 'write failed';

	open my $fh, '<', "$out/$path" or die "Cannot read $path: $!";
	binmode $fh;
	local $/ = undef;
	my $html = <$fh>;
	close $fh;

	return $html;
}


my $RC = <<'RC';
site = Example
url  = https://example.org/

nav "index.html" {
	label = Home
}

nav "manuals.html" {
	label = Manuals
}
RC

# The description of a site of three languages. The tree of zh-Hans
# takes the path zh-hans, and the language ar is right to left.
my $LANGUAGES = $RC . <<"RC";

language en {
	name = English
}

language zh-Hans {
	name   = \xe7\xae\x80\xe4\xbd\x93\xe4\xb8\xad\xe6\x96\x87
	site   = \xe7\xa4\xba\xe4\xbe\x8b
	footer = zh-hans/footer.body.html
}

language ar {
	name = Arabic
	dir  = rtl
}

nav zh-Hans "index.html" {
	label = \xe9\xa6\x96\xe9\xa1\xb5
}
RC

subtest 'each link comes from the path of the page and of its target' => sub {
	# WEB-LINKS-1. The link steps up out of each directory that the
	# target does not share, then down into the target.
	my %link = (
		'en/a.html en/b.html'           => 'b.html',
		'en/a.html en/a.html'           => 'a.html',
		'en/a.html zh-hans/a.html'      => '../zh-hans/a.html',
		'en/a.html style.css'           => '../style.css',
		'keys/index.html en/index.html' => '../en/index.html',
		'404.html en/index.html'        => 'en/index.html',
		'404.html style.css'            => 'style.css',
		'en/a.html keys/index.html'     => '../keys/index.html',

		# A query and a fragment stay at the end of the link.
		'en/a.html en/b.html?q=1/2#x' => 'b.html?q=1/2#x',

		# A first segment with a colon would read as a scheme.
		'en/a.html en/App::Thing.3p.html' => './App::Thing.3p.html',
		'zh-hans/a.html en/App::Thing.3p.html' =>
		    '../en/App::Thing.3p.html',
	);
	for my $pair ( sort keys %link ) {
		my ( $from, $to ) = split / /, $pair;
		is( App::FuguWeb::Page::relative( $from, $to ),
			$link{$pair}, "from $from to $to" );
	}
};

subtest 'the whole chrome of a tree page, in order' => sub {
	my $page = App::FuguWeb::Page->new( config => site($RC) );
	my $html =
	    render( $page, 'en/install.html', 'Install', "<h1>Install</h1>\n" );

	# WEB-CHROME-1 to WEB-CHROME-6. A tree page links each page of
	# its own tree from its directory, and the stylesheet at the top
	# level, one step up. A site of one language takes no list of
	# the languages, and two links of WEB-CHROME-6 still name it.
	my $expected = <<"HTML";
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Install \xe2\x80\x94 Example</title>
<link rel="canonical" href="https://example.org/en/install.html">
<link rel="alternate" hreflang="en" href="https://example.org/en/install.html">
<link rel="alternate" hreflang="x-default" href="https://example.org/">
<link rel="stylesheet" href="../style.css">
</head>
<body>
<header>
<a href="index.html">Example</a>
</header>
<nav>
<ul>
<li><a href="index.html">Home</a></li>
<li><a href="manuals.html">Manuals</a></li>
</ul>
</nav>
<main>
<h1>Install</h1>
</main>
</body>
</html>
HTML

	is( $html, $expected, 'the page is byte for byte the chrome' );

	# WEB-LANGUAGE-10. The html element carries the tag of the tree,
	# and dir="rtl" for a language that is right to left.
	my $config = site( $RC . <<'RC' );

language en {
	name = English
}

language sv {
	name = Svenska
}

language ar {
	name = Arabic
	dir  = rtl
}
RC
	$page = App::FuguWeb::Page->new(
		config   => $config,
		language => $config->language('sv')
	);
	like( render( $page, 'sv/install.html', 'Install', '' ),
		qr/<html lang="sv">\n/,
		'the html element carries the tag of the tree' );

	$page = App::FuguWeb::Page->new(
		config   => $config,
		language => $config->language('ar')
	);
	like( render( $page, 'ar/install.html', 'Install', '' ),
		qr/<html lang="ar" dir="rtl">\n/,
		'and dir="rtl" for a tree that is right to left' );
};

subtest 'the whole chrome of a tree page of three languages' => sub {
	my $config = site($LANGUAGES);
	my $page   = App::FuguWeb::Page->new(
		config   => $config,
		language => $config->language('zh-Hans'),
		footer   => "<p>ISC.</p>\n",
	);
	my $html = render( $page, 'zh-hans/manuals.html', 'Manuals', '',
		body_lang => 'en' );

	# WEB-CHROME-3 and WEB-CHROME-6. The head names the page in each
	# language, and the list of the languages follows the site link.
	# The link of the language of the page and the nav link of the
	# page are the current ones. The name of ar is right to left on
	# a page that is not.
	my $expected = <<"HTML";
<!DOCTYPE html>
<html lang="zh-Hans">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Manuals \xe2\x80\x94 \xe7\xa4\xba\xe4\xbe\x8b</title>
<link rel="canonical" href="https://example.org/zh-hans/manuals.html">
<link rel="alternate" hreflang="en" href="https://example.org/en/manuals.html">
<link rel="alternate" hreflang="zh-Hans" href="https://example.org/zh-hans/manuals.html">
<link rel="alternate" hreflang="ar" href="https://example.org/ar/manuals.html">
<link rel="alternate" hreflang="x-default" href="https://example.org/">
<link rel="stylesheet" href="../style.css">
</head>
<body>
<header>
<a href="index.html">\xe7\xa4\xba\xe4\xbe\x8b</a>
<ul>
<li><a href="../en/manuals.html" hreflang="en" lang="en">English</a></li>
<li><a href="manuals.html" hreflang="zh-Hans" lang="zh-Hans" aria-current="page">\xe7\xae\x80\xe4\xbd\x93\xe4\xb8\xad\xe6\x96\x87</a></li>
<li><a href="../ar/manuals.html" hreflang="ar" lang="ar" dir="rtl">Arabic</a></li>
</ul>
</header>
<nav>
<ul>
<li><a href="index.html">\xe9\xa6\x96\xe9\xa1\xb5</a></li>
<li><a href="manuals.html" lang="en" aria-current="page">Manuals</a></li>
</ul>
</nav>
<main lang="en">
</main>
<footer>
<p>ISC.</p>
</footer>
</body>
</html>
HTML

	is( $html, $expected, 'the page is byte for byte the chrome' );

	# A page of ar gives the name of each other language its
	# direction, and its own name none.
	$page = App::FuguWeb::Page->new(
		config   => $config,
		language => $config->language('ar')
	);
	like(
		render( $page, 'ar/manuals.html', 'Manuals', '' ),
		qr{<li><a href="\.\./en/manuals\.html" hreflang="en" lang="en" dir="ltr">English</a></li>
<li><a href="\.\./zh-hans/manuals\.html" hreflang="zh-Hans" lang="zh-Hans" dir="ltr">[^<]+</a></li>
<li><a href="manuals\.html" hreflang="ar" lang="ar" aria-current="page">Arabic</a></li>
},
		'the list of a page of ar'
	);

	# A module page holds a colon in its name, so the link to its
	# own tree takes ./ in front.
	$page = App::FuguWeb::Page->new(
		config   => $config,
		language => $config->language('zh-Hans')
	);
	$html = render( $page, 'zh-hans/App::Thing.3p.html', 'Thing', '' );
	like( $html, qr{<a href="\.\./en/App::Thing\.3p\.html" hreflang="en"},
		'the link names the page as the tree names it' );
	like(
		$html,
		qr{<a href="\./App::Thing\.3p\.html" hreflang="zh-Hans" lang="zh-Hans" aria-current="page">},
		'and the link to the page itself keeps its ./'
	);
	like( $html,
		qr{<link rel="canonical" href="https://example\.org/zh-hans/App::Thing\.3p\.html">},
		'and the head names it below the url' );
};

subtest 'the nav link of the current page' => sub {
	my $config = site( $RC . <<'RC' );

nav "./App::Thing.3p.html" {
	label = Thing
}

nav "search.html?q=1" {
	label = Search
}
RC

	# WEB-CHROME-4. The entry that names the page carries
	# aria-current, and no other entry does.
	my $page = App::FuguWeb::Page->new( config => $config );
	my $html = render( $page, 'en/index.html', 'Home', '' );
	like( $html,
		qr{<li><a href="index\.html" aria-current="page">Home</a></li>},
		'the entry of the page is the current one' );
	is( () = $html =~ /aria-current/g, 1, 'and it is the one current entry' );

	$html = render( $page, 'en/install.html', 'Install', '' );
	unlike( $html, qr/aria-current/, 'a page of no entry has none' );

	$html = render( $page, 'en/App::Thing.3p.html', 'Thing', '' );
	like(
		$html,
		qr{<li><a href="\./App::Thing\.3p\.html" aria-current="page">Thing</a></li>},
		'an entry with its ./ names the page too'
	);

	# WEB-LINKS-3. A query is no part of the name of a file.
	$html = render( $page, 'en/search.html', 'Search', '' );
	like(
		$html,
		qr{<li><a href="search\.html\?q=1" aria-current="page">Search</a></li>},
		'an entry with a query names the page too'
	);

	# A page outside every tree is no page of a nav entry.
	for my $path ( 'keys/index.html', '404.html' ) {
		unlike( render( $page, $path, 'Keys', '' ),
			qr/aria-current/, "$path has no current entry" );
	}
};

subtest 'a site with no nav entry carries no nav' => sub {
	my $page = App::FuguWeb::Page->new( config => site( <<'RC' ) );
site = Example
url  = https://example.org/
RC

	# WEB-CHROME-4. A description with no nav entry writes no nav
	# element, and not an empty one.
	for my $path ( 'en/install.html', 'keys/index.html', '404.html' ) {
		my $html = render( $page, $path, 'Install', '' );
		unlike( $html, qr/<nav\b/, "$path carries no nav" );
		like( $html, qr{</header>\n<main>\n},
			"and the main part of $path follows the header" );
	}
};

subtest 'the whole chrome of the key page, in order' => sub {
	my $page = App::FuguWeb::Page->new( config => site($RC) );
	my $html =
	    render( $page, 'keys/index.html', 'Keys', "<h1>Keys</h1>\n" );

	# WEB-CHROME-8. The key page sits one directory below the top
	# level, and links the default tree. Its head holds four parts,
	# and its title holds the English title alone.
	my $expected = <<"HTML";
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Keys</title>
<link rel="stylesheet" href="../style.css">
</head>
<body>
<header>
<a href="../en/index.html">Example</a>
</header>
<nav>
<ul>
<li><a href="../en/index.html">Home</a></li>
<li><a href="../en/manuals.html">Manuals</a></li>
</ul>
</nav>
<main>
<h1>Keys</h1>
</main>
</body>
</html>
HTML

	is( $html, $expected, 'the page is byte for byte the chrome' );

	# A site of more than one language gives the key page no list of
	# the languages, and no link of WEB-CHROME-6.
	$page = App::FuguWeb::Page->new( config => site($LANGUAGES) );
	$html = render( $page, 'keys/index.html', 'Keys', '' );
	unlike( $html, qr/<ul>\n<li><a [^>]*hreflang/,
		'the key page holds no list of the languages' );
	unlike( $html, qr/<link rel="(?:canonical|alternate)"/,
		'and its head names no page' );
};

subtest 'the key page is a page of en' => sub {
	# WEB-CHROME-8. The chrome takes the words of the default
	# language, and each part of it carries the marks of that
	# language when it is not en.
	my $config = site( <<"RC" );
site = Example
url  = https://example.org/

language zh-Hans {
	name = \xe7\xae\x80\xe4\xbd\x93\xe4\xb8\xad\xe6\x96\x87
	site = \xe7\xa4\xba\xe4\xbe\x8b
}

language en {
	name = English
}

nav "index.html" {
	label = \xe9\xa6\x96\xe9\xa1\xb5
}
RC
	my $page = App::FuguWeb::Page->new( config => $config );
	my $html =
	    render( $page, 'keys/index.html', 'Keys', "<h1>Keys</h1>\n" );

	like( $html, qr{<html lang="en">\n}, 'the page is a page of en' );
	like( $html, qr{<title>Keys</title>},
		'its title holds the words of en alone' );
	like(
		$html,
qr{<header>\n<a href="\.\./zh-hans/index\.html" lang="zh-Hans">\xe7\xa4\xba\xe4\xbe\x8b</a>\n</header>},
		'its site link goes into the default tree, with its marks'
	);
	like(
		$html,
		qr{<li><a href="\.\./zh-hans/index\.html" lang="zh-Hans">\xe9\xa6\x96\xe9\xa1\xb5</a></li>},
		'and so does each nav link'
	);
	like( $html, qr{<main>\n<h1>Keys</h1>}, 'the body of en takes none' );

	# A default language that is right to left gives each mark its
	# direction too.
	$config = site( <<'RC' );
site = Example
url  = https://example.org/

language ar {
	name = Arabic
	dir  = rtl
}

nav "index.html" {
	label = Home
}
RC
	$page = App::FuguWeb::Page->new( config => $config );
	$html = render( $page, 'keys/index.html', 'Keys', '' );
	like( $html, qr{<html lang="en">\n}, 'a page of en, left to right' );
	like( $html,
		qr{<header>\n<a href="\.\./ar/index\.html" lang="ar" dir="rtl">},
		'with the marks of ar on the site link' );
	like( $html,
		qr{<li><a href="\.\./ar/index\.html" lang="ar" dir="rtl">Home},
		'and on each nav link' );
};

subtest 'the whole chrome of the top-level 404 page, in order' => sub {
	my $page = App::FuguWeb::Page->new( config => site($RC) );
	my $html =
	    render( $page, '404.html', 'Not found', "<h1>Not found</h1>\n" );

	# The host serves the page at any path. The base is the path of
	# the url, so each relative link resolves from the site root.
	my $expected = <<"HTML";
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<base href="/">
<title>Not found \xe2\x80\x94 Example</title>
<link rel="stylesheet" href="style.css">
</head>
<body>
<header>
<a href="en/index.html">Example</a>
</header>
<nav>
<ul>
<li><a href="en/index.html">Home</a></li>
<li><a href="en/manuals.html">Manuals</a></li>
</ul>
</nav>
<main>
<h1>Not found</h1>
</main>
</body>
</html>
HTML

	is( $html, $expected, 'the page is byte for byte the chrome' );

	# A site below a path of its host takes that path as its base.
	my $config = site( $RC =~ s{https://example\.org/}{https://example.org/sub/}r );
	is( $config->url_path, '/sub/', 'the path of the url' );
	like( render( App::FuguWeb::Page->new( config => $config ),
			'404.html', 'Not found', '' ),
		qr{<base href="/sub/">\n<title>},
		'is the base of the page' );
};

subtest 'the top-level 404 page of three languages' => sub {
	# WEB-TOP-4. The page lists each language after the site link.
	# It belongs to no tree, so each link goes to the entry page of
	# its language, and no link is the current one. The nav is that
	# of the default tree, and the page carries no footer.
	my $config = site($LANGUAGES);
	my $page   = App::FuguWeb::Page->new(
		config => $config,
		footer => "<p>ISC.</p>\n"
	);

	# WEB-TOP-5. Each body sits in its own section, with the marks of
	# the language of its text.
	my $html = render(
		$page,
		'404.html',
		'Not found',
		$page->sections(
			[ 'en',      "<h1>Not found</h1>\n" ],
			[ 'zh-Hans', "<h1>\x{672a}\x{627e}\x{5230}</h1>\n" ],
			[ 'ar',      "<h1>Lost</h1>\n" ],
		)
	);

	my $expected = <<"HTML";
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<base href="/">
<title>Not found \xe2\x80\x94 Example</title>
<link rel="stylesheet" href="style.css">
</head>
<body>
<header>
<a href="en/index.html">Example</a>
<ul>
<li><a href="en/index.html" hreflang="en" lang="en">English</a></li>
<li><a href="zh-hans/index.html" hreflang="zh-Hans" lang="zh-Hans">\xe7\xae\x80\xe4\xbd\x93\xe4\xb8\xad\xe6\x96\x87</a></li>
<li><a href="ar/index.html" hreflang="ar" lang="ar" dir="rtl">Arabic</a></li>
</ul>
</header>
<nav>
<ul>
<li><a href="en/index.html">Home</a></li>
<li><a href="en/manuals.html">Manuals</a></li>
</ul>
</nav>
<main>
<section>
<h1>Not found</h1>
</section>
<section lang="zh-Hans">
<h1>\xe6\x9c\xaa\xe6\x89\xbe\xe5\x88\xb0</h1>
</section>
<section lang="ar" dir="rtl">
<h1>Lost</h1>
</section>
</main>
</body>
</html>
HTML

	is( $html, $expected, 'the page is byte for byte the chrome' );
};

subtest 'the forward page' => sub {
	# WEB-TOP-1. A page of the default language. Its head holds the
	# charset, the meta refresh, the title and the links of
	# WEB-CHROME-6, and nothing else. It loads nothing. Its
	# canonical link is the bare url, and the link of each language
	# goes to the entry page of that language, per WEB-TOP-2.
	my $page = App::FuguWeb::Page->new( config => site($RC) );
	is( App::FuguWeb::encode( $page->forward ), <<'HTML',
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta http-equiv="refresh" content="0; url=en/index.html">
<title>Example</title>
<link rel="canonical" href="https://example.org/">
<link rel="alternate" hreflang="en" href="https://example.org/en/index.html">
<link rel="alternate" hreflang="x-default" href="https://example.org/">
</head>
<body>
<p><a href="en/index.html">Example</a></p>
</body>
</html>
HTML
		'a site of one language links the entry page with the site name' );

	# WEB-TOP-2. A site of more than one language lists each one,
	# with no current link.
	$page = App::FuguWeb::Page->new( config => site($LANGUAGES) );
	is( App::FuguWeb::encode( $page->forward ), <<"HTML",
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta http-equiv="refresh" content="0; url=en/index.html">
<title>Example</title>
<link rel="canonical" href="https://example.org/">
<link rel="alternate" hreflang="en" href="https://example.org/en/index.html">
<link rel="alternate" hreflang="zh-Hans" href="https://example.org/zh-hans/index.html">
<link rel="alternate" hreflang="ar" href="https://example.org/ar/index.html">
<link rel="alternate" hreflang="x-default" href="https://example.org/">
</head>
<body>
<ul>
<li><a href="en/index.html" hreflang="en" lang="en">English</a></li>
<li><a href="zh-hans/index.html" hreflang="zh-Hans" lang="zh-Hans">\xe7\xae\x80\xe4\xbd\x93\xe4\xb8\xad\xe6\x96\x87</a></li>
<li><a href="ar/index.html" hreflang="ar" lang="ar" dir="rtl">Arabic</a></li>
</ul>
</body>
</html>
HTML
		'a site of three languages lists the entry page of each one' );
};

subtest 'the language of the main element of a page' => sub {
	# WEB-LANGUAGE-11. The main element takes the language of the
	# value of the page. An index marks each part of its own, so its
	# main element takes the language of the tree.
	my $zh = site($LANGUAGES)->language('zh-Hans');
	is( App::FuguWeb::Page::body_lang( { source => 'body', lang => 'en' }, $zh ),
		'en', 'a body takes the language of its value' );
	is( App::FuguWeb::Page::body_lang( { source => 'index', lang => 'en' }, $zh ),
		'zh-Hans', 'and an index takes the language of the tree' );
};

subtest 'an absolute URL passes unchanged' => sub {
	my $config = site( <<'RC' );
site = Example
url  = https://example.org/

nav "https://example.org/" {
	label = Away
}
RC

	# WEB-LINKS-2. A step in front of it would name a page that the
	# site does not hold.
	my $page = App::FuguWeb::Page->new( config => $config );
	for my $path ( 'en/install.html', 'keys/index.html', '404.html' ) {
		like(
			render( $page, $path, 'Install', '' ),
			qr{<a href="https://example\.org/">Away</a>},
			"an absolute URL on $path"
		);
	}
};

subtest 'a path of more than two segments is no page' => sub {
	my $page = App::FuguWeb::Page->new( config => site($RC) );
	ok( !eval { $page->document( 'en/a/b.html', 'B', '' ) },
		'the document dies' );
	like( $@, qr{not the path of a page: en/a/b\.html}, 'and names it' );
};

subtest 'the chrome holds no separator, no rule and no class' => sub {
	# WEB-CHROME-5 and D-04. The sheet draws each rule and each
	# separator.
	is( App::FuguWeb::Page::EM_DASH(), "\x{2014}", 'the em dash' );

	my $config = site($LANGUAGES);
	my $page   = App::FuguWeb::Page->new(
		config => $config,
		footer => "<p>ISC.</p>\n"
	);
	my $html = render( $page, 'en/install.html', 'Install', '' );

	like( $html, qr/<title>Install \xe2\x80\x94 Example<\/title>/,
		'an em dash separates the title from the site' );
	unlike( $html, qr/\xc2\xb7/, 'no middle dot' );
	unlike( $html, qr/<hr/,      'no hr' );
	unlike( $html, qr/class=/,   'no class' );

	# The footer fragment is the prose of the project.
	my ($body) = $html =~ m{<body>(.*)<footer>}s;
	$body =~ s{<a\b[^>]*>.*?</a>}{}gs;
	$body =~ s{<[^>]*>}{}g;
	like( $body, qr/\A\s*\z/, 'and no word outside a link' );
};

subtest 'the title and the labels are escaped' => sub {
	my $config = site( <<'RC' );
site = A & B
url  = https://example.org/

nav "index.html" {
	label = <Home>
}
RC
	my $page = App::FuguWeb::Page->new( config => $config );
	my $html = render( $page, 'en/tags.html', 'Tags < & >', '' );

	like( $html, qr/<title>Tags &lt; &amp; &gt; /,
		'the title is escaped' );
	like( $html, qr/&amp; B<\/title>/, 'the site name is escaped' );
	like( $html, qr/>&lt;Home&gt;<\/a>/, 'a navigation label is escaped' );

	# The shell chrome that this replaced substituted the title with
	# sed. A slash ended the substitution and an ampersand meant
	# "the whole match", so neither could ever reach a page.
	$html = render( $page, 'en/conf.html', 'openhapd.conf(5) / 8', '' );
	like( $html, qr{<title>openhapd\.conf\(5\) / 8 },
		'a title may hold a slash' );
};

subtest 'a value that reaches an attribute is escaped' => sub {
	my $config = site( <<'RC' );
site  = Example
url   = https://example.org/
entry = index.html?a&b" onload="x

nav "search.html?q=1&r=2" {
	label = Search
}
RC
	my $page = App::FuguWeb::Page->new( config => $config );
	my $html = render( $page, 'en/install.html', 'Install', '' );

	# A quote in a value would end the attribute early, and
	# everything after it would become markup.
	like( $html, qr/href="index\.html\?a&amp;b&quot; onload=&quot;x"/,
		'a quote in the header href is escaped' );
	unlike( $html, qr/onload="x"/, 'no attribute was injected' );

	# An ampersand is not markup, but it is not valid in an
	# attribute either, and the same escape covers both.
	like( $html, qr{href="search\.html\?q=1&amp;r=2"},
		'a navigation href is escaped' );
};

subtest 'the footer fragment is optional' => sub {
	my $page = App::FuguWeb::Page->new( config => site($RC) );
	my $html = render( $page, 'en/install.html', 'Install', '' );
	unlike( $html, qr/<footer>/, 'no fragment, no footer element' );
	like( $html, qr/<\/main>\n<\/body>/, 'and nothing after the main part' );

	my $config = site($RC);
	$page = App::FuguWeb::Page->new(
		config => $config,
		footer => "<p>ISC.</p>\n"
	);
	$html = render( $page, 'en/install.html', 'Install', '' );
	like( $html, qr{</main>\n<footer>\n<p>ISC\.</p>\n</footer>\n},
		'the fragment becomes the footer of a tree page' );

	# WEB-KEYS-32. A relative link of the fragment resolves inside a
	# tree, and nowhere else.
	for my $path ( 'keys/index.html', '404.html' ) {
		unlike( render( $page, $path, 'Install', '' ), qr/<footer>/,
			"$path carries no footer" );
	}
};

subtest 'each part of another language carries its marks' => sub {
	my $config = site($LANGUAGES);

	# WEB-LANGUAGE-11. A page of zh-Hans takes its own site name and
	# its own label, and the default label of the other entry.
	my $page = App::FuguWeb::Page->new(
		config   => $config,
		language => $config->language('zh-Hans'),
		footer   => "<p>ISC.</p>\n",
	);
	my $html = render( $page, 'zh-hans/install.html', 'Install',
		"<p>Words.</p>\n", body_lang => 'en' );
	like( $html, qr{<html lang="zh-Hans">\n}, 'a page of zh-Hans' );
	like( $html, qr{<header>\n<a href="index\.html">\xe7\xa4\xba\xe4\xbe\x8b</a>\n},
		'its own site name takes no mark' );
	like( $html, qr{<a href="index\.html">\xe9\xa6\x96\xe9\xa1\xb5</a>},
		'nor does its own label' );
	like( $html, qr{<a href="manuals\.html" lang="en">Manuals</a>},
		'a label of en carries lang="en"' );
	like( $html, qr{</nav>\n<main lang="en">\n<p>Words\.</p>\n</main>\n},
		'and so does a body of en' );
	like( $html, qr{<footer>\n<p>ISC\.</p>\n</footer>},
		'the footer of zh-Hans takes no mark' );

	# A page of ar takes each value of en. Each mark carries the
	# direction too, because the two directions differ.
	$page = App::FuguWeb::Page->new(
		config   => $config,
		language => $config->language('ar'),
		footer   => "<p>ISC.</p>\n",
	);
	$html = render( $page, 'ar/install.html', 'Install', "<p>Words.</p>\n",
		body_lang => 'en' );
	like( $html, qr{<html lang="ar" dir="rtl">\n}, 'a page of ar' );
	like(
		$html,
		qr{<header>\n<a href="index\.html" lang="en" dir="ltr">Example</a>\n},
		'the site link carries the marks of en'
	);
	like( $html, qr{<a href="index\.html" lang="en" dir="ltr">Home</a>},
		'and so does each nav link' );
	like( $html, qr{<main lang="en" dir="ltr">\n}, 'and the body' );
	like( $html, qr{<footer lang="en" dir="ltr">\n<p>ISC\.</p>\n</footer>},
		'and the footer' );

	like(
		render( $page, 'ar/install.html', 'Install', '', body_lang => 'ar' ),
		qr{</nav>\n<main>\n},
		'a body of ar carries no mark'
	);
	like( render( $page, 'ar/install.html', 'Install', '' ),
		qr{</nav>\n<main>\n}, 'and the body takes the language of the page' );
};

done_testing();
