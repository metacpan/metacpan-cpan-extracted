package Daizu::Feed;
use warnings;
use strict;

use XML::LibXML;
use Carp qw( croak );
use Daizu;
use Daizu::Util qw( w3c_datetime rfc2822_datetime add_xml_elem );
use Daizu::HTML qw(
    dom_body_to_html4 absolutify_links dom_filtered_for_feeds
    html_escape_text
);

our $ATOM_NS = 'http://www.w3.org/2005/Atom';

=head1 NAME

Daizu::Feed - class for creating Atom and RSS feeds

=head1 DESCRIPTION

A class for creating feeds in Atom and RSS formats.  Currently it is
only possible to use this for feeds where the entries are Daizu articles.

To use this, first create an object, indicating what kind of feed you
want, and then call the L<add_entry()|/$feed-E<gt>add_entry($file)>
method for each
article you want to include.  Then you can call the L<xml()|/$feed-E<gt>xml()>
method to get the output.

=head1 FEED FORMATS

The format of a feed determines how the information is encoded, but should
not affect I<what> information is provided.  The currently supported feed
formats are:

=over

=item atom

S<Atom 1.0>, as described in S<RFC 4287>.

This format is used for the default blog configuration because of its
technical advantages over RSS.

Specification: L<http://atompub.org/rfc4287.html>

=item rss2

S<RSS 2.0>.  Provided for compatability with older feed consuming software.

Specification: L<http://www.rssboard.org/rss-specification>

=back

=head1 FEED TYPES

The type of feed determines what information is provided for each article.
This is more a matter of editorial policy than the choice of feed format.

The description for an article (from the C<dc:description> property)
is always included in the feed if present.  In Atom feeds it will be
provided in an C<atom:summary> element, which will only appear if the
article has a description.  In RSS feeds the C<description> element will
have this value, but if there is no description then it will still appear
(since some consumers may rely on it being present), and will instead
carry a short extract of the text from the start of the article.

Note that in RSS feeds the actual content of articles, if it's included,
is put in a C<content:encoded> element, which the
feed validator recommends against
(L<http://feedvalidator.org/docs/warning/DuplicateDescriptionSemantics.html>).
There's no right answer for this, and I might change my mind
about it in the future, but for now I'm copying what
Wordpress (L<http://wordpress.org/>) does.

The actual content of an article may appear, depending on the type
of feed you ask for.  The options are:

=over

=item description

No extra information about the article is provided, beyond the title,
description (as described above), a link to the article's URL, and
the its publication and update times.

For Atom feeds: the C<atom:content> element is omitted.

For RSS feeds: the C<content:encoded> element is omitted.

=item snippet

If the article's content contains a 'fold' (indicated with a C<daizu:fold>
element) or a page break, then only the content before the fold or first page
break is included in the feed.  If there is any more content in the full
article then a text link to the article's URL is included after the extract
to make it more obvious that only part of the article is shown.  If there
is no fold or page break then the full article is included in the feed, as
for the C<content> type feeds described below.

For Atom feeds: the extract of the article content is provided as raw
XHTML in an C<atom:content> element.

For RSS feeds: the extract of the article content is provided in a
C<content:encoded> element.  The C<description> element will still carry
the description or extract as described above.

=item content

The full content of the article is included in the feed, even if the article
has page breaks.  Any C<daizu:fold> elements or C<daizu:page> elements in
the article's content will be ignored (and will not appear in the feed).

For Atom feeds: the article content is provided as raw XHTML in an
C<atom:content> element.

For RSS feeds: the article content is provided in a C<content:encoded>
element.  The C<description> element will still carry the description or
extract as described above.

=back

=head1 METHODS

=over

=item Daizu::Feed-E<gt>new($cms, $file, $url, $format, $type)

Return a new Daizu::Feed object and set up the basic outline of
the XML feed.  C<$file> should be a L<Daizu::File> object representing
the 'homepage' of this feed.  C<$url> should be a string containing the URL
of the feed file itself once it has been output.  C<$format> should be
either 'atom' (for S<Atom 1.0> feeds) or 'rss2' (for S<RSS 2.0> feeds).
C<$type> can be one of the feed types L<mentioned above|/FEED TYPES>
('description', 'snippet', or 'content').

=cut

sub new
{
    my ($class, $cms, $file, $url, $format, $type) = @_;
    croak "unknown feed format '$format'"
        unless $format eq 'atom' || $format eq 'rss2';
    croak "unknown feed type '$type'"
        unless $type eq 'content' || $type eq 'snippet' ||
               $type eq 'description';

    my $feed_title = $file->title;
    croak "no title available for feed, or any of its ancestors"
        unless defined $feed_title;

    my $homepage_url = $file->generator->base_url($file);
    croak "blog homepage doesn't seem to have a URL"
        unless defined $homepage_url;

    my $doc = XML::LibXML::Document->new('1.0', 'UTF-8');
    my $feed;
    my $entry_parent;
    my $updated_elem;
    if ($format eq 'atom') {    # Atom 1.0
        $feed = $doc->createElementNS($ATOM_NS, 'feed');
        $entry_parent = $feed;

        add_xml_elem($feed, title => $feed_title);
        # TODO - description should be decoded from utf-8 at some point
        add_xml_elem($feed, subtitle => $file->{description})
            if defined $file->{description};
        add_xml_elem($feed, id => $file->guid_uri);
        add_xml_elem($feed, generator => 'Daizu CMS',
            uri => 'http://www.daizucms.org/',
            version => $Daizu::VERSION,
        );
        add_xml_elem($feed, link => undef,
            rel => 'self',
            href => $url,
            type => 'application/atom+xml',
        );
        add_xml_elem($feed, link => undef,
            href => $homepage_url,
            type => 'text/html',
        );
        $updated_elem = add_xml_elem($feed, updated => undef);
    }
    else {                      # RSS 2.0
        $feed = XML::LibXML::Element->new('rss');
        $feed->setAttribute(version => '2.0');
        $feed->setNamespace($ATOM_NS, 'atom', 0);
        $feed->setNamespace('http://purl.org/rss/1.0/modules/content/',
                            'content', 0);
        $feed->setNamespace('http://purl.org/dc/elements/1.1/', 'dc', 0);

        my $channel = XML::LibXML::Element->new('channel');
        $feed->appendChild($channel);
        $entry_parent = $channel;

        add_xml_elem($channel, title => $feed_title);
        add_xml_elem($channel, link => "$homepage_url");
        add_xml_elem($channel, description =>
            defined $file->{description} ? $file->{description} : '');

        add_xml_elem($channel, generator => "http://www.daizucms.org/?v=$Daizu::VERSION");
        $updated_elem = add_xml_elem($channel, lastBuildDate => undef);

        # For the Universal Subscription Mechanism:
        #    http://www.kbcafe.com/rss/usm.html
        add_xml_elem($channel, 'atom:link' => undef,
            rel => 'self',
            href => $url,
            type => 'application/rss+xml',
            title => $feed_title,
        );
    }

    $doc->setDocumentElement($feed);

    return bless {
        cms => $cms,
        doc => $doc,
        feed_elem => $feed,
        entry_parent => $entry_parent,
        file => $file,
        format => $format,
        type => $type,
        feed_updated_elem => $updated_elem,
    }, $class;
}

=item $feed-E<gt>xml()

Returns the L<XML::LibXML::Document> object for the feed, which you
can use to write it out to a file.  Call this after you've addded
all the entries.

Before the XML is returned, the feed's 'updated' timestamp is set
to the update time of the most recently updated article, or the current
time (if there are no articles or if the most recently updated one
was updated in the future).  Because of this, if you add any more articles
after calling this function, you should call it again to get an updated
version of the feed XML.

=cut

sub xml {
    my ($self) = @_;

    # Set the feed's latest update time to the time of the most recent
    # article's latest update.  This is idempotent in case you add some
    # more articles and get the document again.
    my $latest_update = $self->{latest_update};
    my $now = DateTime->now;
    $latest_update = $now
        if !defined $latest_update || $latest_update > $now;
    $self->{feed_updated_elem}->removeChildNodes;
    $self->{feed_updated_elem}->appendText(
        $self->{format} eq 'atom' ? w3c_datetime($latest_update)
                                  : rfc2822_datetime($latest_update));

    return $self->{doc};
}

=item $feed-E<gt>add_entry($file)

Add an entry to the feed, for C<$file>, which should be a L<Daizu::File>
object.  The file must be an article, and must have a title.

It is the responsibility of the caller to ensure that the file has been
published under it's expected URL, otherwise the feed will include a
broken link.

=cut

sub add_entry
{
    my ($self, $file) = @_;
    croak "bad entry for feed: file $file->{id} has no title"
        unless defined $file->{title};

    my $doc = $self->{doc};
    my $article_url = $file->generator->base_url($file);

    if ($self->{format} eq 'atom') {    # Atom 1.0
        my $entry = add_xml_elem($self->{entry_parent}, 'entry');
        add_xml_elem($entry, published => w3c_datetime($file->issued_at));
        add_xml_elem($entry, updated => w3c_datetime($file->modified_at));
        add_xml_elem($entry, id => $file->guid_uri);
        add_xml_elem($entry, link => undef,
            rel => 'alternate',
            href => $article_url,
            type => 'text/html',
        );
        add_xml_elem($entry, title => $file->{title});

        my $authors = $file->authors;
        if (@$authors) {
            for (@$authors) {
                my $author = add_xml_elem($entry, 'author');
                add_xml_elem($author, name => $_->{name});
                add_xml_elem($author, email => $_->{email})
                    if defined $_->{email};
                add_xml_elem($author, uri => $_->{uri})
                    if defined $_->{uri};
            }
        }
        else {
            # No information has been provided about authors, but the Atom
            # specification requires one, so we hard-code an 'Anonymous' one.
            my $author = add_xml_elem($entry, 'author');
            add_xml_elem($author, name => 'Anonymous');
        }

        for (@{$file->tags}) {
            add_xml_elem($entry, category => undef,
                term => $_->{tag},
                label => $_->{original_spelling},
            );
        }

        add_xml_elem($entry, summary => $file->{description})
            if defined $file->{description};

        if ($self->{type} ne 'description') {
            my $content_elem = add_xml_elem($entry, content => undef,
                type => 'xhtml',
                'xml:base' => $article_url,
            );
            my $div = $doc->createElementNS('http://www.w3.org/1999/xhtml',
                                            'div');
            $content_elem->appendChild($div);
            my $content = $self->{type} eq 'snippet' ? $file->article_snippet
                                                     : $file->article_doc;
            $content = dom_filtered_for_feeds($content);
            $div->appendChild($_->cloneNode(1))
                for $content->documentElement->childNodes;
        }
    }
    else {                              # RSS 2.0
        my $entry = add_xml_elem($self->{entry_parent}, 'item');
        add_xml_elem($entry, pubDate => rfc2822_datetime($file->issued_at));
        add_xml_elem($entry, link => "$article_url");
        add_xml_elem($entry, title => $file->{title});

        my $guid = add_xml_elem($entry, guid => $file->guid_uri);
        $guid->setAttribute(isPermaLink => 'false');

        # As far as I can tell, although I don't think it's explicit in the
        # specification, there can only be one author.  Standard RSS 2.0 also
        # has no way of indicating an author without including their email
        # address, so we have to use 'dc:creator' for that.
        my $authors = $file->authors;
        if (@$authors) {
            my $author = shift @$authors;
            if (defined $author->{email}) {
                add_xml_elem($entry, author =>
                    "$author->{email} ($author->{name})");
            }
            else {
                add_xml_elem($entry, 'dc:creator' => $author->{name});
            }
        }

        for (@{$file->tags}) {
            add_xml_elem($entry, category => $_->{tag});
        }

        # Extra level of XML escaping, because consumers might expect it
        # to be escaped HTML.  Following the spec it's not really necessary
        # to provide the extract if there's no real description, but it's
        # conventional to include it, especially if there's a content:encoded
        # element as well.
        add_xml_elem($entry, description => html_escape_text(
            defined $file->{description} ? $file->{description}
                                         : $file->article_extract));

        if ($self->{type} ne 'description') {
            my $content = $self->{type} eq 'snippet' ? $file->article_snippet
                                                     : $file->article_doc;
            absolutify_links($content, $article_url);
            $content = dom_filtered_for_feeds($content);
            add_xml_elem($entry, 'content:encoded' =>
                         dom_body_to_html4($content));
        }
    }

    $self->{latest_update} = $file->modified_at
        if !defined $self->{latest_update} ||
           $self->{latest_update} < $file->modified_at
}

=back

=head1 COPYRIGHT

This software is copyright 2006 Geoff Richards E<lt>geoff@laxan.comE<gt>.
For licensing information see this page:

L<http://www.daizucms.org/license/>

=cut

1;
# vi:ts=4 sw=4 expandtab
