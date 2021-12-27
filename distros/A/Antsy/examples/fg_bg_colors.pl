#!perl

use v5.32;
use experimental qw(signatures);
use lib qw(lib);

use Antsy;

my $fg_rgb = Antsy::iterm_fg_color();

say "@$fg_rgb";

my $bg_rgb = Antsy::iterm_bg_color();

say "@$bg_rgb";
