#!/usr/bin/perl
use warnings;
use strict;

use Test::More;
use XML::LibXML;
use Carp::Assert qw( assert );
use Path::Class qw( file );
use Daizu;
use Daizu::Test qw( init_tests );
use Daizu::Util qw( db_select );

init_tests(50);

my $cms = Daizu->new($Daizu::Test::TEST_CONFIG);

# XHTMLArticle
{
    my $plugin_info = $cms->{article_loaders}{'text/html'}{''}[0];
    assert(defined $plugin_info);
    my ($plugin_object, $plugin_method) = @$plugin_info;
    is(ref $plugin_object, 'Daizu::Plugin::XHTMLArticle',
       'XHTMLArticle: plugin object of right class');
    my $file = MockFile->new;
    my $article = $plugin_object->$plugin_method($cms, $file);
    ok(defined $article, 'XHTMLArticle: article info');

    is(scalar(keys %$article), 1, 'XHTMLArticle: no metadata');
    my $doc = $article->{content};
    ok(defined $doc, 'XHTMLArticle: content');
    isa_ok($doc, 'XML::LibXML::Document', 'XHTMLArticle: content');

    my $root = $doc->documentElement;
    is($root->nodeName, 'body', 'XHTMLArticle: right root elem');

    my (@child_elems) = map {
        $_->nodeType == XML_ELEMENT_NODE ? ($_) : ()
    } $root->getChildNodes();
    is(scalar(@child_elems), 5,
       'XHTMLArticle: right number of child elems');
    is($child_elems[0]->localname, 'p', 'XHTMLArticle: elem 0 is p');
    is($child_elems[0]->namespaceURI, 'http://www.w3.org/1999/xhtml',
       'XHTMLArticle: elem 0 is XHTML');
    is($child_elems[1]->localname, 'fold',
       'XHTMLArticle: elem 1 is fold');
    is($child_elems[1]->namespaceURI,
       'http://www.daizucms.org/ns/html-extension/',
       'XHTMLArticle: elem 0 is Daizu extension');
    ok($child_elems[2]->findnodes("*[local-name() = 'include']"),
       'XHTMLArticle: XInclude not expanded yet');

    my $text = $child_elems[3]->textContent;
    is($text, "More\x{2026}", 'XHTMLArticle: char entity refs expanded');

    $text = $child_elems[4]->textContent;
    my $expected = "UTF-8 characters: (\xA0) (\x{2026})";
    assert(utf8::is_utf8($expected));
    is($text, $expected, 'XHTMLArticle: UTF-8 chars preserved');
}


# PictureArticle
{
    my $plugin_info = $cms->{article_loaders}{'image/*'}{''}[0];
    assert(defined $plugin_info);
    my ($plugin_object, $plugin_method) = @$plugin_info;
    is(ref $plugin_object, 'Daizu::Plugin::PictureArticle',
       'PictureArticle: plugin object of right class');
    my $file = $cms->live_wc->file_at_path('foo.com/blog/2005/photos/wasp-on-holly-leaf.jpg');
    assert(defined $file);
    my $article = $plugin_object->$plugin_method($cms, $file);
    ok(defined $article, 'PictureArticle: article info');

    is(scalar(keys %$article), 3, 'PictureArticle: no metadata');
    my $doc = $article->{content};
    ok(defined $doc, 'PictureArticle: content');
    isa_ok($doc, 'XML::LibXML::Document', 'PictureArticle: content');

    my $root = $doc->documentElement;
    is($root->nodeName, 'body', 'PictureArticle: right root elem');
    is($root->namespaceURI, 'http://www.w3.org/1999/xhtml',
       'PictureArticle: body is XHTML');

    # Content of the <body> element.
    my (@elems) = map {
        $_->nodeType == XML_ELEMENT_NODE ? ($_) : ()
    } $root->getChildNodes();
    is(scalar(@elems), 1,
       'PictureArticle: body has right number of child elems');
    is($elems[0]->localname, 'div', 'PictureArticle: elem is div');
    is($elems[0]->getAttribute('class'), 'display-picture',
       'PictureArticle: div has right class');

    # Content of the <div> element.
    @elems = $elems[0]->getChildNodes();
    is(scalar(@elems), 2, 'PictureArticle: div has right number of children');
    is($elems[0]->nodeType, XML_ELEMENT_NODE,
       'PictureArticle: <a>, right type');
    is($elems[0]->localname, 'a', 'PictureArticle: <a>, right name');
    is($elems[0]->getAttribute('href'), 'wasp-on-holly-leaf.jpg',
       'PictureArticle: <a>, right href');
    is($elems[1]->nodeType, XML_TEXT_NODE,
       'PictureArticle: non-linked text, right type');
    is($elems[1]->textContent, " (1024\xD71024, 170Kb)",
       'PictureArticle: non-linked text, right text');

    # Content of the <a> element.
    @elems = $elems[0]->getChildNodes();
    is($elems[0]->localname, 'img', 'PictureArticle: <img>, right name');
    is($elems[0]->getAttribute('width'), 300, 'PictureArticle: <img>, width');
    is($elems[0]->getAttribute('height'), 300, 'PictureArticle: <img>, height');
    is($elems[0]->getAttribute('src'), 'wasp-on-holly-leaf-thm.jpg',
       'PictureArticle: <img>, src');
    is($elems[0]->getAttribute('alt'), "Wasp \x{2018}photo\x{2019}",
       'PictureArticle: <img>, alt');
    is($elems[1]->localname, 'br', 'PictureArticle: <br>, right name');
    is($elems[2]->nodeType, XML_TEXT_NODE,
       'PictureArticle: linked text, right type');
    is($elems[2]->textContent, 'Full size image',
       'PictureArticle: linked text, right text');

    # URL adjustments made by the plugin.
    is($article->{pages_url}, '', 'PictureArticle: pages_url');
    assert(defined $article->{extra_urls});
    my @extra_urls = @{$article->{extra_urls}};
    is(scalar(@extra_urls), 2, 'PictureArticle: extra_urls, right num');

    is($extra_urls[0]{url}, 'wasp-on-holly-leaf.jpg',
       'PictureArticle: orig pic URL, url');
    is($extra_urls[0]{type}, 'image/jpeg',
       'PictureArticle: orig pic URL, type');
    is($extra_urls[0]{generator}, 'Daizu::Gen',
       'PictureArticle: orig pic URL, generator');
    is($extra_urls[0]{method}, 'unprocessed',
       'PictureArticle: orig pic URL, method');

    is($extra_urls[1]{url}, 'wasp-on-holly-leaf-thm.jpg',
       'PictureArticle: thumb pic URL, url');
    is($extra_urls[1]{type}, 'image/jpeg',
       'PictureArticle: thumb pic URL, type');
    is($extra_urls[1]{generator}, 'Daizu::Gen',
       'PictureArticle: thumb pic URL, generator');
    is($extra_urls[1]{method}, 'scaled_image',
       'PictureArticle: thumb pic URL, method');
    is($extra_urls[1]{argument}, '300 300',
       'PictureArticle: thumb pic URL, argument');
}


# Check that article content is properly saved.
{
    my $got = db_select($cms->db, 'wc_file',
        { wc_id => 1, path => 'foo.com/_index.html' },
        'article_content',
    );
    assert(defined $got);
    my $expected = read_file('expected.xml');
    is("$got\n", $expected, 'loaded article_content saved correctly');
}


sub test_filename { file(qw( t data 21articleloader ), @_) }

# TODO perhaps some stuff like this should be moved to Daizu::Test
sub read_file
{
    my ($test_file) = @_;
    open my $fh, '<', test_filename($test_file)
        or die "error: $!";
    binmode $fh
        or die "error reading file '$test_file' in binary mode: $!";
    local $/;
    return <$fh>;
}


package MockFile;

use Carp::Assert qw( assert );
use Encode qw( encode );

sub new
{
    return bless { path => 'test/file' }, 'MockFile';
}

sub data
{
    my $text = qq[
        <p>Paragraph.</p>
        <daizu:fold/>
        <blockquote><xi:include href="inc.txt" parse="text"/></blockquote>
        <p>More&hellip;</p>
        <p>UTF-8 characters: (\xA0) (\x{2026})</p>
    ];
    $text = encode('UTF-8', $text, Encode::FB_CROAK);
    assert(!utf8::is_utf8($text));
    return \$text;
}

# vi:ts=4 sw=4 expandtab filetype=perl
