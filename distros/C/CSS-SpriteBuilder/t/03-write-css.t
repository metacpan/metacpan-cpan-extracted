
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

    my $css = $builder->write_css();
    is(
        $css,
        <<CSS,
.spr-small-add{background-image: url('sample_sprite.png') !important;}
.spr-small-add{background-position:0px 0px !important;width:32px;height:32px;}
CSS
        'check write css'
    );
}

done_testing();
