use warnings;
use strict;

use lib 'lib';

use Test::More 'no_plan';

use Data::Leaf::Walker;

my %opts =
   (
   default   => {},
   max_depth => { max_depth => 3 },
   min_depth => { min_depth => 3 },
   );

for my $opt_set_name ( keys %opts )
   {
   
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
      128,
      );

   my @exp_keys =
      (
      [ qw/ 0 / ],
      [ qw/ 1 / ],
      [ qw/ 2 0 / ],
      [ qw/ 2 1 / ],
      [ qw/ 3 0 0 / ],
      [ qw/ 3 0 1 aaa / ],
      [ qw/ 4 aab / ],
      [ qw/ 4 aac / ],
      [ qw/ 4 aad aae aaf 0 0 / ],
      [ qw/ 4 aad aag / ],
      [ qw/ 4 aah 0 / ],
      [ qw/ 4 aah 1 / ],
      [ qw/ 4 aaj 0 / ],
      [ qw/ 4 aaj 1 / ],
      [ qw/ 4 aaj 2 aak / ],
      [ qw/ 4 aaj 3 aal / ],
      [ qw/ 4 aao / ],
      [ qw/ 5 / ],
      );
      
   my $walker = Data::Leaf::Walker->new( \@orig );
   
   OPTS:
      {
      
      my %got_opts = $walker->opts( %{ $opts{$opt_set_name} } );

      is_deeply( \%got_opts, $opts{$opt_set_name}, "($opt_set_name) opts - from set" );
      
      %got_opts = $walker->opts;
      
      is_deeply( \%got_opts, $opts{$opt_set_name}, "($opt_set_name) opts - empty" );

      }

   RESET:
      {
      
      my @pre = map { [ $walker->each ] } 1 .. 8;
      
      $walker->reset;
      
      my @post = map { [ $walker->each ] } 1 .. 8;
      
      is_deeply( \@post, \@pre, "($opt_set_name) reset" );
      
      $walker->reset;
      
      }

   FETCH:
      {

      for my $key_path_i ( 0 .. $#exp_keys )
         {
         
         my $key_path = $exp_keys[$key_path_i];
         
         my $value = $walker->fetch( $key_path );
         
         is( $value, $key_path_i + 111, "($opt_set_name) fetch - @{ $key_path } : $value" );
         
         }
         
      my $top_undef = $walker->fetch( [ qw/ 1000 / ] );
      is( $top_undef, undef, "($opt_set_name) fetch - top not exist" );

      my $deep_undef = $walker->fetch( [ qw/ 3 0 1 potato / ] );
      is( $deep_undef, undef, "($opt_set_name) fetch - deep not exist" );
      
      eval { $walker->fetch( [ qw/ 3 0 0 potato / ] ) };
      my $err = $@;
      like( $err, qr/\A\QError: cannot lookup key (potato) in invalid ref type ()/,
            "($opt_set_name) fetch - invalid path" );

      }

   STORE:
      {

      my @exp_data =
         (
         211,
         212,
         [ 213, 214 ],
         [ [ 215, { aaa => 216 } ] ],
         {
         aab => 217,
         aac => 218,
         aad => { aae => { aaf => [[ 219 ]] }, aag => 220 },
         aah => [ 221, 222 ],
         aai => [[]],
         aaj => [ 223, 224, { aak => 225 }, { aal => 226 } ],
         aam => { aan => {} },
         aao => 227,
         },
         228,
         );

      for my $key_path_i ( 0 .. $#exp_keys )
         {
         my $key_path = $exp_keys[$key_path_i];
         $walker->store( $key_path, $key_path_i + 211 );
         }

      is_deeply( \@orig, \@exp_data, "($opt_set_name) store" );   

      }
      
   EXISTS:
      {

      for my $key_path ( @exp_keys )
         {
         ok( $walker->fetch( $key_path ), "($opt_set_name) exists - @{ $key_path }" );
         }

      my $top = $walker->exists( [ qw/ 1000 / ] );
      ok( ! $top, "($opt_set_name) exists - top not exist" );

      my $deep = $walker->exists( [ qw/ 3 0 1 potato / ] );
      ok( ! $deep, "($opt_set_name) exists - deep not exist" );
      
      my $extra_deep = $walker->exists( [ qw/ 3 0 1 potato cake cat / ] );
      ok( ! $extra_deep, "($opt_set_name) exists - extra deep not exist" );

      my $repeat = $walker->exists( [ qw/ 3 0 1 potato / ] );
      ok( ! $repeat, "($opt_set_name) exists - repeat deep not exist" );

      my $invalid = $walker->exists( [ qw/ 3 0 0 potato / ] );
      ok( ! $invalid, "($opt_set_name) exists - invalid not exist" );

      }

   DELETE:
      {
      
      my $ret = $walker->delete( [ qw/ 4 aaj 3 aal / ] );
      
      my @exp_data =
         (
         211,
         212,
         [ 213, 214 ],
         [ [ 215, { aaa => 216 } ] ],
         {
         aab => 217,
         aac => 218,
         aad => { aae => { aaf => [[ 219 ]] }, aag => 220 },
         aah => [ 221, 222 ],
         aai => [[]],
         aaj => [ 223, 224, { aak => 225 }, {} ],
         aam => { aan => {} },
         aao => 227,
         },
         228,
         );

      is_deeply( \@orig, \@exp_data, "($opt_set_name) delete" );
      is( $ret, 226, "($opt_set_name) delete - return" );

      }
   
   }
