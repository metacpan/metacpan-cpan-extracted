package CSS::SpriteMaker;

use strict;
use warnings;

use File::Find;
use Image::Magick;
use List::Util qw(max);

use Module::Pluggable 
    search_path => ['CSS::SpriteMaker::Layout'],
    except => qr/CSS::SpriteMaker::Layout::Utils::.*/,
    require => 1,
    inner => 0;

use POSIX qw(ceil);


=head1 NAME

CSS::SpriteMaker - Combine several images into a single CSS sprite

=head1 VERSION

Version 1.01

=cut

our $VERSION = '1.01';


=head1 SYNOPSIS

    use CSS::SpriteMaker;

    my $SpriteMaker = CSS::SpriteMaker->new(
        verbose => 1, # optional

        #
        # Options that impact the lifecycle of css class name generation
        #
        # if provided will replace the default logic for creating css classnames
        # out of image filenames. This filename-to-classname is the FIRST step
        # of css classnames creation. It's safe to return invalid css characters
        # in this subroutine. They will be cleaned up internally.
        #
        rc_filename_to_classname => sub { my $filename = shift; ... } # optional

        # ... cleaning stage happens (all non css safe characters are removed)

        # This adds a prefix to all the css class names. This is called after
        # the cleaning stage internally. Don't mess with invalid CSS characters!
        #
        css_class_prefix => 'myicon-',

        # This is the last step. Change here whatever part of the final css
        # class name.
        #
        rc_override_classname => sub { my $css_class = shift; ... } # optional
    );

    $SpriteMaker->make_sprite(
        source_images  => ['/path/to/imagedir', '/images/img1.png', '/img2.png'];
        target_file => '/tmp/test/mysprite.png',
        layout_name => 'Packed',    # optional
        remove_source_padding => 1, # optional
        enable_colormap => 1,       # optional
        add_extra_padding => 31,    # optional +31px padding around all images
        format => 'png8',           # optional
    );

    $SpriteMaker->print_css();

    $SpriteMaker->print_html();

OR

    my $SpriteMaker = CSS::SpriteMaker->new();

    $SpriteMaker->make_sprite(
       source_dir => '/tmp/test/images',
       target_file => '/tmp/test/mysprite.png',
    );

    $SpriteMaker->print_css();

    $SpriteMaker->print_html();

OR

    my $SpriteMaker = CSS::SpriteMaker->new();

    $SpriteMaker->compose_sprite(
        parts => [
            { source_dir => 'sample_icons',
              layout_name => 'Packed',
              add_extra_padding => 32       # just add extra padding in one part
            },
            { source_dir => 'more_icons',
                layout => {
                    name => 'FixedDimension',
                    options => {
                        'dimension' => 'horizontal',
                        'n' => 4,
                    }
                }
            },
        ],
        # the composing layout
        layout => {
            name => 'FixedDimension',
            options => {
                n => 2,
            }
        },
        target_file => 'composite.png',
    );

    $SpriteMaker->print_css();

    $SpriteMaker->print_html();

ALTERNATIVELY

you can generate a fake CSS only containing the original images...

    my $SpriteMakerOnlyCss = CSS::SpriteMaker->new();

    $SpriteMakerOnlyCss->print_fake_css(
        filename => 'some/fake_style.css',
        source_dir => 'sample_icons'
    );


=head1 DESCRIPTION

A CSS Sprite is an image obtained by arranging many smaller images on a 2D
canvas, according to a certain layout.

Transferring one larger image is generally faster than transferring multiple
images separately as it greatly reduces the number of HTTP requests (and
overhead) necessary to render the original images on the browser.

=head1 PUBLIC METHODS

=head2 new

Create and configure a new CSS::SpriteMaker object.

The object can be initialised as follows:
    
    my $SpriteMaker = CSS::SpriteMaker->new(
        rc_filename_to_classname => sub { my $filename = shift; ... }, # optional
        css_class_prefix      => 'myicon-',                            # optional
        rc_override_classname => sub { my $css_class = shift; ... }    # optional
        source_dir => '/tmp/test/images',       # optional
        target_file => '/tmp/test/mysprite.png' # optional
        remove_source_padding => 1,             # optional
        add_extra_padding     => 1,             # optional
        verbose => 1,                           # optional
        enable_colormap => 1,                  # optional
    );
    
Default values are set to:

=over 4

=item remove_source_padding : false,

=item verbose : false,

=item enable_colormap : false,

=item format  : png,

=item css_class_prefix : ''

=back

The parameter rc_filename_to_classname is a code reference to a function that
allow to customize the way class names are generated. This function should take
one parameter as input and return a class name

=cut

sub new {
    my $class  = shift;
    my %opts   = @_;

    # defaults
    $opts{remove_source_padding} //= 0;
    $opts{add_extra_padding}     //= 0;
    $opts{verbose}               //= 0;
    $opts{format}                //= 'png';
    $opts{layout_name}           //= 'Packed';
    $opts{css_class_prefix}      //= '';
    $opts{enable_colormap}       //= 0;
    
    my $self = {
        css_class_prefix => $opts{css_class_prefix},
        source_images => $opts{source_images},
        source_dir => $opts{source_dir},
        target_file => $opts{target_file},
        is_verbose => $opts{verbose},
        format => $opts{format},
        remove_source_padding => $opts{remove_source_padding},
        enable_colormap => $opts{enable_colormap},
        add_extra_padding => $opts{add_extra_padding},
        output_css_file => $opts{output_css_file},
        output_html_file => $opts{output_html_file},

        # layout_name is used as default
        layout => {
            name => $opts{layout_name},
            # no options by default
            options => {}
        },
        rc_filename_to_classname => $opts{rc_filename_to_classname},
        rc_override_classname => $opts{rc_override_classname},

        # the maximum color value
        color_max => 2 ** Image::Magick->QuantumDepth - 1,
    };

    return bless $self, $class;
}

=head2 compose_sprite

Compose many sprite layouts into one sprite. This is done by applying
individual layout separately, then merging the final result together using a
glue layout.

    my $is_error = $SpriteMaker->compose_sprite (
        parts => [
            { source_images => ['some/file.png', 'path/to/some_directory'],
              layout_name => 'Packed',
            },
            { source_images => ['path/to/some_directory'],
              layout => { 
                  name => 'DirectoryBased',
              }
              include_in_css => 0,        # optional
              remove_source_padding => 1, # optional (defaults to 0)
              enable_colormap => 1, # optional (defaults to 0)
              add_extra_padding     => 40, # optional, px (defaults to 0px)
            },
        ],
        # arrange the previous two layout using a glue layout
        layout => {
            name => 'FixedDimension',
            dimension => 'horizontal',
            n => 2
        }
        target_file => 'sample_sprite.png',
        format => 'png8', # optional, default is png
    );

Note the optional include_in_css option, which allows to exclude a group of
images from the CSS (still including them in the resulting image).

=cut

sub compose_sprite {
    my $self = shift;
    my %options = @_;

    if (exists $options{layout}) {
        return $self->_compose_sprite_with_glue(%options);
    }
    else {
        return $self->_compose_sprite_without_glue(%options);
    }
}

=head2 make_sprite

Creates the sprite file out of the specifed image files or directories, and
according to the given layout name.

    my $is_error = $SpriteMaker->make_sprite(
        source_images => ['some/file.png', path/to/some_directory],
        target_file => 'sample_sprite.png',
        layout_name => 'Packed',

        # all imagemagick supported formats
        format => 'png8', # optional, default is png
    );

returns true if an error occurred during the procedure.

Available layouts are:

=over 4

=item * Packed: try to pack together the images as much as possible to reduce the
  image size.

=item * DirectoryBased: put images under the same directory on the same horizontal
  row. Order alphabetically within each row.

=item * FixedDimension: arrange a maximum of B<n> images on the same row (or
  column).

=back

=cut

sub make_sprite {
    my $self    = shift;
    my %options = @_;

    my $rh_sources_info = $self->_ensure_sources_info(%options);
    my $Layout          = $self->_ensure_layout(%options, 
        rh_sources_info => $rh_sources_info
    );

    return $self->_write_image(%options,
        Layout => $Layout,
        rh_sources_info => $rh_sources_info
    );
}

=head2 print_css

Creates and prints the css stylesheet for the sprite that was previously
produced.

You can specify the filename or the filehandle where the output CSS should be
written:

    $SpriteMaker->print_css(
       filehandle => $fh, 
    );

OR

    $SpriteMaker->print_css(
       filename => 'relative/path/to/style.css',
    );

Optionally you can provide the name of the image file that should be included in
the CSS file instead of the default one:

    # within the style.css file, override the default path to the sprite image
    # with "custom/path/to/sprite.png".
    #
    $SpriteMaker->print_css(
       filename => 'relative/path/to/style.css',
       sprite_filename => 'custom/path/to/sprite.png', # optional
    );


NOTE: make_sprite() must be called before this method is called.

=cut

sub print_css {
    my $self     = shift;
    my %options  = @_;
    
    my $rh_sources_info = $self->_ensure_sources_info(%options);
    my $Layout          = $self->_ensure_layout(%options,
        rh_sources_info => $rh_sources_info    
    );

    my $fh = $self->_ensure_filehandle_write(%options);

    $self->_verbose("  * writing css file");

    my $target_image_filename;
    if (exists $options{sprite_filename} && $options{sprite_filename}) {
        $target_image_filename = $options{sprite_filename};
    }

    my $stylesheet = $self->_get_stylesheet_string({
            target_image_filename => $target_image_filename,
            use_full_images => 0
        },
        %options
    );

    print $fh $stylesheet;

    return 0;
}

=head2 print_fake_css

Fake a css spritesheet by generating a stylesheet containing just the original
images (not the ones coming from the sprite!)

    $SpriteMaker->print_fake_css(
       filename        => 'relative/path/to/style.css',
       fix_image_path => {
           find: '/some/absolute/path',  # a Perl regexp 
           replace: 'some/relative/path'
       }
    );

NOTE: unlike print_css you don't need to call this method after make_sprite.

=cut

sub print_fake_css {
    my $self     = shift;
    my %options  = @_;
    
    my $rh_sources_info = $self->_ensure_sources_info(%options);

    my $fh = $self->_ensure_filehandle_write(%options);

    $self->_verbose("  * writing fake css file");

    if (exists $options{sprite_filename}) {
        die "the sprite_filename option is incompatible with fake_css. In this mode the original images are used in the spritesheet"; 
    }

    my $stylesheet = $self->_get_stylesheet_string({
            use_full_images => 1
        },
        %options
    );

    print $fh $stylesheet;

    return 0;
}

=head2 print_html

Creates and prints an html sample page containing informations about each sprite produced.

    $SpriteMaker->print_html(
       filehandle => $fh, 
    );

OR

    $SpriteMaker->print_html(
       filename => 'relative/path/to/index.html',
    );

NOTE: make_sprite() must be called before this method is called.

=cut
sub print_html {
    my $self    = shift;
    my %options = @_;
    
    my $rh_sources_info = $self->_ensure_sources_info(%options);
    my $Layout          = $self->_ensure_layout(%options,
        rh_sources_info => $rh_sources_info
    );
    my $fh              = $self->_ensure_filehandle_write(%options);
    
    $self->_verbose("  * writing html sample page");

    my $stylesheet = $self->_get_stylesheet_string({}, %options);

    print $fh '<html><head><style type="text/css">';
    print $fh $stylesheet;
    print $fh <<EOCSS;
    h1 {
        color: #0073D9;
    }
    .color {
        width: 10px;
        height: 10px;
        margin: 1px;
        float: left;
        border: 1px solid black;
    }
    .item {
        margin-bottom: 1em;
    }
    .item-container {
        background-color: #BCE;
        max-width: 340px;
        margin: 10px;
        -webkit-border-radius: 10px;
        -moz-border-radius: 10px;
        -o-border-radius: 10px;
        border-radius: 10px;
        overflow: hidden;
        float: left;
    }
    .included {
        background-color: #BCE;
    }
    .not-included {
        background-color: #BEBEBE;
    }
EOCSS
    print $fh '</style></head><body><h1>CSS::SpriteMaker Image Information</h1>';

    # html
    for my $id (sort { $a <=> $b } keys %$rh_sources_info) {
        my $rh_source_info = $rh_sources_info->{$id};
        my $css_class = $self->_generate_css_class_name($rh_source_info->{name});
        $self->_verbose(
            sprintf("%s -> %s", $rh_source_info->{name}, $css_class)
        );

        $css_class =~ s/[.]//;

        my $is_included = $rh_source_info->{include_in_css};
        my $width = $rh_source_info->{original_width};
        my $height = $rh_source_info->{original_height};

        my $onclick = <<EONCLICK;
    if (typeof current !== 'undefined' && current !== this) {
        current.style.width = current.w;
        current.style.height = current.h;
        current.style.position = '';
        delete current.w;
        delete current.h;
    }
    if (typeof this.h === 'undefined') {
        this.h = this.style.height;
        this.w = this.style.width;
        this.style.width = '';
        this.style.height = '';
        this.style.position = 'fixed';
        current = this;
    }
    else {
        this.style.width = this.w;
        this.style.height = this.h;
        this.style.position = '';
        delete this.w;
        delete this.h;
        current = undefined;
    }
EONCLICK


        print $fh sprintf(
            '<div class="item-container%s" onclick="%s" style="padding: 1em; width: %spx; height: %spx;">',
            $is_included ? ' included' : ' not-included',
            $onclick,
            $width, $height
        );

            
        if ($is_included) {
            print $fh "  <div class=\"item $css_class\"></div>";
        }
        else {
            print $fh "  <div class=\"item\" style=\"width: ${width}px; height: ${height}px;\"></div>";
        }
        print $fh "  <div class=\"item_description\">";
        for my $key (sort keys %$rh_source_info) {
            next if $key eq "colors";
            print $fh "<b>" . $key . "</b>: " . ($rh_source_info->{$key} // 'none') . "<br />";
        }

        print $fh '<h3>Colors</h3>';
        print $fh "<b>total</b>: " . $rh_source_info->{colors}{total} . '<br />';

        if ($self->{enable_colormap}) {
            for my $colors (sort keys %{$rh_source_info->{colors}{map}}) {
                my ($r, $g, $b, $a) = split /,/, $colors;
                my $rrgb = $r * 255 / $self->{color_max};
                my $grgb = $g * 255 / $self->{color_max};
                my $brgb = $b * 255 / $self->{color_max};
                my $argb = 255 - ($a * 255 / $self->{color_max});
                print $fh '<div class="color" style="background-color: ' . "rgba($rrgb, $grgb, $brgb, $argb);\"></div>";
            }
        }

        print $fh "  </div>";
        print $fh '</div>';
    }

    print $fh "</body></html>";

    return 0;
}

=head2 get_css_info_structure

Returns an arrayref of hashrefs like:

    [
        {
            full_path => 'relative/path/to/file.png',
            css_class => 'file',
            width     => 16,  # pixels
            height    => 16,
            x         => 173, # offset within the layout
            y         => 234,
        },
        ...more
    ]

This structure can be used to build your own html or css stylesheet for
example.

NOTE: the x y offsets within the layout, will be always positive numbers.

=cut

sub get_css_info_structure {
    my $self            = shift;
    my %options         = @_;

    my $rh_sources_info = $self->_ensure_sources_info(%options);
    my $Layout          = $self->_ensure_layout(%options,
        rh_sources_info => $rh_sources_info
    );

    my $rh_id_to_class  = $self->_generate_css_class_names($rh_sources_info);

    my @css_info;

    for my $id (sort { $a <=> $b } keys %$rh_sources_info) {
        my $rh_source_info = $rh_sources_info->{$id};
        my $css_class = $rh_id_to_class->{$id};

        my ($x, $y) = $Layout->get_item_coord($id);

        push @css_info, {
            full_path => $rh_source_info->{pathname},
            x => $x + $rh_source_info->{add_extra_padding},
            y => $y + $rh_source_info->{add_extra_padding},
            css_class => $css_class,
            width => $rh_source_info->{original_width},
            height => $rh_source_info->{original_height},
        };
    }

    return \@css_info;
}

=head1 PRIVATE METHODS

=head2 _generate_css_class_names

Returns a mapping id -> class_name out of the current information structure.

It guarantees unique class_name for each id.

=cut

sub _generate_css_class_names {
    my $self = shift;
    my $rh_source_info = shift;;

    my %existing_classnames_lookup;
    my %id_to_class_mapping;

    PROCESS_SOURCEINFO:
    for my $id (sort { $a <=> $b } keys %$rh_source_info) {
        
        next PROCESS_SOURCEINFO if !$rh_source_info->{$id}{include_in_css};

        my $css_class = $self->_generate_css_class_name(
            $rh_source_info->{$id}{name}
        );
        
        # keep modifying the css_class name until it doesn't exist in the hash
        my $i = 0;
        while (exists $existing_classnames_lookup{$css_class}) {
            # ... we want to add an incremental suffix like "-2"
            if (!$i) {
                # the first time, we want to add the prefix only, but leave the class name intact
                if ($css_class =~ m/-\Z/) {
                    # class already ends with a dash
                    $css_class .= '1';
                }
                else {
                    $css_class .= '-1';
                }
            }
            elsif ($css_class =~ m/-(\d+)\Z/) { # that's our dash added before!
                my $current_number = $1;
                $current_number++;
                $css_class =~ s/-\d+\Z/-$current_number/;
            }
            $i++;
        }

        $existing_classnames_lookup{$css_class} = 1;
        $id_to_class_mapping{$id} = $css_class;
    }

    return \%id_to_class_mapping;
}


=head2 _image_locations_to_source_info

Identify informations from the location of each input image, and assign
numerical ids to each input image.

We use a global image identifier for composite layouts. Each identified image
must have a unique id in the scope of the same CSS::SpriteMaker instance!

=cut

sub _image_locations_to_source_info {
    my $self         = shift;
    my $ra_locations = shift;
    my $remove_source_padding = shift;
    my $add_extra_padding = shift;
    my $include_in_css = shift // 1;
    my $enable_colormap = shift;

    my %source_info;
    
    # collect properties of each input image. 
    IMAGE:
    for my $rh_location (@$ra_locations) {

        my $id = $self->_get_image_id;

        my %properties = %{$self->_get_image_properties(
            $rh_location->{pathname},
            $remove_source_padding,
            $add_extra_padding,
            $enable_colormap
        )};

        # add whether to include this item in the css or not
        $properties{include_in_css} = $include_in_css;

        # this is really for write_image, it should add padding as necessary
        $properties{add_extra_padding} = $add_extra_padding;

        # skip invalid images
        next IMAGE if !%properties;

        for my $key (keys %$rh_location) {
            $source_info{$id}{$key} = $rh_location->{$key};
        }
        for my $key (keys %properties) {
            $source_info{$id}{$key} = $properties{$key};
        }
    }

    return \%source_info;
}

=head2 _get_image_id

Returns a global numeric identifier.

=cut

sub _get_image_id {
    my $self = shift;
    $self->{_unique_id} //= 0;
    return $self->{_unique_id}++;
}

=head2 _locate_image_files

Finds the location of image files within the given directory. Returns an
arrayref of hashrefs containing information about the names and pathnames of
each image file.

The returned arrayref looks like:

    [   # pathnames of the first image to follow
        {
            name => 'image.png',
            pathname => '/complete/path/to/image.png',
            parentdir => '/complete/path/to',
        },
        ...
    ]

Dies if the given directory is empty or doesn't exist.

=cut

sub _locate_image_files {
    my $self             = shift;
    my $source_directory = shift;

    if (!defined $source_directory) {
        die "you have called _locate_image_files but \$source_directory was undefined";
    }

    $self->_verbose(" * gathering files and directories of source images");

    my @locations;
    find(sub {
        my $filename = $_;
        my $fullpath = $File::Find::name;
        my $parentdir = $File::Find::dir;
    
        return if $filename eq '.';

        if (-f $filename) {
            push @locations, {
                # only the name of the file 
                name     => $filename,

                # the full relative pathname
                pathname => $fullpath,

                # the full relative path to the parent directory
                parentdir => $parentdir
            };
        }

    }, $source_directory);

    return \@locations;
}

=head2 _get_stylesheet_string

Returns the stylesheet in a string.

=cut

sub _get_stylesheet_string {
    my $self = shift;
    my $rh_opts = shift // {};
    my %options = @_;

    # defaults
    my $target_image_filename = $self->{_cache_target_image_file};
    if (exists $rh_opts->{target_image_filename} && defined $rh_opts->{target_image_filename}) {
        $target_image_filename = $rh_opts->{target_image_filename};
    }

    my $use_full_images = 0;
    if (exists $rh_opts->{use_full_images} && defined $rh_opts->{use_full_images}) {
        $use_full_images = $rh_opts->{use_full_images};
    }

    my $rah_cssinfo = $self->get_css_info_structure(%options); 

    my @classes = map { "." . $_->{css_class} } 
        grep { defined $_->{css_class} }
        @$rah_cssinfo;

    my @stylesheet;

    if ($use_full_images) {
        my ($f, $r);
        my $is_path_to_be_fixed = 0;
        if (exists $options{fix_image_path} && 
            exists $options{fix_image_path}{find} && 
            exists $options{fix_image_path}{replace}) {

            $is_path_to_be_fixed = 1;
            $f = qr/$options{fix_image_path}{find}/;
            $r = $options{fix_image_path}{replace};
        }

        ##
        ## use full images instead of the ones from the sprite
        ##
        for my $rh_info (@$rah_cssinfo) {

            # fix the path (maybe)
            my $path = $rh_info->{full_path};
            if ($is_path_to_be_fixed) {
                $path =~ s/$f/$r/;
            }

            if (defined $rh_info->{css_class}) {
                push @stylesheet, sprintf(
                    ".%s { background-image: url('%s'); width: %spx; height: %spx; }",
                    $rh_info->{css_class}, 
                    $path,
                    $rh_info->{width},
                    $rh_info->{height},
                );
            }
        }
    }
    else {
        # write header
        # header associates the sprite image to each class
        push @stylesheet, sprintf(
            "%s { background-image: url('%s'); background-repeat: no-repeat; }",
            join(",", @classes),
            $target_image_filename
        );

        for my $rh_info (@$rah_cssinfo) {
            if (defined $rh_info->{css_class}) {
                push @stylesheet, sprintf(
                    ".%s { background-position: %spx %spx; width: %spx; height: %spx; }",
                    $rh_info->{css_class}, 
                    -1 * $rh_info->{x},
                    -1 * $rh_info->{y},
                    $rh_info->{width},
                    $rh_info->{height},
                );
            }
        }
    }

    return join "\n", @stylesheet;
}


=head2 _generate_css_class_name

This method generates the name of the CSS class for a certain image file. Takes
the image filename as input and produces a css class name (excluding the
prepended ".").

=cut

sub _generate_css_class_name {
    my $self     = shift;
    my $filename = shift;

    my $rc_filename_to_classname = $self->{rc_filename_to_classname};
    my $rc_override_classname = $self->{rc_override_classname};

    if (defined $rc_filename_to_classname) {
        my $classname = $rc_filename_to_classname->($filename);
        if (!$classname) {
            warn "custom sub to generate class names out of file names returned empty class for file name $filename";
        }
        if ($classname =~ m/^[.]/) {
            warn sprintf('your custom sub should not include \'.\' at the beginning of the class name. (%s was generated from %s)',
                $classname,
                $filename
            );
        }
    
        if (defined $rc_override_classname) {
            $classname = $rc_override_classname->($classname);
        }

        return $classname;
    }

    # prepare (lowercase)
    my $css_class = lc($filename);

    # remove image extensions if any
    $css_class =~ s/[.](tif|tiff|gif|jpeg|jpg|jif|jfif|jp2|jpx|j2k|j2c|fpx|pcd|png|pdf)\Z//;

    # remove @ [] +
    $css_class =~ s/[+@\]\[]//g;

    # turn certain characters into dashes
    $css_class =~ s/[\s_.]/-/g;

    # remove dashes if they appear at the end
    $css_class =~ s/-\Z//g;

    # remove initial dashes if any
    $css_class =~ s/\A-+//g;

    # add prefix if it was requested
    if (defined $self->{css_class_prefix}) {
        $css_class = $self->{css_class_prefix} . $css_class;
    }

    # allow change (e.g., add prefix)
    if (defined $rc_override_classname) {
        $css_class = $rc_override_classname->($css_class);
    }

    return $css_class;
}


=head2 _ensure_filehandle_write

Inspects the input %options hash and returns a filehandle according to the
parameters passed in there.

The filehandle is where something (css stylesheet for example) is going to be
printed.

=cut

sub _ensure_filehandle_write {
    my $self = shift;
    my %options = @_;

    return $options{filehandle} if defined $options{filehandle};

    if (defined $options{filename}) {
        open my ($fh), '>', $options{filename};
        return $fh;
    }

    return \*STDOUT;
}

=head2 _ensure_sources_info

Makes sure the user of this module has provided a valid input parameter for
sources_info and return the sources_info structure accordingly. Dies in case
something goes wrong with the user input.

Parameters that allow us to obtain a $rh_sources_info structure are: 

- source_images: an arrayref of files or directories, directories will be
  visited recursively and any image file in it becomes the input.

If none of the above parameters have been found in input options, the cache is
checked before giving up - i.e., the user has previously provided the layout
parameter, and was able to generate a sprite. 

=cut

sub _ensure_sources_info {
    my $self = shift;
    my %options = @_;

    ##
    ## Shall we remove source padding?
    ## - first check if an option is provided
    ## - otherwise default to the option in $self
    my $remove_source_padding = $self->{remove_source_padding};
    my $add_extra_padding = $self->{add_extra_padding};
    my $enable_colormap = $self->{enable_colormap};
    if (exists $options{remove_source_padding} 
        && defined $options{remove_source_padding}) {

        $remove_source_padding = $options{remove_source_padding};
    }
    if (exists $options{add_extra_padding} 
        && defined $options{add_extra_padding}) {

        $add_extra_padding = $options{add_extra_padding};
    }
    if (exists $options{enable_colormap}
        && defined $options{enable_colormap}) {

        $enable_colormap = $options{enable_colormap};
    }

    my $rh_source_info;

    return $options{source_info} if exists $options{source_info};

    my @source_images;

    if (exists $options{source_dir} && defined $options{source_dir}) {
        push @source_images, $options{source_dir};
    }

    if (exists $options{source_images} && defined $options{source_images}) {
        die 'source_images parameter must be an ARRAY REF' if ref $options{source_images} ne 'ARRAY';
        push @source_images, @{$options{source_images}};
    }

    if (@source_images) {
        # locate each file within each directory and then identify all...
        my @locations;
        for my $file_or_dir (@source_images) {
            my $ra_locations = $self->_locate_image_files($file_or_dir);
            push @locations, @$ra_locations;
        }

        my $include_in_css = exists $options{include_in_css} 
            ? $options{include_in_css}
            : 1;

        $rh_source_info = $self->_image_locations_to_source_info(
            \@locations,
            $remove_source_padding,
            $add_extra_padding,
            $include_in_css,
            $enable_colormap
        );
    }
    
    if (!$rh_source_info) {
        if (exists $self->{_cache_rh_source_info}
            && defined $self->{_cache_rh_source_info}) {

            $rh_source_info = $self->{_cache_rh_source_info};
        }
        else {
            die "Unable to create the source_info_structure!";
        }
    }

    return $rh_source_info;
}



=head2 _ensure_layout

Makes sure the user of this module has provided valid layout options and
returns a $Layout object accordingly. Dies in case something goes wrong with
the user input. A Layout actually runs over the specified items on instantiation.

Parameters in %options (see code) that allow us to obtain a $Layout object are:

- layout: a CSS::SpriteMaker::Layout object already;
- layout: can also be a hashref like 

    {
        name => 'LayoutName',
        options => {
            'Layout-Specific option' => 'value',
            ...
        }
    }

- layout_name: the name of a CSS::SpriteMaker::Layout object.

If none of the above parameters have been found in input options, the cache is
checked before giving up - i.e., the user has previously provided the layout
parameter... 

=cut 

sub _ensure_layout {
    my $self = shift;
    my %options = @_;

    die 'rh_sources_info parameter is required' if !exists $options{rh_sources_info};

    # Get the layout from the layout parameter in case it is a $Layout object
    my $Layout;
    if (exists $options{layout} && $options{layout} && ref $options{layout} ne 'HASH') {
        if (exists $options{layout}{_layout_ran}) {
            $Layout = $options{layout};
        }
        else {
            warn 'a Layout object was specified but strangely was not executed on the specified items. NOTE: if a layout is instantiated it\'s always ran over the items!';
        }
    }

    if (defined $Layout) {
        if (exists $options{layout_name} && defined $options{layout_name}) {
            warn 'the parameter layout_name was ignored as the layout parameter was specified. These two parameters are mutually exclusive.';
        }
    }
    else {
        ##
        ## We were unable to get the layout object directly, so we need to
        ## create the layout from a name if possible...
        ##

        $self->_verbose(" * creating layout");

        # the layout name can be specified in the options as layout_name
        my $layout_name = '';
        my $layout_options;
        if (exists $options{layout_name}) {
            $layout_name = $options{layout_name};
            # if this is the case this layout must support no options
            $layout_options = {};  
        }

        # maybe a layout => { name => 'something' was specified }
        if (exists $options{layout} && exists $options{layout}{name}) {
            $layout_name = $options{layout}{name};
            $layout_options = $options{layout}{options} // {};
        }

        LOAD_LAYOUT_PLUGIN:
        for my $plugin ($self->plugins()) {
            my ($plugin_name) = reverse split "::", $plugin;
            if ($plugin eq $layout_name || $plugin_name eq $layout_name) {
                $self->_verbose(" * using layout $plugin");
                $Layout = $plugin->new($options{rh_sources_info}, $layout_options);
                last LOAD_LAYOUT_PLUGIN;
            }
        }

        if (!defined $Layout && $layout_name ne '') {
            die sprintf(
                "The layout you've specified (%s) couldn't be found. Valid layouts are:\n%s",
                $layout_name,
                join "\n", $self->plugins()
            );
        }
    }

    #
    # Still no layout, check the cache!
    #
    if (!defined $Layout) {
        # try checking in the cache before giving up...
        if (exists $self->{_cache_layout} 
            && defined $self->{_cache_layout}) {
 
            $Layout = $self->{_cache_layout};
        }
    }

    #
    # Still nothing, then use default layout
    #
    if (!defined $Layout) {
        my $layout_name = $self->{layout}{name};
        my $layout_options = {};
        LOAD_DEFAULT_LAYOUT_PLUGIN:
        for my $plugin ($self->plugins()) {
            my ($plugin_name) = reverse split "::", $plugin;
            if ($plugin eq $layout_name || $plugin_name eq $layout_name) {
                $self->_verbose(" * using DEFAULT layout $plugin");
                $Layout = $plugin->new($options{rh_sources_info}, $layout_options);
                last LOAD_DEFAULT_LAYOUT_PLUGIN;
            }
        }
    }

    return $Layout;
}

sub _write_image {
    my $self    = shift;
    my %options = @_;

    my $target_file   = $options{target_file} // $self->{target_file};
    my $output_format = $options{format} // $self->{format};
    my $Layout        = $options{Layout} // 0;
    my $rh_sources_info = $options{rh_sources_info} // 0;

    if (!$target_file) {
        die "the ``target_file'' parameter is required for this subroutine or you must instantiate Css::SpriteMaker with the target_file parameter";
    }

    if (!$rh_sources_info) {
        die "The 'rh_sources_info' parameter must be passed to _write_image";
    }

    if (!$Layout) {
        die "The 'layout' parameter needs to be specified for _write_image, and must be a CSS::SpriteMaker::Layout object";
    }

    $self->_verbose(" * writing sprite image");

    $self->_verbose(sprintf("Target image size: %s, %s",
        $Layout->width(),
        $Layout->height())
    );

    my $Target = Image::Magick->new();

    $Target->Set(size => sprintf("%sx%s",
        $Layout->width(),
        $Layout->height()
    ));

    # prepare the target image
    if (my $err = $Target->ReadImage('xc:white')) {
        warn $err;
    }
    $Target->Set(type => 'TruecolorMatte');
    
    # make it transparent
    $self->_verbose(" - clearing canvas");
    $Target->Draw(
        fill => 'transparent', 
        primitive => 'rectangle', 
        points => sprintf("0,0 %s,%s", $Layout->width(), $Layout->height())
    );
    $Target->Transparent('color' => 'white');

    # place each image according to the layout
    ITEM_ID:
    for my $source_id ($Layout->get_item_ids) {
        my $rh_source_info = $rh_sources_info->{$source_id};
        my ($layout_x, $layout_y) = $Layout->get_item_coord($source_id);

        $self->_verbose(sprintf(" - placing %s (format: %s  size: %sx%s  position: [%s,%s])",
            $rh_source_info->{pathname},
            $rh_source_info->{format},
            $rh_source_info->{width},
            $rh_source_info->{height},
            $layout_y,
            $layout_x
        ));
        my $I = Image::Magick->new(); 
        my $err = $I->Read($rh_source_info->{pathname});
        if ($err) {
            warn $err;
            next ITEM_ID;
        }

        my $padding = $rh_source_info->{add_extra_padding};

        my $destx = $layout_x + $padding;
        my $desty = $layout_y + $padding;
        $Target->Composite(image=>$I,compose=>'xor',geometry=>"+$destx+$desty");
    }

    # write target image
    my $err = $Target->Write("$output_format:".$target_file);
    if ($err) {
        warn "unable to obtain $target_file for writing it as $output_format. Perhaps you have specified an invalid format. Check http://www.imagemagick.org/script/formats.php for a list of supported formats. Error: $err";

        $self->_verbose("Wrote $target_file");

        return 1;
    }

    # cache the layout and the rh_info structure so that it hasn't to be passed
    # as a parameter next times.
    $self->{_cache_layout} = $Layout;

    # cache the target image file, as making the stylesheet can't be done
    # without this information.
    $self->{_cache_target_image_file} = $target_file;

    # cache sources info
    $self->{_cache_rh_source_info} = $rh_sources_info;

    return 0;
    
}

=head2 _get_image_properties

Return an hashref of information about the image at the given pathname.

=cut

sub _get_image_properties {
    my $self       = shift;
    my $image_path = shift;
    my $remove_source_padding = shift;
    my $add_extra_padding = shift;
    my $enable_colormap = shift;

    my $Image = Image::Magick->new();

    my $err = $Image->Read($image_path);
    if ($err) {
        warn $err;
        return {};
    }

    my $rh_info = {};
    $rh_info->{first_pixel_x} = 0,
    $rh_info->{first_pixel_y} = 0,
    $rh_info->{width} = $Image->Get('columns');
    $rh_info->{height} = $Image->Get('rows');
    $rh_info->{comment} = $Image->Get('comment');
    $rh_info->{colors}{total} = $Image->Get('colors');
    $rh_info->{format} = $Image->Get('magick');

    if ($remove_source_padding) {
        #
        # Find borders for this image.
        #
        # (RE-)SET:
        # - first_pixel(x/y) as the true point the image starts
        # - width/height as the true dimensions of the image
        #
        my $w = $rh_info->{width};
        my $h = $rh_info->{height};

        # seek for left/right borders
        my $first_left = 0;
        my $first_right = $w-1;
        my $left_found = 0;
        my $right_found = 0;

        BORDER_HORIZONTAL:
        for my $x (0 .. ceil(($w-1)/2)) {
            my $xr = $w-$x-1;
            for my $y (0..$h-1) {
                my $al = $Image->Get(sprintf('pixel[%s,%s]', $x, $y));
                my $ar = $Image->Get(sprintf('pixel[%s,%s]', $xr, $y));
                
                # remove rgb info and only get alpha value
                $al =~ s/^.+,//;
                $ar =~ s/^.+,//;

                if ($al != $self->{color_max} && !$left_found) {
                    $first_left = $x;
                    $left_found = 1;
                }
                if ($ar != $self->{color_max} && !$right_found) {
                    $first_right = $xr;
                    $right_found = 1;
                }
                last BORDER_HORIZONTAL if $left_found && $right_found;
            }
        }
        $rh_info->{first_pixel_x} = $first_left;
        $rh_info->{width} = $first_right - $first_left + 1;

        # seek for top/bottom borders
        my $first_top = 0;
        my $first_bottom = $h-1;
        my $top_found = 0;
        my $bottom_found = 0;

        BORDER_VERTICAL:
        for my $y (0 .. ceil(($h-1)/2)) {
            my $yb = $h-$y-1;
            for my $x (0 .. $w-1) {
                my $at = $Image->Get(sprintf('pixel[%s,%s]', $x, $y));
                my $ab = $Image->Get(sprintf('pixel[%s,%s]', $x, $yb));
                
                # remove rgb info and only get alpha value
                $at =~ s/^.+,//;
                $ab =~ s/^.+,//;

                if ($at != $self->{color_max} && !$top_found) {
                    $first_top = $y;
                    $top_found = 1;
                }
                if ($ab != $self->{color_max} && !$bottom_found) {
                    $first_bottom = $yb;
                    $bottom_found = 1;
                }
                last BORDER_VERTICAL if $top_found && $bottom_found;
            }
        }
        $rh_info->{first_pixel_y} = $first_top;
        $rh_info->{height} = $first_bottom - $first_top + 1;
    }

    if ($enable_colormap) {
        $self->_generate_colormap_for_image_properties($Image, $rh_info);
    }

    # save the original width as it may change later
    $rh_info->{original_width} = $rh_info->{width};
    $rh_info->{original_height} = $rh_info->{height};

    if ($add_extra_padding) {
        # fix the width of the image if a padding was added, as if the image
        # was actually wider
        $rh_info->{width} += 2 * $add_extra_padding;
        $rh_info->{height} += 2 * $add_extra_padding;
    }

    return $rh_info; 
}

=head2 _compose_sprite_with_glue

Compose a layout though a glue layout: first each image set is layouted, then
it is composed using the specified glue layout.

=cut

sub _compose_sprite_with_glue {
    my $self = shift;
    my %options = @_;

    my @parts = @{$options{parts}};

    my $i = 0;

    # compose the following rh_source_info of Layout objects
    my $rh_layout_source_info = {};

    # also join each rh_sources_info_from the parts...
    my %global_sources_info;

    # keep all the layouts
    my @layouts;

    # layout each part
    for my $rh_part (@parts) {

        my $rh_sources_info = $self->_ensure_sources_info(%$rh_part);
        for my $key (sort { $a <=> $b } keys %$rh_sources_info) {
            $global_sources_info{$key} = $rh_sources_info->{$key};
        }

        my $Layout = $self->_ensure_layout(%$rh_part,
            rh_sources_info => $rh_sources_info
        );

        # we now do as if we were having images, but actually we have layouts
        # to do this we re-build a typical rh_sources_info.
        $rh_layout_source_info->{$i++} = {
            name => sprintf("%sLayout%s", $options{layout_name} // $options{layout}{name}, $i),
            pathname => "/fake/path_$i",
            parentdir => "/fake",
            width => $Layout->width,
            height => $Layout->height,
            first_pixel_x => 0,
            first_pixel_y => 0,
        };

        # save this layout
        push @layouts, $Layout;
    }

    # now that we have the $rh_source_info **about layouts**, we layout the
    # layouts...
    my $LayoutOfLayouts = $self->_ensure_layout(
        layout => $options{layout},
        rh_sources_info => $rh_layout_source_info,
    );

    # we need to adjust the position of each element of the layout according to
    # the positions of the elements in $LayoutOfLayouts
    my $FinalLayout;
    for my $layout_id ($LayoutOfLayouts->get_item_ids()) {
        my $Layout = $layouts[$layout_id];
        my ($dx, $dy) = $LayoutOfLayouts->get_item_coord($layout_id);
        $Layout->move_items($dx, $dy);
        if (!$FinalLayout) {
            $FinalLayout = $Layout;
        }
        else {
            # merge $FinalLayout <- $Layout
            $FinalLayout->merge_with($Layout);
        }
    }

    # fix width and height
    $FinalLayout->{width} = $LayoutOfLayouts->width();
    $FinalLayout->{height} = $LayoutOfLayouts->height();

    # now simply draw the FinalLayout
    return $self->_write_image(%options,
        Layout => $FinalLayout,
        rh_sources_info => \%global_sources_info,
    );
}

=head2 _compose_sprite_without_glue

Compose a layout without glue layout: the previously lay-outed image set
becomes part of the next image set.

=cut

sub _compose_sprite_without_glue {
    my $self = shift;
    my %options = @_;

    my %global_sources_info;

    my @parts = @{$options{parts}};

    my $LayoutOfLayouts;

    my $i = 0;

    for my $rh_part (@parts) {
        $i++;
        
        # gather information about images in the current part
        my $rh_sources_info = $self->_ensure_sources_info(%$rh_part);

        # keep composing the global sources_info structure
        # as we find new images... we will need this later
        # when we actually write the image.
        for my $key (sort { $a <=> $b } keys %$rh_sources_info) {
            $global_sources_info{$key} = $rh_sources_info->{$key};
        }

        if (!defined $LayoutOfLayouts) {
            # we keep the first layout
            $LayoutOfLayouts = $self->_ensure_layout(%$rh_part,
                rh_sources_info => $rh_sources_info
            );
        }
        else {
            # tweak the $rh_sources_info to include a new
            # fake image (the previously created layout)
            my $fake_img_id = $self->_get_image_id();
            $rh_sources_info->{$fake_img_id} = {
                name => 'FakeImage' . $i,
                pathname => "/fake/path_$i",
                parentdir => "/fake",
                width => $LayoutOfLayouts->width,
                height => $LayoutOfLayouts->height,
                first_pixel_x => 0,
                first_pixel_y => 0,
            };

            # we merge down this layout with the first
            # one, but first we must fix it, as it may
            # have been moved during this second
            # iteration.
            my $Layout = $self->_ensure_layout(%$rh_part,
                rh_sources_info => $rh_sources_info
            );

            # where was LayoutOfLayout positioned?
            my ($lol_x, $lol_y) = $Layout->get_item_coord($fake_img_id);

            # fix previous layout
            $LayoutOfLayouts->move_items($lol_x, $lol_y);

            # now remove it from $Layout and merge down!
            $Layout->delete_item($fake_img_id);
            $LayoutOfLayouts->merge_with($Layout);

            # fix the width that doesn't get updated with
            # the new layout...
            $LayoutOfLayouts->{width} = $Layout->width();
            $LayoutOfLayouts->{height} = $Layout->height();
        }
    }

    # draw it all!
    return $self->_write_image(%options,
        Layout => $LayoutOfLayouts,
        rh_sources_info => \%global_sources_info
    );
}


=head2 _generate_color_histogram

Generate color histogram out of the information structure of all the images.

=cut

sub _generate_color_histogram {
    my $self           = shift;
    my $rh_source_info = shift;

    if (!$self->{enable_colormap}) {
        die "cannot generate color histogram with enable_colormap option disabled";
    }

    my %histogram;
    for my $id (sort { $a <=> $b } keys %$rh_source_info) {
        for my $color (sort keys %{ $rh_source_info->{$id}{colors}{map} }) {
            my $rah_colors_info = $rh_source_info->{$id}{colors}{map}{$color};

            $histogram{$color} = scalar @$rah_colors_info;
        }
    }

    return \%histogram;
}

=head2 _verbose

Print verbose output only if the verbose option was passed as input.

=cut

sub _verbose {
    my $self = shift;
    my $msg  = shift;

    if ($self->{is_verbose}) {
        print "${msg}\n";
    }
}

=head2 _generate_colormap_for_image_properties

Load the color map into the image properties hashref. This method takes 85% of
the execution time when the sprite is generated with enable_colormap = 1.

=cut


sub _generate_colormap_for_image_properties {
    my($self, $Image, $rh_info) = @_;
    return 1 if ref  $rh_info->{colors}{map};
    # Store information about the color of each pixel
    $rh_info->{colors}{map} = {};
    my $x = 0;
    for my $fake_x ($rh_info->{first_pixel_x} .. $rh_info->{width}) {

        my $y = 0;
        for my $fake_y ($rh_info->{first_pixel_y} .. $rh_info->{height}) {

            my $color = $Image->Get(
                sprintf('pixel[%s,%s]', $fake_x, $fake_y),
            );

            push @{$rh_info->{colors}{map}{$color}}, {
                x => $x,
                y => $y,
            };

            $y++;
        }
    }
    return 1;
}

=head1 LICENSE AND COPYRIGHT

Copyright 2013 Savio Dimatteo.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of CSS::SpriteMaker
