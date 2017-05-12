use strict;
use warnings;

use Test::More;
  
use_ok('CSS::SpriteMaker');

# this test creates the sprite image file in various ways and checks if the
# sprite file was generated.

{
    my $SpriteMaker = CSS::SpriteMaker->new();

    isa_ok($SpriteMaker, 'CSS::SpriteMaker', 'created CSS::SpriteMaker instance');

    my $err = $SpriteMaker->make_sprite(
        source_dir => 'sample_icons',
        target_file => 'sample_sprite.png',
    );

    is ($err, 0, 'a. make_sprite returned false');
    ok (-f "sample_sprite.png", 'a1. sprite file was created')
        && unlink "sample_sprite.png";
}

{
    my $SpriteMaker = CSS::SpriteMaker->new();

    my $err1 = $SpriteMaker->make_sprite(
        source_images => ['sample_icons/apple.png', 'sample_icons/banknote.png'],
        target_file => 'sample_sprite.png',
    );

    is($err1, 0, 'b. make_sprite returned false');
    ok (-f "sample_sprite.png", 'b1. sprite file was created')
        && unlink "sample_sprite.png";

    my $result_b = $SpriteMaker->make_sprite(
        target_file => 'sample_sprite2.png',
    );

    is($result_b, 0, 'b2. make_sprite() returned false');
    ok (-f "sample_sprite2.png", 'b3. sprite file was created')
        && unlink "sample_sprite2.png";
}

done_testing();
