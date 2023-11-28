package Dancer2::Plugin::LiteBlog::Article;

=head1 NAME

Dancer2::Plugin::LiteBlog::Article - Represents a single article or page in LiteBlog.

=head1 SYNOPSIS

    use Dancer2::Plugin::LiteBlog::Article;

    my $article = Dancer2::Plugin::LiteBlog::Article->new(
        basedir => '/path/to/article/directory'
    );

    print $article->title;
    print $article->published_date;
    print $article->content;

=head1 DESCRIPTION

This module provides an object-oriented interface to manage individual articles
or pages for LiteBlog, a Dancer2-based blogging platform. Each article
contains metadata and content, parsed from two specific files located in the 
directory root of the C<Article>: C<meta.yml> and C<content.md>.

=cut

use Moo;
use Carp 'croak';
use File::Spec;
use File::Basename;
use Path::Tiny;
use YAML::XS;
use Text::Markdown 'markdown';
use File::Slurp;
use DateTime;

=head1 METHODS

=head2 BUILD 

At build time, this class validates the integrity of the Article. Namely, it
makes sure the object is corretly initialized, which means a valid meta.yml 
and contend.md files are found and successfully parsed in the basedir.

=cut

sub BUILD {
    my ($self) = @_;
    eval {
        $self->title && $self->content 
    };
    croak "Basedir '".$self->basedir."' is not valid: $@ " if $@; 
}

=head1 ATTRIBUTES

=head2 basedir

The base directory where the article files (content.md, meta.yml) reside. Note
that the directory name is used as the C<slug> of the article. Must be an existing
directory, read-only and required attribute.

    my $basedir = $article->basedir;

=cut

has basedir => (
    is => 'ro',
    required => 1,
    isa => sub {
        my $val = shift;
        croak "Not a valid directory ($val)" if ! -d $val;
    },
);

=head2 base_path

The base path for articles, when constructing URLs for the articles. 
Defaults to '/blog'. 

=cut 

has base_path => (
    is => 'ro',
    default => sub { '/blog' },
);

=head2 slug

Derived from the article directory's name, representing the URL-friendly version
of the title.

=cut

#TODO: should be cleaned up (no spaces, no non-ASCII chars, etc)
has slug => (
    is => 'ro',
    lazy => 1,
    default => sub {
        my ($self) = @_;
        return basename($self->basedir);
    },
);

=head2 category

Articles directly under the 'articles' directory are considered 'page'.
Articles that are stored in a sub-directory, below the articles directory 
are considered articles of that category.

Examples:

    .../articles/some-page # this is a page (top-level article)
    .../articles/tech/a-blog-post # this is a blog post under the 'tech' category.

Note: this will be changed in future version, the hard-coded value 'articles' 
will become an attribute of this class so that it can be changed (C<parent_directory>).

=cut

# TODO : 'articles' should become a configurable attribute.

has category => (
    is => 'ro',
    lazy => 1,
    default => sub {
        my ($self) = @_;
        my $parentdir = basename(dirname($self->basedir));
        return ($parentdir eq 'articles') ? 'page' : $parentdir;
    },
);

=head2 is_page

Boolean indicating whether the article is a standalone page, based on the 
value returned by C<category>.

=cut

has is_page => (
    is => 'ro',
    lazy => 1,
    default => sub {
        my ($self) = @_;
        return $self->category eq 'page';
    },
);

=head2 published_time

The time the article was published, derived from the content file's modification
time.

=cut

has published_time => (
    is => 'ro',
    lazy => 1,
    default => sub {
        my ($self) = @_;
        my $content_file = File::Spec->catfile($self->basedir, 'content.md');
        my $path = path($content_file);

        # Hopefully the underlying FS supports birthtime
        my $time;
        if ( $path->can('birthtime') ) {
            $time = $path->birthtime;
        }
        else {
            my @stat = stat($content_file);
            $time = $stat[9]; # mtime
        }
        return $time;
    }
);


=head2 published_date

Formatted publishing date, e.g., "25 October, 2023", derived from
C<published_time>.

=cut

has published_date => (
    is => 'ro',
    lazy => 1,
    default => sub {
        my ($self) = @_;
        my $time = $self->published_time;
        my $dt = DateTime->from_epoch( epoch => $self->published_time );
        return $dt->strftime('%d %B, %Y');  # e.g., "25 October, 2023"
    },
);

=head2 meta

A hash reference containing metadata of the article loaded from the 'meta.yml'
file. That file is supposed to be located within the directory of the Article
(C<basedir>).

=cut

has meta => (
    is => 'ro',
    lazy => 1,
    default => sub {
        my ($self) = @_;
        my $meta_file = File::Spec->catfile($self->basedir, 'meta.yml');
        if (! -e $meta_file) {
            croak "No meta file, unable to initialize this article";
        }
        return YAML::XS::LoadFile($meta_file);
    },
);

=head2 title

The title of the article. Parsed from the content of C<meta.yml>.

=cut


has title => (
    is => 'ro',
    lazy => 1,
    default => sub {
        my ($self) = @_;
        return $self->meta->{'title'};
    },
);

=head2 image

An associated image for the article, if any.

Parsed from the content of C<meta.yml>.  If that value is relative (no starting
'/'), then it is transformed into the absolute permalink of the asset, using
C<base_path>, the C<category> if needed and the C<slug>.

If the C<image> meta field is an absolute path (either starting with a C</> 
or with C<https?>, it is returned unchanged.

Example:

    image: "featured.jpg" # in article/meta.yml
    $article->image; # returns '/blog/cat/some-article/featured.jpg' 

=cut

# Returns true if the $path begins with either a '/' or 'https?'.
sub _is_absolute_path {
    my ($self, $path) = @_;
    return $path =~ /^\// || $path =~ /^https?:\/\//;
}

sub _normalize_path_to_absolute {
    my ($self, $asset) = @_;

    # an absolute path remains unchanged
    return $asset if $self->_is_absolute_path($asset);
        
    my $base = $self->base_path;
    $base = '' if $base eq '/';

    # this is a relative path, transform to its permalink
    if ($self->is_page) {
        return $base .
               '/'.$self->slug .
               '/'.$asset;
    }
    else {
        return $base .
               '/'.$self->category .
               '/'.$self->slug . 
               '/'.$asset;
    }
}

has image => (
    is => 'ro',
    lazy => 1,
    default => sub {
        my ($self) = @_;
        my $asset = $self->meta->{'image'};
        return undef if ! defined $asset;
        return $self->_normalize_path_to_absolute($asset); 
    },
);

=head2 background

If defined in C<meta.yml>, this is expected to be a path to a big image that
will be used as the background image of the whole page. 
As with C<image>, if the path is relative, it will be transformed to 
its absolute form, based on the Article location.

=cut

has background => (
    is => 'ro',
    lazy => 1,
    default => sub {
        my ($self) = @_;
        my $asset = $self->meta->{'background'};
        return undef if ! defined $asset;
        return $self->_normalize_path_to_absolute($asset); 
    },
);

=head2 author

The author of the article/page. To be displayed in the meta
data of the HTML.

=cut

has author => (
    is => 'ro',
    lazy => 1,
    default => sub {
        my ($self) = @_;
        return $self->meta->{'author'};
    },
);

=head2 tags

Array reference of tags associated with the article.
Parsed from the content of C<meta.yml>.

=cut

has tags => (
    is => 'ro',
    lazy => 1,
    default => sub {
        my ($self) = @_;
        return $self->meta->{'tags'} // [];
    },
);

=head2 excerpt

A brief summary or excerpt of the article.
Parsed from the content of C<meta.yml>.

=cut

has excerpt => (
    is => 'ro',
    lazy => 1,
    default => sub {
        my ($self) = @_;
        return $self->meta->{'excerpt'};
    },
);

=head2 permalink

The article's unique URL path.
Derived from C<base_path>, C<category> and C<slug>.

=cut


has permalink => (
    is => 'ro',
    lazy => 1,
    default => sub {
        my ($self) = @_;
        my $base = $self->base_path;
        $base = '' if !defined $base || $base eq '/';

        my $path;
        $path = join('/', ($base, $self->slug)) if $self->is_page;
        $path = join('/', ($base, $self->category, $self->slug ));
        return $path . '/';
    },
);

=head2 content

The content of the article, parsed from the associated Markdown file C<content.md>
and rendered to HTML.
That file is supposed to be located in the C<basedir> of the Article.


=cut

has content => (
    is => 'ro',
    lazy => 1,
    default => sub {
        my ($self) = @_;
        my $content_file = File::Spec->catfile($self->basedir, 'content.md');
        if (! -e $content_file) {
            croak "content.md file not found in ".$self->basedir;
        };
    
        my $markdown = read_file($content_file, { binmode => ':encoding(UTF-8)' });
        return markdown($markdown);
    },
);

1;
=head1 SEE ALSO

L<Dancer2::Plugin::LiteBlog>, L<Text::Markdown>

=head1 AUTHOR

Alexis Sukrieh, E<lt>sukria@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2023 by Alexis Sukrieh.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
