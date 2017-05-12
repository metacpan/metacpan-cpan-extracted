package Daizu::Plugin::HeaderAnchor;
use warnings;
use strict;

use XML::LibXML;

=head1 NAME

Daizu::Plugin::HeaderAnchor - add anchors to headings in all articles

=head1 DESCRIPTION

This plugin filters articles and adds anchors (C<a> elements with
an C<id> attribute but no C<href> attribute) to all the headings
(from C<h1> to C<h6>).  This allows people to link to a specific
section of your web page.

The names used for the anchors are based on the textual content of
the headings.  All the names have a C<sec-> prefix added.

Care is taken to ensure that anchor names aren't duplicated, although
if the templates add any which start with the same prefix then it would
be possible to get a duplicate value.  Anchors are not added to headings
which already contain an C<a> element with either a C<name> or C<id>
attribute.

=head1 CONFIGURATION

To turn on this plugin, include the following in your Daizu CMS configuration
file:

=for syntax-highlight xml

    <plugin class="Daizu::Plugin::HeaderAnchor" />

=head1 METHODS

=over

=item Daizu::Plugin::HeaderAnchor-E<gt>register($cms, $whole_config, $plugin_config, $path)

Registers the plugin as a filter for all articles at or in C<$path>.

=cut

sub register
{
    my ($class, $cms, $whole_config, $plugin_config, $path) = @_;
    my $self = bless {}, $class;
    $cms->add_html_dom_filter($path, $self => 'filter_article');
}

=item $self-E<gt>filter_article($cms, $file, $doc)

Does the actual filtering in-place on C<$doc> and returns it.
Currently C<$cms> and C<$file> are ignored.

=cut

sub filter_article
{
    my (undef, undef, undef, $doc) = @_;
    my %name_used;

    # Find any anchors already used in the article, in case the user
    # wants to customize one, or put move an anchor to a specific place.
    # In that case we need to avoid adding an anchor with the same name.
    # We're only interested in ones starting with 'sec-' because that's
    # all we generate.  Treat the IDs case insensitvely just to be on
    # the safe side.
    for ($doc->findnodes(qq{
        //@*[name() = 'id' or name() = 'name' or name() = 'xml:id']
    }))
    {
        my $value = $_->getValue;
        $name_used{lc $value} = undef
            if $value =~ /^sec-/i;
    }

    # Search for heading elements and add the anchors.
    for my $elem ($doc->findnodes(qq{
        //*[namespace-uri() = 'http://www.w3.org/1999/xhtml' and
            substring(local-name(), 1, 1) = 'h']
    }))
    {
        # Only process heading elements: h1, h2, h3, h4, h5, and h6.
        next unless $elem->localname =~ /^h[123456]$/;

        # If the heading already has an anchor, ignore it.
        next if $elem->findnodes(q{
            *[namespace-uri() = 'http://www.w3.org/1999/xhtml' and
              local-name() = 'a' and
              (@name or @id)]
        });
        next if $elem->hasAttribute('id');

        my $text = lc $elem->textContent;
        for ($text) {
            s/\.+/./g;
            s/[^-.a-zA-Z0-9]+/ /g;
            s/^[-. ]+//;
            s/[-. ]+$//;
        }
        my @words = ('sec', split ' ', $text);
        @words = map { $_ eq '' ? () : ($_) } @words;

        # Shorten it to at most three words.
        my $max_words = 3;      # doesn't include 'sec-' prefix.
        $#words = $max_words
            if @words > ($max_words + 1);
        $#words = $max_words - 1
            if @words == ($max_words + 1) &&
               $words[$max_words] =~/^(?:a|the|and|or|of|in|at|to)$/;

        push @words, 'unnamed' if @words == 1;
        my $anchor_name = join '-', @words;

        # Make sure it's unique (within the content we can see) by
        # appending a number if necessary.
        if (exists $name_used{$anchor_name}) {
            my $n = 2;
            while (exists $name_used{"$anchor_name-$n"}) {
                ++$n;
            }
            $anchor_name = "$anchor_name-$n";
        }
        $name_used{$anchor_name} = undef;

        # Add a new empty anchor element at the start of the heading.
        my $anchor = XML::LibXML::Element->new('a');
        $anchor->setAttribute(id => $anchor_name);
        $elem->insertBefore($anchor, $elem->firstChild);
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
