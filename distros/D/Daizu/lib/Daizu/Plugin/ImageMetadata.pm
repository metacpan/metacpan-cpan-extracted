package Daizu::Plugin::ImageMetadata;
use warnings;
use strict;

use Daizu::Util qw( db_row_id db_select );

=head1 NAME

Daizu::Plugin::ImageMetadata - add information to 'img' elements

=head1 DESCRIPTION

This plugin filters articles and adds additional attributes to C<img>
elements when appropriate.

TODO - how it finds the image file

The following information can be added:

=over

=item width and height

These attributes are filled in (if I<neither> of them are present already)
using the size of the image file as recorded by Daizu.  The size comes
from the C<image_width> and C<image_height> values in the C<wc_file> table
in the database.  This information is only available if the image file
has a MIME type like 'image/*', and if the L<Image::Size> module knows
how to extract the size for a the type of image.  The bitmap formats you're
likely to use on websites are all supported (PNG, JPEG, and GIF) as well
as a few others.

=item alt

The alternative text is added, if there isn't already an C<alt> attribute,
from the C<daizu:alt> property of the image file.  This allows you to
store appropriate alternative text with the image so that it can be reused
automatically whenever the image is used.

An C<alt> attribute is added to all images that don't have one.  If there
is no C<daizu:alt> property, or if the image isn't stored in Daizu, then
an empty value is used because HTML requires that the attribute be present.

=item title

If there isn't already a C<title> attribute then one might be added
using the value of the C<dc:title> property of the image file, or if
that doesn't exist then the C<dc:description> property.  If the image
doesn't have either then this attribute isn't added.

Special case: this property isn't added if the image file is the same
file as the article being filtered.  This happens when you publish an
image as an article using L<Daizu::Plugin::PictureArticle>.  In that
case the title and description of the image file will be displayed in
the article just above the image itself, so there seems little point
repeating them.

=back

=head1 CONFIGURATION

To turn on this plugin, include the following in your Daizu CMS configuration
file:

=for syntax-highlight xml

    <plugin class="Daizu::Plugin::ImageMetadata" />

=head1 METHODS

=over

=item Daizu::Plugin::ImageMetadata-E<gt>register($cms, $whole_config, $plugin_config, $path)

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

=cut

sub filter_article
{
    my (undef, $cms, $file, $doc) = @_;
    my $wc_id = $file->{wc_id};
    my $db = $cms->{db};

    # Search for heading elements and add the anchors.
    for my $elem ($doc->findnodes(qq{
        //*[namespace-uri() = 'http://www.w3.org/1999/xhtml' and
            local-name() = 'img']
    }))
    {
        my $url = $elem->getAttribute('src');
        if (!defined $url || $url !~ /\S/) {
            warn "<img> in $file->{path} has missing or bad 'src' attribute\n";
            next;
        }
        $url = URI->new($url)->abs($file->permalink);

        # Try to find the image file being referred to.
# TODO - url update problem
        my ($guid_id, $method, $argument) = db_select($db, 'url',
            { wc_id => $wc_id, url => $url },
            qw( guid_id method argument ),
        );

        # If the image file isn't known to Daizu then we can't do much with
        # this, but we do add an empty 'alt' attribute if necessary to make
        # it valid.  We also skip image URLs published in ways we don't
        # understand.
        if (!defined $guid_id ||
            ($method ne 'unprocessed' && $method ne 'scaled_image'))
        {
            $elem->setAttribute(alt => '')
                unless $elem->hasAttribute('alt');
            next;
        }

        # If the URL is a 'scaled_image' one (for an automatically generated
        # thumbnail image) then we need to get the width, height, and possibly
        # the GUID ID of the actual image file, from the URL's argument.
        my ($width, $height);
        if ($method eq 'scaled_image') {
            if ($argument !~ /^(\d+) (\d+)(?: (\d+))?$/) {
                warn "bad scaled_image argument '$argument'";
                next;
            }
            $width = $1;
            $height = $2;
            $guid_id = $3 if defined $3;
        }

        my ($img_id) = db_row_id($db, 'wc_file',
            wc_id => $wc_id,
            guid_id => $guid_id,
        );
        if (!defined $img_id) {
            warn "image at '$url' not in working copy";
            next;
        }
        my $img = Daizu::File->new($cms, $img_id);

        if ($method eq 'unprocessed') {
            $width = $img->{image_width};
            $height = $img->{image_height};
        }

        # Add 'width' and 'height' attributes.
        if (!$elem->hasAttribute('width') && !$elem->hasAttribute('height') &&
            defined $width && defined $height)
        {
            $elem->setAttribute(width => $width);
            $elem->setAttribute(height => $height);
        }

        # Add 'alt' attribute.
        if (!$elem->hasAttribute('alt')) {
            my $alt = $img->property('daizu:alt');
            $elem->setAttribute(alt => (defined $alt ? $alt : ''));
        }

        # Add 'title' attribute.  This isn't done for PictureArticle content.
        if (!$elem->hasAttribute('title') && $img->{id} != $file->{id}) {
            my $title = $img->title;
            $title = $img->description unless defined $title;
            $elem->setAttribute(title => $title) if defined $title;
        }
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
