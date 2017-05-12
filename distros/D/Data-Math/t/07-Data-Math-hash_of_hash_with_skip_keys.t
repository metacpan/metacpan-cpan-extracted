#  06-Data-Math-hash_of_hash_with_skip_keys.t
#         jbrenner@ffn.com     2014/09/15 21:17:44

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
### BEGIN { plan tests => 28 }; # TODO revise test count

use FindBin qw( $Bin );
use lib "$Bin/../lib";
use_ok( 'Data::Math' );

{
  my $test_name = "Testing calc '+' with skip key patterns";

  my $dm = Data::Math->new( skip_key_patterns => [ qr{^alpha$}, qr{^beta$} ] );
  my %a = ( 'deeper' => { 'able'    => 23,
                          'baker'   => 23,
                          'charlie' => "don't surf",
                       },
            'alpha' => 23,
            'beta'  => 'blocker',
          );

  my %b = ( 'deeper' => { 'able'    => 23,
                          'baker'   => 23,
                          'chomsky' => "don't rock",
                       },
            'alpha' => 23,
            'beta'  => 'ship it',
            'gamma' => 'green',
          );

  my $ds_sum = $dm->calc( '+', \%a, \%b );

  my $exp = {
          'gamma' => 'green',
          'deeper' => {
                     'able'    => 46,
                     'baker'   => 46,
                     'charlie' => "don't surf",
                     'chomsky' => "don't rock",
                   },
          'alpha' => 23,       ### should stay unchanged
          'beta' => 'blocker', ### picks the first string value
        };

  is_deeply( $ds_sum, $exp, "$test_name:" )
      or print STDERR "ds_sum: ", Dumper( $ds_sum ), "\n";

#   print STDERR "exp: ", Dumper( $exp ), "\n";
}



done_testing();
