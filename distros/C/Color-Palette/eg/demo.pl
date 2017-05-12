use strict;
use warnings;

use Color::Palette;
use Color::Palette::Schema;
use HTML::Entities;
use JSON;

my $pb_palette = Color::Palette->new({
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

my $lb_palette = Color::Palette->new({
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

my $template = Color::Palette::Schema->new({
  required_colors => [ qw(
    background plainText errorText brightText highlight lowlight linkText
  ) ],
});

my $opb_palette = $pb_palette->optimize_for($template);
my $olb_palette = $lb_palette->optimize_for($template);

my $pcs = JSON->new->encode($opb_palette->hex_triples);
my $lcs = JSON->new->encode($olb_palette->hex_triples);

my $HTML = <<"HTML";
<html>
<head>
  <title>Test Page</title>
  <script src='http://ajax.googleapis.com/ajax/libs/jquery/1.3/jquery.min.js'></script>
</head>

<script>
var palette = {
  pobox  : $pcs,
  listbox: $lcs,
};

function applyStyle(which) {
  var pal = palette[ which ];
  var rgb_str;
  
  \$("body").css({ backgroundColor: pal.background });

  \$("h1").css({ color: pal.highlight });

  \$(".error").css({ color: pal.errorText });

  \$("blockquote").css({
    color: pal.highlight,
    backgroundColor: pal.lowlight
  });

  \$("pre").css({
    border: "medium dashed " + pal.linkText
  });
}
</script>

<body>
  <h1>This is a Demo Page</h1>

  <div class='error'>error text</div>
  <blockquote>
    This is some demo text.
  </blockquote>

  <p>
    ...and here is some boring normal text.
  </p>

  <button onClick="applyStyle('pobox')">Pobox</button>
  <button onClick="applyStyle('listbox')">Listbox</button>

<pre>
PROGRAM_SOURCE
</pre>
</body>
</html>
HTML

my $source = do {
  seek *DATA, 0, 0;
  local $/;
  <DATA>;
};

$source = encode_entities($source);
$HTML =~ s/PROGRAM_SOURCE/$source/;

print $HTML;
__DATA__
