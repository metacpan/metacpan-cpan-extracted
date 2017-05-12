#!/usr/bin/perl
use warnings;
use strict;

use Test::More;
use Carp::Assert qw( assert );
use Encode qw( encode );
use Daizu;
use Daizu::Test qw( init_tests );
use Daizu::File;
use Daizu::Util qw( db_row_id db_select );
use Daizu::HTML qw( dom_body_to_html4 );

init_tests(95);

my $cms = Daizu->new($Daizu::Test::TEST_CONFIG);
my $db = $cms->db;
my $wc = $cms->live_wc;

my $file_id_1 = db_row_id($db, 'wc_file',
    wc_id => $wc->id,
    path => 'foo.com/blog/2006/fish-fingers/article-1.html',
);

# new
my $file_1 = Daizu::File->new($cms, $file_id_1);
isa_ok($file_1, 'Daizu::File');
is($file_1->{id}, $file_id_1, '$file_1->{id}');

my $file_2 = $wc->file_at_path('foo.com/blog/2006/fish-fingers/article-2.html');
assert($file_2);
my $file_3 = $wc->file_at_path('foo.com/blog/2006/parsnips/article-3.html');
assert($file_3);
my $file_5 = $wc->file_at_path('foo.com/blog/2006/strawberries/article-5/_index.html');
assert($file_5);

# data
{
    my $data = $file_1->data;
    is(ref $data, 'SCALAR', '$file_1->data returns scalar ref');
    like($$data, qr/\A<p>Blog article 1.*full-content ones.<\/p>\x0A\z/s,
         '$file_1->data returns correct text');
}

# wc
{
    my $got = $file_1->wc;
    isa_ok($got, 'Daizu::Wc');
    is($got->id, $wc->id, 'correct working copy');
}

# guid_uri
{
    my $guid_id = db_select($db, wc_file => $file_id_1, 'guid_id');
    my $guid_uri = db_select($db, file_guid => $guid_id, 'uri');
    is($file_1->guid_uri, $guid_uri, '$file_1->guid_uri');
}

# directory_path
is($file_1->directory_path, 'foo.com/blog/2006/fish-fingers',
   '$file_1->directory_path');
is($wc->file_at_path('top-level')->directory_path, '',
   '$top_level->directory_path');

# parent and directory_path
{
    my $parent_id = db_row_id($db, 'wc_file',
        wc_id => $wc->id,
        path => 'foo.com/blog/2006/fish-fingers',
    );
    my $parent = $file_1->parent;
    isa_ok($parent, 'Daizu::File', 'parent is right class');
    is($parent->{id}, $parent_id, '$parent->{id}');

    is($parent->directory_path, 'foo.com/blog/2006/fish-fingers',
       '$parent->directory_path');
}

# file_at_path
{
    my $file = $file_1->file_at_path('/example.com/fractal.png');
    is($file->{path}, 'example.com/fractal.png',
       'file_at_path: /example.com/fractal.png');

    $file = $file_1->file_at_path('/./example.com/./fractal.png');
    is($file->{path}, 'example.com/fractal.png',
       'file_at_path: /./example.com/./fractal.png');

    $file = $file_1->file_at_path('article-2.html');
    is($file->{path}, 'foo.com/blog/2006/fish-fingers/article-2.html',
       'file_at_path: article-2.html');

    $file = $file_1->file_at_path('../parsnips');
    is($file->{path}, 'foo.com/blog/2006/parsnips',
       'file_at_path: ../parsnips');

    $file = $file_1->file_at_path('../../2005/photos/wasp-on-holly-leaf.jpg');
    is($file->{path}, 'foo.com/blog/2005/photos/wasp-on-holly-leaf.jpg',
       'file_at_path: ../../2005/photos/wasp-on-holly-leaf.jpg');

    # Bad paths.
    for ('/.', '..', '/example.com/fractal.png/') {
        $@ = undef;
        eval { $file_1->file_at_path('/.') };
        like($@, qr/no file at/, "file_at_path: $_");
    }
}

# article_doc
{
    my $doc = $file_1->article_doc;
    isa_ok($doc, 'XML::LibXML::Document', 'article_doc: article 1');
    my $body = $doc->documentElement;
    is($body->localname, 'body', 'article_doc: correct root element');

    # There should be three paragraphs and a daizu:fold element, and the
    # only other nodes at the top level should be text (newlines).
    my $node = $body->firstChild;
    my $pos = 1;
    while (defined $node) {
        if ($pos == 1 || $pos == 3 || $pos == 7) {
            isa_ok($node, 'XML::LibXML::Element', "article_doc: $pos: element");
            is($node->localname, 'p', "article_doc: $pos: <p>");
            is($node->namespaceURI, 'http://www.w3.org/1999/xhtml',
               "article_doc: $pos: XHTML namespace");
        }
        elsif ($pos == 5) {
            isa_ok($node, 'XML::LibXML::Element', "article_doc: $pos: element");
            is($node->localname, 'fold', "article_doc: $pos: <fold>");
            is($node->namespaceURI, $Daizu::HTML_EXTENSION_NS,
               "article_doc: $pos: Daizu HTML extension namespace");
        }
        else {
            assert($pos <= 8);
            isa_ok($node, 'XML::LibXML::Text', "article_doc: $pos: text");
            like($node->textContent, qr/\A\n+\z/,
                 "article_doc: $pos: only newlines");
        }
        ++$pos;
        $node = $node->nextSibling;
    }

    # Check UTF-8 characters are preserved in the DOM.
    $doc = $file_2->article_doc;
    my (@para) = $doc->documentElement->getChildrenByTagName('p');
    is(scalar @para, 6, 'article_doc: article 2, right number of paragraphs');
    my $text = $para[2]->textContent;
    is($text, "It also has some UTF-8 stuff:\x{A0}\x{201C}\x{2014}\x{201D}",
       'article_doc: article 2, UTF-8 characters preserved');

    # Make sure the filtering has been done for the <daizu:syntax-highlight/>
    # element.  It should have been replaced by a <pre> element.
    $doc = $file_5->article_doc;
    my (@pre) = $doc->documentElement->getChildrenByTagName('pre');
    is(scalar @pre, 1, 'article_doc: article 5, syntax highlighting done');
    is($pre[0]->namespaceURI, 'http://www.w3.org/1999/xhtml',
       'article_doc: article 5, new <pre> element in XHTML namespace');
    $text = $pre[0]->textContent;
    like($text, qr/syntax coloured external file/,
       'article_doc: article 5, highlighting on text from XIncluded file');
}

# article_body
{
    my $body = $file_1->article_body;
    isa_ok($body, 'XML::LibXML::Element', 'article_body: is element');
    is($body->localname, 'body', 'article_body: is <body>');
    is($body->namespaceURI, 'http://www.w3.org/1999/xhtml',
       'article_body: XHTML namespace');
}

# article_content_html4
{
    is($file_2->article_content_html4,
       "<p>Blog article 2</p>\n\n" .
       "<p>This one has three pages but no fold mark, so the first" .
       " page break\012should be treated like a fold.</p>\n\n" .
       enc("<!-- Unicode text: \x{8A9E} -->\n" .
           "<p title=\"Some \x{2018}UTF-8\x{2019} text\">" .
           "It also has some UTF-8 stuff:" .
           "\x{A0}\x{201C}\x{2014}\x{201D}</p>\n\n") .
       "\n\n" .
       "<p>Content on page 2.</p>\n\n" .
       "\n\n" .
       "<p>Content on page 3.</p>\n\n" .
       "<p>This is the end of the article.</p>\n",
       'article_content_html4: whole article');

    is($file_2->article_content_html4(1),
       "<p>Blog article 2</p>\n\n" .
       "<p>This one has three pages but no fold mark, so the first" .
       " page break\012should be treated like a fold.</p>\n\n" .
       enc("<!-- Unicode text: \x{8A9E} -->\n" .
           "<p title=\"Some \x{2018}UTF-8\x{2019} text\">" .
           "It also has some UTF-8 stuff:" .
           "\x{A0}\x{201C}\x{2014}\x{201D}</p>\n\n"),
       'article_content_html4: page 1');

    is($file_2->article_content_html4(2),
       "\n\n<p>Content on page 2.</p>\n\n",
       'article_content_html4: page 2');

    is($file_2->article_content_html4(3),
       "\n\n<p>Content on page 3.</p>\n\n" .
       "<p>This is the end of the article.</p>\n",
       'article_content_html4: page 3');
}

# article_extract
is($file_1->article_extract,
   "Blog article 1\n\nThis one has a fold after the first two" .
   " paragraphs.\n\nThis text should only appear in the full article" .
   " page, not on index pages, and not in feeds except for full-content ones.",
   'article_extract: short article');
# Test a longer article, which should exceed the word limit.
is($file_3->article_extract,
   "Blog article\x{A0}3\n\nThis blog article is no more interesting" .
   " than the other test articles, except for the fact that it has" .
   " more text. In fact, there is more text in this article than" .
   " will fit into the default size of an article extract used" .
   " sometimes in blog feeds. This will \x{2026}",
   'article_extract: longer article');

# article_snippet
{
    # article with a <daizu:fold/> element
    my $snippet = $file_1->article_snippet;
    isa_ok($snippet, 'XML::LibXML::Document', 'article_snippet: article 1');
    is($snippet->documentElement->localname, 'body',
       'article_snippet: article 1, correct root element');
    my $html = dom_body_to_html4($snippet);
    is($html,
       "<p>Blog article 1</p>\n\n" .
       "<p>This one has a fold after the first two paragraphs.</p>\n\n",
       'article_snippet: article 1, cut before fold');

    # article with a <daizu:page/> element but no fold
    $snippet = $file_2->article_snippet;
    isa_ok($snippet, 'XML::LibXML::Document', 'article_snippet: article 2');
    is($snippet->documentElement->localname, 'body',
       'article_snippet: article 2, correct root element');
    $html = dom_body_to_html4($snippet);
    is($html,
       "<p>Blog article 2</p>\n\n" .
       "<p>This one has three pages but no fold mark, so the first" .
       " page break\012should be treated like a fold.</p>\n\n" .
       enc("<!-- Unicode text: \x{8A9E} -->\n" .
           "<p title=\"Some \x{2018}UTF-8\x{2019} text\">" .
           "It also has some UTF-8 stuff:" .
           "\x{A0}\x{201C}\x{2014}\x{201D}</p>\n\n"),
       'article_snippet: article 2, cut before page break');
}

# generator
{
    my $blog_dir = $wc->file_at_path('foo.com/blog');
    my $gen = $file_1->generator;
    isa_ok($gen, 'Daizu::Gen::Blog', 'generator: blog article');
    isa_ok($gen->{cms}, 'Daizu', 'generator: blog article, cms object');
    is($gen->{root_file}{id}, $blog_dir->{id},
       'generator: blog article, root file');

    $gen = $blog_dir->generator;
    isa_ok($gen, 'Daizu::Gen::Blog', 'generator: blog dir');
    is($gen->{root_file}{id}, $blog_dir->{id},
       'generator: blog dir, root file');

    my $top_file = $wc->file_at_path('foo.com');
    $gen = $top_file->generator;
    isa_ok($gen, 'Daizu::Gen', 'generator: default');
    is($gen->{root_file}{id}, $top_file->{id},
       'generator: default, root file');
}

# tags
{
    my @tags = @{$file_2->tags};
    is(scalar @tags, 2, 'tags: article 2, two tags');
    is($tags[0]{tag}, 'bar baz', 'tags: article 2, 1st tag');
    is($tags[0]{original_spelling}, 'Bar  Baz',
       'tags: article 2, 1st spelling');
    is($tags[1]{tag}, 'foo', 'tags: article 2, 2nd tag');
    is($tags[1]{original_spelling}, 'foo', 'tags: article 2, 2nd spelling');

    @tags = @{$file_5->tags};
    is(scalar @tags, 0, 'tags: article 2, no tags');
}

# authors
test_authors($wc, 'example.com/bad-image.png');
test_authors($wc, 'foo.com');
test_authors($wc, 'foo.com/about.html', {
    username => 'geoff',
    name => 'Geoff Richards',
    email => 'geoff@daizucms.org',
    uri => 'http://www.laxan.com/',
});
test_authors($wc, 'foo.com/blog/2006/parsnips/article-3.html');
test_authors($wc, 'foo.com/blog/2006/strawberries/article-4.html', {
    username => 'alice',
    name => 'Alice Foonly',
}, {
    username => 'bob',
    name => 'bob',
    email => 'bob@daizucms.org',
});


sub enc { encode('UTF-8', "$_[0]", Encode::FB_CROAK) }

sub test_authors
{
    my ($wc, $path, @expected) = @_;
    my $file = $wc->file_at_path($path);
    assert(defined $file);

    my $user = $file->authors;
    is(scalar @$user, scalar @expected, "authors: $path: number");

    my $n = 1;
    for my $exp_user (@expected) {
        my $user = shift @$user;
        SKIP: {
            skip "got no user to test against", 5
                unless defined $user;
            my $msg = "authors: $path: author$n";
            like($user->{id}, qr/^\d$/, "$msg, id");

            for (qw( username name email uri )) {
                is($user->{$_}, $exp_user->{$_}, "$msg, $_");
            }

            ++$n;
        }
    }
}

# vi:ts=4 sw=4 expandtab filetype=perl
