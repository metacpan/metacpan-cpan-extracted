
use strict;
use warnings;
use lib qw(lib);

use Test::More tests => 2;

use_ok('CSS::SpriteBuilder');

{
    my $builder = CSS::SpriteBuilder->new(
        source_dir       => "examples/icons",
        is_add_timestamp => 0,
    );

    $builder->build(
        sprites => [{
            file   => 'sample_sprite.png',
            images => [
                { file => 'small/Add.png' },
            ],
        }],
    );

    ok(-f 'sample_sprite.png', 'build sprite') && unlink 'sample_sprite.png';
}

done_testing();
