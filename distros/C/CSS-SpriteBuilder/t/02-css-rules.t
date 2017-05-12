
use strict;
use warnings;
use lib qw(lib);

use Test::More tests => 3;

use_ok('CSS::SpriteBuilder');

{
    my $builder = CSS::SpriteBuilder->new(
        source_dir       => "examples/icons",
        is_add_timestamp => 0,
    );

    my $css_rules = $builder->build(
        sprites => [{
            file   => 'sample_sprite.png',
            images => [
                { file => 'small/Add.png' },
            ],
        }],
    );

    ok(-f 'sample_sprite.png', 'build sprite') && unlink 'sample_sprite.png';

    is_deeply($css_rules, {
        'sample_sprite.png' => [{
            'y' => 0,
            'width' => 32,
            'selector' => '.spr-small-add',
            'is_background' => 0,
            'x' => 0,
            'height' => 32,
            'image' => 'small/Add.png',
            'repeat' => 'no'
        }]
    }, 'check css rules');
}

done_testing();
