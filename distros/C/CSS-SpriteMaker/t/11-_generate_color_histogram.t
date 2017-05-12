use strict;
use warnings;

use Test::More;
  
use_ok('CSS::SpriteMaker');

my $ra_fixture = [{
    id => "colormap disabled",
    enable_colormap => 0,
    expected_die => 1,
}, {
    id => "colormap enabled",
    enable_colormap => 1,
    expected_die => 0
}];

for my $rh_test (@$ra_fixture) {
    my $SpriteMaker = CSS::SpriteMaker->new(
        enable_colormap => $rh_test->{enable_colormap}
    );

    isa_ok($SpriteMaker, 'CSS::SpriteMaker', "created CSS::SpriteMaker instance when $rh_test->{id}");

    my $err = $SpriteMaker->make_sprite(
        source_dir => 'sample_icons',
        target_file => 'sample_sprite.png',
    );
    is ($err, 0, "sprite was successfully created when $rh_test->{id}") 
        && unlink 'sample_sprite.png';
    
    eval { $SpriteMaker->_generate_color_histogram() };
    is(!!$@, !!$rh_test->{expected_die}, "dies as expected when $rh_test->{id}");

}



done_testing();
