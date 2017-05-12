package Daizu::Plugin::DisplayPicture;
use warnings;
use strict;

use Carp qw( croak );
use Carp::Assert qw( assert DEBUG );
use Encode qw( decode );
use Math::Round qw( round );
use Encode qw( encode );
use Daizu;
use Daizu::Util qw(
    trim display_byte_size
    db_row_id db_select
    add_xml_elem xml_attr xml_croak
);

=head1 NAME

Daizu::Plugin::DisplayPicture - display scaled-down versions of images in articles

=head1 DESCRIPTION

TODO - refactor this to share code with PictureArticle.

This plugin filters articles looking for the special element
C<daizu:display-picture> and replacing it with suitable markup
to render the image nicely in the middle of the page.  If the image
file referred to is too big then it includes a scaled-down version
in the page 

Note that this plugin is very similar in effect to the
L<Daizu::Plugin::PictureArticle> one.  The difference is that it
allows any article to have pictures displayed in that way, and
there can be more than one of them.  The PictureArticle plugin is
for displaying a single image, where that image (and its metadata)
constitutes the whole article.

This example page has several images displayed using this plugin:

L<http://ungwe.org/blog/2002/12/29/20:21/>

To use this plugin, turn it on in the configuration file and then
add markup like this to your articles (assuming you're writing them
in XHTML):

=for syntax-highlight xml

    <daizu:display-picture filename="photo.jpg"/>

=head1 CONFIGURATION

TODO - this section is essentially the same as the corresponding one
in the PictureArticle documentation, so I should probably just refer to that.

To turn on this plugin, include the following in your Daizu CMS configuration
file:

=for syntax-highlight xml

    <plugin class="Daizu::Plugin::DisplayPicture" />

By default it will ensure that the image included in the page will
not be more than 600 pixels wide or 600 pixels high.  The thumbnail
image will have the suffix I<-thm> added to its URL just before the
file extension.  You can change these settings in the configuration
file as follows:

=for syntax-highlight xml

    <plugin class="Daizu::Plugin::DisplayPicture">
     <thumbnail max-width="400" min-height="400"
                filename-suffix="-small"/>
    </plugin>

This example limits included images to 400 pixels on a side, and
will use I<-small> as the suffix on the filename.

If the C<thumbnail> element is present at all then the C<max-width>
and C<max-height> values will default to unlimited size.  This means
that you can specify a maximum width but leave the height unbounded.

You can use different configuration for different websites, or parts
of websites, by providing multiple C<plugin> elements in the configuration
file: a default one and others in C<config> elements with paths.

=cut

our $DEFAULT_THUMBNAIL_MAX_WIDTH = 600;
our $DEFAULT_THUMBNAIL_MAX_HEIGHT = 600;
our $DEFAULT_THUMBNAIL_FILENAME_SUFFIX = '-thm';

# This is done on demand when it's needed.
sub _parse_config
{
    my ($self) = @_;
    return if $self->{config_parsed};

    my $config = $self->{config};
    my $config_filename = $self->{cms}{config_filename};
    my ($elem, $extra) = $config->getChildrenByTagNameNS($Daizu::CONFIG_NS,
                                                         'thumbnail');
    xml_croak($config_filename, $extra, "only one <thumbnail> element allowed")
        if defined $extra;

    if (!defined $elem) {
        # If there's no 'thumbnail' element, fall back to defaults.
        $self->{max_width} = $DEFAULT_THUMBNAIL_MAX_WIDTH;
        $self->{max_height} = $DEFAULT_THUMBNAIL_MAX_HEIGHT;
        $self->{thumbnail_filename_suffix} = $DEFAULT_THUMBNAIL_FILENAME_SUFFIX;
    }
    else {
        # Extract attributes from 'thumbnail' element.
        my $max_wd = trim(xml_attr($config_filename, $elem, 'max-width', ''));
        my $max_ht = trim(xml_attr($config_filename, $elem, 'max-height', ''));
        for ($max_wd, $max_ht) {
            if (!defined $_ || $_ eq '') {
                $_ = undef;
                next;
            }
            xml_croak($config_filename, $elem,
                      "attribute on element <thumbnail> should be a number")
                unless /^\d+$/;
        }

        $self->{max_width} = $max_wd;
        $self->{max_height} = $max_ht;

        $self->{thumbnail_filename_suffix} =
            trim(xml_attr($config_filename, $elem, 'filename-suffix',
                          $DEFAULT_THUMBNAIL_FILENAME_SUFFIX));
        xml_croak($config_filename, $elem, "filename-suffix must not be empty")
            if $self->{thumbnail_filename_suffix} eq '';
    }

    $self->{config_parsed} = 1;
}

=head1 METHODS

=over

=item Daizu::Plugin::DisplayPicture-E<gt>register($cms, $whole_config, $plugin_config, $path)

Registers the plugin to filter articles.

=cut

sub register
{
    my ($class, $cms, $whole_config, $plugin_config, $path) = @_;
    my $self = bless { config => $plugin_config }, $class;
    $cms->add_html_dom_filter($path, $self => 'filter_article');
}

=item $self-E<gt>filter_article($cms, $file, $doc)

Do the actual filtering on the content in C<$doc>.

This returns the same C<$doc> value, possibly with modifications.
It also returns the extra URLs for any automatically-generated thumbnail
images which are to be used.

=cut

sub filter_article
{
    my ($self, $cms, $file, $doc) = @_;
    $self->_parse_config;
    my $db = $cms->db;

    my @extra_url;

    for my $elem ($doc->findnodes(qq{
        //*[namespace-uri() = '$Daizu::HTML_EXTENSION_NS' and
            local-name() = 'display-picture']
    }))
    {
        my $filename = $elem->getAttribute('filename');
        croak "<daizu:display-picture> requires 'filename' attribute"
            unless defined $filename;
        my $pic_file = $file->file_at_path($filename);

        # Size of the displayed picture.
        my ($pic_wd, $pic_ht) = ($pic_file->{image_width},
                                 $pic_file->{image_height});
        croak "size of display-picture image file not available in database"
            unless defined $pic_wd && defined $pic_ht;

        my $pic_url = $pic_file->permalink;
        croak "display-picture image file has no URL"
            unless defined $pic_url;

        # URL of the thumbnail image, if any.
        my $thm_url = $pic_url;
        my $filename_suffix = $self->{thumbnail_filename_suffix};
        $thm_url =~ s!\.([^/.]+)$!$filename_suffix.$1!
            or $thm_url .= $filename_suffix;

        # Does the thumbnail exist in the repository, and if so how big is it.
# TODO - this won't work, because URL updating hasn't been done by the time the article is loaded.  This needs to be based on filename not URL, then it can generate the URL from that once it has found the image file.
        my ($thm_guid_id) = db_select($db, 'url',
            { url => $thm_url, status => 'A' },
            'guid_id',
        );
        $thm_guid_id = undef
            if defined $thm_guid_id && $thm_guid_id == $file->{guid_id};
        my ($thm_exists, $thm_wd, $thm_ht);
        if (defined $thm_guid_id) {
            ($thm_exists, $thm_wd, $thm_ht) = db_select($db, wc_file => {
                wc_id => $file->{wc_id},
                guid_id => $thm_guid_id,
            }, qw( 1 image_width image_height ));
            croak "thumbnail '$thm_url' doesn't have size recorded in database"
                if $thm_exists && (!defined $thm_wd || !defined $thm_ht);
        }

        # How big is the thumbnail allowed to be, if there's a limit.
        my $max_wd = $self->{max_width};
        $max_wd = $pic_wd unless defined $max_wd;
        my $max_ht = $self->{max_height};
        $max_ht = $pic_ht unless defined $max_ht;

        # If there is no thumbnail provided for us, and the article image is too
        # big, then add add our own thumbnail URL.
        if (!$thm_exists && ($pic_wd > $max_wd || $pic_ht > $max_ht)) {
            $thm_wd = $pic_wd unless defined $thm_wd;
            $thm_ht = $pic_ht unless defined $thm_ht;

            my $x_mul = $thm_wd / $max_wd;
            my $y_mul = $thm_ht / $max_ht;
            if ($x_mul > $y_mul) {
                $thm_wd = $max_wd;
                $thm_ht = round($thm_ht / $x_mul);
            }
            else {
                $thm_wd = round($thm_wd / $y_mul);
                $thm_ht = $max_ht;
            }
            assert($thm_wd <= $max_wd && $thm_ht <= $max_ht) if DEBUG;
            assert($thm_wd == $max_wd || $thm_ht == $max_ht) if DEBUG;

            push @extra_url, {
                url => $thm_url,
                type => $pic_file->{content_type},
                generator => 'Daizu::Gen',
                method => 'scaled_image',
                argument => "$thm_wd $thm_ht $pic_file->{guid_id}",
            };
            $thm_exists = 1;
        }

        # Create the article content.
        my $img = XML::LibXML::Element->new('img');
        $img->setAttribute(src => ($thm_exists ? $thm_url : $pic_url));

        my $alt = $elem->getAttribute('alt');
        $alt = $pic_file->property('daizu:alt')
            unless defined $alt;
        $img->setAttribute(alt => (defined $alt ? $alt : ''));

        $img->setAttribute(width => $thm_wd) if $thm_wd;
        $img->setAttribute(height => $thm_ht) if $thm_ht;

        my $img_block = $doc->createElementNS('http://www.w3.org/1999/xhtml',
                                              'div');
        $img_block->setAttribute(class => 'display-picture');

        if ($thm_exists) {
            add_xml_elem($img_block, 'a', $img, href => $pic_url);
            add_xml_elem($img_block, 'br');
            # Since we're linking to the full size image, provide some details
            # about it, mainly as a warning if it's really big.
            my $desc = "full size: $pic_wd\xD7$pic_ht, " .
                       display_byte_size($pic_file->{data_len});
            $desc = encode('UTF-8', $desc, Encode::FB_CROAK);
            add_xml_elem($img_block, 'a', $desc, href => $pic_url);
        }
        else {
            # Don't provide a link to the image if it's the same file as we're
            # including directly in the page.
            $img_block->appendChild($img);
        }

        $elem->replaceNode($img_block);
    }

    return {
        content => $doc,
        extra_urls => \@extra_url,
    };
}

=back

=head1 COPYRIGHT

This software is copyright 2006 Geoff Richards E<lt>geoff@laxan.comE<gt>.
For licensing information see this page:

L<http://www.daizucms.org/license/>

=cut

1;
# vi:ts=4 sw=4 expandtab
