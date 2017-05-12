#!/usr/bin/perl
use warnings;
use strict;

use Test::More;
use Path::Class qw( file );
use XML::LibXML;
use Encode qw( decode encode );
use Daizu;
use Daizu::Test qw( init_tests );
use Daizu::HTML qw(
    dom_body_to_html4 dom_node_to_html4 dom_body_to_text
    dom_filtered_for_feeds
    absolutify_links
    html_escape_text html_escape_attr
);

init_tests(20);

# html_escape_text
is(html_escape_text(q{ < > & ' " }), q{ &lt; &gt; &amp; ' " },
   'html_escape_text');
is(html_escape_text("<\x{8A9E}>"), "&lt;\x{8A9E}&gt;",
   'html_escape_text: UTF-8 text');
is(html_escape_text(enc("<\x{8A9E}>")), enc("&lt;\x{8A9E}&gt;"),
   'html_escape_text: encoded UTF-8 data');

# html_escape_attr
is(html_escape_attr(q{ < > & ' " }), q{ &lt; &gt; &amp; ' &quot; },
   'html_escape_attr');
is(html_escape_attr("<\x{8A9E}>"), "&lt;\x{8A9E}&gt;",
   'html_escape_attr: UTF-8 text');
is(html_escape_attr(enc("<\x{8A9E}>")), enc("&lt;\x{8A9E}&gt;"),
   'html_escape_attr: encoded UTF-8 data');

# dom_node_to_html4
{
    is(dom_node_to_html4(XML::LibXML::Text->new(q{ < > & ' " })),
       q{ &lt; &gt; &amp; ' " },
       'dom_node_to_html4: text');
    is(dom_node_to_html4(XML::LibXML::Comment->new(q{ < > & ' " })),
       q{<!-- &lt; &gt; &amp; ' " -->},
       'dom_node_to_html4: comment');

    my $elem = XML::LibXML::Element->new('p');
    is(dom_node_to_html4($elem), q{<p></p>},
       'dom_node_to_html4: empty paragraph');

    $elem->appendText(q{ < > & ' " });
    is(dom_node_to_html4($elem),
       q{<p> &lt; &gt; &amp; ' " </p>},
       'dom_node_to_html4: paragraph with text');

    $elem->appendChild(XML::LibXML::Element->new('br'));
    $elem->appendText("more\ntext");
    my $em = XML::LibXML::Element->new('em');
    $em->appendText('text nested in <em>');
    $elem->appendChild($em);
    my $img = XML::LibXML::Element->new('img');
    $img->setAttribute(src => 'foo.png');
    $img->setAttribute(class => 'TestImage');
    $elem->appendChild($img);
    my $got = dom_node_to_html4($elem);

    # Munge the output to remove dependence on Perl's hash ordering.
    $got =~ s/class="TestImage" src="foo\.png"/src="foo.png" class="TestImage"/;

    is($got,
       qq{<p> &lt; &gt; &amp; ' " <br>more\ntext<em>text nested in &lt;em&gt;</em><img src="foo.png" class="TestImage"></p>},
       'dom_node_to_html4: complex markup and empty elements');
}

# dom_body_to_html4
{
    my $doc = XML::LibXML::Document->new('1.0', 'UTF-8');
    my $body = XML::LibXML::Element->new('body');
    $body->setNamespace('http://www.w3.org/1999/xhtml');
    $doc->setDocumentElement($body);

    my @para;
    for (1 .. 3) {
        my $elem = XML::LibXML::Element->new('p');
        $elem->appendText($_);
        $body->appendChild($elem);
        push @para, $elem;
    }

    # This extension element should not be output to the HTML 4 code.
    $body->appendChild(
        $doc->createElementNS($Daizu::HTML_EXTENSION_NS, 'extension'),
    );

    is(dom_body_to_html4($doc), '<p>1</p><p>2</p><p>3</p>',
       'dom_body_to_html4: whole document');
    is(dom_body_to_html4($doc, $para[0], undef), '<p>1</p><p>2</p><p>3</p>',
       'dom_body_to_html4: start=first para, end=undef');
    is(dom_body_to_html4($doc, $para[1], undef), '<p>2</p><p>3</p>',
       'dom_body_to_html4: start=second para, end=undef');
    is(dom_body_to_html4($doc, undef, $para[2]), '<p>1</p><p>2</p>',
       'dom_body_to_html4: start=undef, end=last para');
    is(dom_body_to_html4($doc, $para[1], $para[2]), '<p>2</p>',
       'dom_body_to_html4: start=second para, end=last para');
    is(dom_body_to_html4($doc, $para[2], $para[2]), '',
       'dom_body_to_html4: start=second para, end=second para');
}

# dom_body_to_text
{
    my $input_doc = read_xml('text-input.html');
    my $expected = read_file('text-expected.txt');
    $expected = decode('UTF-8', $expected, Encode::FB_CROAK);

    is(dom_body_to_text($input_doc), $expected, 'dom_body_to_text');
}

# dom_filtered_for_feeds
{
    my $input_doc = read_xml('feed-filter-input.html');
    my $expected = read_file('feed-filter-expected.html');

    my $got_doc = dom_filtered_for_feeds($input_doc);

    my $output = '';
    for ($got_doc->documentElement->childNodes) {
        $output .= $_->toString;
    }

    is($output, $expected, 'dom_filtered_for_feeds');
}

# absolutify_links
{
    my $input_doc = read_xml('absolutify-input.html');
    my $expected = read_file('absolutify-expected.html');

    absolutify_links($input_doc, 'http://example.com/base/basefile.html');

    my $output = '';
    for ($input_doc->documentElement->childNodes) {
        $output .= $_->toString;
    }
    is($output, $expected, 'absolutify_links');
}


sub test_filename { file(qw( t data 15html ), @_) }

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

sub read_xml
{
    my $input = read_file(@_);
    return XML::LibXML->new->parse_string($input);
}

sub enc { encode('UTF-8', "$_[0]", Encode::FB_CROAK) }

# vi:ts=4 sw=4 expandtab filetype=perl
