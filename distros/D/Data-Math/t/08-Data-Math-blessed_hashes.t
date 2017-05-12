# Perl test file, can be run like so:
#   `perl 05-Data-Math-blessed_hashes.t`
#         jbrenner@ffn.com     Fri  January 23, 2015  09:35

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
# use List::MoreUtils qw( any );

use Test::More;
use Test::Deep;
use Test::Exception;
use Test::Trap;

use FindBin qw( $Bin );
use lib "$Bin/../lib";
use_ok( 'Data::Math' );

{
  # this test handles a blessed object at the *top* level,
  # which exercises only the initial defaults outside of the loop
  my $test_name = "Testing calc '-' with blessed hashes";
  my $dm = Data::Math->new();
  my %gross = ( de => 2345.37,
                es => 1238.99,
                us => 1.98,
             );

  my $class = "Financials";

  my $gross_obj = bless \%gross, $class;

  my %costs = ( de => 35.00,
                es => 259.11,
                us => 666.66,
             );

  my $costs_obj = bless \%costs, $class;

  my $profit = $dm->calc( '-', $gross_obj, $costs_obj );
   #print STDERR "profit: ", Dumper( $profit ), "\n";

  my $profit_class = ref $profit;

  is( $profit_class, $class, "$test_name: preserved class" );

  my $exp = bless( { 'de' => '2310.37',
                     'us' => '-664.68',
                     'es' => '979.88'
                  }, 'Financials' );

  cmp_deeply( $profit, $exp, "$test_name:" )
          or print STDERR "profit: ", Dumper( $profit ), "\n";
}

{
  # This test uses a nested set of objects.
  # to exercise the handling inside the loop.
  # TODO add a test with another level of nesting?
  my $test_name = "Testing calc '-' with objects within objects (hashes)";
  my $dm = Data::Math->new();

  my $class = "Bozotech::Financials";
  my %gross = ( de => 2345.37,
              es => 1238.99,
              us => 1.98,
             );
  my %gross2 = ( de => 2345.37,
              es => 1238.99,
              us => 1.98,
             );

  my $gross_obj  = bless \%gross, $class;
  my $gross2_obj = bless \%gross2, $class;

  my %costs = ( de => 35.00  ,
                es => 259.11 ,
                us => 666.66 ,
             );

  my %costs2 = ( de => 35.00  + 44,
                 es => 259.11 + 44,
                 us => 666.66 + 44,
             );

  my $costs_obj = bless \%costs, $class;
  my $costs2_obj = bless \%costs2, $class;

  my $container_class = 'Bozotech::Divisions';

  my %div1 =
    (
     name => 'Stuff1',
     gross => $gross_obj,
     costs => $costs_obj,
    );

  my %div2 =
    (
     name => 'Stuff2',
     gross => $gross2_obj,
     costs => $costs2_obj,
    );

  my $div1_obj = bless \%div1, $container_class;
  my $div2_obj = bless \%div2, $container_class;

  my $whateva = $dm->calc( '-', $div1_obj, $div2_obj );

### TODO these kind of individual tests aren't necessary with cmp_deeply, but the messaging is better:
#  my $whateva_class = ref $whateva;
#  is( $whateva_class, $container_class, "$test_name: preserved top level class" );

  my $exp =
    bless( {
                 'costs' => bless( {
                              'de' => -44,
                              'us' => -44,
                              'es' => -44,
                            }, 'Bozotech::Financials' ),
                 'name' => 'Stuff1|Stuff2',
                 'gross' => bless( {
                              'de' => '0',
                              'us' => '0',
                              'es' => '0',
                            }, 'Bozotech::Financials' ),
               }, 'Bozotech::Divisions' );


  cmp_deeply( $whateva, $exp,
              "$test_name")
    or print STDERR "whateva: ", Dumper( $whateva ), "\n";
}


{
  my $test_name = "Testing calc '+' on deep holes with blessed refs";
  # print STDERR "developing:  $test_name... \n";
  my $dm = Data::Math->new();

  my $outer_class = 'Beatnik';
  my $inner_class = 'Bongo';

  my $a =
   bless( {'deep' => {
                      pluto => bless( { 'whun' => 1,
                                      }, $inner_class )
                     },
          }, $outer_class );

  my $b =
    bless( {'deep' => {
                       anubis => bless( { 'tew' => 2,
                                        }, $inner_class )
                      },
           }, $outer_class );

  my $ds_sum = $dm->calc( '+', $a, $b );

  my $exp =
     bless( {'deep' => {
                        pluto => bless( { 'whun' => 1,
                                        }, $inner_class ),
                        anubis => bless( { 'tew' => 2,
                                         }, $inner_class ),
          },
      }, $outer_class );
  # print STDERR "exp: ", Dumper( \%exp ), "\n";

  cmp_deeply( $ds_sum, $exp, "$test_name:" )
      or print STDERR "ds_sum: ", Dumper( $ds_sum ), "\n";
}

{
  my $test_name = "Testing calc '+' merging parallel blessed hrefs";
  # print STDERR "developing:  $test_name... \n";
  my $dm = Data::Math->new();

  my $outer_class = 'Beatnik';
  my $inner_class = 'Bongo';
  my $low_class   = 'Tambo';

  my $a =
   bless( {'deep' => {
                      pluto => bless( { 'whun' => 1,
                                      }, $inner_class )
                     },
          }, $outer_class );

  my $b =
    bless( {'deep' => {
                       pluto => bless( { 'tew' => 2,
                                        }, $inner_class )
                      },
           }, $outer_class );

  my $ds_sum = $dm->calc( '+', $a, $b );

  my $exp =
     bless( {'deep' => {
                        pluto => bless( { 'whun' => 1,
                                          'tew' => 2,
                                        }, $inner_class ),
          },
      }, $outer_class );
  # print STDERR "exp: ", Dumper( $exp ), "\n";

  cmp_deeply( $ds_sum, $exp, "$test_name:" )
      or print STDERR "ds_sum: ", Dumper( $ds_sum ), "\n";
}

### TODO what happens if you've got mis-matched classes?
###      should throw an error, no?
{
  my $test_name = "Testing calc '+' on mismatched parallel blessed hrefs (should error)";
  # print STDERR "developing:  $test_name... \n";
  my $dm = Data::Math->new();

  my $outer_class = 'Beatnik';
  my $inner_class = 'Bongo';
  my $low_class   = 'Tambo';

  my $a =
   bless( {'deep' => {
                      pluto => bless( { 'whun' => 1,
                                      }, $low_class )
                     },
          }, $outer_class );

  my $b =
    bless( {'deep' => {
                       pluto => bless( { 'tew' => 2,
                                        }, $inner_class )
                      },
           }, $outer_class );

#  my $ds_sum = $dm->calc( '+', $a, $b );
#  print STDERR "ds_sum: ", Dumper( $ds_sum ) , "\n";

### TODO busted test.  What's up?

#   throws_ok { $dm->calc( '+', $a, $b ) }
#              qr{mismatched types}, "$test_name: dies as expected" ;

  trap{ $dm->calc( '+', $a, $b ) };
  like( $trap->die, qr/^mismatched/, "$test_name: dies as expected" );

# TODO would be better to check the error message:
# Found mismatched classes in parallel locations: Tambo and Bongo

}

done_testing();

### TODO more tests, maybe modifying the following
exit;

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
                     'able' => 46,
                     'baker' => 46,
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

  my %a = ( 'deeper' => { 'able'    => 23,
                       'baker'   => 23,
                       'deeper'  => {
                           underground => 6,
                           pluto => { 'beats uranus' => 3,
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

# exit;



{ # first trial: one condition and action
    my $test_name = "Testing do_calc method with one condition and action";
#     my $num_rule = do {
#         my $dm = Data::Math->new();
#         $dm->regexp_library->{ NUMERIC_RULE };
#     };

    my $num_rule = qr{ ^ [+-]? [.0-9]+ $ }x;

    my $actions =
        [
            [ sub{ $a =~ /$num_rule/ && $b =~ m/$num_rule/ }, sub{ $a + $b * 2 } ],
            #  [ sub{}, sub{} ],
            #  [ sub{}, sub{} ],
        ];

    my $dm = Data::Math->new( actions => $actions );

    my $d1 = {
        es => 100,
        de => 333,
        us => 666,
    };

    my $d2 = {
        es => 3,
        de => 4,
        us => 2,
    };

    # my ( $a, $b ) = ( 7.9, 6.8 );

    # print "PRE a: $a\n" if defined $a;
    # print "PRE b: $b\n" if defined $b;

    my $result =
        $dm->do_calc( $d1, $d2 );

    # print "POST a: $a\n" if defined $a;
    # print "POST b: $b\n" if defined $b;

    # print "YO result: ", Dumper( $result ), "\n";

    my $expected = {
          'de' => 341,
          'es' => 106,
          'us' => 670
        };

    is_deeply( $result, $expected, "$test_name" );
}

{ # second trial
    my $test_name = "Testing do_calc method with multiple conditions and actions";

#     my $num_rule = do {
#         my $dm = Data::Math->new();
#         $dm->regexp_library->{ NUMERIC_RULE };
#     };
    my $num_rule = qr{ ^ [+-]? [.0-9]+ $ }x;

    my $actions2 =
        [
            [ sub{ $a =~ /$num_rule/ && $a < 0.001 }, sub{ "too low: $a" } ],
            [ sub{ $a =~ /$num_rule/ && $b =~ m/$num_rule/ }, sub{ $a + $b * 2   } ],
            [ sub{ $a =~ /^\w*$/ && $b =~ m/^\w*$/ },         sub{ $a . ' ' . $b } ],
        ];

    my $dm = Data::Math->new( actions => $actions2 );

    my $d1 = {
        xx => 0.0001,
        es => 100,
        de => 333,
        us => 666,
        note => 'greenback',
    };

    my $d2 = {
        yy => 0.0001,
        es => 3,
        de => 4,
        us => 2,
        note => 'sharp',
    };

    # print "2nd: pre a: $a\n" if defined $a;
    # print "2nd: pre b: $b\n" if defined $b;

    my $result =
        $dm->do_calc( $d1, $d2 );

    # print Dumper( $result ), "\n";

    # print "2nd: post a: $a\n" if defined $a;
    # print "2nd: POST b: $b\n" if defined $b;

    # print "YEA result: ", Dumper( $result ), "\n";

    my $expected = {
          'yy' => undef,
          'de' => 341,
          'us' => 670,
          'es' => 106,
          'xx' => 'too low: 0.0001',
          'note' => 'greenback sharp'
        };
    is_deeply( $result, $expected, "$test_name" );
}






done_testing();
