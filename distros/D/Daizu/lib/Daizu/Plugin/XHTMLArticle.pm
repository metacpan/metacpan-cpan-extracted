package Daizu::Plugin::XHTMLArticle;
use warnings;
use strict;

use XML::LibXML;
use Carp qw( croak );
use Encode qw( decode );
use Daizu::Util qw(
    url_encode daizu_data_dir
);

=head1 NAME

Daizu::Plugin::XHTMLArticle - plugin for loading articles written in XHTML

=head1 DESCRIPTION

This article loader plugin allows you to write Daizu articles in XHTML
format.  The content of the files it is used for must be well-formed XML,
except that there is no need to have a single root element.  The content
is wrapped in a C<body> element before being parsed.  This plugin will
fail if there are any errors during parsing.

The default namespace declared on the root C<body> element is the XHTML
namespace.  The namespace prefix C<daizu> is also declared and mapped to
the Daizu HTML extension namespace.

A DTD is also included automatically.  It doesn't validate the input,
but it does provide all the standard HTML entity references, so for
example you can use C<&nbsp;> to get a non-breaking space.

TODO - link to a page describing the HTML extensions.

TODO - describe the XInclude support and daizu: URI scheme.

=head1 CONFIGURATION

To turn on this plugin, include the following in your Daizu CMS configuration
file:

=for syntax-highlight xml

    <plugin class="Daizu::Plugin::XHTMLArticle" />

=head1 METHODS

=over

=item Daizu::Plugin::XHTMLArticle-E<gt>register($cms, $whole_config, $plugin_config, $path)

Called by Daizu CMS when the plugin is registered.  It registers the
L<load_article()|/$self-E<gt>load_article($cms, $file)> method as
an article loader for the MIME types 'text/html' and 'application/xhtml+xml'.

The configuration is currently ignored.

=cut

sub register
{
    my ($class, $cms, $whole_config, $plugin_config, $path) = @_;
    my $self = bless {}, $class;
    $cms->add_article_loader($_, '', $self => 'load_article')
        for qw( text/html application/xhtml+xml );
}

=item $self-E<gt>load_article($cms, $file)

Does the actual parsing of the XHTML content of C<$file> (which should
be a L<Daizu::File> object), and returns the appropriate content as an XHTML
DOM of the file.

Never rejects a file, and therefore always returns true.

=cut

sub load_article
{
    my ($self, $cms, $file) = @_;

    my $parser = XML::LibXML->new;
    $parser->pedantic_parser(1);
    $parser->validation(0);
    $parser->line_numbers(1);

    my $xml_dir = url_encode(daizu_data_dir('xml')->stringify);
    my $doc = $parser->parse_string(
        '<?xml version="1.0" encoding="UTF-8"?>' .
        qq{<!DOCTYPE body SYSTEM "file://$xml_dir/xhtml-entities.dtd">} .
        qq{<body xmlns="http://www.w3.org/1999/xhtml"} .
             qq{ xmlns:xi="http://www.w3.org/2001/XInclude"} .
             qq{ xmlns:daizu="$Daizu::HTML_EXTENSION_NS">} .
        decode('UTF-8', ${$file->data}, Encode::FB_CROAK) .
        '</body>'
    );

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
