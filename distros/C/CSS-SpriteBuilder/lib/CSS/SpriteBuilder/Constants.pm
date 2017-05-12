package CSS::SpriteBuilder::Constants;

use warnings;
use strict;

use base 'Exporter';
our @EXPORT = qw(
    LAYOUT_LIST
    PACKED_LAYOUT
    HORIZONTAL_LAYOUT
    VERTICAL_LAYOUT
    SPRITE_OPTS
    IMAGE_OPTS
    DEF_IMAGE_QUALITY
    DEF_MAX_IMAGE_SIZE
    DEF_MAX_IMAGE_WIDTH
    DEF_MAX_IMAGE_HEIGHT
    DEF_MAX_SPRITE_WIDTH
    DEF_MAX_SPRITE_HEIGHT
    DEF_MARGIN
    DEF_LAYOUT
    DEF_CSS_SELECTOR_PREFIX
);

use constant {
    LAYOUT_LIST       => [qw/ packed horizontal vertical /],
    PACKED_LAYOUT     => 'packed',
    HORIZONTAL_LAYOUT => 'horizontal',
    VERTICAL_LAYOUT   => 'vertical',
};

use constant SPRITE_OPTS => [qw/
    source_dir
    image_quality
    max_image_size
    max_image_width
    max_image_height
    max_sprite_width
    max_sprite_height
    margin
    transparent_color
    is_background
    layout
    css_selector_prefix
    css_url_prefix
    is_add_timestamp
/];

use constant IMAGE_OPTS => [qw/
    is_background
    is_repeat
    css_selector
/];

# default options
use constant {
    DEF_IMAGE_QUALITY       => 90,
    DEF_MAX_IMAGE_SIZE      => 64 * 1024,
    DEF_MAX_IMAGE_WIDTH     => 2000,
    DEF_MAX_IMAGE_HEIGHT    => 2000,
    DEF_MAX_SPRITE_WIDTH    => 2000,
    DEF_MAX_SPRITE_HEIGHT   => 2000,
    DEF_MARGIN              => 0,
    DEF_LAYOUT              => PACKED_LAYOUT,
    DEF_CSS_SELECTOR_PREFIX => '.spr-',
};

1;
