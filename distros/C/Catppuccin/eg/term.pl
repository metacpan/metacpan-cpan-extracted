#!perl
use warnings;
use strict;
use Catppuccin;
use Term::ANSIColor qw(colored);

binmode STDOUT, ':encoding(UTF-8)';

my $colfmt = '%-10s';

my @palettes = map { Catppuccin->$_->term } Catppuccin->flavors;
my @colors = $palettes[0]->colors;

printf((join '  ', map { $colfmt } (0..@palettes))."\n",
  '', map { $_->id } @palettes);
for my $color (@colors) {
  printf "$colfmt  %s\n", $color, join('  ',
    map { colored(['on_'.$_->$color], sprintf $colfmt, '') } @palettes);
}
