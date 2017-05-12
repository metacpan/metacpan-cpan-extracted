
use strict;
use warnings;
use lib qw(lib);

use Test::More;

foreach my $module (qw/Test::XML XML::LibXML/) {
    eval "use $module";
    if ($@) {
        plan skip_all => "$module missing!";
    }
}

plan tests => 3;

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

    my $xml = $builder->write_xml();
    is_xml(
        $xml,
        <<XML,
<root>
    <sprite src="sample_sprite.png">
        <image y="0" width="32" selector=".spr-small-add" is_background="0" x="0" height="32" repeat="no" image="small/Add.png"/>
    </sprite>
</root>
XML
        'check writing xml'
    );
}

done_testing();
