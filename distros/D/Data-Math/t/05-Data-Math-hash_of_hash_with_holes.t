# Perl test file, can be run like so:
#   `perl Data-Math.t'
#         jbrenner@ffn.com     2014/09/15 21:1g7:44

use warnings;
use strict;
$|=1;
my $DEBUG = 0;              # TODO set to 0 before ship
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

($DEBUG) && print STDERR $ENV{ PERL5LIB }, "\n";
($DEBUG) && print STDERR Dumper( \@INC ),  "\n";

use_ok( 'Data::Math' );

{
  my $test_name = "Testing calc '-' with hashes";
  my $dm = Data::Math->new();
  my %gross = ( de => 2345.37,
                es => 1238.99,
                us => 1.98,
             );
  my %costs = ( de => 35.00,
                es => 259.11,
                us => 666.66,
             );
   my $profit = $dm->calc( '-', \%gross, \%costs );
   #print STDERR "profit: ", Dumper( $profit ), "\n";

  my $exp = { 'de' => '2310.37', 'us' => '-664.68', 'es' =>
          '979.88' }; is_deeply( $profit, $exp, "$test_name:" )
          or print STDERR "profit: ", Dumper( $profit ), "\n";
}

{
  my $test_name = "Testing calc '+' on stringvals hases with holes"; # used for bug in expand_hash
  my $dm = Data::Math->new();

  my %a = (  'rand'    => 'a',
             'queen'   => 'b',
             'charlie' => "don't surf",
          );

  my %b = ( 'rand'    => 'not_a',
            'queen'   => 'b',
            'chomsky' => "don't rock",
          );

   my $res = $dm->calc( '+', \%a, \%b );
   #print STDERR "profit: ", Dumper( $profit ), "\n";

  my %exp = ( 'rand'    => 'a|not_a',
              'queen'   => 'b',
              'chomsky' => "don't rock",
              'charlie' => "don't surf",
          );

  is_deeply( $res, \%exp, "$test_name:" )
          or print STDERR "res: ", Dumper( $res ), "\n";
}


{
  my $test_name = "Testing calc '+' with some scalar string values";

  my $dm = Data::Math->new();
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
          'alpha' => 46,
          'beta' => 'blocker|ship it'
        };

  is_deeply( $ds_sum, $exp, "$test_name:" )
      or print STDERR "ds_sum: ", Dumper( $ds_sum ), "\n";

  # print STDERR "exp: ", Dumper( \%exp ), "\n";
}


{
  my $test_name = "Testing calc '+' on structures with deep holes (stripped version)";
  # print STDERR "developing:  $test_name... \n";
  my $dm = Data::Math->new();

  # The trouble here is a hole at the intermediate level
  # (if set is renamed pluto, the bug goes away).

  my %a =
      ( 'deep' => {
          pluto => { 'whun' => 1,
                 },
      },
    );

  my %b =
      ( 'deep' => {
          set => { 'tew' => 2,
               },
      },
    );

  my $ds_sum = $dm->calc( '+', \%a, \%b );

  my %exp =
      (
          'deep' => {
              pluto => { 'whun' => 1,
                     },
              set => { 'tew' => 2,
                   },
          },
      );
  # print STDERR "exp: ", Dumper( \%exp ), "\n";

  is_deeply( $ds_sum, \%exp, "$test_name:" )
      or print STDERR "ds_sum: ", Dumper( $ds_sum ), "\n";
}

{
  my $test_name = "Testing calc '+' on structures with deep holes";
  # print STDERR "developing:  $test_name... \n";
  my $dm = Data::Math->new();

  my %a = ( 'deeper' => { 'able'   => 23,
                          'baker'  => 23,
                          'deeper' => {
                                       underground => 6,
                                       pluto       => { 'beats uranus' => 3,
                                                      },
                                       beatnik => 59,
                                      },
                        },
            'alpha' => 23,
            'beta'  => 23,
            'epsilon' => 86,
          );

  my %b = ( 'deeper' => { 'able'    => 23,
                          'baker'   => 23,
                          'charlie' => 23,
                          'deeper'  => {
                              roots => 7,
                              set => { 'beats uranus' => 3,
                                      },
                              beat => 23,
                                      },
                        },
            'alpha' => 23,
            'gamma' => 23,
            'delta' => 7,
          );

  my $ds_sum = $dm->calc( '+', \%a, \%b );

  my %exp = (
      'deeper' => { 'able'    => 46,
                 'baker'   => 46,
                 'charlie' => 23,
                 'deeper'  => {
                           underground => 6,
                           roots => 7,
                           pluto => { 'beats uranus' => 3,
                                      },
                             set => { 'beats uranus' => 3,
                                      },
                           beatnik => 59,
                           beat => 23,
                                    },
                       },
            'alpha' => 46,
            'beta'  => 23,
            'gamma' => 23,
            'epsilon' => 86,
            'delta' => 7,
          );

  is_deeply( $ds_sum, \%exp, "$test_name:" )
      or print STDERR "ds_sum: ", Dumper( $ds_sum ), "\n";

  # print STDERR "exp: ", Dumper( \%exp ), "\n";
}



{
  my $test_name = "Testing calc with '-' operation";
  my $dm = Data::Math->new();

  my %a = ( 'deeper' => { 'able'    => 23,
                          'baker'   => 23,
                       },
            'alpha' => 23,
            'beta'  => 23,
          );

  my %b = ( 'deeper' => { 'able'    => 3,
                       'baker'   => 3,
                       'charlie' => 3,
                       },
            'alpha' => 3,
            'gamma' => 3,
          );

  my $ds_sum = $dm->calc( '-', \%a, \%b );


  my %exp = ( 'deeper' => { 'able'    => 20,
                         'baker'   => 20,
                         'charlie' => -3,
                       },
              'alpha' => 20,
              'beta'  => 23,
              'gamma' => -3,
          );

  is_deeply( $ds_sum, \%exp, "$test_name:" )
      or print STDERR "ds_sum: ", Dumper( $ds_sum ), "\n";

  # print STDERR "exp: ", Dumper( \%exp ), "\n";
}

{
  my $test_name = "Testing ds_op '+' on simple structures with holes";
  my $dm = Data::Math->new();

  my %a = ( 'deeper' => { 'able'    => 23,
                          'baker'   => 23,
                       },
            'alpha' => 23,
            'beta'  => 23,
          );

  my %b = ( 'deeper' => { 'able'    => 23,
                       'baker'   => 23,
                       'charlie' => 23,
                       },
            'alpha' => 23,
            'gamma' => 23,
          );

  my $ds_sum = $dm->calc( '+', \%a, \%b );

  my %exp = ( 'deeper' => { 'able'    => 46,
                         'baker'   => 46,
                         'charlie' => 23,
                       },
              'alpha' => 46,
              'beta'  => 23,
              'gamma' => 23,
          );

#  print STDERR "exp: ", Dumper( \%exp ), "\n"; ### DEBUG

  is_deeply( $ds_sum, \%exp, "$test_name:" )
      or print STDERR "ds_sum: ", Dumper( $ds_sum ), "\n";
}

done_testing();
