use strict;
use warnings;

use Test::More;
  
use_ok('CSS::SpriteMaker');

my $ra_fixture = [{
    id => "colormap disabled",
    enable_colormap => 0,
    expected_colors => 171,
    expected_color_markup => 0
}, {
    id => "colormap enabled",
    enable_colormap => 1,
    expected_colors => 171,
    expected_color_markup => 1
}];

for my $rh_test (@$ra_fixture) {
    my $SpriteMaker = CSS::SpriteMaker->new(
        enable_colormap => $rh_test->{enable_colormap}
    );

    isa_ok($SpriteMaker, 'CSS::SpriteMaker', 'created CSS::SpriteMaker instance');

    my $err = $SpriteMaker->make_sprite(
        source_dir => 'sample_icons',
        target_file => 'sample_sprite.png',
    );
    is ($err, 0, 'sprite was successfully created') 
        && unlink 'sample_sprite.png';

    my $out_html;
    open my($fh), '>', \$out_html
        or die 'Cannot open file for writing $!';

    $SpriteMaker->print_html(filehandle => $fh);
    close $fh;

    is(length $out_html > 100, 1, 'more than 100 characters returned for html sample page');
    if ($out_html =~ m@<h3>Colors</h3><b>total</b>:\s\d+@) {
        pass("colors appear in html when $rh_test->{id}");
    }
    else {
        fail("colors appear in html with enable_colormap = $rh_test->{enable_colormap}");
    }

    if ($out_html =~ m@<div class="color".+?rgba@g) {
        is(1, $rh_test->{expected_color_markup}, "color markup appears as expected when $rh_test->{id}");
    } else {
        is(0, $rh_test->{expected_color_markup}, "color markup appears as expected when $rh_test->{id}");
    }
}



done_testing();
