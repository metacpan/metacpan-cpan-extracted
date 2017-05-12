use strict;
use warnings;

use Color::Palette;
use Color::Palette::Schema;
use Color::Palette::Types -all;
use Test::More;

my $pal_schema = Color::Palette::Schema->new({
  required_colors => [ qw(
    background plainText errorText brightText highlight lowlight linkText
  ) ]
});

my $bad_pal = Color::Palette->new({ colors => { blue => '#00f' } });
eval { $pal_schema->check($bad_pal); };
like($@, qr/no color named/, "bad palette rejected by schema");

my $pobox_palette   = Color::Palette->new({
  colors => {
    background => [ 0xEE, 0xEE, 0xEE ],

    plainText  => 'black',
    errorText  => 'poboxRedDark',
    brightText => 'poboxBlueLight',

    highlight  => 'poboxBlue',
    lowlight   => [ 0x33, 0x33, 0x33 ],

    linkText   => 'poboxBlueDark',

    black      => [ 0x00, 0x00, 0x00 ],
    white      => [ 0xFF, 0xFF, 0xFF ],

    poboxBlue      => [ 0x0A, 0x5E, 0xFF ],
    poboxBlueDark  => [ 0x04, 0x3F, 0xA6 ],
    poboxBlueLight => [ 0xC8, 0xDF, 0xFE ],
    poboxRedDark   => [ 0xA4, 0x00, 0x05 ],
  },
});

my $listbox_palette = Color::Palette->new({
  colors => {
    background => [ 0xEE, 0xEE, 0xEE ],

    plainText  => 'black',
    errorText  => 'listboxRedDark',
    brightText => 'listboxGreenLight',

    highlight  => 'listboxGreen',
    lowlight   => [ 0x33, 0x33, 0x33 ],

    linkText   => 'listboxGreenDark',

    black      => [ 0x00, 0x00, 0x00 ],
    white      => [ 0xFF, 0xFF, 0xFF ],

    listboxGreen      => [ 0x66, 0x99, 0x00 ],
    listboxGreenDark  => [ 0x3E, 0x51, 0x13 ],
    listboxGreenLight => [ 0xB9, 0xDB, 0x5D ],
    listboxRedDark    => [ 0xA4, 0x00, 0x05 ],
  },
});

my $opto_pobox = $pobox_palette->optimized_for($pal_schema);

isa_ok(
  $pobox_palette->color('poboxBlue'),
  'Graphics::Color',
);

eval { $opto_pobox->color('poboxBlue') };
like($@, qr/no color named poboxBlue/, "poboxBlue is removed by optimize");

{
  my $strict_hash = $opto_pobox->as_strict_css_hash;
  is($strict_hash->{background}, '#eeeeee', "strict hash can give us bg color");

  eval { my $x = $strict_hash->{zorch} };
  like($@, qr/no entry in palette/, "...but not a color that didn't exist");
}

isa_ok(
  $opto_pobox->color('highlight'),
  'Graphics::Color',
);

is(
  $pobox_palette->color('poboxBlue')->as_hex_string,
  $opto_pobox->color('highlight')->as_hex_string,
  "the optimized highlight value is really poboxBlue",
);

my @orig_names = $pobox_palette->color_names;
my @opto_names = $opto_pobox->color_names;
is(@orig_names, 13, "we defined 13 colors in the pobox palette");
is(@opto_names,  7, "...but we strip down to 7 when optimizing");

{
  no warnings 'qw';
  for my $hex (qw(d33 dd3333 #d33 #dd3333)) {
    my $color = to_Color($hex);
    is($color->as_css_hex, '#dd3333', "$hex -> #dd3333");
  }
}

done_testing;
