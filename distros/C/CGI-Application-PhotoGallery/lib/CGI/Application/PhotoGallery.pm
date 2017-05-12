package CGI::Application::PhotoGallery;

=head1 NAME

CGI::Application::PhotoGallery - module to provide a simple photo gallery

=head1 SYNOPSIS

    use CGI::Application::PhotoGallery;
    
    my $webapp = CGI::Application::PhotoGallery->new(
        PARAMS => {
            photos_dir  => '/path/to/photos'
        }
    );
    
    $webapp->run();

=head1 DESCRIPTION

CGI::Application::PhotoGallery is a L<CGI::Application> module allowing people
to create their own simple photo gallery. There is no need to generate your
own thumbnails since they are created on the fly (using either the GD or
Image::Magick modules).

To use this module you need to create an instance script.  It
should look like:

    #!/usr/bin/perl
    
    use CGI::Application::PhotoGallery;
    
    my $webapp = CGI::Application::PhotoGallery->new(
        PARAMS => {
            photos_dir  => '/path/to/photos'
        }
    );
    
    $webapp->run();

You'll need to replace the "/path/to/photos" with the real path to your
photos (see the photos_dir options below).

Put this somewhere where CGIs can run and name it something like
C<index.cgi>.

This gets you the default behavior and look.  To get something more to
your specifications you can use the options described below.

=head1 INSTALLATION

    perl Makefile.PL
    make
    make test
    make install

=head1 OPTIONS

L<CGI::Application> modules accept options using the PARAMS arguement to
C<new()>.  To give options for this module you change the C<new()>
call in the instance script shown above:

    my $webapp = CGI::Application::PhotoGallery->new(
        PARAMS => {
            photos_dir  => '/path/to/photos',
            title       => 'My Photos'
        }
    );

The C<title> option tells PhotoGallery to use 'My Photos' as the title
rather than the default value.  See below for more information
about C<title> and other options.

=head2 photos_dir (required)

This parameter is used to specify where all of your photos are
located.

Previous limitations of this directory have been lifted.

Your photos directory can have any number of images and sub-directories
of images. This is applied recursively so a gallery can have any number
of sub-galleries.

=head2 script_name

This parameter uses C<$0> by default, you can change it (or set it to the
empty string) if you neeed to. It is needed for creating self referencial
links.

=head2 title

By default every page will start with the title "My Photo Gallery".
You can specify your own using the title parameter.

=head2 thumb_size

By default PhotoGallery displays thumbnail images that are 100 x 100
on the index page. You can change this by specifying a number
(in pixels) for this option.

=head2 preview_thumbs

Before viewing the entire contents of a gallery, you are shown a few
preview image. The default number of thumbnails is C<4>. You
can change it by specifying your own value in the instance script.

=head2 graphics_lib

You can specifify which graphics library you wish to use to size your
thumbnails. Included in this package are C<Magick> (Image::Magick) and
the default: C<GD>. You can also create your own if you wish.

=head2 index_template

This application uses L<HTML::Template> to generate its HTML pages.  If
you would like to customize the HTML you can copy the default form
template and edit it to suite your needs.  The default form template
is called 'photos_index.tmpl' and you can get it from the distribution
or from wherever this module ended up in your C<@INC>.  Pass in the
path to your custom template as the value of this parameter.

See L<HTML::Template> for more information about the template syntax.

=head2 single_template

The default template for an individual photo is called
'photos_single.tmpl' and you can get it from the distribution or from
wherever this module ended up in your C<@INC>.  Pass in the path to
your custom template as the value of this parameter.

See L<HTML::Template> for more information about the template syntax.

=head2 max_width

Setting this value will force the browser to scale images down to this
particular width and proportioned height. This is done by setting the width
and height attributes on the image tag, thus saving the image will retain the
full resolution.

=head2 max_height

Setting this value will force the browser to scale images down to this
particular height and proportioned width. This is done by setting the width
and height attributes on the image tag, thus saving the image will retain the
full resolution.

=head2 cache_root

Specifies where the file cache data will be stored.  Defaults to FileCache
under the OS-specific temporary filesdirectory (e.g. /tmp/FileCache).  You
may want to move this to make the cache persist.  Under selinux, however,
be careful to put it in a webserver-writable directory.

=head2 cache_namespace

Specifies the namespace for this gallery's cache data.  Defaults to the
gallery title - or 'default'.  Changing this will orphan the cache data.

=head2 cache_dirumask

Specifies the umask value to use when cache directories are created.  Defaults
to 0007 to avoid cache poisioning attacks.

=head2 cache_datumask

Specifies the umask value to use when cache data is written.  Defaults to 006
to avoid cache poisioning attacks.  Note that this becomes the umask for all
files written by this script.  (See Cache::FileCache documentation for why.)

=head1 CAPTIONS

You can include captions for your photos by creating a tab-separated
database named C<captions.txt> in your C<photos_dir>. The filename
should be specified relative of your C<photos_dir>.

    1.jpg   This is a caption.
    Test Gallery/1.jpg  This is another caption.

=head1 METHODS

=cut

use base qw( CGI::Application );

use strict;
use warnings;

use File::Basename;
use Cache::FileCache;
use MIME::Types;
use File::Find::Rule;
use File::ShareDir;
use HTTP::Date ();

our $VERSION = '0.16';

=head2 setup( )

This method sets the default options and makes sure all required
parameteres are set.

=cut

sub setup {
    my $self = shift;

    $self->mode_param( 'mode' );
    $self->run_modes(
        index    => 'gallery_index',
        thumb    => 'thumbnail',
        full     => 'show_image',
        view     => 'single_index',
        AUTOLOAD => 'gallery_index'
    );
    $self->start_mode( 'index' );
    $self->error_mode( 'handle_error' );

    # setup defaults

    $self->param( thumb_size => 100 )
        unless defined $self->param( 'thumb_size' );
    $self->param( preview_thumbs => 4 )
        unless defined $self->param( 'preview_thumbs' );
    $self->param( title => 'My Photo Gallery' )
        unless defined $self->param( 'title' );
    $self->param( graphics_lib => 'GD' )
        unless defined $self->param( 'graphics_lib' );
    $self->param( script_name => $0 )
        unless defined $self->param( 'script_name' );

    # check required params

    die
        "PARAMS => { photos_dir => '/path/to/photos' } not set in your instance script!"
        unless defined $self->param( 'photos_dir' );

    # fixes $0 for win32

    $self->param( script_name => basename( $self->param( 'script_name' ) ) )
        if $self->param( 'script_name' );
}

=head2 get_photos( $dir )

This method finds all of the C<image/*> files in the specified
directory.

=cut

sub get_photos {
    my $self  = shift;
    my $dir   = shift;
    my $types = $self->mime_types;

    my @photos = sort File::Find::Rule->maxdepth( 1 )->file->exec(
        sub {
            my $name = pop;
            return 0 if basename( $name ) eq 'favicon.ico';
            my $mime = $types->mimeTypeOf( $name );
            return 1 if $mime && $mime->mediaType eq 'image';
        }
    )->in( $dir );

    return @photos;
}

=head2 mime_types( )

This method will create (if needed) and return a new L<MIME::Types> object.

=cut

sub mime_types {
    my $self = shift;

    unless ( $self->{ _mime_types } ) {
        my $types = MIME::Types->new( only_complete => 1 );
        $types->create_type_index;
        $self->{ _mime_types } = $types;
    }

    return $self->{ _mime_types };
}

=head2 gfx_lib( )

This method will create (if needed) and return the graphics adaptor specified by
the user (default is GD).

=cut

sub gfx_lib {
    my $self = shift;

    unless ( $self->{ _gfx_lib } ) {
        my $lib = 'CGI::Application::PhotoGallery::'
            . $self->param( 'graphics_lib' );
        eval "require $lib";
        $self->{ _gfx_lib } = $lib->new;
    }

    return $self->{ _gfx_lib };
}

=head2 cache( )

This method will create (if needed) and return a L<Cache::FileCache> object,

=cut

sub cache {
    my $self = shift;

    unless ( $self->{ _cache } ) {
        my %options = ( namespace => $self->param( 'title' ),
            directory_umask => 0007 );

        $options{ 'cache_root' } = $self->param( 'cache_root' )
            if defined $self->param( 'cache_root' );
        $options{ 'namespace' } = $self->param( 'cache_namespace' )
            if defined $self->param( 'cache_namespace' );
        $options{ 'directory_umask' } = $self->param( 'cache_dirumask' )
            if defined $self->param( 'cache_dirumask' );
        if ( defined $self->param( 'cache_datumask' ) ) {
            umask $self->param( 'cache_datumask' );
        }
        else {
            umask 006;
        }
        $self->{ _cache } = Cache::FileCache->new( \%options );
    }

    return $self->{ _cache };

}

=head1 RUN MODES

=head2 gallery_index( )

Reads in the contents of your C<photos_dir> and generates an index of photos.

=cut

sub gallery_index {
    my $self  = shift;
    my $types = $self->mime_types;
    my $query = $self->query;

    my $limit     = $self->param( 'preview_thumbs' );
    my $photo_dir = $self->param( 'photos_dir' );
    my $user_dir  = $self->query->param( 'dir' ) || '';

    $user_dir =~ s/\.\.//g;
    $user_dir =~ s/\/$//;

    my $parent = $user_dir;
    $parent =~ s{^(.*?)/([^/]+?)/?$}{$1/};

    my $directory = $photo_dir . $user_dir;
    die "ERROR: File not found."                 unless -e $directory;
    die "ERROR: '$directory' is not a directory" unless -d $directory;

    my $output;
    my $cache   = $self->cache;
    my $key     = $directory;
    my $lastmod = ( stat( $directory ) )[ 9 ];
    my $cstamp  = "$directory/.cachetime";

    if ( $output = $cache->get( $key ) ) {
        my $cachetime = $cache->get( $cstamp );
        if ( $cachetime && $cachetime == $lastmod ) {
            my $reqmod;
            if ( my $header = $query->http( 'If-Modified-Since' ) ) {
                $reqmod = HTTP::Date::str2time(
                    ( split( /;/, $header, 2 ) )[ 0 ] );

                if ( $reqmod && $reqmod == $lastmod ) {
                    $self->header_props( { -status => '304 Not Modified' } );
                    return;
                }
            }

            $self->header_add(
                { -last_modified => HTTP::Date::time2str( $lastmod ) } );
            return $output;
        }
    }

    my @dirs = sort File::Find::Rule->directory->mindepth( 1 )->maxdepth( 1 )
        ->in( $directory );

    my @galleries;
    for my $dir ( $directory, @dirs ) {
        my @files = map { s/^$photo_dir//; { filename => $_ }; }
            $self->get_photos( $dir );

        # only limit the number of photos on sub-galleries
        if ( $dir ne $directory ) {
            @files = @files[ 0 .. $limit - 1 ] if @files > $limit;
        }

        ( my $location = $dir ) =~ s/^$photo_dir//;
        push @galleries,
            {
            dir    => $location,
            title  => basename( $dir ),
            photos => \@files
            };
    }

    my $current = shift( @galleries );

    my $html = $self->load_tmpl(
        $self->param( 'index_template' )
            || $self->_dist_file( 'photos_index.tmpl' ),
        associate         => $self,
        global_vars       => 1,
        loop_context_vars => 1,
        die_on_bad_params => 0
    );

    $html->param(
        photos => $current->{ photos },
        gallery_name =>
            ( $user_dir ? $current->{ title } : $self->param( 'title' ) ),
        galleries => \@galleries,
        parent    => $parent,
    );

    $self->header_add(
        { -last_modified => HTTP::Date::time2str( $lastmod ) } );
    $output = $html->output;
    $cache->set( $key    => $output );
    $cache->set( $cstamp => $lastmod );

    return $output;
}

=head2 thumbnail( )

Generates a thumbnail for the requested image using the selected graphics
library.

=cut

sub thumbnail {
    my $self  = shift;
    my $query = $self->query;
    my $dir   = $self->param( 'photos_dir' );
    my $photo = $query->param( 'photo' );
    my $size  = $self->param( 'thumb_size' );

    die 'ERROR: Missing photo query argument.' unless $photo;

    my $path    = "$dir$photo";
    my $cache   = $self->cache;
    my $key     = "$path$size";
    my $lastmod = ( stat( $path ) )[ 9 ];

    my $data;
    if ( $data = $cache->get( $key ) ) {
        my $reqmod;
        if ( my $header = $query->http( 'If-Modified-Since' ) ) {
            $reqmod
                = HTTP::Date::str2time( ( split( /;/, $header, 2 ) )[ 0 ] );
        }

        if ( $reqmod && $reqmod == $lastmod ) {
            $self->header_props( { -status => '304 Not Modified' } );
            return;
        }
        else {
            $data = undef;
        }
    }

    unless ( $data ) {
        my $gfx = $self->gfx_lib;
        $data = $gfx->resize( $path, $size );
        $cache->set( $key => $data );
    }

    $self->header_props(
        {   -type          => $self->mime_types->mimeTypeOf( $path ),
            -last_modified => HTTP::Date::time2str( $lastmod )
        }
    );

    binmode STDOUT;
    return $data;
}

=head2 show_image( )

Sends the contents of the image to the browser.

=cut

sub show_image {
    my $self  = shift;
    my $query = $self->query;
    my $dir   = $self->param( 'photos_dir' );
    my $photo = $query->param( 'photo' );
    my $path  = "$dir$photo";

    die 'ERROR: Missing $photo query argument.' unless $photo;

    my $lastmod = ( stat( $path ) )[ 9 ];

    my $reqmod;
    if ( my $header = $query->http( 'If-Modified-Since' ) ) {
        $reqmod = HTTP::Date::str2time( ( split( /;/, $header, 2 ) )[ 0 ] );
    }

    if ( $reqmod && $reqmod == $lastmod ) {
        $self->header_props( { -status => '304 Not Modified' } );
        return;
    }

    open( PHOTO, $path ) or die "ERROR: Cannot open $path: $!";
    binmode PHOTO;
    my $data = do { local $/; <PHOTO> };
    close( PHOTO );

    $self->header_props(
        {   -type          => $self->mime_types->mimeTypeOf( $path ),
            -last_modified => HTTP::Date::time2str( $lastmod )
        }
    );

    return $data;
}

=head2 single_index( )

Fills and sends the template for viewing an individual image.

=cut

sub single_index {
    my $self  = shift;
    my $query = $self->query();
    my $dir   = $self->param( 'photos_dir' );
    my $photo = $query->param( 'photo' );
    my $path  = "$dir$photo";

    die 'ERROR: Missing photo query argument.' unless $photo;
    die 'ERROR: File not found' unless -e $path;

    my $caption_path = "$dir/captions.txt";

    my $output;
    my $cache   = $self->cache;
    my $key     = "$path.#frame";
    my $lastmod = ( stat( $path ) )[ 9 ];

    # Directory change means links may have changed
    # Caption file change is a content change
    my $lastdir = ( stat( $dir ) )[ 9 ];
    $lastmod = $lastdir if ( $lastdir > $lastmod );
    my $lastcap = 0;
    $lastcap = ( stat( $caption_path ) )[ 9 ] if ( -r $caption_path );
    $lastmod = $lastcap if ( $lastcap > $lastmod );
    my $cstamp = "$key#cachetime";

    if ( $output = $cache->get( $key ) ) {
        my $cachetime = $cache->get( $cstamp );
        if ( $cachetime && $cachetime == $lastmod ) {
            my $reqmod;
            if ( my $header = $query->http( 'If-Modified-Since' ) ) {
                $reqmod = HTTP::Date::str2time(
                    ( split( /;/, $header, 2 ) )[ 0 ] );

                if ( $reqmod && $reqmod == $lastmod ) {
                    $self->header_props( { -status => '304 Not Modified' } );
                    return;
                }
            }

            $self->header_add(
                { -last_modified => HTTP::Date::time2str( $lastmod ) } );
            return $output;
        }
    }

    my $gfx = $self->gfx_lib;

    my ( $width, $height ) = eval { $gfx->size( $path ); };

    die "Unable to determine size of $path; file may be corrupt.\nError string: $@" if $@;

    # get data for prev/next/parent links
    my ( undef, $search_dir ) = fileparse( $path );
    my ( undef, $parent )     = fileparse( $photo );
    my @files = $self->get_photos( $search_dir );
    my ( $prev, $next );

    while ( my $f = shift @files ) {
        $f =~ s{^$dir}{};
        if ( $f ne $photo ) {
            $prev = $f;
            next;
        }
        else {
            $next = shift @files;
            $next =~ s{^$dir}{} if $next;
            last;
        }
    }

    my $html = $self->load_tmpl(
        $self->param( 'single_template' )
            || $self->_dist_file( 'photos_single.tmpl' ),
        associate         => $self,
        global_vars       => 1,
        die_on_bad_params => 0
    );

    if ( defined( my $max_width = $self->param( 'max_width' ) ) ) {
        if ( $width > $max_width ) {
            my $scale = $max_width / $width;
            $width  = int( $width * $scale );
            $height = int( $height * $scale );
        }
    }

    if ( defined( my $max_height = $self->param( 'max_height' ) ) ) {
        if ( $height > $max_height ) {
            my $scale = $max_height / $height;
            $width  = int( $width * $scale );
            $height = int( $height * $scale );
        }
    }

    $html->param(
        photo  => $photo,
        width  => $width,
        height => $height,
        next   => $next,
        prev   => $prev,
        parent => $parent,
    );

    # get caption, if available
    if ( -e $caption_path ) {
        open( CAPTIONS, $caption_path )
            or die "ERROR: Cannot open caption file $caption_path: $!";
        while ( my $caption = <CAPTIONS> ) {
            if ( $caption =~ /^\Q$photo\E\t(.+)$/ ) {
                $html->param( caption => $1 );
                last;
            }
        }
        close( CAPTIONS );
    }

    $self->header_add(
        { -last_modified => HTTP::Date::time2str( $lastmod ) } );
    $output = $html->output;
    $cache->set( $key    => $output );
    $cache->set( $cstamp => $lastmod );

    return $output;
}

sub _dist_file {
    my ( $self, $file ) = @_;
    return File::ShareDir::dist_file( 'CGI-Application-PhotoGallery', $file );
}

=head2 handle_error( )

Renders a template for any failed action.

=cut

sub handle_error {
    my ( $self, $error ) = @_;

    if ( $error =~ m{file not found}i ) {
        $self->header_props( { -status => '404 Not Found' } );
        $error = 'ERROR: File not found.';
    }
    else {
        # log non-404 errors
        warn $error;
        $error =~ s{\n}{<br/>}g;
        $self->header_props( { -status => '500 Error' } );
    }

    my $html = $self->load_tmpl(
        $self->param( 'error_template' ) || $self->_dist_file( 'error.tmpl' ),
        associate         => $self,
        global_vars       => 1,
        die_on_bad_params => 0
    );

    $html->param( error => $error );

    return $html->output;
}

=head1 SEE ALSO

=over 4 

=item * L<CGI::Application>

=item * L<HTML::Template>

=item * L<CGI::Application::MailPage>

=back

=head1 AUTHOR

Brian Cassidy E<lt>bricas@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003-2013 by Brian Cassidy

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

1;
