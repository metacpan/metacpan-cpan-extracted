package CSS::SpriteBuilder::Sprite;

use warnings;
use strict;
use File::Glob ":glob";
use File::Spec;
use Cwd ();
use CSS::SpriteBuilder::Constants;
use CSS::SpriteBuilder::SpriteItem;
use base 'CSS::SpriteBuilder::ImageDriver::Auto';

sub max { $_[ $_[0] < $_[1] ] }

sub new {
    my ($class, @args) = @_;

    my $self = $class->SUPER::new(
        source_dir          => undef,
        source_images       => undef,
        target_file         => undef,

        image_quality       => DEF_IMAGE_QUALITY,
        max_image_size      => DEF_MAX_IMAGE_SIZE,
        max_image_width     => DEF_MAX_IMAGE_WIDTH,
        max_image_height    => DEF_MAX_IMAGE_HEIGHT,
        max_sprite_width    => DEF_MAX_SPRITE_WIDTH,
        max_sprite_height   => DEF_MAX_SPRITE_HEIGHT,
        margin              => DEF_MARGIN,
        transparent_color   => undef,
        is_background       => 0,
        layout              => DEF_LAYOUT,
        css_selector_prefix => DEF_CSS_SELECTOR_PREFIX,
        css_url_prefix      => '',
        is_add_timestamp    => 1,

        _sprite_no          => 1,
        _repeated_images    => [],
        _sprites            => {},
        _x                  => 0,
        _y                  => 0,

        @args,
    );

    unless ( grep { $_ eq $self->{layout} } @{ LAYOUT_LIST() } ) {
        die "Invalid 'layout' parameter: $self->{layout}";
    }

    return $self;
}

sub target_file    { sprintf( $_[0]->{target_file}, $_[0]->{_sprite_no} )                }

sub _init {
    my ($self, $image) = @_;

    die "The 'target_file' parameter is not defined"    unless $self->{target_file};
    die "The 'source_images' parameter is not defined"  unless $self->{source_images};

    $self->SUPER::_init($image);

    $self->{_x} = $self->{_y} = 0;

    return;
}

sub build {
    my ($self) = @_;

    my $images = $self->search_images();
    foreach my $image (@$images) {
        $self->process_image($image);
    }

    $self->write();

    return $self->{_sprites};
}

sub search_images {
    my ($self) = @_;

    my $save_dir;
    if ( $self->{source_dir} ) {
        $save_dir = Cwd::getcwd();
        chdir $self->{source_dir} or die "Cannot chdir to $self->{source_dir}: $!\n";
    }

    my @images = grep {
           ( !$self->{max_image_size}   || -s $_->source_file() <= $self->{max_image_size}   )
        && ( !$self->{max_image_width}  || $_->width()          <= $self->{max_image_width}  )
        && ( !$self->{max_image_height} || $_->height()         <= $self->{max_image_height} )
        && ( $_->width() <= $self->{max_sprite_width} && $_->height <= $self->{max_sprite_height}
            or die "The image resolution is bigger than maximum configured value for '". $_->source_file() ."'"
        )
    } map {
        my $image_opts = $_;
        map {
            CSS::SpriteBuilder::SpriteItem->new(
                %$image_opts,
                source_file => $_,
            )
        } bsd_glob( $image_opts->{file}, File::Glob::GLOB_ERR );
    } @{ $self->{source_images} };

    if ($save_dir) {
        chdir $save_dir or die "Cannot chdir to $save_dir: $!\n";
    }

    return wantarray ? @images: \@images;
}

sub process_image {
    my ($self, $image) = @_;

    $self->allocate_space($image);

    $self->align_image($image);

    $self->save_info($image);

    $self->save_repeated_images($image)
        if $self->{layout} ne PACKED_LAYOUT && $image->{is_repeat};

    $self->post_process($image);
}

sub align_image {
    my ($self, $image) = @_;

    if ( $self->is_blank() ) {
        $self->reset($image);
    }
    else {
        $self->{_x} += $self->{margin} if $self->{_x};

        $self->extent(
            max($self->width(),  $self->{_x} + $image->width() ),
            max($self->height(), $self->{_y} + $image->height()),
        );

        $self->composite( $image, $self->{_x}, $self->{_y} );
    }

    return;
}

sub allocate_space {
    my ($self, $image) = @_;

    return if $self->is_blank();

    my $x_margin = $self->{_x} == 0 ? 0 : $self->{margin};

    if (
        $self->{layout} eq VERTICAL_LAYOUT
        || ($self->{_x} + $image->width() + $x_margin) > $self->{max_sprite_width}
    ) {
        $self->{_x} = 0;
        $self->{_y} = $self->height() + $self->{margin};
    }

    if (
        $self->{_y} > 0 && (
            $self->{layout} eq HORIZONTAL_LAYOUT
            || ($self->{_y} + $image->height() + $self->{margin}) > $self->{max_sprite_height}
        )
    ) {
        $self->write();
    }

    return;
}

sub save_info {
    my ($self, $image) = @_;

    my (undef, undef, $filename) = File::Spec->splitpath( $self->target_file() );
    my $sprite_image = $self->{css_url_prefix} . $filename;

    $sprite_image .= '?' . time() if $self->{is_add_timestamp};

    push @{ $self->{_sprites}{$sprite_image} }, {
        image           => $image->source_file(),
        width           => $image->width(),
        height          => $image->height(),
        x               => $self->{_x},
        y               => $self->{_y},
        selector        => $image->get_css_selector( $self->{css_selector_prefix} ),
        is_background   => (
            defined $image->is_background()
                ? $image->is_background()
                : $self->{is_background}
        ) ? 1 : 0,
        repeat          => $self->{layout} ne PACKED_LAYOUT && $image->is_repeat()
            ? $self->{layout} eq HORIZONTAL_LAYOUT ? 'y' : 'x'
            : 'no'
        ,
    };

    return;
}

sub save_repeated_images {
    my ($self, $image) = @_;

    push @{ $self->{_repeated_images} }, {
        image => $image,
        x     => $self->{_x},
        y     => $self->{_y},
    };

    return;
}

sub post_process {
    my ($self, $image) = @_;

    $self->{ $self->{layout} eq VERTICAL_LAYOUT ? '_y' : '_x' } += $image->width;

    return;
}

sub write {
    my ($self) = @_;

    return if $self->is_blank();

    $self->process_repeated_images();

    $self->set_transparent_color( $self->{transparent_color} )
        if $self->{transparent_color};

    $self->set_quality( $self->{image_quality} );

    $self->SUPER::write( $self->target_file() );

    $self->{_sprite_no}++;

    $self->reset();

    return;
}

sub process_repeated_images {
    my ($self) = @_;

    return unless scalar @{ $self->{_repeated_images} };

    my $meter                = $self->{layout} eq VERTICAL_LAYOUT ? 'width' : 'height';
    my $original_sprite_size = $self->$meter();
    my $max_sprite_size      = $self->{ $self->{layout} eq VERTICAL_LAYOUT ? 'max_sprite_width' : 'max_sprite_height' };
    my @images_size          = reverse sort map { $_->{image}->$meter() } @{ $self->{_repeated_images} };
    my $max_image_size       = shift @images_size;

    for (
        my $k = int($original_sprite_size / $max_image_size) + ($original_sprite_size % $max_image_size ? 1 : 0);
        $k * $max_image_size <= $max_sprite_size;
        $k++
    ) {
        my $extented_sprite_size = $k * $max_image_size;
        unless (grep { $extented_sprite_size % $_ } @images_size) {
            $self->extent(
                $meter eq 'width'
                    ? ( $extented_sprite_size, $self->height()        )
                    : ( $self->width()       , $extented_sprite_size  )
            );

            foreach my $image_info (@{ $self->{_repeated_images} }) {
                my $image = $image_info->{image};
                my $size  = $image->$meter();

                while (($image_info->{ $self->{layout} eq VERTICAL_LAYOUT ? 'x' : 'y' } += $size) < $extented_sprite_size) {
                    $self->composite( $image, $image_info->{x}, $image_info->{y} )
                }
            }

            return;
        }
    }

    $self->{_repeated_images} = [];

    die "Can't process repeated images";
}

1;
