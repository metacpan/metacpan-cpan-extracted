use strict;
use warnings;

use Test::More;

use_ok('CSS::SpriteMaker');

my $SpriteMaker = CSS::SpriteMaker->new(
    source_images => ['sample_icons/bubble.png'],
    target_file => 'sample_sprite.png',
);

my $rh_source_info = $SpriteMaker->_ensure_sources_info(
    source_images => ['sample_icons/bubble.png']
);

my $Layout = $SpriteMaker->_ensure_layout(
    layout_name => 'Packed',
    rh_sources_info => $rh_source_info
);

isa_ok($Layout, 'CSS::SpriteMaker::Layout::Packed', 'obtained the layout class');

done_testing();
