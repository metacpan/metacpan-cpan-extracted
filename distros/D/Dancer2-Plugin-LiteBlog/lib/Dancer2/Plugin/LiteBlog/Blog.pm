package Dancer2::Plugin::LiteBlog::Blog;

=head1 NAME

Dancer2::Plugin::LiteBlog::Blog - Blog widget for Liteblog.

=head1 DESCRIPTION

This module is responsible for handling the core blog functionalities within the
L<Dancer2::Plugin::LiteBlog> system. It extends from the 'Widget' class and
provides features to retrieve and display blog articles or pages as well as 
category pages and a landing page widget used to display blog post cards.

=head1 SYNOPSIS

A Blog object is based on a C<root> directory that must hold a blog-meta.yml 
file, describing all specific details of the blog. In this directory, pages 
and articles are located, represented by L<Dancer2::Plugin::LiteBlog::Article> 
objects.

=cut

use Moo;
use Carp 'croak';
use Cwd 'abs_path';
use YAML::XS;
use File::Spec;
use File::Stat;
use Path::Tiny;
use POSIX qw(strftime LC_TIME setlocale);
use Dancer2::Plugin::LiteBlog::Article;
use XML::RSS;

extends 'Dancer2::Plugin::LiteBlog::Widget';

=head1 ATTRIBUTES

=head2 meta

Read-only attribute that retrieves and returns the meta information for the blog
from the 'blog-meta.yml' file. If this file is not found, an exception will be
thrown.

=cut

has meta => (
    is => 'ro',
    lazy => 1,
    default => sub {
        my ($self) = @_;
        my $meta = File::Spec->catfile($self->root, 'blog-meta.yml');
        if (! -e $meta) {
            croak "No meta file found for the blog : $meta";
        }
        my $yaml = YAML::XS::LoadFile($meta);
        $self->info("Meta loaded from : '$meta'");
        return $yaml;
    },
);

=head2 mount 

Read-only attribute that set where the blog resources should be accessible from, 
in the site's URL.

=cut

has mount => (
    is => 'ro',
    default => sub {
        "/blog"
    },
);

sub has_rss { 1 }

=head2 elements

Read-only attribute that contains a list of featured posts to show on the home
page widget section.  If a C<featured_post> entry is found in the C<blog-meta>
file of the widget, use this. If not, returns the last 3 posts published.  Each
post is represented as an instance of the L<Dancer2::Plugin::LiteBlog::Article>
class.

=cut

# The widget returns the featured posts.
# TODO : option to return the last N posts instead.
has elements => (
    is => 'ro',
    lazy => 1,
    default => sub {
        my ($self) = @_;
        
        # A featured_posts entry is defined in the blog config...
        my $featured_posts = $self->meta->{'featured_posts'};
        return $self->featured_posts() if defined $featured_posts;
       
        # Return the last 3 published posts
        return $self->select_articles(limit => 3);
   },
);

=head2 featured_posts()

=cut

sub featured_posts {
    my ($self) = @_;
    my $featured_posts = $self->meta->{'featured_posts'};
    croak "No 'featured_posts' entry found in blog-meta.yml" 
        if !defined $featured_posts;

    my @posts;
    foreach my $path (@{ $featured_posts }) {
        my $post;
        eval { $post = Dancer2::Plugin::LiteBlog::Article->new(
                base_path => $self->mount,
                basedir => File::Spec->catfile( $self->root, $path)
            )
        };
        if ($@) {
            $self->error("Featured post has an invalid path '$path' : $@"); 
            next;
        }
        
        # At this point, we're sure the post is OK to be rendered.
        $self->info("Featured post is valid: ".$post->title);
        push @posts, $post;
    }
    return \@posts;
}

=head2 select_articles (%params)

Lookup the article repository (C<root>) for articles that match the criteria.

Articles are always returned in descending chronological order (using their 
published_date attibute).

TODO : Should recursively find articles in all category as well as top-level pages.

=head3 params

=over 4 

=item * C<limit>: (default: 1), number of article to retreive (max: 20).

=item * C<category>: if specified, limit the lookup to articles of that category

=back

=cut

sub select_articles {
    my ($self, %params) = @_;

    my $limit = $params{limit} || 10;
    $limit = 20 if $limit > 20;

    # We'll look in the Blog's repository
    my $root = $self->root;

    # If a category is given, the root is the category's repo.
    if (defined $params{category}) {
        my $cat = $params{category};
        $root = File::Spec->catdir($root, $cat);
        croak "Not a valid category: '$cat'" if ! -d $root;
    }

    # caching result exists? Return it if so.
    my $cache_key = join('|', 'select', $root, $self->mount, $limit);
    return $self->cache($cache_key) if defined $self->cache($cache_key);

    # Get the list of all directories in the root
    opendir my $dh, $root or croak "Cannot open directory: $!";
    my @dirs = grep { 
        -d File::Spec->catdir($root, $_) && !/^\.{1,2}$/ 
    } readdir $dh;
    closedir $dh;

    # Then parse each of these dirs (possible category) and look for articles
    my @cat_articles;
    foreach my $catdir (@dirs) {
        # skip if it's a page
        next if -e File::Spec->catfile($root, $catdir, 'meta.yml') || 
            -e File::Spec->catfile($root, $catdir, 'contend.md');
        
        # it's a valid dir without page's files, assume it's a category dir.
        opendir my $dh, File::Spec->catdir($root, $catdir) 
            or croak "Unable to open dir : $!";
        # capture all of these that contain meta.yml & content.md
        my @match = grep { 
            -e File::Spec->catfile($root, $catdir, $_, 'content.md') && 
            -e File::Spec->catfile($root, $catdir, $_, 'meta.yml')
        } readdir $dh;
        closedir $dh;

        foreach my $a (@match) {
            push @cat_articles, File::Spec->catdir($catdir, $a);
        }
    }

    # Sort directories by creation date in descending order
    @dirs = sort {
        my $time_a = $self->_created_time(File::Spec->catdir($root, $a));
        my $time_b = $self->_created_time(File::Spec->catdir($root, $b));
        $time_b <=> $time_a;
    } (@dirs, @cat_articles);

    my @records;
    my $count = 0;
    # Load Article objects up to the limit
    foreach my $dir (@dirs) {
        my $article;

        # TODO: use ->find ? 
        eval { 
            $article = Dancer2::Plugin::LiteBlog::Article->new( 
                basedir => File::Spec->catdir($root, $dir),
                base_path => $self->mount,
            );
        };
        # make sur this is a valid article 
        if ($@) {
            $self->info("Not a valid article '$root/$dir' : $@, skipping");
            next;
        }
        
        # do not return pages
        next if $article->is_page;

        push @records, $article;
        last if ++$count == $limit;
    }
    return $self->cache($cache_key, \@records);
}

=head2 find_article (%params)

Searches and returns an article based on the provided path. Optionally, you can
specify a category as well.
Cache the resulting object in-memory for future calls with same params.

=over 4

=item * C<path>: The path to the article. This is mandatory.

=item * C<category>: The category of the article. This is optional. If given, the path will be prefixed with the category.

=back

If the article is found, it returns an instance of
C<Dancer2::Plugin::LiteBlog::Article> corresponding to the article. Otherwise,
it returns undef.

Examples:

    # Find an article in the 'tech' category with path 'new-tech'
    my $article = $blog->find_article(category => 'tech', path => 'new-tech');

    # Find an article with path 'about-me'
    my $article = $blog->find_article(path => 'about-me');

Note: The method will croak if the C<path> parameter is not provided or if an
invalid category is provided.

=cut

sub find_article {
    my ($self, %params) = @_;
    my $path = $params{path};
    croak "Required param 'path' missing" if !defined $path;

    # remove starting '/' and trailing '/'
    $path =~ s/^\///;
    $path =~ s/\/$//;
    
    my $category = $params{category};
    if (defined $category) {
        croak "Invalid category '$category'" if $category =~ /\//;
        $path = "${category}/${path}";
    };

    # if found in cache
    my $cache_key = join('|', 'find', $self->mount, $self->root, $path);
    return $self->cache($cache_key)
        if defined $self->cache($cache_key);

    my $article;
    eval { 
        $article = Dancer2::Plugin::LiteBlog::Article->new(
            base_path => $self->mount,
            basedir => File::Spec->catfile( $self->root, $path));
    };

    # cache and return
    return $self->cache($cache_key, $article);
}

# Dancer Section - TODO: split this class in two?

=head1 LITEBLOG WIDGET INTERFACE

This class implements the L<Dancer2::Plugin::LiteBlog::Widget> interface.
It declares routes.

=head2 has_routes 

Returns a true value as routes are declared by this Widget.

=cut

sub has_routes { 1 }

=head2 declare_routes 

This method declares routes for the Dancer2 application. 

=head3 GET C</$mount/:cat/:slug>

Retrieves and displays a specific article based on its category (C<:cat>) and
permalink (C<:slug>). If the article is not found, it will return a 404 status.
The rendering is done with the C<liteblog/single-page> template.

The prefix (C<$mount>) is taken from the C<mount> attriute of the instance and
defaults to C</blog>.

Examples:

  /blog/tech/new-tech
  /blog/lifestyle/my-journey

=cut


# returns the right prefix, based on mount.
sub _get_prefix {
    my ($self, $mount) = @_;
    $mount ||= '/blog'; # default value is /blog
    
    # handle top-level mount
    return "" if $mount eq '/';
    return $mount;
}

sub _prepare_meta_article {
    my ($self, $article) = @_;
    return {
        page_title   => $article->title,
        page_excerpt => $article->excerpt,
        page_image   => $article->image,
        page_tags    => join(', ', @{$article->tags}),
        page_author  => $article->author,
        page_url     => $article->permalink,
        background_image => $article->background, # if set will use the full screen bg
    };
}

sub declare_routes {
    my ($self, $plugin, $config) = @_;

    my $prefix = $self->_get_prefix($config->{mount});
    $self->info("declaring route ${prefix}/:cat/:slug");

    # redirect missing trailing / 
    $plugin->app->add_route(
        method => 'get',
        regexp  => "${prefix}/:cat/:slug",
        code    => sub {
            my $cat  = $plugin->dsl->param('cat');
            my $slug = $plugin->dsl->param('slug');
            $self->info("In $prefix/$cat/$slug");

            $plugin->dsl->redirect("$prefix/$cat/$slug/");
        },
    );

    $self->_declare_rss_routes($plugin, $prefix);

    # /blog/:category/:permalink
    $self->info("declaring route ${prefix}/:cat/:slug/");
    $plugin->app->add_route(
        method  => 'get',
        regexp  => "${prefix}/:cat/:slug/",
        code    => sub {
            my $cat  = $plugin->dsl->param('cat');
            my $slug = $plugin->dsl->param('slug');
            $self->info("In $prefix/$cat/$slug");

            my $article = $self->find_article(category => $cat, path => $slug );

            if (! defined $article) {
                return $plugin->render_client_error("Article not found : $cat/$slug");
            }

            return $plugin->dsl->template('liteblog/single-page', 
                {
                    %{ $self->_prepare_meta_article($article) },
                    content => $article->content,
                    meta => [{ 
                        label => $article->category, 
                        link => "$prefix/$cat" 
                    },{ 
                        label => $article->published_date 
                    }
                    ],
                },
                {
                    layout => 'liteblog'
                }
            );
        }
    );

=head3 GET C</blog/:category/:slug/:asset>

If the C<:asset> is a readable file in the article's directory, 
this route sends it back to the client. This is useful for hosting
local files like images, PDF, etc in the article's folder.

Example:

    /blog/tech/some-article/featured.jpg

=cut

    $self->info("declaring route ${prefix}/:cat/:slug/:asset");
    $plugin->app->add_route(
        method => 'get',
        regexp => "${prefix}/:category/:slug/:asset",
        code   => sub {
            my $cat = $plugin->dsl->param('category');
            my $slug = $plugin->dsl->param('slug');
            my $asset = $plugin->dsl->param('asset');
            $self->info("in $prefix/$cat/$slug/$asset");

            # the article must exist
            my $article = $self->find_article(
                category => $cat, path => $slug );
            return $plugin->render_client_error(
                "Requested article not found ($cat / $slug)") 
                if ! defined $article;
            $self->info("article is found ($cat/$slug)");
            
            # the asset file must exist in the article's basedir
            my $asset_file = abs_path(File::Spec->catfile($article->basedir, $asset));
            return $plugin->render_client_error(
                "Asset file '$asset' does not exist"
            ) if ! -e $asset_file;
            $self->info("asset is found ($asset_file)");

            return $plugin->dsl->send_file($asset_file, system_path => 1);
        },
    );

=head3 GET C</:page>

This is a catch-all route for retrieving and displaying any article based on its
page path. If the article is not found, it will pass, this might be a category
page.

Examples:

  /about-me
  /contact

=cut

    # redirect to trailing / path
    $self->info("declaring route ${prefix}/:page");
    $plugin->app->add_route(
        method => 'get',
        regexp => "${prefix}/:page",
        code => sub {
            my $slug = $plugin->dsl->param('page');
            $self->info("In $prefix/$slug");

            $plugin->dsl->redirect("${prefix}/$slug/");
        }
    );

    $self->info("declaring route ${prefix}/:page/");
    $plugin->app->add_route(
        method => 'get',
        regexp => "${prefix}/:page/",
        code => sub {
            my $slug = $plugin->dsl->param('page');
            $self->info("In $prefix/$slug/");
            
            my $article = $self->find_article(path => $slug );

            if (! defined $article) {
                $self->info("Not a page '$slug', passing");
                return $plugin->dsl->pass();
            }
            $self->info("Got article : $article");
            
            # TODO hanlde invalid/missing $article->content as a 404
            return $plugin->dsl->template(
                'liteblog/single-page',
                {
                    %{ $self->_prepare_meta_article($article) },
                    content    => $article->content, 
                    meta       => [ { 
                        label => $article->published_date 
                        }
                    ],
                },
                { layout => 'liteblog'}
            );
        },
    );

=head3 GET C</blog/:category/>

Displays a landing page for a specific category. If the category is not found or
invalid, it will return a 404 status. The rendering is done with the
'liteblog/single-page' template.

Examples:

  /blog/tech/
  /blog/lifestyle/

=cut

    # redirect missing trailing / 
    $self->info("declaring route ${prefix}/:category");
    $plugin->app->add_route(
        method => 'get',
        regexp  => "${prefix}/:cat",
        code    => sub {
            my $cat  = $plugin->dsl->param('cat');
            $self->info("In $prefix/$cat");

            $plugin->dsl->redirect("$prefix/$cat/");
        },
    );

    # the /category landing page
    $self->info("declaring route ${prefix}/:category/");
    $plugin->app->add_route(
        method => 'get',
        regexp => "${prefix}/:category/",
        code   => sub {
            my $category = $plugin->dsl->param('category');
            $self->info("In $prefix/$category");

            if (! -d File::Spec->catdir($self->root, $category)) {
                return $plugin->render_client_error("Invalid category requested: '$category'");
            }
            my $articles = $self->select_articles(category => $category, limit => 6);
            $self->info("retrieved ".scalar(@$articles)." articles");
            return $plugin->dsl->template(
                'liteblog/single-page', {
                    page_title => ucfirst($category)." Stories",
                    class      => "category_page",
                    content    => $plugin->dsl->template('liteblog/widgets/blog-cards', {
                        widget => {
                        title =>  "Title",
                        elements  => $articles,
                        #TODO: readmore_button => 'Load more articles', 
                    }},{layout => undef})
                }, 
                {layout => 'liteblog'}
            );
        }
    );
}

=head3 GET C</blog/rss/>

=cut

sub _time_to_rfc822 {
    setlocale(LC_TIME, "C"); # Set the locale to C (standard Unix locale)
    strftime("%a, %d %b %Y %H:%M:%S %z", 
        localtime($_[0]));
}

sub _declare_rss_routes {
    my ($self, $plugin, $prefix) = @_;

    my $site_title = $plugin->dsl->config->{liteblog}->{title};
    my $site_url   = $plugin->dsl->config->{liteblog}->{base_url};
    if (! defined $site_url) {
        croak "You have to set 'base_url' in liteblog's config to use RSS";
    }
    $site_url =~ s/\/$//; # remove trailing '/'

    my $site_desc = $plugin->dsl->config->{liteblog}->{description};

    # Global RSS feed
    $plugin->app->add_route(
        method => 'get',
        regexp => "${prefix}/rss/",
        code => sub {
    
            my $cache_key = 'rss';
            my $cache = $self->cache($cache_key);
            if (defined $cache) {
                $plugin->dsl->content_type( 'application/rss+xml' );
                return $cache;
            }

            # Fetch the last N Article objects
            my $articles = $self->select_articles(limit => 10);

            # Create a new RSS feed
            my $rss = XML::RSS->new(version => '2.0');
            $rss->channel(
                title          => $site_title,
                link           => $site_url,
                description    => $site_desc, 
                language       => "en",
                copyright      => "Copyright © $site_title",
                pubDate        => _time_to_rfc822(time),
            );

            # Add items to the feed for each article
            foreach my $article (@$articles) {
                $rss->add_item(
                    title       => $article->title,
                    permaLink   => $site_url.$article->permalink,
                    description => $article->excerpt,
                    pubDate     => _time_to_rfc822($article->published_time), # Format the date as RFC 2822
                );
            }

            # Set the content type
            $plugin->dsl->content_type( 'application/rss+xml' );

            # Return the RSS feed
            return $self->cache($cache_key, $rss->as_string);
        }, # end code sub
    ); # end add_route
}

=head3 GET C</blog/category/rss/> 

=cut

# Private subs

sub _created_time {
    my ($self, $file_path) = @_;
    my $path = path($file_path);

    # Hopefully the underlying FS supports birthtime
    my $time;
    if ( $path->can('birthtime') ) {
        $time = $path->birthtime;
    }
    else {
        my @stat = stat($file_path);
        $time = $stat[9]; # mtime
    }
    return $time;
}



1;
