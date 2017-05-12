use strict;
use warnings;

use Test::More tests => 1;
use Test::Differences qw( eq_or_diff );

# ABSTRACT: Test reading a swatch

use Color::Swatch::ASE::Reader;
use Path::Tiny qw(path);

my $out = Color::Swatch::ASE::Reader->read_file( path('./corpus/Spring_Blush.ase') );

for my $block ( @{ $out->{blocks} } ) {
  next unless exists $block->{values};
  for my $value_no ( 0 .. $#{ $block->{values} } ) {
    $block->{values}->[$value_no] = int( 255 * $block->{values}->[$value_no] );
  }
}

eq_or_diff $out,
  {
  'blocks' => [
    {
      'group' => 13,
      'label' => 'Spring Blush',
      'type'  => 'group_start'
    },
    {
      'color_type' => 2,
      'group'      => 1,
      'model'      => 'RGB ',
      'type'       => 'color',
      'values'     => [ 93, 114, 165 ]
    },
    {
      'color_type' => 2,
      'group'      => 1,
      'model'      => 'RGB ',
      'type'       => 'color',
      'values'     => [ 187, 198, 80 ],
    },
    {
      'color_type' => 2,
      'group'      => 1,
      'model'      => 'RGB ',
      'type'       => 'color',
      'values'     => [ 214, 206, 144 ]
    },
    {
      'color_type' => 2,
      'group'      => 1,
      'model'      => 'RGB ',
      'type'       => 'color',
      'values'     => [ 88, 84, 59 ]
    },
    {
      'color_type' => 2,
      'group'      => 1,
      'model'      => 'RGB ',
      'type'       => 'color',
      'values'     => [ 191, 174, 148 ]
    },
    {
      'type' => 'group_end'
    }
  ],
  'signature' => 'ASEF',
  'version'   => [ 1, 0 ],
  },
  'ASE File decodes correctly';
