package Daizu::Gen::Blog;
use warnings;
use strict;

use base 'Daizu::Gen';

use DateTime;
use Carp::Assert qw( assert DEBUG );
use Encode qw( encode decode );
use Daizu;
use Daizu::Feed;
use Daizu::Util qw(
    trim like_escape validate_number
    validate_date parse_db_datetime db_datetime
    db_row_exists db_select db_select_col
    xml_attr xml_croak
);

=head1 NAME

Daizu::Gen::Blog - generator for publishing a blog

=head1 DESCRIPTION

To publish a blog using Daizu CMS, create a top-level directory for
it and set that directory's generator class to this one.

This class is a subclass of L<Daizu::Gen>.  The ways in which it
differs are described below.

=head2 Article URLs

Article URLs are partially date-based.  Articles can be stored anywhere
inside the blog directory (the one with this generator class), providing
their generator isn't overridden.  You can use an arbitrary directory
structure to organise your articles, but the URL will always be of this
format:

    .../YYYY/MM/slug/

where the first two parts are based on the 'published' date of the article.
'slug' is either the base part of its filename (everything but the last file
extension) or if it is an '_index' file then the name of its parent directory.
Any other directories, which don't directly contain an '_index' file, won't
affect URLs at all.

Apart from having slightly different URLs than normal, blog articles are
treated like any other articles.

=head2 Homepage

The blog directory will generate a homepage listing recent articles.
Articles with C<daizu:fold> elements in can be displayed specially,
with only the content above the fold shown in the homepage (and date-based
archive pages described below), with a 'Read more' link to the full article.

=head2 Feeds

XML feeds of the latest articles will be generated, either in Atom or RSS
format.  See L</CONFIGURATION> below for information about how to set these
up.  There will always be at least one feed generated for each blog.

=head2 Archive pages

For each year and month in which at least one article was published (based
on the 'published' date) there will be an archive page generated listing
those articles.

=head1 CONFIGURATION

The configuration file can be used to set up the XML feeds for each blog
in various ways.  If you don't configure any feeds then you'll get a default
one.  The default feed will be an S<Atom 1.0> format one, which will include
the content of articles above the 'fold' (or all the content when there
is no fold), and will have the URL 'feed.atom' relative to the URL of the
blog directory.

The configuration can also change the number of articles shown on the blog
homepage.  The default S<is 10>.

If you want to change these defaults, for example to add an RSS feed as
well as the Atom one, then you'll need to add C<feed> elements to the
generator configuration for the blog directory, something like this:

=for syntax-highlight xml

    <generator class="Daizu::Gen::Blog" path="ungwe.org/blog">
     <homepage num-articles="8" />
     <feed format="atom" type="content" />
     <feed format="rss2" type="description" url="qefsblog.rss" />
    </generator>

There can be at most one C<homepage> element, which must have an attribute
C<num-articles> containing a number.  The minimum value S<is 1>.

Each feed element can have the following attributes:

=over

=item format

Required.  Either C<atom> to generate an S<Atom 1.0> feed, or C<rss2>
to generate an S<RSS 2.0> feed.  See L<Daizu::Feed/FEED FORMATS> for
details.

=item type

The type of content to include with each item in the feed.  The default
is C<snippet>, which means to include the full content of each article,
unless the article contains a 'fold' (a C<daizu:fold> element) in which
case only the content above the fold will be included in the feed.
A page break (a C<daizu:page> element) will also be counted as a fold
if no C<daizu:fold> element is found on the first page.
If only part of the article is shown then a link is provided to the
URL where the full article can be read.

The alternative types are C<content> which includes the full content
of each article regardless of whether it as a fold or page break or not, and
C<description> which never includes the full content, but only the
description (from the C<dc:description> property) if available.
If there is no description, a sample of text from the start of the article
will be used instead.

See L<Daizu::Feed/FEED TYPES> for details of how this information is
encoded in the different feed formats.

=item url

The URL where the feed will be published, usually a relative path which
will be resolved against the URL of the blog directory (homepage).

The default is either C<feed.atom> or C<feed.rss>, depending on the
'format' value.

=item size

The number of articles which should be included in the feed.  The default
depends on the 'type' value.

=back

=cut

my $DEFAULT_HOMEPAGE_NUM_ARTICLES = 10;

our $DEFAULT_FEED_FORMAT = 'atom';
our $DEFAULT_FEED_TYPE = 'snippet';
our %DEFAULT_FEED_SIZE = (
    description => 14,
    snippet => 14,
    content => 8,
);
our %FEED_FORMAT_INFO = (
    atom => { default_url => 'feed.atom', mime_type => 'application/atom+xml' },
    rss2 => { default_url => 'feed.rss',  mime_type => 'application/rss+xml' },
);

=head1 METHODS

=over

=item Daizu::Gen::Blog-E<gt>new(%options)

Create a new generator object for a blog.  The options are the same as
for L<the Daizu::Gen constructor|Daizu::Gen/Daizu::Gen-E<gt>new(%options)>.

=cut

sub new
{
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    $self->{blog_homepage_num_articles} = $DEFAULT_HOMEPAGE_NUM_ARTICLES;

    # Load configuration, if there is any.
    my @feeds;
    if (my $conf = $self->{config_elem}) {
        my $config_filename = $self->{cms}{config_filename};
        for my $elem ($conf->getChildrenByTagNameNS($Daizu::CONFIG_NS, 'feed'))
        {
            my $format = trim(xml_attr($config_filename, $elem, 'format'));
            xml_croak($config_filename, $elem, "unknown feed format '$format'")
                unless exists $FEED_FORMAT_INFO{$format};
            my $type = trim(xml_attr($config_filename, $elem, 'type',
                                     $DEFAULT_FEED_TYPE));
            my $size = trim(xml_attr($config_filename, $elem, 'size',
                                     $DEFAULT_FEED_SIZE{$type}));
            xml_croak($config_filename, $elem, "bad feed size '$size'")
                unless validate_number($size);
            my $url = trim(xml_attr($config_filename, $elem, 'url',
                                    $FEED_FORMAT_INFO{$format}{default_url}));
            push @feeds, {
                format => $format,
                type => $type,
                size => $size,
                url => $url,
            };
        }

        my $homepage_conf_found;
        for my $elem ($conf->getChildrenByTagNameNS($Daizu::CONFIG_NS,
                                                    'homepage'))
        {
            xml_croak($config_filename, $elem, 'too many <homepage> elements')
                if $homepage_conf_found;
            $homepage_conf_found = 1;

            my $num = trim(xml_attr($config_filename, $elem, 'num-articles'));
            xml_croak($config_filename, $elem, "bad value for 'num-articles'")
                unless $num =~ /^\d+$/ && $num >= 1;
            $self->{blog_homepage_num_articles} = $num;
        }
    }

    # If no feeds are specified, provide a snippet Atom one as a default.
    if (!@feeds) {
        push @feeds, {
            format => $DEFAULT_FEED_FORMAT,
            type => $DEFAULT_FEED_TYPE,
            size => $DEFAULT_FEED_SIZE{$DEFAULT_FEED_TYPE},
            url => $FEED_FORMAT_INFO{$DEFAULT_FEED_FORMAT}{default_url},
        };
    }

    $self->{feeds} = \@feeds;

    return $self;
}

=item $gen-E<gt>custom_base_url($file, $base)

See the L<custom_base_url() method in Daizu::Gen|Daizu::Gen/$gen-E<gt>custom_base_url($file)>
for details.  The only differences in behaviour
for blogs are that article files (and directories which contain articles
called things like I<_index.html>) get special URLs based on the publication
date of the article and the 'slug' (file or directory name), based
at the URL of the blog directory itself.

Unprocessed files get the same URLs as L<Daizu::Gen> would give them,
unless they are inside a directory which 'belongs' to an article.
That is, if a directory has a child called I<_index.html> or similar,
then all the other non-article files in that directory, including
any in subdirectories to any level, will all get URLs which start
with the article's URL, followed by their path below the article's
directory.  So if an article is in a file called I<blog/foo/_index.html>
and there is also an image file inside I<foo> then it will get a URL
like I<2006/05/foo/image.jpg>, which means the article can include it
with a relative path like I<image.jpg>.  These relative URLs will be
adjusted as necessary when used in feeds and index pages.

=cut

sub custom_base_url
{
    my ($self, $file) = @_;

    # Don't do anything special for the root 'blog directory'.
    return $self->SUPER::custom_base_url($file)
        if $file->{id} == $self->{root_file}{id};

    # The base URL for blog as a whole.
    my $blog_url = $self->base_url($self->{root_file});
    return undef unless defined $blog_url;

    # Blog articles have date-based URLs.
    if ($file->{article}) {
        my $archive_date = $file->issued_at->strftime('%Y/%m');
        my $slug;
        if ($file->{name} =~ /^_index\./) {
            $slug = $file->parent->{name};
        }
        else {
            $slug = $file->{name};
            $slug =~ s/\.[^.]+\z//;
        }
        return URI->new("$archive_date/$slug/")->abs($blog_url);
    }

    # Handle directories which 'belong' to an article specially.
    # They get a URL identical to the article itself, so that any
    # ancillary files in the directory will be published alongside the
    # article.
    if ($file->{is_dir}) {
        my ($article_id) = $self->{cms}{db}->selectrow_array(qq{
            select id
            from wc_file
            where parent_id = ?
              and article
              and name ~ '^_index\\\.'
              and path !~ '(^|/)($Daizu::HIDING_FILENAMES)(/|\$)'
            order by name
            limit 1
        }, undef, $file->{id});
        return $self->base_url(Daizu::File->new($self->{cms}, $article_id))
            if defined $article_id;
    }

    return $self->SUPER::custom_base_url($file);
}

=item $gen-E<gt>root_dir_urls_info($file)

Return the URLs generated by C<$file> (a L<Daizu::File> object),
which will be the blog directory itself.  This overrides the
L<root_dir_urls_info() method in
Daizu::Gen|Daizu::Gen/$gen-E<gt>root_dir_urls_info($file)>, although
it also calls that version in case the blog directory is home to a
Google sitemap.  It adds URLs with the following methods:

=over

=item homepage

Exactly one of these, with no argument.

=item feed

One for each configured feed.  There is always at least one of these,
and there can be as many as you want.  The argument will consist of the
feed format, the feed type, and the number of entries to include, each
separated by a space.

=item year_archive

URLs like '2006/', with the year number as the argument.

=item month_archive

URLs like '2006/05/' with the year and month numbers, separated by
a space, as the argument.  In the argument the month to two digits
(with leading zeroes added if necessary) because some of the code
relies on the month archive argument values sorting in the right order.

=back

=cut

sub root_dir_urls_info
{
    my ($self, $file) = @_;
    my @url = $self->SUPER::root_dir_urls_info($file);

    # Blog homepage
    push @url, { url => '', method => 'homepage', type => 'text/html' };

    # Feeds.
    for (@{$self->{feeds}}) {
        push @url, {
            url => $_->{url},
            method => 'feed',
            argument => "$_->{format} $_->{type} $_->{size}",
            type => $FEED_FORMAT_INFO{$_->{format}}{mime_type},
        };
    }

    # Yearly and monthly archive pages.
    my $sth = $self->{cms}{db}->prepare(qq{
        select distinct extract(year  from issued_at) as year,
                        extract(month from issued_at)
        from wc_file
        where wc_id = ?
          and article
          and root_file_id = ?
          and not retired
          and path !~ '(^|/)($Daizu::HIDING_FILENAMES)(/|\$)'
        order by year
    });
    $sth->execute($file->{wc_id}, $self->{root_file}{id});

    my $last_year;
    while (my ($year, $month) = $sth->fetchrow_array) {
        my $padded_year = sprintf '%04d', $year;
        my $padded_month = sprintf '%02d', $month;
        if (!defined $last_year || $year != $last_year) {
            push @url, {
                url => "$padded_year/",
                method => 'year_archive',
                argument => $padded_year,
                type => 'text/html',
            };
            $last_year = $year;
        }
        push @url, {
            url => "$padded_year/$padded_month/",
            method => 'month_archive',
            argument => "$padded_year $padded_month",
            type => 'text/html',
        };
    }

    return @url;
}

=item $gen-E<gt>article_template_variables($file, $url_info)

This method is overridden to provide extra links to be output in the
I<head/meta.tt> template.  It always returns a C<head_links> value
containing a link to the blogs first feed, and for articles it also
returns links to the previous and next articles.

=cut

sub article_template_variables
{
    my ($self, $file, $url_info) = @_;
    my $cms = $self->{cms};

    # Call the Daizu::Gen version for articles and the home page, to get
    # description and keywords metadata.  We don't call it for other pages
    # because that would give all archive pages the description intended
    # for the blog homepage.
    my $url_method = $url_info->{method};
    my $var = $url_method eq 'article' || $url_method eq 'homepage'
            ? $self->SUPER::article_template_variables($file, $url_info)
            : {};

    # Add a <link> for the first feed URL.
    my @links;
    for ($self->urls_info($self->{root_file})) {
        next unless $_->{method} eq 'feed';

        my $feed_title = $self->{root_file}->title;
        $feed_title = defined $feed_title ? "Feed for $feed_title"
                                          : 'Blog feed';
        push @links, {
            rel => 'alternate',
            href => $_->{url},
            type => $_->{type},
            title => $feed_title,
        };
        last;
    }
    assert(@links) if DEBUG;

    # Links to previous or next page.
    my $root_file_id = $self->{root_file}{id};
    for my $rel (qw( prev next )) {
        my $cmp =   $rel eq 'prev' ? '<'    : '>';
        my $order = $rel eq 'prev' ? 'desc' : 'asc';

        # Article pages.
        if ($url_method eq 'article') {
            my ($url, $type, $title) = _nextprev_article(
                $cms->{db}, $file->{wc_id}, $root_file_id, $file->issued_at,
                $cmp);
            next unless defined $url;

            push @links, {
                rel => $rel,
                href => URI->new($url),
                type => $type,
                title => decode('UTF-8', $title, Encode::FB_CROAK),
            };
        }

        # Archive pages.
        for my $method (qw( year_archive month_archive )) {
            next unless $url_method eq $method;
            my ($url, $arg, $type) = $cms->{db}->selectrow_array(qq{
                select url, argument, content_type
                from url
                where wc_id = ?
                  and guid_id = ?
                  and method = ?
                  and status = 'A'
                  and argument $cmp ?
                order by argument $order
                limit 1
            }, undef, $file->{wc_id}, $file->{guid_id}, $method,
                      $url_info->{argument});
            next unless defined $url;

            $url = URI->new($url);
            my $title_method = "${method}_title";
            push @links, {
                rel => $rel,
                href => $url,
                type => $type,
                title => $self->$title_method($url, split ' ', $arg),
            };
        }
    }

    push @{$var->{head_links}}, @links
        if @links;

    return $var;
}

=item $gen-E<gt>article_template_overrides($file, $url_info)

This method is overridden to adjust the display of article metadata for
blogs, since blog articles should display their author and publication
time.

=cut

sub article_template_overrides
{
    return {
        'article_meta.tt' => 'blog/article_meta.tt',
    };
}

=item $gen-E<gt>url_updates_for_file_change($wc_id, $guid_id, $file_id, $status, $changes)

See L<the baseclass documentation|Daizu::Gen/$gen-E<gt>url_updates_for_file_change($wc_id, $guid_id, $file_id, $status, $changes)>
for details.

This implementation causes the blog directory to be updated if there are
any changes which might mean different URLs are produced for things like
archive pages.  It also update URLs for articles inside a directory
belonging to the file if its generator is changed, which in some
circumstances might mean they get a different URL.

=cut

sub url_updates_for_file_change
{
    my ($self, $wc_id, $guid_id, $file_id, $status, $changes) = @_;
    my @update = @{ $self->SUPER::url_updates_for_file_change(
                        $wc_id, $guid_id, $file_id, $status, $changes) };

    # There's no need to update the root file if we're it, because Daizu
    # will already have done that.
    # TODO - this won't work if the root file is fake (if $status='D')
    my $root_guid_id = $self->{root_file}{guid_id};
    return \@update
        if $guid_id == $root_guid_id;

    if ($status eq 'D') {
        push @update, $root_guid_id;
    }
    else {
        my $file = Daizu::File->new($self->{cms}, $file_id);

        # Maybe this article will require a new archive page to be created.
        if ($changes->{_new_article}) {
            my $issued = $file->issued_at;
            my $month_archive_exists = db_row_exists($self->{cms}{db}, 'url',
                wc_id => $wc_id,
                guid_id => $root_guid_id,
                method => 'month_archive',
                argument => sprintf('%04d %02d', $issued->year, $issued->month),
            );
            push @update, $root_guid_id
                if !$month_archive_exists;
        }

        # If the type of file changes between being an article and an
        # unprocessed file, that might change the URLs of files in its
        # directory, if it has a directory all to itself.
        # Note that we don't do this when a blog article is deleted.  In
        # that case any ancillary files have probably also been deleted,
        # and if they haven't the author is likely to do something with
        # them soon anyway, so they don't need to have their URLs changed
        # automatically.
        if ($changes->{_new_article} != $changes->{_old_article} &&
            $file->{name} =~ /^_index\./)
        {
            my $parent = $file->parent;
            assert(defined $parent) if DEBUG;   # not inside blog directory
            my $guids = $self->{cms}{db}->selectcol_arrayref(q{
                select guid_id
                from wc_file
                where wc_id = ?
                  and not is_dir
                  and id <> ?
                  and path like ?
            }, undef, $wc_id, $file_id, like_escape($parent->{path}) . '/%');
            push @update, @$guids;
        }
    }

    return \@update;
}

=item $gen-E<gt>publishing_for_file_change($wc_id, $guid_id, $file_id, $status, $changes)

See L<the baseclass documentation|Daizu::Gen/$gen-E<gt>publishing_for_file_change($wc_id, $guid_id, $file_id, $status, $changes)>
for details.

This implementation republishes archive pages to include new articles,
and the blog homepage and feed if necessary.  It also republishes articles
which might include a previous/next article link which would be affected
by the changes.

=cut

sub publishing_for_file_change
{
    my ($self, $wc_id, $guid_id, $file_id, $status, $changes) = @_;
    return [] if $guid_id == $self->{root_file}{guid_id};

    my $db = $self->{cms}{db};
    my @publish;

    my $new_issued = $changes->{_new_issued};
    my $old_issued = $changes->{_old_issued};

    my $root_file_id = $self->{root_file}{id};
    my $root_guid_id = $self->{root_file}{guid_id};

    if ($changes->{_new_article} || $changes->{_old_article}) {
        # Changes which may require the year and month archive pages to be
        # republished.
        if ($status ne 'M' ||
            (defined $old_issued && defined $new_issued &&
             ($old_issued->year != $new_issued->year ||
              $old_issued->month != $new_issued->month)) ||
            exists $changes->{_article_url} ||
            exists $changes->{'dc:title'} ||
            exists $changes->{'dc:description'})
        {
            # Republish the URLs for the year and month archive pages which the
            # article would appear in before and after the changes.
            for ($old_issued, $new_issued) {
                next unless defined;

                my $url = db_select($db, 'url', {
                    wc_id => $wc_id,
                    guid_id => $root_guid_id,
                    method => 'year_archive',
                    argument => sprintf('%04d', $_->year),
                    status => 'A',
                }, 'url');
                push @publish, $url if defined $url;

                $url = db_select($db, 'url', {
                    wc_id => $wc_id,
                    guid_id => $root_guid_id,
                    method => 'month_archive',
                    argument => sprintf('%04d %02d', $_->year, $_->month),
                    status => 'A',
                }, 'url');
                push @publish, $url if defined $url;
            }
        }

        my $max_issued = $new_issued;
        $max_issued = $old_issued
            if defined $old_issued && (!defined $new_issued ||
                                       $old_issued > $new_issued);
        my ($pos) = $db->selectrow_array(q{
            select count(*)
            from wc_file
            where wc_id = ?
              and root_file_id = ?
              and article
              and not retired
              and issued_at > ?
        }, undef, $wc_id, $root_file_id, db_datetime($max_issued));

        # Republish homepage if the article appears in it, or used to.
        push @publish, $self->{root_file}->permalink
            if $pos < $self->{blog_homepage_num_articles};

        # Republish any feeds which the article will, or did, appear in.
        {
            my $sth = $db->prepare(q{
                select url, argument
                from url
                where wc_id = ?
                  and guid_id = ?
                  and method = 'feed'
                  and status = 'A'
            });
            $sth->execute($wc_id, $root_guid_id);
            while (my ($url, $arg) = $sth->fetchrow_array) {
                my (undef, undef, $size) = split ' ', $arg;
                warn "bad feed argument '$arg'", next
                    unless defined $size && $size =~ /^\d+$/;
                next unless $pos < $size;
                push @publish, $url;
            }
        }

        # If necessary, republish the article pages before and after this one,
        # because they have should have links to it, which will include this
        # article's title as the cover text.
        my ($new_prev_url, $new_next_url);
        if (defined $new_issued) {
            ($new_prev_url) = _nextprev_article($db, $wc_id, $root_file_id,
                                                $new_issued, '<');
            ($new_next_url) = _nextprev_article($db, $wc_id, $root_file_id,
                                                $new_issued, '>');
        }
        my ($old_prev_url, $old_next_url);
        if (defined $old_issued) {
            ($old_prev_url) = _nextprev_article($db, $wc_id, $root_file_id,
                                                $old_issued, '<');
            ($old_next_url) = _nextprev_article($db, $wc_id, $root_file_id,
                                                $old_issued, '>');
        }
        if ($status ne 'M' ||
            exists $changes->{'dc:title'} ||
            exists $changes->{_article_url} ||
            (defined $old_issued &&
             ((defined $new_prev_url && defined $old_prev_url &&
               $new_prev_url ne $old_prev_url) ||
              (defined $new_next_url && defined $old_next_url &&
               $new_next_url ne $old_next_url))))
        {
            for ($new_prev_url, $new_next_url, $old_prev_url, $old_next_url) {
                next unless defined;
                push @publish, $_;
            }
        }
    }

    return \@publish;
}

=item $gen-E<gt>publishing_for_url_change($wc_id, $status, $old_url_info, $new_url_info)

See L<the baseclass documentation|Daizu::Gen/$gen-E<gt>publishing_for_url_change($wc_id, $status, $old_url_info, $new_url_info)>
for details.

This implementation causes all the archive pages, the homepage, and all
the articles to be republished if there are any URL changes which
would affect the navigation menu.  This will normally happen at most
once per month when a new month (and possibly year) entry needs to appear
in the menu.

=cut

sub publishing_for_url_change
{
    my ($self, $wc_id, $status, $old_url_info, $new_url_info) = @_;

    # We're only interested in pages which appear in the archive menus.
    my $important_change;
    for ($old_url_info, $new_url_info) {
        next unless defined;
        next unless $_->{method} =~ /^(?:homepage|year_archive|month_archive)$/;
        $important_change = 1;
    }
    return [] unless $important_change;

    return $self->{cms}{db}->selectcol_arrayref(q{
        select url
        from url
        where wc_id = ?
          and status = 'A'
          and ((guid_id = ? and method in ('homepage', 'year_archive',
                                           'month_archive'))
            or (root_file_id = ? and method = 'article'))
    }, undef, $wc_id, $self->{root_file}{guid_id}, $self->{root_file}{id});
}

=item $gen-E<gt>homepage($file, $urls)

Generate the output for the homepage, which will be an index page listing
recent articles.

=cut

sub homepage
{
    my ($self, $file, $urls) = @_;
    my $cms = $self->{cms};

    for my $url (@$urls) {
        my $sth = $cms->{db}->prepare(qq{
            select id
            from wc_file
            where wc_id = ?
              and article
              and root_file_id = ?
              and not retired
              and path !~ '(^|/)($Daizu::HIDING_FILENAMES)(/|\$)'
            order by issued_at desc, id desc
            limit ?
        });
        $sth->execute($file->{wc_id}, $self->{root_file}{id},
                      $self->{blog_homepage_num_articles});

        my @articles;
        while (my ($id) = $sth->fetchrow_array) {
            push @articles, Daizu::File->new($cms, $id);
        }

        $self->generate_web_page($file, $url, {
            %{ $self->article_template_overrides($file, $url) },
            'page_content.tt' => 'blog/homepage.tt',
        }, {
            %{ $self->article_template_variables($file, $url) },
            articles => \@articles,
            page_title => $file->title,
        });
    }
}

=item $gen-E<gt>feed($file, $url)

Generate output for a blog feed, in the appropriate format.

=cut

sub feed
{
    my ($self, $file, $urls) = @_;
    my $cms = $self->{cms};

    # Extract the feed configurations from the arguments, and find out how
    # many articles are needed for the largest feed.
    my $feeds = $self->{feeds};
    my $largest_size = 0;
    for my $url (@$urls) {
        my ($format, $type, $size) = split ' ', $url->{argument};
        $url->{feed_format} = $format;
        $url->{feed_type} = $type;
        $url->{feed_size} = $size;
        $largest_size = $size
            if $size > $largest_size;
    }

    # Get the articles, as many as needed for the largest feed.
    my $sth = $cms->{db}->prepare(qq{
        select id
        from wc_file
        where wc_id = ?
          and article
          and root_file_id = ?
          and not retired
          and path !~ '(^|/)($Daizu::HIDING_FILENAMES)(/|\$)'
        order by issued_at desc, id desc
        limit ?
    });
    $sth->execute($file->{wc_id}, $self->{root_file}{id}, $largest_size);

    my @articles;
    while (my ($id) = $sth->fetchrow_array) {
        push @articles, Daizu::File->new($cms, $id);
    }

    for my $url (@$urls) {
        my $feed = Daizu::Feed->new($cms, $file, $url->{url},
                                    $url->{feed_format}, $url->{feed_type});

        my $num_entries = 0;
        for my $article (@articles) {
            last if $num_entries == $url->{feed_size};
            $feed->add_entry($article);
            ++$num_entries;
        }

        # The XML is printed in canonical form to avoid some extraneous
        # namespace declarations in the <content> of the Atom feed.
        my $fh = $url->{fh};
        print $fh encode('UTF-8', $feed->xml->toStringC14N, Encode::FB_CROAK);
    }
}

=item $gen-E<gt>year_archive($file, $urls)

Generate a yearly archive page, listing all files published during
a given year.

=cut

sub year_archive
{
    my ($self, $file, $urls) = @_;
    my $cms = $self->{cms};

    for my $url (@$urls) {
        die "bad argument '$url->{argument}' for year archive URL"
            unless $url->{argument} =~ /^(\d+)$/;
        my $year = $1;

        my $sth = $cms->{db}->prepare(qq{
            select id, extract(month from issued_at), article_pages_url,
                   title, description, issued_at
            from wc_file
            where wc_id = ?
              and article
              and root_file_id = ?
              and not retired
              and path !~ '(^|/)($Daizu::HIDING_FILENAMES)(/|\$)'
              and extract(year from issued_at) = ?
            order by issued_at, id
        });
        $sth->execute($file->{wc_id}, $self->{root_file}{id}, $year);

        my @months;
        my $cur_month;
        my $cur_articles;
        while (my ($id, $month, $permalink, $title, $description, $issued_at)
                   = $sth->fetchrow_array)
        {
            if (!defined $cur_month || $cur_month != $month) {
                $cur_month = $month;
                $cur_articles = [];
                push @months, {
                    month_url => sprintf('%02d/', $month),
                    month_date => DateTime->new(year => $year, month => $month),
                    articles => $cur_articles,
                };
            }
            push @$cur_articles, {
                id => $id,
                permalink => $permalink,
                title => decode('UTF-8', $title, Encode::FB_CROAK),
                description => decode('UTF-8', $description, Encode::FB_CROAK),
                issued_at => parse_db_datetime($issued_at),
            };
        }

        $self->generate_web_page($file, $url, {
            %{ $self->article_template_overrides($file, $url) },
            'page_content.tt' => 'blog/year_index.tt',
        }, {
            %{ $self->article_template_variables($file, $url) },
            months => \@months,
            page_title => $self->year_archive_title($url->{url}, $year),
        });
    }
}

=item $gen-E<gt>year_archive_title($url, $year)

Return a title for a year archive page.  Override this
to change the kind of titles used.
C<$url> is the URL of the archive page for C<$year>, as a L<URI> object.

This default implementation returns something like 'Articles for 2006'.

=cut

sub year_archive_title
{
    my ($self, $url, $year) = @_;
    return "Articles for $year";
}

=item $gen-E<gt>year_archive_short_title($url, $year)

Return an abbreviated title for a year archive page.  Override this
to change the kind of titles used in the navigation menu.
C<$url> is the URL of the archive page for C<$year>, as a L<URI> object.

This default implementation returns the value of C<$year>.

=cut

sub year_archive_short_title
{
    my ($self, $url, $year) = @_;
    return $year;
}

=item $gen-E<gt>month_archive($file, $urls)

Generate a monthly archive page, listing the articles published during
a given year and month.

=cut

sub month_archive
{
    my ($self, $file, $urls) = @_;
    my $cms = $self->{cms};

    for my $url (@$urls) {
        die "bad argument '$url->{argument}' for month archive URL"
            unless $url->{argument} =~ /^(\d+)\s+(\d+)$/;
        my $year = $1;
        my $month = $2;

        my $sth = $cms->{db}->prepare(qq{
            select id, article_pages_url, title, description, issued_at
            from wc_file
            where wc_id = ?
              and article
              and root_file_id = ?
              and not retired
              and path !~ '(^|/)($Daizu::HIDING_FILENAMES)(/|\$)'
              and extract(year from issued_at) = ?
              and extract(month from issued_at) = ?
            order by issued_at, id
        });
        $sth->execute($file->{wc_id}, $self->{root_file}{id}, $year, $month);

        my @articles;
        while (my ($id, $permalink, $title, $description, $issued_at)
                   = $sth->fetchrow_array)
        {
            push @articles, {
                id => $id,
                permalink => $permalink,
                title => decode('UTF-8', $title, Encode::FB_CROAK),
                description => decode('UTF-8', $description, Encode::FB_CROAK),
                issued_at => parse_db_datetime($issued_at),
            };
        }

        $self->generate_web_page($file, $url, {
            %{ $self->article_template_overrides($file, $url) },
            'page_content.tt' => 'blog/month_index.tt',
        }, {
            %{ $self->article_template_variables($file, $url) },
            articles => \@articles,
            page_title => $self->month_archive_title($url->{url},
                                                     $year, $month),
        });
    }
}

=item $gen-E<gt>month_archive_title($url, $year, $month)

Return a title for a month archive page.  Override this
to change the kind of titles used.
C<$url> is the URL of the archive page for C<$year>, as a L<URI> object.

This default implementation returns something like 'Articles for October 2006',
with a non-breaking space between the month name and year.

=cut

sub month_archive_title
{
    my ($self, $url, $year, $month) = @_;
    return 'Articles for ' .
           DateTime->new(year => $year, month => $month)
                   ->strftime("\%B\xA0\%Y");    # September&nbsp;2006
}

=item $gen-E<gt>month_archive_short_title($url, $year, $month)

Return an abbreviated title for a month archive page.  Override this
to change the kind of titles used in the navigation menu.
C<$url> is the URL of the archive page for C<$year>, as a L<URI> object.

This default implementation returns the full name of the month in English.

=cut

sub month_archive_short_title
{
    my ($self, $url, $year, $month) = @_;
    return DateTime->new(year => $year, month => $month)->strftime('%B');
}

=item $gen-E<gt>navigation_menu($file, $url)

Returns a navigation menu for the page with the URL info C<$url>,
for the file C<$file>.  See the
L<subclass method|Daizu::Gen/$gen-E<gt>navigation_menu($file, $url)>
for details of what it does.

This implementation provides a menu of the archive pages, with a link
for each year in which an article was published.  The most recent years
have submenus for months.  After a certain number of months the menu
just shows years.  Each year either has all its months shown (or at least
the ones with articles in), or none at all.

=cut

sub navigation_menu
{
    my ($self, $cur_file, $cur_url_info) = @_;
    my $cms = $self->{cms};
    my $db = $cms->{db};
    my $cur_url = $cur_url_info->{url};
    my $root_file = $self->{root_file};

    # Start off with a menu item for the blog homepage.
    my @menu;
    {
        my $homepage = $self->{root_file};
        my $homepage_title = $homepage->title;
        $homepage_title = 'Blog homepage' unless defined $homepage_title;
        my $link = $homepage->permalink;
        push @menu, {
            ($cur_url->eq($link) ? () :
                (link => $link->rel($cur_url))),
            title => $homepage_title,
            children => [],
        };
    }

    # As an optimization, set one of these values to the argument of the
    # current URL for comparison with those of items in the menu, if the
    # current URL might appear in the menu itself, so that we can more
    # efficiently determine which URL to leave without a link.
    my ($cur_year_arg, $cur_month_arg);
    if ($cur_file->{guid_id} == $root_file->{guid_id}) {
        $cur_year_arg = $cur_url_info->{argument}
            if $cur_url_info->{method} eq 'year_archive';
        $cur_month_arg = $cur_url_info->{argument}
            if $cur_url_info->{method} eq 'month_archive';
    }

    my $year_sth = $db->prepare(q{
        select url, argument
        from url
        where wc_id = ?
          and guid_id = ?
          and method = 'year_archive'
          and status = 'A'
        order by argument desc
    });
    my $month_sth = $db->prepare(q{
        select url, argument
        from url
        where wc_id = ?
          and guid_id = ?
          and method = 'month_archive'
          and status = 'A'
          and argument like ? || ' %'
        order by argument
    });

    # Keep a count of how many months in total have been included in the
    # menu, so that I can decide not to include any more for older years.
    my $months_included = 0;

    $year_sth->execute($root_file->{wc_id}, $root_file->{guid_id});
    while (my ($year_url, $year) = $year_sth->fetchrow_array) {
        $year_url = URI->new($year_url);
        my @months;
        push @menu, {
            (defined $cur_year_arg && $cur_year_arg eq $year ? () :
                (link => $year_url->rel($cur_url))),
            title => $self->year_archive_title($year_url, $year),
            short_title => $self->year_archive_short_title($year_url, $year),
            children => \@months,
        };

        next if $months_included >= 6;

        $month_sth->execute($root_file->{wc_id}, $root_file->{guid_id},
                            sprintf('%04d', $year));
        while (my ($month_url, $month_arg) = $month_sth->fetchrow_array) {
            $month_url = URI->new($month_url);
            die unless $month_arg =~ /^\d+ (\d+)$/;
            my $month = $1;
            push @months, {
                (defined $cur_month_arg && $cur_month_arg eq $month_arg ? () :
                    (link => $month_url->rel($cur_url))),
                title => $self->month_archive_title($month_url, $year, $month),
                short_title => $self->month_archive_short_title($month_url,
                                                                $year, $month),
                children => [],
            };
            ++$months_included;
        }
    }

    return \@menu;
}

sub _nextprev_article
{
    my ($db, $wc_id, $root_file_id, $issued, $cmp) = @_;
    assert(ref $issued) if DEBUG;   # should be a DateTime value
    assert($cmp eq '<' || $cmp eq '>') if DEBUG;
    my $order = $cmp eq '<' ? 'desc' : 'asc';

    return $db->selectrow_array(qq{
        select u.url, u.content_type, f.title
        from wc_file f
        inner join url u on u.wc_id = f.wc_id and u.guid_id = f.guid_id
        where f.wc_id = ?
          and f.root_file_id = ?
          and u.method = 'article'
          and u.status = 'A'
          and f.issued_at $cmp ?
        order by f.issued_at $order, f.id $order
        limit 1
    }, undef, $wc_id, $root_file_id, db_datetime($issued));
}

=back

=head1 COPYRIGHT

This software is copyright 2006 Geoff Richards E<lt>geoff@laxan.comE<gt>.
For licensing information see this page:

L<http://www.daizucms.org/license/>

=cut

1;
# vi:ts=4 sw=4 expandtab
