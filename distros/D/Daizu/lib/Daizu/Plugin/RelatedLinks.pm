package Daizu::Plugin::RelatedLinks;
use warnings;
use strict;

use Encode qw( decode );
use Carp::Assert qw( assert DEBUG );
use Daizu::Util qw( trim );

=head1 NAME

Daizu::Plugin::RelatedLinks - add information to 'img' elements

=head1 DESCRIPTION

This plugin adds a box in the 'extras-col' (the right-hand column of
each page) for articles with a C<daizu:links> property.

Warning: this plugin is experimental and is almost certain to change
the way it works later.  At a minimum the two text files it loads
are likely to become database tables.  The property name used might
also change.

There is a blog article discussing the design of this feature,
and also providing an example of what the related links look like:

L<http://www.daizucms.org/blog/2006/11/related-links/>

To use this you add a property called C<daizu:links> to an article
file.  This should contain one or more URLs separated by whitespace
(probably best to put them on separate lines).  The URLs must be
listed in a file called I<_hide/links.txt>, which contains the following
tab-separated fields:

=over

=item *

The name identifying the source (website) which the link refers to.
This should be a short name which doesn't contain whitespace, and
which must exist in the sources file described below.

=item *

The URL, which must exactly match (as a simple string) the URL used
in the property.

=item *

The title to use for the link, which should be text encoded as UTF-8.

=item *

Optionally, a short description of the format of the information at the
URL.  This can act as a warning to users of what they should expect.
Suitable values would be 'PDF' or 'Flash'.  It will be displayed in
parentheses after the link's title.

If you don't want to include a format for a link you don't need the
last tab separator either.

=back

The name of the link source is looked up in a separate text file
called I<_hide/link-sources.txt> which is in a similar format, with
the following fields:

=over

=item *

The name of the source, used to identify it in the I<links.txt> file.

=item *

The source's URL, which should probably be the homepage of the website.

=item *

The title of the source, which is used as the cover text of its link.

=back

If the URLs of the link itself and the source are the same then only
one link is shown, using the title of the link.

=head1 CONFIGURATION

To turn on this plugin, include the following in your Daizu CMS configuration
file:

=for syntax-highlight xml

    <plugin class="Daizu::Plugin::RelatedLinks" />

=head1 METHODS

=over

=item Daizu::Plugin::RelatedLinks-E<gt>register($cms, $whole_config, $plugin_config, $path)

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

This doesn't actually modify the content, just adds an 'extra template'
if there is a C<daizu:links> property on the file.

=cut

sub filter_article
{
    my (undef, undef, $file, $doc) = @_;
    my @extra_template;

    # TODO - maybe rename this 'daizu:related-links'.
    push @extra_template, 'plugin/relatedlinks_extras.tt'
        if $file->property('daizu:links');

    return {
        content => $doc,
        extra_templates => \@extra_template,
    };
}

=item Daizu::Plugin::RelatedLinks-E<gt>links_for_file($file)

This is called by the template I<plugin/relatedlinks_extras.tt> to
get the links which should be provided.  If that template is used then
this is expected to return at least one related link.  C<$file>
should be the article file whose page is being generated.

This is a class method so that it can be called using the
L<Template::Plugin::Class> module from the template.

This gets the URLs from the C<daizu:links> property and finds the
extra metadata for them in the files I<_hide/links.txt> and
I<_hide/link-sources.txt>.  Those files must exist and must contain
information about any URLs referenced in the property, and any link
'sources' referenced for those URLs.

Returns a reference to an array of hashes containing the URLs and
titles.

=cut

sub links_for_file
{
    my ($class, $file) = @_;

    my $link_sources = _read_link_sources($file);
    my $links = _read_links($file, $link_sources);

    my @links;
    for (split ' ', $file->property('daizu:links')) {
        die "$file->{path}: link '$_' doesn't exist\n"
            unless exists $links->{$_};
        my $link = $links->{$_};
        my $source = $link_sources->{$link->{source}};
        push @links, {
            url => $_,
            title => $link->{title},
            format => $link->{format},
            source_url => $source->{url},
            source_title => $source->{title},
        };
    }

    assert(@links >= 1) if DEBUG;   # shouldn't be called unless there are some
    return \@links;
}

sub _read_link_sources
{
    my ($file) = @_;
    my $filename = '_hide/link-sources.txt';
    my $txt_file = $file->wc->file_at_path($filename)
        or die "file '$filename' not found in content repository";
    my $txt = $txt_file->data;
    open my $fh, '<', $txt or die;

    my %sources;
    while (<$fh>) {
        chomp;
        /^(\S+)\t(\S+)\t([^\t]+)$/
            or die "$filename:$.: bad line\n";
        my $name = $1;
        my $url = $2;
        my $title = decode('UTF-8', trim($3), Encode::FB_CROAK);
        $sources{$name} = {
            url => $url,
            title => $title,
        };
    }

    return \%sources;
}

sub _read_links
{
    my ($file, $link_sources) = @_;
    my $filename = '_hide/links.txt';
    my $txt_file = $file->wc->file_at_path($filename)
        or die "file '$filename' not found in content repository";
    my $txt = $txt_file->data;
    open my $fh, '<', $txt or die;

    my %links;
    while (<$fh>) {
        chomp;
        /^(\S+)\t(\S+)\t([^\t]+)(?:\t([^\t]+))?$/
            or die "$filename:$.: bad line\n";
        die "$filename:$.: link source '$1' doesn't exist"
            unless exists $link_sources->{$1};
        my $source = $1;
        my $url = $2;
        my $title = decode('UTF-8', trim($3), Encode::FB_CROAK);
        my $format = trim($4);
        $format = decode('UTF-8', $format, Encode::FB_CROAK)
            if defined $format;
        $links{$url} = {
            source => $source,
            title => $title,
            format => $format,
        };
    }

    return \%links;
}

=back

=head1 COPYRIGHT

This software is copyright 2006 Geoff Richards E<lt>geoff@laxan.comE<gt>.
For licensing information see this page:

L<http://www.daizucms.org/license/>

=cut

1;
# vi:ts=4 sw=4 expandtab
