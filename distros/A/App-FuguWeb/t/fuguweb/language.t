#!/usr/bin/env perl
# ex:ts=8 sw=4:
# App::FuguWeb::Language: the tag rule, the tree path, the direction,
# the attributes of the html element, and the marks of a part of
# another language.
#
# The test needs no description: App::FuguWeb::Config makes each
# language, and t/fuguweb/config.t holds the blocks that it reads.

use v5.36;
use Test::More;
use FindBin qw($RealBin);
use lib "$RealBin/../../lib";

use_ok('App::FuguWeb::Language');

subtest 'a tag is a BCP 47 tag in its canonical case' => sub {
	# WEB-LANGUAGE-1. A language subtag, an optional script subtag
	# and an optional region subtag, in this order, and no other.
	ok( App::FuguWeb::Language::is_tag($_), "$_ is a tag" )
	    for qw(en fil zh-Hans pt-BR es-419 sr-Latn-RS zh-Hant-TW);

	ok( !App::FuguWeb::Language::is_tag($_), "$_ is no tag" )
	    for (
		'EN',       'zh-hans',  'zh-HANS', 'pt-br',
		'e',        'engl',     'en_US',   'en-',
		'-en',      'en-US-x',  'de-1996', 'en-Latn-US-variant',
		'i-klingon', 'x-private', 'en-12',  "en\n",
		'',         "\x{e9}n"
	    );
	ok( !App::FuguWeb::Language::is_tag(undef), 'undef is no tag' );
};

subtest 'a language holds its values' => sub {
	my $language = App::FuguWeb::Language->new(
		tag         => 'zh-Hans',
		name        => "\x{7b80}\x{4f53}\x{4e2d}\x{6587}",
		site        => "\x{793a}\x{4f8b}",
		footer      => 'zh-hans/footer.body.html',
		footer_lang => 'en',
	);

	is( $language->tag,  'zh-Hans', 'the tag' );
	is( $language->name, "\x{7b80}\x{4f53}\x{4e2d}\x{6587}", 'the name' );
	is( $language->dir,  'ltr', 'the direction is ltr by default' );

	# WEB-LANGUAGE-5. The path of the tree is the tag in lowercase.
	is( $language->path, 'zh-hans', 'the tree path' );

	is( $language->site,        "\x{793a}\x{4f8b}", 'the site name' );
	is( $language->site_lang,   'zh-Hans', 'of its own language' );
	is( $language->footer,      'zh-hans/footer.body.html', 'the footer' );
	is( $language->footer_lang, 'en', 'of the language that gave it' );

	ok( !eval { App::FuguWeb::Language->new( tag => 'zh-hans' ) },
		'a tag of another case is a programming error' );
	like( $@, qr/not a language tag: zh-hans/, 'and names the tag' );

	ok( !eval { App::FuguWeb::Language->new( tag => 'ar', dir => 'up' ) },
		'and so is a direction of another word' );
	like( $@, qr/not a direction: up/, 'and names the word' );
};

subtest 'the html element carries the tag and the direction' => sub {
	# WEB-LANGUAGE-10. dir="rtl" goes with a language that is right
	# to left, and a language that is left to right takes none.
	is( App::FuguWeb::Language->new( tag => 'en' )->attributes,
		' lang="en"', 'a language of ltr' );
	is( App::FuguWeb::Language->new( tag => 'ar', dir => 'rtl' )->attributes,
		' lang="ar" dir="rtl"', 'a language of rtl' );
};

subtest 'a part of another language carries its marks' => sub {
	# WEB-LANGUAGE-11. The tag of the other language, and its
	# direction when the two directions differ.
	my $en = App::FuguWeb::Language->new( tag => 'en' );
	my $zh = App::FuguWeb::Language->new( tag => 'zh-Hans' );
	my $ar = App::FuguWeb::Language->new( tag => 'ar', dir => 'rtl' );
	my $he = App::FuguWeb::Language->new( tag => 'he', dir => 'rtl' );

	is( $en->marks($en), '', 'a part of the language of the page' );
	is( $zh->marks($en), ' lang="en"', 'a part of en on a page of zh-Hans' );
	is( $ar->marks($en), ' lang="en" dir="ltr"',
		'a part of en on a page of ar' );
	is( $en->marks($ar), ' lang="ar" dir="rtl"',
		'a part of ar on a page of en' );
	is( $he->marks($ar), ' lang="ar"',
		'two languages of rtl take the tag alone' );
};

done_testing();
