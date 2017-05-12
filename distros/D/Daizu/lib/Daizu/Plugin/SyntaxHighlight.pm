package Daizu::Plugin::SyntaxHighlight;
use warnings;
use strict;

use Text::VimColor;
use Daizu;

=head1 NAME

Daizu::Plugin::SyntaxHighlight - a plugin for syntax-highlighting code samples in HTML pages

=head1 DESCRIPTION

This plugin filters XHTML content expanding any
C<daizu::syntax-highlight> elements by passing their contents through
the L<Text::VimColor> module, which is required for it to work.  The source
of your articles can contain markup like this:

=for syntax-highlight xml

    <daizu:syntax-highlight filetype="perl">
    # A piece of Perl code which will be syntax highlighted.
    my $foo = 'bar';
    </daizu:syntax-highlight>

The C<daizu> prefix should be bound to the
L<Daizu HTML extension namespace|Daizu/$Daizu::HTML_EXTENSION_NS>
(which is done automatically for the content of XHTML articles).  The output
will be an HTML C<pre> element, containing text and C<span> elements with
appropriate classes.

Extra whitespace at the start or end of the content is trimmed off.

If you want to highlight a larger amount of code, put it in a separate
file and use XInclude to insert it into the C<syntax-highlight> element.
For example:

=for syntax-highlight xml

    <daizu:syntax-highlight filetype="sql">
    <xi:include href="database-schema.sql" parse="text"/>
    </daizu:syntax-highlight>

Note that the C<xi:include> element isn't indented, because that might
leave an extra bit of indentation on the first line.

You can also use a different element instead of C<pre>.  For example
to highlight a Perl regular expression which appears in a paragraph,
you can instead use a C<code> element:

=for syntax-highlight xml

    <daizu:syntax-highlight filetype="perl" element="code"
      >/^_index\./</daizu:syntax-highlight>

=head1 CONFIGURATION

To turn on this plugin, include the following in your Daizu CMS configuration
file:

=for syntax-highlight xml

    <plugin class="Daizu::Plugin::SyntaxHighlight" />

All files which have a C<daizu:type> property of 'article' will then
be filtered by this module.

=head1 STYLING

For the highlighting to be presented properly you will have to provide some
rules in your CSS stylesheet.  The following works well if your C<pre> blocks
will have a white background:

=for syntax-highlight css

    span.syn-comment    { color: #0000FF }
    span.syn-constant   { color: #FF00FF }
    span.syn-identifier { color: #008B8B }
    span.syn-statement  { color: #A52A2A ; font-weight: bold }
    span.syn-preproc    { color: #A020F0 }
    span.syn-type       { color: #2E8B57 ; font-weight: bold }
    span.syn-special    { color: #6A5ACD }
    span.syn-underlined { color: #000000 ; text-decoration: underline }
    span.syn-error      { color: #FFFFFF ; background: #FF0000 none }
    span.syn-todo       { color: #0000FF ; background: #FFFF00 none }

The Daizu CMS default stylesheet has these rules included already.

=head1 METHODS

=over

=item Daizu::Plugin::SyntaxHighlight-E<gt>register($cms, $whole_config, $plugin_config, $path)

Called by Daizu CMS when the plugin is registered.  It registers the
L<do_syntax_highlighting()|/$self-E<gt>do_syntax_highlighting($cms, $file, $doc)>
method as an HTML DOM filter.

The configuration is currently ignored.

=cut

sub register
{
    my ($class, $cms, $whole_config, $plugin_config, $path) = @_;
    my $self = bless {}, $class;
    $cms->add_html_dom_filter($path, $self => 'do_syntax_highlighting');
}

=item $self-E<gt>do_syntax_highlighting($cms, $file, $doc)

Does the actual filtering in-place on C<$doc> and returns it.
Currently C<$cms> is ignored.

=cut

sub do_syntax_highlighting
{
    my (undef, undef, undef, $doc) = @_;

    for my $elem ($doc->findnodes(qq{
        //*[namespace-uri() = '$Daizu::HTML_EXTENSION_NS' and
            local-name() = 'syntax-highlight']
    }))
    {
        my $filetype = $elem->getAttribute('filetype');
        my $output_elem_name = $elem->getAttribute('element') || 'pre';

        my $content = $elem->textContent;

        # Trim leading whitespace, but not indentation on the first line.
        $content =~ s/\A\s*\n//;

        my $syntax = Text::VimColor->new(
            filetype => $filetype,
            string => $content,
        );

        # Text::VimColor seems to add an extra newline at the end, so we
        # trim off trailing whitespace after the markup has been done.
        my $marked = $syntax->marked;
        while (@$marked) {
            $marked->[-1][1] =~ s/\s+\z// or last;
            last unless $marked->[-1][1] eq '';
            --$#$marked;
        }

        my $new_elem = $doc->createElementNS('http://www.w3.org/1999/xhtml',
                                             $output_elem_name);
        $new_elem->setAttribute(class => 'syntax-highlight');
        for (@{$marked}) {
            my ($class, $text) = @$_;
            $text = XML::LibXML::Text->new($text);

            if ($class eq '') {
                $new_elem->appendChild($text);
            }
            else {
                my $elem = XML::LibXML::Element->new('span');
                $elem->setAttribute(class => 'syn-' . lc($class));
                $elem->appendChild($text);
                $new_elem->appendChild($elem);
            }
        }

        $elem->replaceNode($new_elem);
    }

    return { content => $doc };
}

=back

=head1 COPYRIGHT

This software is copyright 2006 Geoff Richards E<lt>geoff@laxan.comE<gt>.
For licensing information see this page:

L<http://www.daizucms.org/license/>

=cut

1;
# vi:ts=4 sw=4 expandtab
