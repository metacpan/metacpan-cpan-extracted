#!/usr/bin/env perl
# ex:ts=8 sw=4:
# App::FuguWeb::Check: one problem for each thing that can be wrong
# with a built site.
#
# The test writes a small site in a File::Temp directory and then
# breaks it, one way at a time. App::FuguWeb::Page writes the chrome
# of each good page, and no renderer runs. The test never reads the
# repository; t/web/site.t covers the real site.

use v5.36;
use Test::More;
use FindBin qw($RealBin);
use lib "$RealBin/../../lib";
use File::Path qw(make_path);
use File::Temp qw(tempdir);

use_ok('App::FuguWeb::Check');
use_ok('App::FuguWeb::Config');
use_ok('App::FuguWeb::Fragment');
use_ok('App::FuguWeb::Page');

my $RC = <<'RC';
site       = Example
url        = https://example.org/
source_dir = web
out_dir    = out

nav "index.html" {
	label = Home
}

nav "https://example.org/" {
	label = Elsewhere
}

page "index.html" {
	title = Home
	body  = index.body.html
}

page "404.html" {
	title    = Not found
	body     = 404.body.html
	unlinked = yes
}

page "other.html" {
	title = Other
	body  = other.body.html
}
RC

# The same site in three languages: en, zh-Hans and ar. The tree of
# zh-Hans takes the path zh-hans, and ar is right to left. The 404
# page of zh-Hans takes its own title and body.
my $THREE = $RC . <<"RC";

language en {
	name = English
}

language zh-Hans {
	name = \xe7\xae\x80\xe4\xbd\x93\xe4\xb8\xad\xe6\x96\x87
	site = \xe7\xa4\xba\xe4\xbe\x8b
}

language ar {
	name = Arabic
	dir  = rtl
}

page zh-Hans "404.html" {
	title = \xe6\x9c\xaa\xe6\x89\xbe\xe5\x88\xb0
	body  = zh-hans/404.body.html
}
RC

# The title and the body of each page, as characters, by its name in
# the tree. A path of a tree names the page of that tree alone. Each
# tree page and the top-level 404.html wrap the body in the chrome
# that App::FuguWeb::Page writes.
my %BODY = (
	'index.html' => [ 'Home', <<'HTML' ],
<h1>Home</h1>
<p><a href="./other.html">Other</a></p>
<p><a href="./other.html#here">The anchor</a></p>
HTML
	'404.html'   => [ 'Not found', "<h1>Not found</h1>\n" ],
	'other.html' => [ 'Other',     qq{<h2 id="here">Here</h2>\n} ],

	'zh-hans/404.html' => [
		"\x{672a}\x{627e}\x{5230}",
		"<h1>\x{672a}\x{627e}\x{5230}</h1>\n"
		    . qq{<p><a href="index.html">\x{9996}\x{9875}</a></p>\n}
	],
);

# good($config):
#	The files of a site that passes every check, by path: each tree
#	page, the top-level 404.html and the forward as
#	App::FuguWeb::Page writes them, the stylesheet and the asset.
#	The top-level 404.html holds the body of the 404 page of each
#	tree, as App::FuguWeb::Fragment fits it. Each subtest starts
#	from this and breaks exactly one thing.
sub good ($config)
{
	my ( %file, @bodies );
	for my $language ( $config->languages ) {
		my $page = App::FuguWeb::Page->new(
			config   => $config,
			language => $language
		);
		for my $entry ( $config->pages( $language->tag ) ) {
			my $name = $entry->{file};
			my $path = $language->path . "/$name";
			my ( $title, $body ) = @{ $BODY{$path} // $BODY{$name} };
			my $lang = App::FuguWeb::Page::body_lang( $entry, $language );

			$file{$path} = App::FuguWeb::encode(
				$page->document( $path, $title, $body,
					body_lang => $lang ) );
			push @bodies,
			    [
				$lang,
				App::FuguWeb::Fragment::not_found(
					$body, $language->path
				)
			    ]
			    if $name eq '404.html';
		}
	}

	my $top = App::FuguWeb::Page->new( config => $config );
	$file{'404.html'} = App::FuguWeb::encode(
		$top->document(
			'404.html', $BODY{'404.html'}[0],
			$top->sections(@bodies)
		) );
	$file{'index.html'} = App::FuguWeb::encode( $top->forward );

	$file{'style.css'}  = "body { color: black }\n";
	$file{'robots.txt'} = "User-agent: *\n";

	return %file;
}

# built(%override):
#	Build the site of one language on disk, with the named files
#	replaced, and return a Check over it.
sub built (%override)
{
	return built_rc( $RC, %override );
}

# built_rc($description, %override):
#	Build a site of the description on disk, and return a Check over
#	it. An override of undef writes no file, a code reference
#	takes the good bytes and gives the bytes to write, and any
#	other value is the bytes to write.
sub built_rc ( $description, %override )
{
	my $root = tempdir( CLEANUP => 1 );
	make_path("$root/web");

	my %source = (
		'.fuguwebrc'                  => $description,
		'web/index.body.html'         => "<h1>Home</h1>\n",
		'web/404.body.html'           => "<h1>Not found</h1>\n",
		'web/other.body.html'         => "<h2 id=\"here\">Here</h2>\n",
		'web/robots.txt'              => "User-agent: *\n",
		'web/zh-hans/404.body.html'   => "<h1>Not found</h1>\n",
	);
	for my $name ( sort keys %source ) {
		make_path( "$root/$name" =~ s{/[^/]+\z}{}r );
		open my $fh, '>', "$root/$name" or die "Cannot write $name: $!";
		print {$fh} $source{$name};
		close $fh;
	}

	my $config =
	    App::FuguWeb::Config->load( root => $root, error => \my $reason );
	die "$reason\n" unless $config;

	my %file = good($config);
	for my $name ( keys %override ) {
		my $value = $override{$name};
		$file{$name} =
		    ref $value eq 'CODE'
		    ? $value->( $file{$name} // '' )
		    : $value;
	}

	my $out = "$root/out";
	make_path($out);
	for my $name ( sort keys %file ) {
		next unless defined $file{$name};

		make_path( "$out/$name" =~ s{/[^/]+\z}{}r );
		open my $fh, '>', "$out/$name" or die "Cannot write $name: $!";
		print {$fh} $file{$name};
		close $fh;
	}

	return App::FuguWeb::Check->new( config => $config, out => $out );
}

# swap($from, $to):
#	An override that replaces the first match of the pattern.
sub swap ( $from, $to )
{
	return sub ($html) {
		$html =~ s{$from}{$to} or die "the page holds no $from";
		return $html;
	};
}

# inside($html):
#	An override that adds the HTML at the end of the body fragment.
sub inside ($html)
{
	return swap( qr{</main>}, "$html</main>" );
}

# lost($html):
#	The overrides that add the HTML at the end of the body of
#	en/404.html, and at the end of its section of the top-level
#	404.html, as App::FuguWeb::Fragment fits it there. The two pages
#	of a good site then hold the same body.
sub lost ($html)
{
	return (
		'en/404.html' => inside($html),
		'404.html'    => swap(
			qr{</section>},
			App::FuguWeb::Fragment::not_found( $html, 'en' )
			    . '</section>'
		),
	);
}

subtest 'a site that is good gives no problem' => sub {
	my $check    = built();
	my @problems = $check->run;

	is( scalar @problems, 0, 'no problem' ) or diag join "\n", @problems;

	# The links of WEB-CHROME-6 name the site by its url, and the
	# check holds each one apart.
	is_deeply( [ $check->external ], ['https://example.org/'],
		'the external link is collected and not fetched' );

	@problems = built_rc($THREE)->run;
	is( scalar @problems, 0, 'and a site of three languages gives none' )
	    or diag join "\n", @problems;
};

subtest 'a page that is missing or empty' => sub {
	my @problems = built( 'en/other.html' => undef )->run;
	like( join( "\n", @problems ),
		qr{en/other\.html: missing from the output}, 'a missing page' );

	@problems = built( 'en/other.html' => '' )->run;
	like( join( "\n", @problems ), qr{en/other\.html: empty},
		'an empty page' );

	@problems = built( 'index.html' => undef )->run;
	like( join( "\n", @problems ), qr{^index\.html: missing from the output}m,
		'a missing forward' );

	@problems = built( '404.html' => undef )->run;
	like( join( "\n", @problems ), qr{^404\.html: missing from the output}m,
		'a missing top-level 404.html' );
};

subtest 'a page with no title' => sub {
	my @problems =
	    built( 'en/other.html' => swap( qr{<title>[^<]*</title>}, '' ) )
	    ->run;
	is_deeply( \@problems, ['en/other.html: has no title'], 'no title' );
};

subtest 'a page that drops a nav entry' => sub {
	my @problems = built( 'en/other.html' =>
		    swap( qr{<li><a href="https://example\.org/">[^\n]*\n}, '' ) )
	    ->run;
	is_deeply(
		\@problems,
		[
			'en/other.html: carries 1 navigation links, and the'
			    . ' site has 2',
			'en/other.html: does not carry the navigation entry'
			    . ' https://example.org/'
		],
		'the missing entry is named'
	);

	# A site with no nav entry carries no nav.
	my $rc = $RC =~ s/nav "[^"]*" \{\n[^}]*\}\n\n//gr;
	@problems = built_rc( $rc,
		'en/other.html' => swap( qr{</header>\n}, "</header>\n<nav>\n</nav>\n" ) )
	    ->run;
	like(
		join( "\n", @problems ),
		qr{^en/other\.html: carries a nav, and the site has no nav entry$}m,
		'a nav of a site with no entry'
	);
};

subtest 'a tree page carries the tag and the direction of its tree' => sub {
	# WEB-LANGUAGE-13. The html element of a tree page carries the
	# tag of its tree, and dir="rtl" when the tree is right to left.
	my @problems = built(
		'en/other.html' => swap( qr{<html lang="en">}, '<html lang="sv">' ) )
	    ->run;
	is_deeply( \@problems, ['en/other.html: does not carry <html lang="en">'],
		'the page is held to the language of its tree' );

	@problems = built( 'en/other.html' =>
		    swap( qr{<html lang="en">}, '<html lang="en" dir="rtl">' ) )
	    ->run;
	is_deeply( \@problems, ['en/other.html: does not carry <html lang="en">'],
		'and a tree of ltr carries no dir="rtl"' );

	# The same site with the one language ar, which is right to
	# left. Its tree is ar.
	my $rc = $RC . "\nlanguage ar {\n\tname = Arabic\n\tdir  = rtl\n}\n";

	@problems = built_rc($rc)->run;
	is( scalar @problems, 0, 'a site of a tree of rtl gives no problem' )
	    or diag join "\n", @problems;

	@problems = built_rc( $rc,
		'ar/other.html' => swap( qr{ dir="rtl"}, '' ) )->run;
	is_deeply( \@problems,
		['ar/other.html: does not carry <html lang="ar" dir="rtl">'],
		'and a page of it with no dir fails' );
};

subtest 'the head names the page in each language' => sub {
	# WEB-CHROME-6. A tree page links itself, the same page in each
	# language, and the forward page.
	my $alternate = '<link rel="alternate" hreflang="zh-Hans"'
	    . ' href="https://example.org/zh-hans/other.html">';
	my @problems = built_rc( $THREE,
		'ar/other.html' => swap( qr{\Q$alternate\E\n}, '' ) )->run;
	is_deeply(
		\@problems,
		[
			"ar/other.html: the head does not carry $alternate",
			'ar/other.html: the head carries 4 canonical and'
			    . ' alternate links, and the page takes 5'
		],
		'a tree page with no link to its page of zh-Hans'
	);

	@problems = built_rc( $THREE,
		'en/other.html' => swap( qr{x-default" href="[^"]*"},
			'x-default" href="https://example.org/en/index.html"' ) )
	    ->run;
	is_deeply(
		\@problems,
		[
			'en/other.html: the head does not carry <link'
			    . ' rel="alternate" hreflang="x-default"'
			    . ' href="https://example.org/">'
		],
		'and one whose x-default is not the bare url'
	);

	# WEB-LINKS-5. Each href is the url, then the path of a page of
	# the inventory, or the bare url.
	@problems = built_rc( $THREE,
		'en/other.html' => swap( qr{https://example\.org/en/other\.html},
			'https://example.net/en/other.html' ) )->run;
	like(
		join( "\n", @problems ),
qr{^en/other\.html: https://example\.net/en/other\.html is no URL of a page of the site$}m,
		'an href of another host'
	);

	@problems = built_rc( $THREE,
		'en/other.html' => swap( qr{https://example\.org/zh-hans/other\.html},
			'https://example.org/zh-hans/gone.html' ) )->run;
	like(
		join( "\n", @problems ),
qr{^en/other\.html: https://example\.org/zh-hans/gone\.html is no URL of a page of the site$}m,
		'and an href of no page of the inventory'
	);

	# A page outside every tree links no page in its head. The head
	# of the top-level 404.html holds five parts alone, per
	# WEB-TOP-3.
	my $canonical =
	    qq{<link rel="canonical" href="https://example.org/404.html">\n};
	@problems = built_rc( $THREE,
		'404.html' => swap( qr{<link rel="stylesheet"}, "$canonical<link rel=\"stylesheet\"" ) )
	    ->run;
	is_deeply(
		\@problems,
		[
			'404.html: the head carries 1 canonical and alternate'
			    . ' links, and the page takes 0',
			'404.html: the head holds charset, viewport, base, title,'
			    . ' links, stylesheet, and the page takes charset,'
			    . ' viewport, base, title, stylesheet'
		],
		'the top-level 404.html names no page'
	);

	# The check reads the rel and the href of a link through the one
	# reader, so the text of another attribute is no rel and no href.
	@problems = built_rc( $THREE,
		'en/other.html' => swap( qr{<link rel="canonical" href="https://example\.org/en/other\.html">},
			q{<link title='rel="canonical"' href="https://example.org/en/other.html">} ) )
	    ->run;
	is_deeply(
		\@problems,
		[
			'en/other.html: the head does not carry <link'
			    . ' rel="canonical"'
			    . ' href="https://example.org/en/other.html">',
			'en/other.html: the head carries 4 canonical and'
			    . ' alternate links, and the page takes 5'
		],
		'a rel in the text of a value is no rel'
	);

	@problems = built_rc( $THREE,
		'en/other.html' => swap( qr{<link rel="alternate" hreflang="ar" href="[^"]*">},
			q{<link rel="alternate" hreflang="ar" data-href="https://example.org/ar/other.html" href="https://example.net/ar/other.html">} ) )
	    ->run;
	like(
		join( "\n", @problems ),
		qr{^en/other\.html: https://example\.net/ar/other\.html is no URL of a page of the site$}m,
		'and a data-href is no href'
	);
};

subtest 'the list of the languages' => sub {
	# WEB-CHROME-3. One item for each language, in the order of the
	# declaration, and the item of the page is the current one.
	my @problems = built_rc( $THREE,
		'zh-hans/other.html' => swap( qr{ aria-current="page">\xe7\xae\x80}, ">\xe7\xae\x80" ) )
	    ->run;
	is_deeply(
		\@problems,
		[
			'zh-hans/other.html: the link to zh-Hans does not carry'
			    . ' aria-current="page"'
		],
		'the link of the language of the page is the current one'
	);

	@problems = built_rc( $THREE,
		'zh-hans/other.html' => swap( qr{lang="en">English}, 'lang="en" aria-current="page">English' ) )
	    ->run;
	is_deeply(
		\@problems,
		[
			'zh-hans/other.html: the link to en carries'
			    . ' aria-current="page"'
		],
		'and the link of another language is not'
	);

	@problems = built_rc( $THREE,
		'ar/other.html' => swap( qr{<li><a href="\.\./en/other\.html"[^\n]*\n}, '' ) )
	    ->run;
	like(
		join( "\n", @problems ),
		qr{^ar/other\.html: carries 2 language links, and the page takes 3$}m,
		'a list with no item of en'
	);

	# The text of each link is the name of the language.
	@problems = built_rc( $THREE,
		'en/other.html' => swap( qr{>Arabic</a>}, '>ar</a>' ) )->run;
	is_deeply( \@problems, ['en/other.html: does not link the page in ar'],
		'a link with the tag as its text' );

	@problems = built_rc( $THREE,
		'en/other.html' => swap( qr{href="\.\./ar/other\.html"}, 'href="../ar/index.html"' ) )
	    ->run;
	is_deeply( \@problems, ['en/other.html: does not link the page in ar'],
		'and a link to another page' );

	@problems = built_rc( $THREE,
		'en/other.html' => swap( qr{hreflang="ar" lang="ar"}, 'hreflang="ar"' ) )
	    ->run;
	is_deeply( \@problems, ['en/other.html: does not link the page in ar'],
		'and a link with no lang' );

	# WEB-TOP-4. The top-level 404.html lists each language too. It
	# belongs to no tree, so each link goes to the entry page of its
	# language, and no link is the current one, per WEB-TOP-2.
	@problems = built_rc( $THREE,
		'404.html' => swap( qr{<li><a href="zh-hans/index\.html"[^\n]*\n}, '' ) )
	    ->run;
	is_deeply(
		\@problems,
		[
			'404.html: carries 2 language links, and the page takes 3',
			'404.html: does not link the entry page in zh-Hans',
			'404.html: does not link the entry page in ar'
		],
		'a top-level 404.html with no item of zh-Hans'
	);

	@problems = built_rc( $THREE,
		'404.html' => swap( qr{href="zh-hans/index\.html"}, 'href="zh-hans/404.html"' ) )
	    ->run;
	is_deeply( \@problems,
		['404.html: does not link the entry page in zh-Hans'],
		'and one that links the 404 page of zh-Hans' );

	@problems = built_rc( $THREE,
		'404.html' => swap( qr{lang="en">English}, 'lang="en" aria-current="page">English' ) )
	    ->run;
	is_deeply( \@problems,
		['404.html: the link to en carries aria-current="page"'],
		'and one with a current link' );

	# The key page holds no list, and a site of one language holds
	# none.
	@problems = built( 'en/other.html' => swap( qr{</a>\n</header>},
			qq{</a>\n<ul>\n<li><a href="../de/other.html" hreflang="de" lang="de">Deutsch</a></li>\n</ul>\n</header>} ) )
	    ->run;
	like(
		join( "\n", @problems ),
		qr{^en/other\.html: carries 1 language links, and the page takes 0$}m,
		'and a list on a site of one language'
	);

	# The chrome ends where the main element starts. A list of the
	# body is the writer's own.
	@problems = built( 'en/other.html' => inside(
			qq{<ul>\n<li><a href="https://example.org/de/" hreflang="de">de</a></li>\n</ul>\n}) )
	    ->run;
	is( scalar @problems, 0, 'a list of the body is no list of the chrome' )
	    or diag join "\n", @problems;
};

subtest 'the nav link of the current page' => sub {
	# WEB-CHROME-4. The entry that names the page is the current one.
	my @problems = built(
		'en/index.html' => swap( qr{ aria-current="page">Home}, '>Home' ) )
	    ->run;
	is_deeply(
		\@problems,
		[
			'en/index.html: the navigation entry index.html does'
			    . ' not carry aria-current="page"'
		],
		'the entry of the page'
	);

	@problems = built(
		'en/other.html' => swap( qr{">Home}, '" aria-current="page">Home' ) )
	    ->run;
	is_deeply(
		\@problems,
		[
			'en/other.html: the navigation entry index.html carries'
			    . ' aria-current="page"'
		],
		'and an entry of another page'
	);

	@problems = built( '404.html' =>
		    swap( qr{">Home}, '" aria-current="page">Home' ) )->run;
	is_deeply(
		\@problems,
		[
			'404.html: the navigation entry index.html carries'
			    . ' aria-current="page"'
		],
		'and an entry of a page outside every tree'
	);
};

subtest 'the site link is no current link' => sub {
	# WEB-CHROME-2. The site link of the entry page goes to the page
	# itself, and it still carries no aria-current.
	my @problems = built( 'en/index.html' =>
		    swap( qr{<a href="index\.html">Example}, '<a href="index.html" aria-current="page">Example' ) )
	    ->run;
	is_deeply( \@problems,
		['en/index.html: the site link carries aria-current="page"'],
		'a site link that carries it' );
};

subtest 'the chrome carries no class, no rule and no separator' => sub {
	# D-04 and WEB-CHROME-5. The sheet draws each rule and each
	# separator, and reaches the chrome by element name.
	my @problems = built( 'en/other.html' =>
		    swap( qr{<header>}, '<header class="banner">' ) )->run;
	is_deeply( \@problems, ['en/other.html: the chrome carries a class'],
		'a class on the header' );

	@problems = built(
		'en/other.html' => swap( qr{</nav>\n}, "</nav>\n<hr>\n" ) )->run;
	is_deeply( \@problems, ['en/other.html: the chrome carries an hr'],
		'a rule before the main part' );

	@problems = built( 'en/other.html' =>
		    swap( qr{Home</a></li>\n}, "Home</a> \xc2\xb7</li>\n" ) )->run;
	is_deeply( \@problems,
		['en/other.html: the chrome carries a text separator'],
		'a middle dot between two nav entries' );

	@problems = built( 'en/other.html' =>
		    swap( qr{</header>}, "| </header>" ) )->run;
	is_deeply( \@problems,
		['en/other.html: the chrome carries a text separator'],
		'and a bar in the header' );

	# The body fragment and the footer fragment are the writer's
	# own.
	@problems = built( 'en/other.html' =>
		    inside(qq{<hr>\n<p class="note">A note.</p>\n}) )->run;
	is( scalar @problems, 0, 'a rule and a class of the body pass' )
	    or diag join "\n", @problems;

	@problems = built( 'en/other.html' => swap( qr{</main>\n},
			qq{</main>\n<footer>\n<hr>\n<p class="note">ISC.</p>\n</footer>\n} ) )
	    ->run;
	is( scalar @problems, 0, 'and so do those of the footer' )
	    or diag join "\n", @problems;
};

subtest 'each link of the chrome resolves from its page' => sub {
	# WEB-LINKS-3. The check reads the target of each link, and not
	# its form.
	my @problems = built( 'en/other.html' => sub ($html) {
			$html =~ s{href="index\.html"}{href="../en/index.html"}g;
			return $html;
		}
	)->run;
	is( scalar @problems, 0, 'a link that steps out and back passes' )
	    or diag join "\n", @problems;

	# A link of the chrome can carry the marks of WEB-LANGUAGE-11
	# after its href.
	@problems = built( 'en/other.html' =>
		    swap( qr{<a href="index\.html">Example}, '<a href="index.html" lang="de">Example' ) )
	    ->run;
	is( scalar @problems, 0, 'a site link with marks gives no problem' )
	    or diag join "\n", @problems;

	# The top-level 404.html with the links of a tree page. Each
	# one names a page of the top level.
	@problems = built( '404.html' => sub ($html) {
			$html =~ s{href="en/index\.html"}{href="index.html"}g;
			return $html;
		}
	)->run;
	is_deeply(
		\@problems,
		[
			'404.html: the header does not link en/index.html',
			'404.html: does not carry the navigation entry'
			    . ' index.html'
		],
		'the top-level 404.html links the default tree from the top level'
	);

	# WEB-CHROME-2. A site link that steps out of the tree names the
	# forward page, and not the entry page of the tree.
	@problems = built( 'en/other.html' =>
		    swap( qr{<a href="index\.html">Example}, '<a href="../index.html">Example' ) )
	    ->run;
	is_deeply( \@problems, ['en/other.html: the header does not link en/index.html'],
		'a tree page whose site link leaves the tree' );
};

subtest 'a nav href names a page of the tree' => sub {
	# WEB-LINKS-2. The top-level 404.html is a file of the site, and
	# no page of the tree.
	my $rc = $RC . qq{\nnav "../404.html" {\n\tlabel = Lost\n}\n};
	my @problems = built_rc($rc)->run;
	is_deeply( \@problems,
		['nav "../404.html": names no page of the tree en'],
		'a nav href that leaves the tree' );

	$rc = $RC . qq{\nnav "./other.html" {\n\tlabel = Other\n}\n};
	@problems = built_rc($rc)->run;
	is( scalar @problems, 0, 'a nav href with its ./ names the page' )
	    or diag join "\n", @problems;

	# Each tree resolves the href from its own path. An href that
	# steps into the tree of en names a page of en alone.
	$rc = $THREE . qq{\nnav "../en/index.html" {\n\tlabel = English\n}\n};
	@problems = built_rc($rc)->run;
	is_deeply(
		\@problems,
		[
			'nav "../en/index.html": names no page of the tree ar',
			'nav "../en/index.html": names no page of the tree'
			    . ' zh-hans'
		],
		'a nav href that names a page of one tree'
	);

	# WEB-LINKS-3. A query is no part of the name of a file. The check
	# of the nav, the check of the references and the walk read the
	# href alike.
	$rc = $RC . qq{\nnav "other.html?q=1" {\n\tlabel = Query\n}\n};
	@problems = built_rc($rc)->run;
	is( scalar @problems, 0, 'a nav href with a query names the page' )
	    or diag join "\n", @problems;

	# WEB-CHROME-4. The href names en/other.html, so its link on that
	# page is the current one.
	@problems = built_rc( $rc,
		'en/other.html' => swap( qr{ aria-current="page">Query}, '>Query' ) )
	    ->run;
	is_deeply(
		\@problems,
		[
			'en/other.html: the navigation entry other.html?q=1'
			    . ' does not carry aria-current="page"'
		],
		'and its link on that page is the current one'
	);

	@problems = built_rc( $rc,
		'en/index.html' => swap( qr{<p><a href="\./other\.html">Other</a></p>\n<p><a href="\./other\.html#here">The anchor</a></p>\n}, '' ) )
	    ->run;
	is( scalar @problems, 0, 'and the walk reaches the page through it' )
	    or diag join "\n", @problems;
};

subtest 'the base href is the one root-absolute href' => sub {
	# WEB-LINKS-4. The top-level 404.html carries the base, and no
	# other page and no other href may be rooted.
	my @problems =
	    built( '404.html' => swap( qr{<base href="/">\n}, '' ) )->run;
	is_deeply(
		\@problems,
		[
			'404.html: the head holds charset, viewport, title,'
			    . ' stylesheet, and the page takes charset, viewport,'
			    . ' base, title, stylesheet',
			'404.html: does not carry <base href="/">'
		],
		'the top-level 404.html needs its base'
	);

	# WEB-TOP-3. The base comes before each element that holds a URL.
	@problems = built( '404.html' => sub ($html) {
			$html =~ s{(<base href="/">\n)(<title>[^\n]*\n)}{$2$1}
			    or die 'the page holds no base';
			return $html;
		}
	)->run;
	is_deeply(
		\@problems,
		[
			'404.html: the head holds charset, viewport, title, base,'
			    . ' stylesheet, and the page takes charset, viewport,'
			    . ' base, title, stylesheet'
		],
		'and its base comes before the title'
	);

	@problems =
	    built( lost(qq{<a href="/en/index.html">Rooted</a>\n}) )->run;
	is_deeply(
		\@problems,
		[
			'en/404.html: /en/index.html is root-absolute',
			'404.html: /en/index.html is root-absolute'
		],
		'a second root-absolute href of the top-level 404.html fails'
	);

	@problems = built( 'en/other.html' =>
		    swap( qr{<title>}, qq{<base href="/">\n<title>} ) )->run;
	is_deeply( \@problems, ['en/other.html: / is root-absolute'],
		'and a base on a tree page fails' );

	# The base is the path of the url, which need not be the root
	# of the host.
	my $sub = $RC =~ s{https://example\.org/\n}{https://example.org/sub/\n}r;
	@problems = built_rc($sub)->run;
	is( scalar @problems, 0, 'a site below a path of its host passes' )
	    or diag join "\n", @problems;

	@problems = built_rc( $sub,
		'404.html' => swap( qr{<base href="/sub/">}, '<base href="/">' ) )
	    ->run;
	is_deeply(
		\@problems,
		[
			'404.html: does not carry <base href="/sub/">',
			'404.html: / is root-absolute'
		],
		'and the base of the host root fails there'
	);

	# WEB-LINKS-3. A reference of the top-level 404.html resolves
	# from its base. A link of a body names its file from the site
	# root there, per WEB-TOP-6, and a fragment alone names the base,
	# which is no page.
	@problems =
	    built( lost(qq{<a href="other.html#here">Other</a>\n}) )->run;
	is( scalar @problems, 0, 'a link from the site root passes' )
	    or diag join "\n", @problems;

	@problems = built( '404.html' =>
		    swap( qr{</section>}, qq{<a href="#top">Top</a>\n</section>} ) )
	    ->run;
	is_deeply(
		\@problems,
		[
			'404.html: the section for en/404.html does not hold its'
			    . ' body',
			'404.html: #top names no page of the site'
		],
		'and a fragment alone fails'
	);
};

subtest 'the top-level 404.html holds the body of each language' => sub {
	# WEB-TOP-4. A page of the default language, with the title of
	# the 404.html of the default tree.
	my @problems = built_rc( $THREE,
		'404.html' => swap( qr{<title>Not found}, '<title>Lost' ) )->run;
	is_deeply( \@problems,
		['404.html: does not carry the title of en/404.html'],
		'a top-level 404.html of another title' );

	@problems = built_rc( $THREE,
		'404.html' => swap( qr{<html lang="en">}, '<html lang="zh-Hans">' ) )
	    ->run;
	is_deeply( \@problems, ['404.html: does not carry <html lang="en">'],
		'and one of another language' );

	# WEB-TOP-5 and WEB-LANGUAGE-11. One section for each language,
	# in the order of the declaration. Each one carries the marks of
	# the language of its text: zh-Hans has a body of its own, and ar
	# takes the body of en. The main carries none.
	@problems = built_rc( $THREE,
		'404.html' => swap( qr{<section lang="zh-Hans">}, '<section>' ) )
	    ->run;
	is_deeply(
		\@problems,
		[
			'404.html: the section for zh-hans/404.html does not'
			    . ' open as <section lang="zh-Hans">'
		],
		'a section of zh-Hans with no marks'
	);

	@problems = built_rc( $THREE,
		'404.html' => swap( qr{<main>}, '<main lang="en">' ) )->run;
	is_deeply( \@problems, ['404.html: does not carry <main>'],
		'and a main with marks' );

	@problems = built_rc( $THREE, '404.html' => sub ($html) {
			$html =~ s{(<section>\n.*?</section>\n)(<section lang="zh-Hans">\n.*?</section>\n)}{$2$1}s
			    or die 'the page holds no section of zh-Hans';
			return $html;
		}
	)->run;
	is_deeply(
		\@problems,
		[
			'404.html: the section for en/404.html does not open as'
			    . ' <section>',
			'404.html: the section for en/404.html does not hold its'
			    . ' body'
		],
		'and two sections out of the order of the declaration'
	);

	@problems = built_rc( $THREE, '404.html' => sub ($html) {
			$html =~ s{<section>\n[^<]*<h1>Not found</h1>\n</section>\n(</main>)}{$1}
			    or die 'the page holds no section of ar';
			return $html;
		}
	)->run;
	is_deeply( \@problems, ['404.html: holds no section for ar/404.html'],
		'and no section of ar' );

	# A tree 404.html with no main gives no body to hold. The check
	# names that page, and holds the section of ar after it.
	@problems = built_rc(
		$THREE,
		'zh-hans/404.html' => sub ($html) {
			$html =~ s{<main\b[^>]*>(.*)</main>}{<div>$1</div>}s
			    or die 'the page holds no main';
			return $html;
		},
		'404.html' => sub ($html) {
			$html =~ s{<h1>Not found</h1>(\n</section>\n</main>)}{<h1>Lost</h1>$1}
			    or die 'the page holds no section of ar';
			return $html;
		}
	)->run;
	is_deeply(
		\@problems,
		[
			'zh-hans/404.html: the chrome carries a text separator',
			'404.html: zh-hans/404.html does not carry <main>',
			'404.html: the section for ar/404.html does not hold its'
			    . ' body',
			'zh-hans/404.html: holds 0 headings, and en/404.html holds 1'
		],
		'and a tree 404.html with no main'
	);

	@problems = built_rc( $THREE,
		'404.html' => swap( qr{</main>}, "<section>\n<p>More.</p>\n</section>\n</main>" ) )
	    ->run;
	is_deeply( \@problems,
		['404.html: the main holds more than one section for each language'],
		'and one more section' );

	# WEB-TOP-6. A body holds no id, and each relative link of it
	# names its file from the site root.
	@problems = built_rc( $THREE,
		'404.html' => swap( qr{<h1>Not found</h1>}, '<h1 id="gone">Not found</h1>' ) )
	    ->run;
	is_deeply( \@problems,
		['404.html: the section for en/404.html does not hold its body'],
		'a body that keeps its id' );

	@problems = built_rc( $THREE,
		'404.html' => swap( qr{<a href="zh-hans/index\.html">\xe9\xa6\x96}, "<a href=\"index.html\">\xe9\xa6\x96" ) )
	    ->run;
	is_deeply(
		\@problems,
		[
			'404.html: the section for zh-hans/404.html does not'
			    . ' hold its body'
		],
		'and a link that resolves from its tree and not from the root'
	);
};

subtest 'the forward takes one shape' => sub {
	# WEB-TOP-1. A page of the default language, whose head holds the
	# charset, a meta refresh, the title and the links of
	# WEB-CHROME-6, and that loads nothing.
	my @problems = built( 'index.html' =>
		    swap( qr{<meta http-equiv="refresh"[^\n]*\n}, '' ) )->run;
	is_deeply(
		\@problems,
		[
			'index.html: the head holds charset, title, links, and'
			    . ' the page takes charset, refresh, title, links',
			'index.html: does not forward to en/index.html'
		],
		'a forward with no refresh'
	);

	@problems = built( 'index.html' => swap( qr{</head>},
			qq{<link rel="stylesheet" href="style.css">\n</head>} ) )->run;
	is_deeply(
		\@problems,
		[
			'index.html: the head holds charset, refresh, title,'
			    . ' links, stylesheet, and the page takes charset,'
			    . ' refresh, title, links'
		],
		'a forward that loads a stylesheet'
	);

	@problems = built( 'index.html' =>
		    swap( qr{<title>Example</title>}, '<title>Home</title>' ) )->run;
	is_deeply( \@problems, ['index.html: the title is not the site name of en'],
		'a forward of another title' );

	@problems = built(
		'index.html' => swap( qr{<html lang="en">}, '<html lang="de">' ) )
	    ->run;
	is_deeply( \@problems, ['index.html: does not carry <html lang="en">'],
		'and one of another language' );

	# WEB-TOP-2. The canonical link is the bare url.
	@problems = built( 'index.html' => swap( qr{<link rel="canonical" href="https://example\.org/">},
			'<link rel="canonical" href="https://example.org/en/index.html">' ) )
	    ->run;
	is_deeply(
		\@problems,
		[
			'index.html: the head does not carry <link'
			    . ' rel="canonical" href="https://example.org/">'
		],
		'a forward whose canonical link is no bare url'
	);

	# A site of one language: one link to the entry page, with the
	# site name as its text, and no other reference.
	@problems =
	    built( 'index.html' => swap( qr{>Example</a>}, '>Home</a>' ) )->run;
	is_deeply( \@problems,
		['index.html: does not link en/index.html with the site name'],
		'a forward link with another text' );

	@problems = built( 'index.html' =>
		    swap( qr{</p>}, qq{</p>\n<img src="robots.txt" alt="">} ) )->run;
	is_deeply( \@problems,
		['index.html: the body holds 2 references, and the forward takes 1'],
		'a forward that loads an image' );

	@problems = built( 'index.html' =>
		    swap( qr{<body>\n}, "<body>\n<nav>\n</nav>\n" ) )->run;
	is_deeply(
		\@problems,
		['index.html: carries a nav, and the forward takes none'],
		'a forward with a nav'
	);

	# A site of more than one language: the list of the languages,
	# with a link to the entry page of each one, and no current link.
	@problems = built_rc( $THREE,
		'index.html' => swap( qr{<li><a href="ar/index\.html"[^\n]*\n}, '' ) )
	    ->run;
	is_deeply(
		\@problems,
		[
			'index.html: carries 2 language links, and the page'
			    . ' takes 3',
			'index.html: does not link the entry page in ar',
			'index.html: the body holds 2 references, and the'
			    . ' forward takes 3'
		],
		'a forward with no item of ar'
	);

	@problems = built_rc( $THREE,
		'index.html' => swap( qr{lang="en">English}, 'lang="en" aria-current="page">English' ) )
	    ->run;
	is_deeply( \@problems,
		['index.html: the link to en carries aria-current="page"'],
		'and one with a current link' );

	@problems = built_rc( $THREE,
		'index.html' => swap( qr{hreflang="zh-Hans" href="https://example\.org/zh-hans/index\.html"},
			'hreflang="zh-Hans" href="https://example.org/zh-hans/404.html"' ) )
	    ->run;
	is_deeply(
		\@problems,
		[
			'index.html: the head does not carry <link'
			    . ' rel="alternate" hreflang="zh-Hans"'
			    . ' href="https://example.org/zh-hans/index.html">'
		],
		'and one whose alternate link of zh-Hans is no entry page'
	);
};

subtest 'the text of a value is no attribute' => sub {
	# The check reads each attribute through the one reader of
	# App::FuguWeb. An href= or a src= in the text of another value
	# is no reference, and a data-href is no href.
	my @problems = built( 'en/other.html' => inside(<<'HTML') )->run;
<a title="see href=gone.html" href="./index.html">Home</a>
<a title='see href="gone.html"' href="./index.html">Home</a>
<a data-href="gone.html" href="./index.html">Home</a>
HTML
	is( scalar @problems, 0, 'a reference of the text of a value' )
	    or diag join "\n", @problems;

	# A data-id and an id= in the text of a value are no id.
	@problems = built( 'en/other.html' => inside(<<'HTML') )->run;
<p data-id="there">There</p>
<p title='see id="there"'>There</p>
<a href="#there">There</a>
HTML
	is_deeply( \@problems, ['en/other.html: #there has no such anchor'],
		'a data-id is no anchor' );

	# The walk reads the same references.
	@problems = built( 'en/index.html' => swap(
			qr{<p><a href="\./other\.html">Other</a></p>\n<p><a href="\./other\.html#here">The anchor</a></p>\n},
			qq{<p data-href="./other.html">Other</p>\n} ) )
	    ->run;
	is_deeply( \@problems, ['en/other.html: no page links to it'],
		'a data-href reaches no page' );

	# The forward holds one reference.
	@problems = built( 'index.html' => swap( qr{<a href="en/index\.html">},
			q{<a title='see src="style.css"' href="en/index.html">} ) )
	    ->run;
	is( scalar @problems, 0, 'a src of the text of a value loads nothing' )
	    or diag join "\n", @problems;

	# A link of the chrome and the chrome itself.
	@problems = built( 'en/other.html' => swap( qr{<a href="index\.html">Example},
			q{<a href="index.html" title='aria-current="page"'>Example} ) )
	    ->run;
	is( scalar @problems, 0, 'an aria-current of the text of a value' )
	    or diag join "\n", @problems;

	@problems = built( 'en/other.html' =>
		    swap( qr{<header>}, q{<header title='see class="banner"'>} ) )
	    ->run;
	is( scalar @problems, 0, 'and a class of the text of a value' )
	    or diag join "\n", @problems;

	# HTML separates two attributes with ASCII white space alone. The
	# last byte of U+00E0 is 0xA0, which is no end of a value.
	@problems = built( 'en/other.html' => inside(
			qq{<p id="voil\xc3\xa0">V</p>\n<a href=#voil\xc3\xa0>V</a>\n}) )
	    ->run;
	is( scalar @problems, 0, 'a value with no quotes reads to its end' )
	    or diag join "\n", @problems;
};

subtest 'a link that leads nowhere, or to no such anchor' => sub {
	my @problems =
	    built( 'en/other.html' => inside(qq{<a href="./gone.html">Gone</a>\n}) )
	    ->run;
	like( join( "\n", @problems ),
		qr{en/other\.html: \./gone\.html leads nowhere}, 'a dead link' );

	@problems = built( 'en/other.html' =>
		    inside(qq{<a href="./index.html#absent">Absent</a>\n}) )->run;
	like( join( "\n", @problems ),
		qr{en/other\.html: \./index\.html#absent has no such anchor},
		'a dead fragment' );

	# WEB-LINKS-3. The target is a file of the inventory. A
	# directory is no file, and a stray file is no file of the site.
	@problems =
	    built( 'en/other.html' => inside(qq{<a href="../en">Tree</a>\n}) )
	    ->run;
	is_deeply( \@problems, ['en/other.html: ../en leads nowhere'],
		'a link to a directory' );

	@problems = built(
		'stray.html'    => "<p>Stray</p>\n",
		'en/other.html' => inside(qq{<a href="../stray.html">Stray</a>\n})
	)->run;
	is_deeply(
		[ sort @problems ],
		[
			'en/other.html: ../stray.html leads nowhere',
			'stray.html: in the output but not in the site'
		],
		'and a link to a stray file'
	);
};

subtest 'each heading of a translation takes the id of en' => sub {
	# WEB-OUTLINE-3. The check compares each heading id of a page of
	# zh-Hans and of ar with the id of the heading at the same
	# position of the page of en.
	my @problems = built_rc(
		$THREE,
		'zh-hans/other.html' => swap( qr{<h2 id="here">}, '<h2 id="ici">' ),
		'ar/other.html'      => swap( qr{<h2 id="here">}, '<h2>' ),
		'ar/index.html'      => swap( qr{<h1>}, '<h1 id="home">' ),
	)->run;
	is_deeply(
		[ sort grep { /heading/ } @problems ],
		[
			'ar/index.html: heading 1 takes the id "home", and'
			    . ' en/index.html takes no id',
			'ar/other.html: heading 1 takes no id, and en/other.html'
			    . ' takes the id "here"',
			'zh-hans/other.html: heading 1 takes the id "ici", and'
			    . ' en/other.html takes the id "here"',
		],
		'a heading id that differs from en, or that one side lacks'
	);

	@problems = built_rc( $THREE,
		'zh-hans/other.html' => inside(qq{<h2 id="more">More</h2>\n}) )
	    ->run;
	is_deeply(
		\@problems,
		[
			'zh-hans/other.html: holds 2 headings, and en/other.html'
			    . ' holds 1'
		],
		'and a page that holds another count of headings'
	);

	# A heading outside the main element is no part of the outline.
	@problems = built_rc( $THREE,
		'zh-hans/other.html' => swap( qr{</header>}, "<h2>Banner</h2>\n</header>" ) )
	    ->run;
	is_deeply( [ grep { /heading/ } @problems ], [],
		'a heading outside the main element is no part of the outline' );
};

subtest 'a reference that leaves the site' => sub {
	my @problems = built( 'en/other.html' => inside(<<'HTML') )->run;
<a href="/index.html">Rooted</a>
<a href="file:///etc/passwd">Local</a>
HTML
	my $joined = join "\n", @problems;

	# The host may serve the site from a path below the root, where
	# a leading slash leaves the site entirely.
	like( $joined, qr{en/other\.html: /index\.html is root-absolute},
		'a root-absolute reference' );
	like( $joined, qr{is a file: URL}, 'a file: URL' );

	# The head alone holds the links of WEB-CHROME-6. A link element
	# of the body takes the check of each reference.
	@problems = built( 'en/other.html' => inside(<<'HTML') )->run;
<link rel="canonical" href="/en/other.html">
<link rel="alternate" hreflang="de" href="../de/other.html">
HTML
	is_deeply(
		\@problems,
		[
			'en/other.html: /en/other.html is root-absolute',
			'en/other.html: ../de/other.html leads nowhere'
		],
		'a link element of the body'
	);
};

subtest 'a local link that reads as a URL scheme' => sub {
	my @problems = built( 'en/other.html' =>
		    inside(qq{<a href="Thing::Depot.3p.html">A module</a>\n}) )
	    ->run;

	# A browser reads a relative URL whose first segment holds a
	# colon as a scheme, so the link above asks for thing:.
	like(
		join( "\n", @problems ),
		qr{Thing::Depot\.3p\.html reads as a URL scheme},
		'the missing ./ is named'
	);
};

subtest 'a cross-reference that dangles' => sub {
	# A local .Xr link is a reference like any other, and the
	# reference check catches it.
	my @problems = built( 'en/other.html' =>
		    inside(qq{<a class="Xr" href="./gone.1.html">gone(1)</a>\n}) )
	    ->run;
	like( join( "\n", @problems ),
		qr{en/other\.html: \./gone\.1\.html leads nowhere},
		'a local .Xr that leads nowhere' );
};

subtest 'a page that nothing links to' => sub {
	# en/index.html no longer links to other.html. 404.html is
	# unlinked on purpose, so it must not be reported.
	my $alone = swap( qr{<p><a href="\./other\.html">Other</a></p>\n<p><a href="\./other\.html#here">The anchor</a></p>\n}, '' );
	my @problems = built( 'en/index.html' => $alone )->run;
	my $joined   = join "\n", @problems;

	like( $joined, qr{en/other\.html: no page links to it},
		'the unreachable page' );
	unlike( $joined, qr{404\.html: no page links to it},
		'a page marked unlinked is not reported' );

	# WEB-LANGUAGE-13. The walk starts at the entry page of the
	# tree, and never at a page of the top level. A link of the
	# top-level 404.html reaches no page of the tree, and neither
	# does a link of en/404.html, which no page links to.
	@problems = built(
		'en/index.html' => $alone,
		lost(qq{<a href="other.html">Other</a>\n}),
	)->run;
	is_deeply( \@problems, ['en/other.html: no page links to it'],
		'a link of the top level does not count' );

	# The walk stays inside the tree. A link out of the tree to the
	# top level reaches no page of the tree through it.
	@problems = built(
		'en/index.html' => sub ($html) {
			return inside(qq{<a href="../404.html">Out</a>\n})
			    ->( $alone->($html) );
		},
		lost(qq{<a href="other.html">Other</a>\n}),
	)->run;
	is_deeply( \@problems, ['en/other.html: no page links to it'],
		'and neither does a page of the top level on the way' );

	@problems = built( 'en/index.html' => undef )->run;
	like( join( "\n", @problems ), qr{en/index\.html: the entry page is missing},
		'the entry page of the tree is missing' );
};

subtest 'what is not a problem stays not a problem' => sub {
	# The two skip rules. Without a case that exercises each of
	# them, a check that lost one would report a false positive and
	# only the real site would notice.
	my @problems = built( 'en/other.html' => inside(<<'HTML') )->run;
<a href="mailto:hi@example.org">Mail</a>
<a class="Xr" href="https://man.openbsd.org/rc.8">rc(8)</a>
HTML
	my $joined = join "\n", @problems;

	is( scalar @problems, 0, 'no problem' ) or diag $joined;
	unlike( $joined, qr/mailto/,
		'a mailto: link is not a dead local link' );
	unlike( $joined, qr/man\.openbsd\.org/,
		'a cross-reference that left for the host does not dangle' );
};

subtest 'a stray file in the output' => sub {
	my @problems = built( 'index.html~' => "an editor backup\n" )->run;
	like( join( "\n", @problems ),
		qr{index\.html~: in the output but not in the site},
		'the stray file is named' );

	# A page at the top level that the site does not name.
	@problems = built( 'other.html' => "<p>Other</p>\n" )->run;
	is_deeply( \@problems, ['other.html: in the output but not in the site'],
		'a page at the top level is named' );

	# WEB-OUTPUT-4. The tree of a language that the description
	# does not declare is no tree of the site.
	@problems = built( 'de/index.html' => "<p>Start</p>\n" )->run;
	is_deeply( \@problems, ['de/index.html: in the output but not in the site'],
		'a tree of no declared language is named' );
};

done_testing();
