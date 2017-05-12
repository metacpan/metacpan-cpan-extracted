package Daizu::HTML;
use warnings;
use strict;

use base 'Exporter';
our @EXPORT_OK = qw(
    dom_body_to_html4 dom_node_to_html4 dom_body_to_text
    dom_filtered_for_feeds
    absolutify_links
    html_escape_text html_escape_attr
);

use XML::LibXML;
use HTML::Tagset;
use URI;
use Encode qw( encode );
use Carp qw( croak );
use Carp::Assert qw( assert DEBUG );
use Daizu::Util qw( trim );

=head1 NAME

Daizu::HTML - functions for handling HTML and XHTML content

=head1 FUNCTIONS

The following functions are available for export from this module.
None of them are exported by default.

=over

=item dom_body_to_html4($doc, [$start_node], [$end_node])

Given an L<XML::LibXML::Document> object for an XHTML document fragment,
whose root element should be C<body>, returns a string representation of
the content in S<HTML 4> format.

C<$start_node> and C<$end_node> are both independently optional.
If either is present then only part of the document will be presented
in the HTML output.  Both must be either C<undef> or a node from the
root (C<body>) element of the document.  C<$start_node> should be the first
node to be shown in the output, or C<undef> to start from the beginning.
C<$end_node> should be the node I<after> the last node to be output,
or C<undef> to end at the end of the document.

=cut

sub dom_body_to_html4
{
    my ($doc, $start_node, $end_node) = @_;
    my $html = '';

    my $right_part = !defined $start_node;
    for my $child ($doc->documentElement->childNodes) {
        $right_part = 1
            if defined $start_node && $child->isSameNode($start_node);
        $right_part = 0
            if defined $end_node && $child->isSameNode($end_node);
        $html .= dom_node_to_html4($child)
            if $right_part;
    }

    return $html;
}

=item dom_node_to_html4($node)

Used by the
L<dom_body_to_html4()|/dom_body_to_html4($doc, [$start_node], [$end_node])>
function above
to process individual nodes.  The argument should be an
L<XML::LibXML::Node> object of some kind.  Returns a string containing
S<HTML 4> code, which for example will have text properly escaped.

=cut

sub dom_node_to_html4
{
    my ($node) = @_;
    my $type = $node->nodeType;

    return encode('UTF-8', html_escape_text($node->data), Encode::FB_CROAK)
        if $type == XML::LibXML::XML_TEXT_NODE ||
           $type == XML::LibXML::XML_CDATA_SECTION_NODE;

    if ($type == XML::LibXML::XML_ELEMENT_NODE) {
        my $ns = $node->namespaceURI;
        return '' if defined $ns && $ns eq $Daizu::HTML_EXTENSION_NS;

        my $elem_name = lc $node->localname;

        my $html = "<$elem_name";
        for my $attr ($node->attributes) {
            next unless $attr->nodeType == XML::LibXML::XML_ATTRIBUTE_NODE;
            my $attr_name = lc $attr->localname;
            $html .= " $attr_name";
            my $boolattr = $HTML::Tagset::boolean_attr{$elem_name};
            $html .= '="' .
                     encode('UTF-8', html_escape_attr($attr->value),
                            Encode::FB_CROAK) .
                     '"'
                unless $boolattr &&
                       ((!ref $boolattr && $boolattr eq $attr_name) ||
                        (ref $boolattr && $boolattr->{$attr_name}));
        }
        $html .= '>';

        if (!$HTML::Tagset::emptyElement{$elem_name}) {
            for my $child ($node->childNodes) {
                $html .= dom_node_to_html4($child);
            }
            $html .= "</$elem_name>";
        }
        elsif ($node->hasChildNodes) {
            warn "element '$elem_name' at line " . $node->line_number .
                 " shouldn't have content";
        }

        return $html;
    }

    return '<!--' .
           encode('UTF-8', html_escape_text($node->data), Encode::FB_CROAK) .
           '-->'
        if $type == XML::LibXML::XML_COMMENT_NODE;

    return ''
        if $type == XML::LibXML::XML_XINCLUDE_START ||
           $type == XML::LibXML::XML_XINCLUDE_END;

    die "node type $type in XML::LibXML DOM not expected";

#   These are the node types I don't currently bother with:
#       XML::LibXML::XML_ATTRIBUTE_NODE = 2
#       XML::LibXML::XML_ENTITY_REF_NODE = 5
#       XML::LibXML::XML_ENTITY_NODE = 6
#       XML::LibXML::XML_PI_NODE = 7
#       XML::LibXML::XML_DOCUMENT_NODE = 9
#       XML::LibXML::XML_DOCUMENT_TYPE_NODE = 10
#       XML::LibXML::XML_DOCUMENT_FRAG_NODE = 11
#       XML::LibXML::XML_NOTATION_NODE = 12
#       XML::LibXML::XML_HTML_DOCUMENT_NODE = 13
#       XML::LibXML::XML_DTD_NODE = 14
#       XML::LibXML::XML_ELEMENT_DECL = 15
#       XML::LibXML::XML_ATTRIBUTE_DECL = 16
#       XML::LibXML::XML_ENTITY_DECL = 17
#       XML::LibXML::XML_NAMESPACE_DECL = 18
#       XML::LibXML::XML_DOCB_DOCUMENT_NODE = 21
}

=item dom_body_to_text($doc)

Given an XHTML body (as an L<XML::LibXML::Document> object in the usually
format) return a plain text version of the content, with some markup
translatted into text formatting in a limited way to make it reasonably
readable.

=cut

sub dom_body_to_text
{
    my ($doc) = @_;
    my $text = '';
    my $accum = '';

    # This 'object' is used to track the progress of the formatting and
    # accumulate the output text.
    my $fmt = {
        # State:
        txt => '',
        linelen => 0,
        indent => 0,
        indent_stack => [],
        list_type => 'ul',
        list_pos => 1,
        list_stack => [],
        block_started => 0,
        word_gap => 0,
        text_level => undef,    # undef=normal, otherwise 'sup' or 'sub'

        # Configuration:
        max_linelen => 72,
        min_breakable_line => 10,
        block_indent => '    ',
        ul_indent => ' * ',
        ol_indent => ' %d. ',
    };

    _dom_node_children_to_text($doc->documentElement, $fmt);

    return _fmt_finish($fmt);
}

our %SUPERSCRIPT_CHARS = (
    0x0028 => 0x207D,   # SUPERSCRIPT LEFT PARENTHESIS
    0x0029 => 0x207E,   # SUPERSCRIPT RIGHT PARENTHESIS
    0x002B => 0x207A,   # SUPERSCRIPT PLUS SIGN
    0x002D => 0x207B,   # close enough for superscript HYPHEN-MINUS
    0x0030 => 0x2070,   # SUPERSCRIPT ZERO
    0x0031 => 0x00B9,   # SUPERSCRIPT ONE
    0x0032 => 0x00B2,   # SUPERSCRIPT TWO
    0x0033 => 0x00B3,   # SUPERSCRIPT THREE
    0x0034 => 0x2074,   # SUPERSCRIPT FOUR
    0x0035 => 0x2075,   # SUPERSCRIPT FIVE
    0x0036 => 0x2076,   # SUPERSCRIPT SIX
    0x0037 => 0x2077,   # SUPERSCRIPT SEVEN
    0x0038 => 0x2078,   # SUPERSCRIPT EIGHT
    0x0039 => 0x2079,   # SUPERSCRIPT NINE
    0x003D => 0x207C,   # SUPERSCRIPT EQUALS SIGN
    0x0069 => 0x2071,   # SUPERSCRIPT LATIN SMALL LETTER I
    0x006E => 0x207F,   # SUPERSCRIPT LATIN SMALL LETTER N
    0x2212 => 0x207B,   # SUPERSCRIPT MINUS
);
our %SUBSCRIPT_CHARS = (
    0x0028 => 0x208D,   # SUBSCRIPT LEFT PARENTHESIS
    0x0029 => 0x208E,   # SUBSCRIPT RIGHT PARENTHESIS
    0x002B => 0x208A,   # SUBSCRIPT PLUS SIGN
    0x002D => 0x208B,   # close enough for subscript HYPHEN-MINUS
    0x0030 => 0x2080,   # SUBSCRIPT ZERO
    0x0031 => 0x2081,   # SUBSCRIPT ONE
    0x0032 => 0x2082,   # SUBSCRIPT TWO
    0x0033 => 0x2083,   # SUBSCRIPT THREE
    0x0034 => 0x2084,   # SUBSCRIPT FOUR
    0x0035 => 0x2085,   # SUBSCRIPT FIVE
    0x0036 => 0x2086,   # SUBSCRIPT SIX
    0x0037 => 0x2087,   # SUBSCRIPT SEVEN
    0x0038 => 0x2088,   # SUBSCRIPT EIGHT
    0x0039 => 0x2089,   # SUBSCRIPT NINE
    0x003D => 0x208C,   # SUBSCRIPT EQUALS SIGN
    0x0069 => 0x1D62,   # LATIN SUBSCRIPT SMALL LETTER I
    0x0072 => 0x1D63,   # LATIN SUBSCRIPT SMALL LETTER R
    0x0075 => 0x1D64,   # LATIN SUBSCRIPT SMALL LETTER U
    0x0076 => 0x1D65,   # LATIN SUBSCRIPT SMALL LETTER V
    0x03B2 => 0x1D66,   # GREEK SUBSCRIPT SMALL LETTER BETA
    0x03B3 => 0x1D67,   # GREEK SUBSCRIPT SMALL LETTER GAMMA
    0x03C1 => 0x1D68,   # GREEK SUBSCRIPT SMALL LETTER RHO
    0x03C6 => 0x1D69,   # GREEK SUBSCRIPT SMALL LETTER PHI
    0x03C7 => 0x1D6A,   # GREEK SUBSCRIPT SMALL LETTER CHI
    0x2212 => 0x208B,   # SUBSCRIPT MINUS
);

sub _fmt_add_text
{
    my ($fmt, $text) = @_;
    return if $text eq '';

    # Split into words, but keep track of where whitespace appeared.
    # The ugly character class are because \s matches \xA0 (&nbsp;),
    # which shouldn't be collapsed like normal spaces.
    $text =~ s/[ \t\x0A\x0D]+/ /g;
    $fmt->{word_gap} = 1 if $text =~ s/\A //;
    my $word_gap_at_end = $text =~ s/ \z//;

    if (defined $fmt->{text_level}) {
        my $new = $text;
        my $lookup = $fmt->{text_level} eq 'sup' ? \%SUPERSCRIPT_CHARS
                                                 : \%SUBSCRIPT_CHARS;
        $new =~ s{([^ ])}{
            exists $lookup->{ord $1} ? chr($lookup->{ord $1}) : '@'
        }ge;
        $text = $new unless $new =~ /@/;
    }

    my $not_first;
    for my $word (split ' ', $text) {
        $fmt->{word_gap} = 1 if $not_first;
        $not_first = 1;
        $fmt->{word_gap} = 0 if $fmt->{linelen} == $fmt->{indent};

        _fmt_new_line($fmt)
            if $fmt->{linelen} >= $fmt->{min_breakable_line} &&
               $fmt->{linelen} + 1 + length($word) > $fmt->{max_linelen};

        $word = " $word" if $fmt->{word_gap};

        $fmt->{txt} .= $word;
        $fmt->{linelen} += length $word;
        $fmt->{block_started} = 1;
    }

    $fmt->{word_gap} = $word_gap_at_end;
}

sub _fmt_new_line
{
    my ($fmt) = @_;
    $fmt->{txt} .= "\n" . (' ' x $fmt->{indent});
    $fmt->{linelen} = $fmt->{indent};
    $fmt->{word_gap} = 0;
}

sub _fmt_new_block
{
    my ($fmt, $extra_indent) = @_;

    $fmt->{txt} .= "\n"                             # end last line
        if $fmt->{linelen} > $fmt->{indent};

    if ($fmt->{block_started}) {
        $fmt->{txt} .= "\n" if $fmt->{txt} ne '';   # gap between blocks
        $fmt->{txt} .= ' ' x $fmt->{indent};
        $fmt->{linelen} = $fmt->{indent};
    }

    push @{$fmt->{indent_stack}}, $fmt->{indent};
    if (defined $extra_indent) {
        $fmt->{txt} .= $extra_indent;
        $fmt->{linelen} += length $extra_indent;
        $fmt->{indent} += length $extra_indent;
    }

    $fmt->{block_started} = 0;
    $fmt->{word_gap} = 0;
}

sub _fmt_end_block
{
    my ($fmt) = @_;
    assert(@{$fmt->{indent_stack}}) if DEBUG;
    $fmt->{indent} = pop @{$fmt->{indent_stack}};
    $fmt->{word_gap} = 0;
}

sub _fmt_finish
{
    my ($fmt) = @_;
    if ($fmt->{linelen} > $fmt->{indent} && $fmt->{txt} ne '') {
        $fmt->{txt} .= "\n";
        $fmt->{linelen} = 0;
        $fmt->{word_gap} = 0;
    }
    return $fmt->{txt};
}

sub _dom_node_children_to_text
{
    my ($node, $fmt) = @_;

    for my $child ($node->childNodes) {
        _dom_node_to_text($child, $fmt);
    }
}

sub _dom_node_to_text
{
    my ($node, $fmt) = @_;
    my $type = $node->nodeType;

    if ($type == XML_TEXT_NODE) {
        _fmt_add_text($fmt, $node->textContent);
    }
    elsif ($type == XML_ELEMENT_NODE) {
        my $name = $node->nodeName;
        # TODO - definition lists
        # TODO - a marker for the presence of an object/embed/applet
        if ($name =~ /^(?:p|div|td|th|h\d)$/) {
            _fmt_new_block($fmt);
            _dom_node_children_to_text($node, $fmt);
            _fmt_end_block($fmt);
        }
        elsif ($name eq 'blockquote' || $name eq 'table') {
            _fmt_new_block($fmt, $fmt->{block_indent});
            _dom_node_children_to_text($node, $fmt);
            _fmt_end_block($fmt);
        }
        elsif ($name eq 'li') {
            my $indent = $fmt->{list_type} eq 'ul'
                       ? $fmt->{ul_indent}
                       : sprintf $fmt->{ol_indent}, $fmt->{list_pos};
            ++$fmt->{list_pos};
            _fmt_new_block($fmt, $indent);
            _dom_node_children_to_text($node, $fmt);
            _fmt_end_block($fmt);
        }
        elsif ($name eq 'ul' || $name eq 'ol') {
            push @{$fmt->{list_type_stack}}, [ $fmt->{list_type}, $fmt->{list_pos} ];
            $fmt->{list_type} = $name;
            $fmt->{list_pos} = 1;
            _dom_node_children_to_text($node, $fmt);
            ($fmt->{list_type}, $fmt->{list_pos}) = @{pop @{$fmt->{list_type_stack}}};
        }
        elsif ($name eq 'pre') {
            _fmt_new_block($fmt, $fmt->{block_indent});
            my $indent = ' ' x $fmt->{indent};
            my $code = trim($node->textContent);
            $code =~ s/(?:\x0D\x0A|\x0A|\x0D)/\n$indent/g;
            $fmt->{txt} .= $code;
            $code =~ s/^.*\n//s;
            if ($code =~ /\S/) {
                $fmt->{linelen} = $fmt->{indent} + length $code;
                $fmt->{block_started} = 1;
            }
            _fmt_end_block($fmt);
        }
        elsif ($name eq 'img') {
            my $alt = trim($node->getAttribute('alt'));
            $alt = '' unless defined $alt;
            _fmt_add_text($fmt, $alt);
        }
        elsif ($name eq 'br') {
            _fmt_new_line($fmt);
        }
        elsif ($name eq 'q') {
            _fmt_add_text($fmt, chr 8220);
            _dom_node_children_to_text($node, $fmt);
            _fmt_add_text($fmt, chr 8221);
        }
        elsif ($name eq 'sup' || $name eq 'sub') {
            my $old_text_level = $fmt->{text_level};
            $fmt->{text_level} = $name;
            _dom_node_children_to_text($node, $fmt);
            $fmt->{text_level} = $old_text_level;
        }
        else {
            # Unknown element.  Ignore the markup and just process the text.
            _dom_node_children_to_text($node, $fmt);
        }
    }
}

=item dom_filtered_for_feeds($doc)

Return a new version of the article content in C<$doc>, with bits of
markup which aren't relevant or might be unwelcome in feed content,
such as C<script> elements and C<style> attributes.  Also remove C<span>
elements because they're not needed when there's no custom styling,
and Bloglines currently turns them into invalid HTML.  Also remove
C<class> attributes in case they cause some unexpected styling to be
applied.

In addition, any elements in the Daizu HTML extension namespace are
removed.  Elements in other non-XHTML namespaces will cause this function
to fail.  They shouldn't be there by the time the content is being output
anyway.

Both C<$doc> and the return value are L<XML::LibXML::Document> objects
of the kind returned by
L<the article_doc() method in Daizu::File|Daizu::File/$file-E<gt>article_doc>.
The original DOM in C<$doc> is not altered.  The return value is a
completely independent copy.

=cut

sub dom_filtered_for_feeds
{
    my ($in_doc) = @_;

    my $out_doc = XML::LibXML::Document->new('1.0', 'UTF-8');
    my @out_child = _node_filtered_for_feeds($in_doc->documentElement);
    assert(@out_child == 1) if DEBUG;
    $out_doc->setDocumentElement(@out_child);

    return $out_doc;
}

sub _node_filtered_for_feeds
{
    my ($node) = @_;
    my $type = $node->nodeType;

    return $node->cloneNode(0)
        if $type == XML::LibXML::XML_TEXT_NODE ||
           $type == XML::LibXML::XML_CDATA_SECTION_NODE;

    if ($type == XML::LibXML::XML_ELEMENT_NODE) {
        my $ns = $node->namespaceURI;
        return if defined $ns && $ns eq $Daizu::HTML_EXTENSION_NS;
        croak "unrecognized namespace '$ns' used in article"
            if defined $ns && $ns ne 'http://www.w3.org/1999/xhtml';

        # Ignore certain elements which would be rude to put in a feed.
        my $elem_name = $node->localname;
        return if $elem_name =~ /^(script|style)$/i;

        if ($elem_name eq 'span' ||
            ($elem_name eq 'a' && !$node->hasAttribute('href')))
        {
            # Strip the element out but retain its content.
            return map { _node_filtered_for_feeds($_) } $node->childNodes;
        }
        else {
            my $out_elem = XML::LibXML::Element->new($elem_name);

            for my $attr ($node->attributes) {
                next unless $attr->nodeType == XML::LibXML::XML_ATTRIBUTE_NODE;
                my $attr_name = $attr->localname;
                next if $attr_name =~ /^(class|style|on.*|id|name)$/i;
                $out_elem->setAttribute($attr_name => $attr->value);
            }

            for my $child ($node->childNodes) {
                my @out = _node_filtered_for_feeds($child);
                $out_elem->appendChild($_)
                    for @out;
            }

            return $out_elem;
        }
    }

    return
        if $type == XML::LibXML::XML_COMMENT_NODE   ||
           $type == XML::LibXML::XML_XINCLUDE_START ||
           $type == XML::LibXML::XML_XINCLUDE_END;

    die "node type $type in XML::LibXML DOM not expected";

#   These are the node types I don't currently bother with:
#       XML::LibXML::XML_ATTRIBUTE_NODE = 2
#       XML::LibXML::XML_ENTITY_REF_NODE = 5
#       XML::LibXML::XML_ENTITY_NODE = 6
#       XML::LibXML::XML_PI_NODE = 7
#       XML::LibXML::XML_DOCUMENT_NODE = 9
#       XML::LibXML::XML_DOCUMENT_TYPE_NODE = 10
#       XML::LibXML::XML_DOCUMENT_FRAG_NODE = 11
#       XML::LibXML::XML_NOTATION_NODE = 12
#       XML::LibXML::XML_HTML_DOCUMENT_NODE = 13
#       XML::LibXML::XML_DTD_NODE = 14
#       XML::LibXML::XML_ELEMENT_DECL = 15
#       XML::LibXML::XML_ATTRIBUTE_DECL = 16
#       XML::LibXML::XML_ENTITY_DECL = 17
#       XML::LibXML::XML_NAMESPACE_DECL = 18
#       XML::LibXML::XML_DOCB_DOCUMENT_NODE = 21
}

=item absolutify_links($doc, $base_url)

Given an XHTML document (as an L<XML::LibXML::Document> object), find
all the attributes in the markup which are relative URLs and turn them
into absolute URLs relative to C<$base_url>.  This can be used to prepare
content from an article to be published in a different place with a different
URL, such as in an RSS feed or on an index page, while ensuring that any
links or embedded files continue to work.

The document's elements must be in the XHTML namespace, or they will be
ignored.

TODO - some of this could be refactored with the link replacing stuff
in Daizu::Preview to be more thorough.  For now though it just works on
'a href' and 'img src', since that will catch almost all cases.

=cut

sub absolutify_links
{
    my ($doc, $base_url) = @_;
    $base_url = URI->new($base_url);

    my %FIND_ATTRS = (
        a => 'href',
        img => 'src',
    );

    while (my ($elem_name, $attr_name) = each %FIND_ATTRS) {
        for ($doc->findnodes("//*[(namespace-uri() = 'http://www.w3.org/1999/xhtml' or namespace-uri() = '') and local-name() = '$elem_name']/@*[local-name() = '$attr_name']")) {
            my $url = URI->new($_->getValue);
            $_->setValue($url->abs($base_url));
        }
    }
}

=item html_escape_text($text)

Escape C<$text> in a way which makes it safe to include in the content
of HTML or XML elements.  The characters C<E<lt>>, C<E<gt>>, and C<&> are
escaped.  Returns the new value.

The output may not be suitable for including as the value of an
HTML or XML attribute.

The return value is always formatted as bytes encoded in UTF-8.

=cut

sub html_escape_text
{
    my ($s) = @_;
    $s =~ s/&/&amp;/g;
    $s =~ s/</&lt;/g;
    $s =~ s/>/&gt;/g;
    return $s;
}

=item html_escape_attr($text)

Escape C<$text> in a way which makes it safe to include in the content of
HTML or XML elements, or the values of HTML or XML attributes in double
quotes.  The characters C<E<lt>>, C<E<gt>>, C<&>, and C<"> are escaped.
Returns the new value.

The return value is always formatted as bytes encoded in UTF-8.

=cut

sub html_escape_attr
{
    my ($s) = @_;
    $s =~ s/&/&amp;/g;
    $s =~ s/</&lt;/g;
    $s =~ s/>/&gt;/g;
    $s =~ s/"/&quot;/g;
    return $s;
}

=back

=head1 COPYRIGHT

This software is copyright 2006 Geoff Richards E<lt>geoff@laxan.comE<gt>.
For licensing information see this page:

L<http://www.daizucms.org/license/>

=cut

1;
# vi:ts=4 sw=4 expandtab
