use strict;
use warnings;

use Test::More;

use_ok('CSS::SpriteMaker');

{
    my $SpriteMaker = CSS::SpriteMaker->new();

    ok($SpriteMaker, "Got a Css::SpriteMaker object back");

    # we need to run make or make_sprite otherwise we can't get the coordinate
    # of each item!
    $SpriteMaker->make_sprite(
        source_images => ['sample_icons/bubble.png'],
        target_file => 'sample_sprite.png',
    ) || unlink 'sample_sprite.png';

    my $rh_structure = $SpriteMaker->get_css_info_structure();
    is_deeply($rh_structure, [{
        'css_class' => 'bubble',
        'width' => 32,
        'y' => 0,
        'x' => 0,
        'full_path' => 'sample_icons/bubble.png',
        'height' => 28
    }], 'have obtained the desided css information structure');
}

##
## Test Remove source padding
##
my $apple_padded_width = 128;
my $apple_padded_height = 128;
my $apple_padding_horizontal = 18;
my $apple_padding_vertical = 0;
{
    my $SpriteMaker = CSS::SpriteMaker->new(
        remove_source_padding => 0
    );

    # NOTE: The apple icon has padding
    make_apple_sprite($SpriteMaker);

    my $rh_structure = $SpriteMaker->get_css_info_structure();

    is_deeply($rh_structure, [{
        'css_class' => 'apple',
        'y' => 0,
        'x' => 0,
        'full_path' => 'sample_icons/apple.png',
        'width' => $apple_padded_width,
        'height' => $apple_padded_height,
    }], 'Image padding is preserved into the sprite');
}

# now remove padding
{
    my $SpriteMaker = CSS::SpriteMaker->new(
        remove_source_padding => 1
    );
    make_apple_sprite($SpriteMaker);

    my $rh_structure = $SpriteMaker->get_css_info_structure();

    is_deeply($rh_structure, [{
        'css_class' => 'apple',
        'y' => 0,
        'x' => 0,
        'full_path' => 'sample_icons/apple.png',
        'width' => $apple_padded_width - $apple_padding_horizontal,
        'height' => $apple_padded_height - $apple_padding_vertical,
    }], 'Image padding is removed correctly from the css');
}
# now add some extra padding after removing 
{
    my $extra_padding = 20;
    my $SpriteMaker = CSS::SpriteMaker->new(
        remove_source_padding => 1,
        add_extra_padding => $extra_padding,
    );
    make_apple_sprite($SpriteMaker);

    my $rh_structure = $SpriteMaker->get_css_info_structure();

    is_deeply($rh_structure, [{
        'css_class' => 'apple',
        'y' => $extra_padding,
        'x' => $extra_padding,
        'full_path' => 'sample_icons/apple.png',
        'width' => $apple_padded_width - $apple_padding_horizontal,
        'height' => $apple_padded_height - $apple_padding_vertical,
    }], 'CSS starts from different position and width of the icon stays the same')
}
# just add some extra padding
{
    my $extra_padding = 20;
    my $SpriteMaker = CSS::SpriteMaker->new(
        add_extra_padding => $extra_padding,
    );
    make_apple_sprite($SpriteMaker);

    my $rh_structure = $SpriteMaker->get_css_info_structure();

    is_deeply($rh_structure, [{
        'css_class' => 'apple',
        'y' => $extra_padding,
        'x' => $extra_padding,
        'full_path' => 'sample_icons/apple.png',
        'width' => $apple_padded_width,
        'height' => $apple_padded_height,
    }], 'extra padding was added and original padding is preserved');
}

#
# Now make a sprite with two images, and add padding to only one of them.
#

# first make sure about the dimensions of the bubble
my $bubble_height = 28;
my $bubble_width = 32;
{
    my $SpriteMaker = CSS::SpriteMaker->new();

    $SpriteMaker->compose_sprite(
        parts => [
            { source_images => ['sample_icons/apple.png'], },
            { source_images => ['sample_icons/bubble.png'], },
        ],
        layout_name => 'Packed',
        target_file => 'sample_sprite.png',
    ) || unlink 'sample_sprite.png';

    my $ra_structure = $SpriteMaker->get_css_info_structure();

    my ($rh_bubble_structure) = grep {
        $_->{css_class} eq 'bubble'
    } @$ra_structure;

    is_deeply($rh_bubble_structure, {
        'css_class' => 'bubble',
        'y' => 0,
        'x' => 128,
        'full_path' => 'sample_icons/bubble.png',
        'width' => $bubble_width,
        'height' => $bubble_height,
    }, 'got expected size for the bubble in the composite sprite');
}

# then add padding only to the bubble 
my $bubble_extra_padding = 50;
{
    my $SpriteMaker = CSS::SpriteMaker->new();

    $SpriteMaker->compose_sprite(
        parts => [
            { source_images => ['sample_icons/apple.png'], 
              add_extra_padding => 0
            },
            { source_images => ['sample_icons/bubble.png'], 
              add_extra_padding => $bubble_extra_padding
            },
        ],
        target_file => 'sample_sprite.png',
    ) || unlink 'sample_sprite.png';

    my $ra_structure = $SpriteMaker->get_css_info_structure();

    is_deeply($ra_structure, [
        {
            'width' => $apple_padded_width,
            'y' => 0,
            'css_class' => 'apple',
            'x' => 132,
            'full_path' => 'sample_icons/apple.png',
            'height' => $apple_padded_height
        },
        {
            'css_class' => 'bubble',
            'y' => $bubble_extra_padding,
            'x' => $bubble_extra_padding,
            'full_path' => 'sample_icons/bubble.png',
            'width' => $bubble_width,
            'height' => $bubble_height,
        },
    ], 'only the bubble has extra padding');
}

sub make_apple_sprite {
    my $SpriteMaker = shift;

    # NOTE: The apple icon has padding
    $SpriteMaker->make_sprite( source_images => ['sample_icons/apple.png'],
        target_file => 'sample_sprite.png',
    ) || unlink 'sample_sprite.png';

    return;
}

done_testing();
