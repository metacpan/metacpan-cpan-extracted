use warnings;
use strict;

use lib 'lib';

use Test::More 'no_plan';

use Data::Leaf::Walker;

my %hoh;

for my $a ( 1, 2 )
   {
   for my $b ( 1, 2 )
      {
      $hoh{$a}{$b} = { a => $a, b => $b };
      }
   }

my $walker = Data::Leaf::Walker->new( \%hoh );

my $twig_depth = @{ scalar $walker->each } - 1;
$walker->reset;
$walker->opts( max_depth => $twig_depth );

my @keys   = sort { $a->[0] <=> $b->[0] || $a->[1] <=> $b->[1] } $walker->keys;
my @values = map { $walker->fetch($_) } @keys;

my @exp_keys =
   (
    [
      1,
      1
    ],
    [
      1,
      2
    ],
    [
      2,
      1
    ],
    [
      2,
      2
    ]
   );

is_deeply( \@keys, \@exp_keys, 'keys' );

my @exp_values =
   (
    {
      'a' => 1,
      'b' => 1
    },
    {
      'a' => 1,
      'b' => 2
    },
    {
      'a' => 2,
      'b' => 1
    },
    {
      'a' => 2,
      'b' => 2
    }
   );

is_deeply( \@values, \@exp_values, 'values' );
