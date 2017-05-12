use strict;
use warnings;

use Test::More;
  
use_ok('CSS::SpriteMaker');

##
## Css is written
##
my $SpriteMaker = CSS::SpriteMaker->new();

isa_ok($SpriteMaker, 'CSS::SpriteMaker', 'created CSS::SpriteMaker instance');

my $err = $SpriteMaker->make_sprite(
    source_dir => 'sample_icons',
    target_file => 'sample_sprite.png',
);

is ($err, 0, 'sprite was successfully created') 
    && unlink 'sample_sprite.png';

my $out_css;
open my($fh), '>', \$out_css
    or die 'Cannot open file for writing $!';

my $rh_out_css_classes = $SpriteMaker->print_css(filehandle => $fh);
close $fh;

like ($out_css, qr/'sample_sprite[.]png'/, 'found sample sprite url');

##
## Class name prefix is added
##
my $SpriteMakerWithPrefix = CSS::SpriteMaker->new(
    css_class_prefix => 'icon-'
);

my $err_prefix = $SpriteMakerWithPrefix->make_sprite(
    source_dir => 'sample_icons',
    target_file => 'sample_sprite_with_prefix.png',
);

is ($err_prefix, 0, 'sprite was successfully created') 
    && unlink 'sample_sprite_with_prefix.png';

my $out_css_with_prefix;
open my($fh_prefix), '>', \$out_css_with_prefix
    or die 'Cannot open file for writing $!';

$SpriteMakerWithPrefix->print_css(filehandle => $fh_prefix);
close $fh_prefix;


##
## Prefix must be included in every class generated
##
my $line = 0;
for my $css (split "\n", $out_css_with_prefix) {
    if ($line++ > 0 && $css =~ m/^([.].+?)\s[{]/) {
        my $class = $1;
        if ($class !~ '^[.]icon-') {
            fail("Got $class, but was expecting something with the 'icon-' prefix as per css_class_prefix option!");
        }
    }
}

done_testing();
