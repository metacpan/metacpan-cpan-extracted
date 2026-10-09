#!perl

use warnings;
use strict;

use Test::More;

# basic data module lookup & traversal, mostly making sure whatever we
# generated isn't totally wrong
#
require_ok('Catppuccin::Data');

is(Catppuccin::Data->version, '1.8.0');

my $latte = Catppuccin::Data->latte;
is($latte->id, 'latte');
is($latte->name, 'Latte');

my $c = $latte->color;
is($c->crust->id, 'crust');
is($c->lavender->name, 'Lavender');
is($c->maroon->hex, '#e64553');
is_deeply([$c->peach->rgb], [254,100,11]);
is(scalar [$c->rosewater->hsl]->@*, 3);
is(scalar [$c->sky->oklch]->@*, 3);

my $a = $latte->ansi;
is($a->blue->id, 'blue');
is($a->cyan->name, 'Cyan');
is($a->green->normal->name, 'Green');
is($a->green->bright->name, 'Bright Green');
is($a->yellow->bright->hex, '#eea02d');
is_deeply([$a->magenta->normal->rgb], [234,118,203]);

my ($flavor) = Catppuccin::Data->flavors;
is($flavor->id, do { my $id = $flavor->id; Catppuccin::Data->$id }->id);

my ($color) = $flavor->colors;
is($color->id, do { my $id = $color->id; $flavor->color->$id }->id);

my ($ansi_color) = $flavor->ansi_colors;
is($ansi_color->id, do { my $id = $ansi_color->id; $flavor->ansi->$id }->id);

done_testing;
