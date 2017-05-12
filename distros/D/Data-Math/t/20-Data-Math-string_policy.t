# Perl test file, can be run like so:
#   perl 17-Data-Math-merge_hashes.t
#         jbrenner@ffn.com   December 04, 2015  17:10

use warnings;
use strict;
$|=1;
my $DEBUG = 1;              # TODO set to 0 before ship
use Data::Dumper;
use File::Path      qw( mkpath );
use File::Basename  qw( fileparse basename dirname );
use File::Copy      qw( copy move );
use Fatal           qw( open close mkpath copy move );
use Cwd             qw( cwd abs_path );
use Env             qw( HOME );
use List::MoreUtils qw( any );

use Test::More;

use FindBin qw( $Bin );
use lib "$Bin/../lib";
use_ok( 'Data::Math' );

# globals
my %fur = ( cat    => 'krazy',
            dog    => 'anubis',
            hippie => 'sanders',
          );

my %skin = ( cat => 'sphinx',
             dog => 'pug',
             punk => 'rotten',
           );

{
  my $policy = 'pick_one';
  my $test_name = "Testing string_policy of $policy  ";
  my $dm = Data::Math->new( string_policy => $policy );

  my $merged = $dm->calc( '+', \%fur, \%skin );
#  print STDERR "merged: ", Dumper( $merged ), "\n";

  my %exp =  (
               cat    => 'krazy',
               dog    => 'anubis',
               hippie => 'sanders',
               punk   => 'rotten',
             );

  is_deeply( $merged, \%exp, "$test_name" )
          or print STDERR "merged: ", Dumper( $merged ), "\n";
}

{
  my $policy = 'pick_2nd';
  my $test_name = "Testing string_policy of $policy  ";
  my $dm = Data::Math->new( string_policy => $policy );

  my $merged = $dm->calc( '+', \%fur, \%skin );
#  print STDERR "merged: ", Dumper( $merged ), "\n";

  my %exp =  (
              cat    => 'sphinx',
              dog    => 'pug',
              hippie => 'sanders',
              punk   => 'rotten',
             );

  is_deeply( $merged, \%exp, "$test_name" )
          or print STDERR "merged: ", Dumper( $merged ), "\n";
}

{
  my $policy = 'default'; # same as 'concat_if_differ'
  my $test_name = "Testing string_policy of $policy, with alternate join_char";
  my $dm = Data::Math->new( string_policy => $policy, join_char => '^' );

  my $merged = $dm->calc( '+', \%fur, \%skin );
#  print STDERR "merged: ", Dumper( $merged ), "\n";

  my %exp =  (
              cat    => 'krazy^sphinx',
              dog    => 'anubis^pug',
              hippie => 'sanders',
              punk   => 'rotten',
             );

  is_deeply( $merged, \%exp, "$test_name" )
          or print STDERR "merged: ", Dumper( $merged ), "\n";
}

{
  my $policy = 'concat_if_differ'; # same as 'default'
  my $test_name = "Testing string_policy of $policy, with empty string join_char";
  my $dm = Data::Math->new( string_policy => $policy, join_char => '' );

  my $merged = $dm->calc( '+', \%fur, \%skin );
#  print STDERR "merged: ", Dumper( $merged ), "\n";

  my %exp =  (
              cat    => 'krazysphinx',
              dog    => 'anubispug',
              hippie => 'sanders',
              punk   => 'rotten',
             );

  is_deeply( $merged, \%exp, "$test_name" )
          or print STDERR "merged: ", Dumper( $merged ), "\n";
}


done_testing();


