package CSS::SpriteBuilder;

use strict;
use warnings;
use File::Spec;
use Scalar::Util qw(openhandle);
use CSS::SpriteBuilder::Constants;
use CSS::SpriteBuilder::Sprite;

our $VERSION = '0.03';

sub new {
    my ($class, @args) = @_;

    my $self = bless {
        source_dir          => undef,
        output_dir          => undef,

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

        _sprites            => {},

        @args,
    }, $class;

    return $self;
}

sub build {
    my ($self, %args) = @_;

    my $sprites;
    if ( my $config = delete $args{config} ) {
        $sprites = $self->_parse_xml_config($config);
    }
    else {
        $sprites = delete $args{sprites};
    }

    foreach my $sprite_opts (@$sprites) {
        my $images      = delete $sprite_opts->{images};
        my $output_file = $self->{output_dir}
            ? File::Spec->catfile( $self->{output_dir}, delete $sprite_opts->{file} )
            : delete $sprite_opts->{file}
        ;

        my $sprite = CSS::SpriteBuilder::Sprite->new(
            ( map { $_ => $self->{$_} } grep { exists $self->{$_} } @{ SPRITE_OPTS() } ),
            %$sprite_opts,
            source_images => $images,
            target_file   => $output_file,
        );

        my $sprites = $sprite->build();
        $self->{_sprites} = {%{ $self->{_sprites} }, %$sprites};
    }

    return $self->{_sprites};
}

sub get_sprites_info {
    my ($self) = @_;
    return $self->{_sprites};
}

sub write_css {
    my ($self, $filename) = @_;

    my ($fh, $str);

    if ($filename) {
        if ( openhandle($filename) ) {
            $fh = $filename;
        }
        else {
            open($fh, '>', $filename) or die "Can't to open file '$filename'!";
        }
    }
    else {
        $str = '';
        open($fh, '>', \$str) or die "Can't to create file handle!";
    }

    while (my ($sprite_image, $images) = each %{ $self->{_sprites} }) {
        my @selectors = map { $_->{selector} } @$images;
        print $fh sprintf(
            "%s{background-image: url('%s') !important;}\n",
            join(',', @selectors),
            $sprite_image,
        );

        foreach my $image_info (@$images) {
            print $fh sprintf(
                "%s{background-position:%dpx %dpx !important;",
                $image_info->{selector},
                -$image_info->{x},
                -$image_info->{y},
            );

            if ( $image_info->{repeat} ne 'no' ) {
                print $fh sprintf(
                    "background-repeat:repeat-%s;",
                    $image_info->{repeat},
                );
            }

            unless ( $image_info->{is_background} ) {
                print $fh sprintf(
                    "width:%dpx;height:%dpx;",
                    $image_info->{width},
                    $image_info->{height},
                );
            }

            print $fh "}\n";
        }
    }

    unless ($filename) {
        close $fh;
        return $str;
    }

    return;
}

sub write_xml {
    my ($self, $filename) = @_;

    eval "require XML::LibXML";
    die "XML::LibXML module is required!" if $@;

    my $dom     = XML::LibXML::Document->new();
    my $root_el = $dom->createElement('root');
    $dom->setDocumentElement($root_el);

    while (my ($sprite_image, $images) = each %{ $self->{_sprites} }) {
        my $sprite_el = $dom->createElement('sprite');
        $root_el->appendChild($sprite_el);
        $sprite_el->setAttribute('src', $sprite_image);

        foreach my $image (@$images) {
            my $image_el = $dom->createElement('image');
            $sprite_el->appendChild($image_el);
            while (my ($key, $value) = each %$image) {
                $image_el->setAttribute($key, $value);
            }
        }
    }

    if ($filename) {
        if ( openhandle($filename) ) {
            return $dom->toFH($filename, 2);
        }
        else {
            return $dom->toFile($filename, 2);
        }
    }

    return $dom->toString(2);
}

sub write_html {
    my ($self, $filename) = @_;

    my ($fh, $str);

    if ($filename) {
        if ( openhandle($filename) ) {
            $fh = $filename;
        }
        else {
            open($fh, '>', $filename) or die "Can't to open file '$filename'!";
        }
    }
    else {
        $str = '';
        open($fh, '>', \$str) or die "Can't to create file handle!";
    }

    print $fh <<HTML;
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
    <title>CSS::SpriteBuilder generated page</title>
    <style type="text/css">
        .container {
            width: 800px;
            margin: 0 auto;
            text-align: center;
            font-size: 12px;
        }
        table {
            border-collapse: collapse;
            width: 100%;
        }
        th, td {
            border: 1px solid;
            text-align: center;
            padding: 8px;
        }
        .spr {
            display: -moz-inline-stack;
            display: inline-block;
            zoom: 1;
            *display: inline;
            background-repeat: no-repeat;
        }
HTML

    $self->write_css($fh);

    print $fh <<HTML;
    </style>
</head>
<body>
    <div class="container">
    <h3>CSS::SpriteBuilder generated page</h3>
    <table>
        <thead>
            <tr>
                <th>Image</th>
                <th>CSS selector</th>
                <th>Sprite</th>
                <th>Pos</th>
            </tr>
        </thead>
        <tbody>
HTML

    while (my ($sprite_image, $images) = each %{ $self->{_sprites} }) {
        for (my $i = 0; $i < scalar @$images; $i++) {
            my $image_info = $images->[$i];
            my $selector   = $image_info->{selector};

            my $rule = $selector =~ /^#/
                ? 'class="spr" id="'. substr($selector, 1) .'"'
                : 'class="spr '. substr($selector, 1) .'"'
            ;

            if ($image_info->{repeat} eq 'x') {
                $rule .= ' style="width:'. $image_info->{width} * 3 .'px;"';
            }
            elsif ($image_info->{repeat} eq 'y') {
                $rule .= ' style="height:'. $image_info->{height} * 3 .'px;"';
            }

            print $fh <<HTML;
            <tr>
                <td>
                    <span $rule>&nbsp;</span><br/>
                    $image_info->{image}<br/>
                    $image_info->{width} x $image_info->{height} (repeat-$image_info->{repeat})
                </td>
                <td>$selector</td>
HTML
            if ($i == 0) {
                my $rowspan = scalar @$images;
                print $fh <<HTML;
                    <td rowspan="$rowspan">
                        <img alt="" src="$sprite_image" /><br/>
                        $sprite_image
                    </td>
HTML
            }

            print $fh <<HTML;
                <td>$image_info->{x} x $image_info->{y}</td>
            </tr>
HTML
        }
    }

    print $fh <<HTML;
        </tbody>
    </table>
    </div>
</body>
</html>
HTML

    unless ($filename) {
        close $fh;
        return $str;
    }

    return;
}

sub _parse_xml_config {
    my ($self, $filename) = @_;

    eval "require XML::LibXML";
    die "XML::LibXML module is required!" if $@;

    my $xml_parser = XML::LibXML->new();

    my $dom;
    if ( openhandle($filename) ) {
        $dom = $xml_parser->parse_fh($filename);
    }
    elsif ( $filename =~ /^</ ) {
        $dom = $xml_parser->parse_string($filename);
    }
    else {
        $dom = $xml_parser->parse_file($filename);
    }

    my %global_opts = (
        ( map { $_             => $self->{$_}       } grep { exists $self->{$_} } @{ SPRITE_OPTS() } ),
        ( map { $_->nodeName() => $_->textContent() } $dom->findnodes("/root/global_opts/*")        ),
    );

    my @sprites;
    foreach my $sprite_node ( $dom->findnodes("/root/sprites/sprite") ) {
        my %sprite_opts = (
            %global_opts,
            map { $_->nodeName() => $_->textContent() } $sprite_node->findnodes("@*"),
        );

        my @images = map +{
            ( map { $_             => $sprite_opts{$_}  } grep { exists $sprite_opts{$_} } @{ IMAGE_OPTS() }   ),
            ( map { $_->nodeName() => $_->textContent() } $_->findnodes("@*")                                  ),
        }, $sprite_node->findnodes('image');

        push @sprites, {
            %sprite_opts,
            images => \@images,
        };
    }

    return wantarray ? @sprites : \@sprites;
}

1;
__END__

=head1 NAME

CSS::SpriteBuilder - CSS sprite builder.

=head1 SYNOPSIS

    use CSS::SpriteBuilder

    my $builder = CSS::SpriteBuilder->new( [%args] );
    $builder->build(
        sprites => [{
            file   => 'sample_sprite_%d.png',
            images => [
                { file => 'small/Add.png', [ %options ] },
            ],
            [ %options ],
        }],
    );

    $build->write_css('sprite.css');

    Or

    $builder->build(config => 'config.xml');

    $build->write_css('sprite.css');

=head1 DESCRIPTION

This module generate CSS sprites with one of these modules: Image::Magick or GD.

It has many useful settings and can be used for sites with complex structure.

=head1 METHODS

=head2 new(<%args>)

my $builder = CSS::SpriteBuilder->new(<%args>);

Create instance.

Valid arguments are:

=over

=item * B<source_dir> [ = undef ]

Specify custom location for source images.

=item * B<output_dir> [ = undef ]

Specify custom location for generated images.

=item * B<image_quality> 0..100 [ = 90 ]

Specify image quality for generated images (for JPEG only).

=item * B<max_image_size> [ = 65536 ]

Specify max size of images that will be used to generate a sprite.

=item * B<max_image_width> [ = 2000 ]

Specify max width of images that will be used to generate a sprite.

=item * B<max_image_height> [ = 2000 ]

Specify max height of images that will be used to generate a sprite.

=item * B<max_sprite_width> [ = 2000 ]

Specify max width of sprite.
When sprite has no free space, than creates a new sprite with addition of a suffix to the sprite name.
Opera 9.0 and below have a bug which affects CSS background offsets less than -2042px. All values less than this are treated as -2042px exactly.

=item * B<max_sprite_height> [ = 2000 ]

Specify max height of sprite.

=item * B<margin> [ = 0 ]

Add margin to each image.

=item * B<transparent_color> [ = undef ]

Set transparent color for image, for example: 'white', 'black', ....

=item * B<is_background> [ = 0 ]

If B<is_background> flag is '0' will be generated CSS rule such as: 'width:XXXpx;height:YYYpx;'.

=item * B<layout> [ = 'packed' ]

Specify layout algorithm (horizontal, vertical or packed).

=item * B<css_selector_prefix> [ = '.spr-' ]

Specify CSS selector prefix.
For example, for an image "img/icon/arrow.gif" will be generated selector such as ".spr-img-icon-arrow".

=item * B<css_url_prefix> [ = '' ]

Specify prefix for CSS url.
For example: background-image: url('B<css_url_prefix>sample_sprite.png')

=item * B<is_add_timestamp> [ = 1 ]

If parameter set to '1' than timestamp will be added for CSS url.
For example: background-image: url('sample_sprite.png?12345678')

=back

=head2 build(<%args>)

Build sprites.

    $builder->build(<%args>);

This method returning structure like:

    {
        'sample_sprite_1.png' => [
            {
                'y' => 0,
                'width' => 32,
                'selector' => '.spr-small-add',
                'is_background' => 0,
                'x' => 0,
                'height' => 32,
                'image' => 'small/Add.png',
                'repeat' => 'no'
            },
            ...
        ],
        ...
    }

Valid arguments are:

=over

=item * B<sprites>

Specify sprite list.

    $builder->build(
        sprites => [
            {
                file               => 'horizontal_%d.png',
                layout             => 'horizontal',
                max_sprite_width   => 1000,
                ...
                images => [
                    { file => 'small/*.png', is_repeat => 1, ... },
                    { file => 'small/*.gif' },
                    { file => 'small/a.jpg', is_background => 1 },
                ],
            },
            {
                file                => 'sprite_%d.png',
                max_sprite_width    => 1000,
                css_selector_prefix => '#spr-',
                ...
                images => [
                    { file => 'small/Add.png', is_repeat => 1, ... },
                ],
            },
        ],
    );

=item * B<config>

Specify XML config filename (it requires XML::LibXML module).

    $builder->build(config => 'config.xml');

Example of config.xml:

    <root>
        <global_opts>
            <max_image_size>20000</max_image_size>
            <layout>packed</layout>
            <css_selector_prefix>.spr-</css_selector_prefix>
            <css_url_prefix>/sprite/</css_url_prefix>
        </global_opts>

        <sprites>
            <sprite file="sprite_%d.png">
                <image file="small/Add.png"/>
                <image file="small/Box.png"/>
                <image file="medium/CD.png"/>
            </sprite>
            <sprite file="sprite_x_%d.png" layout="vertical">
                <image file="small/Brick.png" is_repeat="1"/>
                <image file="small/Bin_Empty.png"/>
                <image file="medium/Close.png"/>
            </sprite>
            <sprite file="sprite_y_%d.png" layout="horizontal">
                <image file="small/Pattern.png" is_repeat="1"/>
                <image file="small/Address_Book.png"/>
                <image file="medium/Chat.png"/>
            </sprite>
        </sprites>
    </root>

=back

=head2 write_css([<filename|fh>])

Write CSS to file.
When B<filename> parameter is not specified than this method returning a string.

    $builder->write_css('sprite.css');

=head2 write_xml([<filename|fh>])

Write CSS sprites info structure into XML format (it requires XML::LibXML module).
When B<filename> parameter is not specified than this method returning a string.

    $builder->write_xml('sprite.xml');

Example of sprite.xml:

    <root>
        <sprite src="sample_sprite.png">
            <image y="0" width="32" selector=".spr-small-add" is_background="0" x="0" height="32" repeat="no" image="small/Add.png"/>
        </sprite>
    </root>


=head2 write_html([<filename|fh>])

Write HTML sample page.
When B<filename> parameter is not specified than this method returning a string.

=head2 get_sprites_info()

This method returning structure like:

    {
        'sample_sprite.png' => [
            {
                'y' => 0,
                'width' => 32,
                'selector' => '.spr-small-add',
                'is_background' => 0,
                'x' => 0,
                'height' => 32,
                'image' => 'small/Add.png',
                'repeat' => 'no'
            },
            ...
        ],
        ...
    }

=head1 AUTHOR

=over 4

Yuriy Ustushenko, E<lt>yoreek@yahoo.comE<gt>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 Yuriy Ustushenko

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
