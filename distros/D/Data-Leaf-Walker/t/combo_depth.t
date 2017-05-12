use warnings;
use strict;

use lib 'lib';

use Test::More 'no_plan';

use Data::Leaf::Walker;

my @orig =
   (
   111,
   112,
   [ 113, 114 ],
   [ [ 115, { aaa => 116 } ] ],
   {
   aab => 117,
   aac => 118,
   aad => { aae => { aaf => [[ 119 ]] }, aag => 120 },
   aah => [ 121, 122 ],
   aai => [[]],
   aaj => [ 123, 124, { aak => 125 }, { aal => 126 } ],
   aam => { aan => {} },
   aao => 127,
   },
   );

my @exp_keys =
   (
   [ qw/ 2 0 / ],
   [ qw/ 2 1 / ],
   [ qw/ 3 0 0 / ],
   [ qw/ 3 0 1 / ],
   [ qw/ 4 aab / ],
   [ qw/ 4 aac / ],
   [ qw/ 4 aad aae / ],
   [ qw/ 4 aad aag / ],
   [ qw/ 4 aah 0 / ],
   [ qw/ 4 aah 1 / ],
   [ qw/ 4 aai 0 / ],
   [ qw/ 4 aaj 0 / ],
   [ qw/ 4 aaj 1 / ],
   [ qw/ 4 aaj 2 / ],
   [ qw/ 4 aaj 3 / ],
   [ qw/ 4 aam aan / ],
   [ qw/ 4 aao / ],
   );
   
my @exp_values =
   (
   113,
   114,
   115,
   117,
   118,
   120,
   121,
   122,
   123,
   124,
   127,
   [],
   {},
   { aaa => 116 },
   { aaf => [[ 119 ]] },
   { aak => 125 },
   { aal => 126 },
   );

my $walker = Data::Leaf::Walker->new( \@orig, min_depth => 2, max_depth => 3 );

EACH:
   {

   my @keys;
   my @values;

   while ( my ( $k, $v ) = $walker->each )
      {
      push @keys, $k;
      push @values, $v;
      }
   
   @keys = map  { $_->[0] }
           sort { $a->[1] cmp $b->[1] }
           map  { [ $_, join(':', @{$_}) ] } @keys;
             
   is_deeply( \@keys, \@exp_keys, "each - keys" );

   @values = map { $_->[0] } sort { $a->[1] cmp $b->[1] } map
      {
      my $w = ref $_ ? Data::Leaf::Walker->new( $_ ) : ();
      my $k = ref $_ ? $w->each : ();
      ref $_ && $w->keys;
      [ $_, $k ? join ':', @{ $k } : ref $_ ? ref $_ : $_ ]
      } @values;

   is_deeply( \@values, \@exp_values, "each - values" );
   
   }

KEYS:
   {

   my @keys = map  { $_->[0] }
              sort { $a->[1] cmp $b->[1] }
              map  { [ $_, join(':', @{$_}) ] } $walker->keys;
             
   is_deeply( \@keys, \@exp_keys, "keys" );

   }

VALUES:
   {

   my @values = $walker->values;

   @values = map { $_->[0] } sort { $a->[1] cmp $b->[1] } map
      {
      my $w = ref $_ ? Data::Leaf::Walker->new( $_ ) : ();
      my $k = ref $_ ? $w->each : ();
      ref $_ && $w->keys;
      [ $_, $k ? join ':', @{ $k } : ref $_ ? ref $_ : $_ ]
      } @values;

   is_deeply( \@values, \@exp_values, "values" );

   }
