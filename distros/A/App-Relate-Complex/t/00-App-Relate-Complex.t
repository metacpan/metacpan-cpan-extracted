# Test file, run like so: "perl 00-App-Relate-Complex.t"
#    doom@kzsu.stanford.edu     2007/05/17 01:03:37

use warnings;
use strict;
$|=1;
my $DEBUG = 0;

use Test::More;
my $total_count;
BEGIN {
  $total_count = 34;
  plan tests => $total_count;
  if ($DEBUG) {
    require Data::Dumper;
  }
};

use Test::Trap qw( trap $trap );

use FindBin qw($Bin);
use lib ("$Bin/../lib");
use File::Locate::Harder;

BEGIN {
  use_ok( 'App::Relate::Complex' );
}

ok(1, "Traditional 'If we made it this far, we're ok.'");

# Many of the following tests in this file may be skipped for different reasons:
# (1) if the system seems to have no form of 'locate' installed (e.g. OpenBSD)
# (2) if a baby locate database can't be created to track the tree of test files
# (3) if the search terms used in the tests happen to match the path to the
#     tree of test files (locate tracks absolute paths, and when writing
#     these tests I can't know what those absolute paths will be).

# skip all tests if there is no locate installation
SKIP:
{
  my $obj;
  my @r = trap {
    $obj = File::Locate::Harder->new();
  };
  if ( my $err_mess = $trap->die ) {
    my $expected_err_mess =
      "File::Locate::Harder is not working. " .
        "Problem with 'locate' installation?";
    $expected_err_mess =~ s{ \s+? }{ \\s+ }gx;

    unless ( $err_mess =~ qr{ $expected_err_mess }x) {
      die "$err_mess";
    }
    my $how_many = $total_count - 2; # all remaining tests
    skip "Problem with installation of 'locate'", $how_many;
  }
  { #3
    my $test_name = 'Testing creation of a basic List::Filter::Relate object';
    my $lfr = App::Relate::Complex->new();
    my $type = ref $lfr;
    is($type, 'App::Relate::Complex', $test_name);
  }

 SKIP:
  {                             #4, #5, #6
    # Initialize for following tests

    my $db_loc = "$Bin/dat/slocate";
    my $db     = "$db_loc/slocate.db";
    my $tree   = "$Bin/dat/tree";
    my $loc    = $tree;
    my $stash  = "$Bin/dat/stash/stash.yaml";

    my $flh = File::Locate::Harder->new( db => undef );
    my $why = '';
    if ( not(
             $flh->create_database( $tree, $db )
            ) ) {
      $why = "Could not create locate database $db";
    } elsif ( not( $flh->probe_db ) ) {
      $why = "Can't get File::Locate::Harder to work with $db";
    }
    if ($why) {
      my $how_many = 3;
      skip $why, $how_many;
    }

    { #4
      my $test_name = "Testing relate_complex method using default filter";
      my $lfr = App::Relate::Complex->new( {
                                                 storage  => $stash,
                                                 locatedb => $db
                                                } );
    SKIP:
      {
        my @terms = qw(groovy txt);
        my $how_many = 1;
        foreach my $term (@terms) {
          if ($loc =~ m/$term/i) {
            skip "tests invalid because $term matches the path, $loc", $how_many;
            last;
          }
        }

        my $matches = $lfr->relate_complex( \@terms );

        my @expected = sort( (
                              "$tree/subdir/groovy.txt",
                              "$tree/subdir/deepdir/groovy.txt",
                             ) );
        my $matches_sorted = [ sort( @{ $matches } ) ];
        is_deeply( $matches_sorted, \@expected, $test_name);
      }                         # end skip -- $term matches path
    }

    {                           #5
      my $test_name = "Testing relate_complex method using named filter";
      my $lfr = App::Relate::Complex->new( {
                                                 storage  => $stash,
                                                 locatedb => $db
                                                } );

    SKIP:
      {
        my @terms = qw(sex_hundart_und_sexty_sexy compilitations);
        my $how_many = 1;
        foreach my $term (@terms) {
          if ($loc =~ m/$term/i) {
            skip "tests invalid because $term matches the path, $loc", $how_many;
            last;
          }
        }

        my $matches = $lfr->relate_complex( \@terms, { add_filters => ":c-omit"} );

        my @expected = sort( (
                              "$tree/nother_dir/compilitations/sex_hundart_und_sexty_sexy-one.c",
                              "$tree/nother_dir/compilitations/sex_hundart_und_sexty_sexy-two.c",
                             ) );

        my $matches_sorted = [ sort( @{ $matches } ) ];
        is_deeply( $matches_sorted, \@expected, $test_name);
      }                         # end skip -- $term matches path
    }


    {                           #6
      my $test_name = "Testing relate_complex method using the :jpeg filter as a filter";
      my $lfr = App::Relate::Complex->new( {
                                                 storage  => $stash,
                                                 locatedb => $db
                                                } );
    SKIP:
      {
        my @terms = ('ThreeThree', '^ThreeThree' );
        my $how_many = 1;
        foreach my $term (@terms) {
          if ($loc =~ m/$term/i) {
            skip "tests invalid because $term matches the path, $loc", $how_many;
            last;
          }
        }


        my $matches = $lfr->relate_complex( \@terms, { add_filters => ":jpeg" } );

        my @expected = sort( (
                              "$tree/ThreeThreeThree.JPG",
                              "$tree/ThreeThreeTwo.jpeg",
                             ));

        my @sorted_matches = sort @{ $matches };
        is_deeply( \@sorted_matches, \@expected, $test_name);
      }                         # end skip -- $term matches path
    }
  }                          # end skip -- can't create locate db

 SKIP:
  {                             #7 - #15
    # Initialize for another series of tests (working the omit filters)

    my $db_loc = "$Bin/dat/slocate2";
    my $db     = "$db_loc/slocate.db";
    my $tree   = "$Bin/dat/tree2";
    my $stash  = "$Bin/dat/stash2/stash-not_used.yaml";

    my $flh = File::Locate::Harder->new( db => undef );
    my $why = '';
    if ( not(
             $flh->create_database( $tree, $db )
            ) ) {
      $why = "Could not create locate database $db";
    } elsif ( not( $flh->probe_db ) ) {
      $why = "Can't get File::Locate::Harder to work with $db";
    }
    if ($why) {
      my $how_many = 8;
      skip $why, $how_many;
    }

    {                           #7, #8, #9, #10, #11
      my $test_name = "Testing relate_complex method using the :skipdull filter";
      my $lfr = App::Relate::Complex->new( {
                                                 storage  => $stash,
                                                 locatedb => $db
                                                } );
    SKIP:
      {
        my $loc = "$tree/test7";
        my @terms = ('shadow', 'the' );
        my $how_many = 5;
        foreach my $term (@terms) {
          if ($loc =~ m/$term/i) {
            skip "tests invalid because $term matches the path, $loc", $how_many;
            last;
          }
        }

        my @terms_original = @terms;

        my $opt_a = {
                    };

        my $opt_b = {
                     no_default_filters => 1,
                    };

        my $opt_c = {          # should be the same as opt_a case
                     add_filters => ":skipdull",
                    };

        my $opt_d = {          # should be the same as opt_a case
                     no_default_filters => 1,
                     add_filters => ":skipdull",
                    };


        my $matches_a = $lfr->relate_complex( \@terms, $opt_a );
        my $matches_b = $lfr->relate_complex( \@terms, $opt_b );
        my $matches_c = $lfr->relate_complex( \@terms, $opt_c );
        my $matches_d = $lfr->relate_complex( \@terms, $opt_d );

        is_deeply( [ sort( @terms ) ], [ sort( @terms_original ) ],
                   "Testing that the relate_complex method does not modify search terms array");

        ($DEBUG) && print STDERR "matches_a: ", Data::Dumper::Dumper($matches_a), "\n";
        ($DEBUG) && print STDERR "matches_b: ", Data::Dumper::Dumper($matches_b), "\n";
        ($DEBUG) && print STDERR "matches_c: ", Data::Dumper::Dumper($matches_c), "\n";
        ($DEBUG) && print STDERR "matches_d: ", Data::Dumper::Dumper($matches_d), "\n";

        my @expected_a = sort( (
                                "$loc/essays/scared_of_their_shadow.txt",
                                "$loc/reviews/the_living_shadow-maxwell_grant",
                               ));

        my @expected_b = sort( (
                                "$loc/essays/scared_of_their_shadow.txt",
                                "$loc/reviews/the_living_shadow-maxwell_grant",
                                "$loc/reviews/#the_living_shadow-maxwell_grant#",
                             #  "$loc/reviews/.#the_living_shadow-maxwell_grant", # "make dist" won't ship a symlink
                                "$loc/reviews/RCS/the_living_shadow-maxwell_grant,v",
                               ));

        my @sorted_matches_a = sort @{ $matches_a };
        is_deeply( \@sorted_matches_a, \@expected_a, "$test_name: default filter on");

        my @sorted_matches_b = sort @{ $matches_b };
        is_deeply( \@sorted_matches_b, \@expected_b, "$test_name: filters off");

        my @sorted_matches_c = sort @{ $matches_c };
        is_deeply( \@sorted_matches_c, \@expected_a, "$test_name: ':skipdull' filter specified explicitly");

        my @sorted_matches_d = sort @{ $matches_d };
        is_deeply( \@sorted_matches_d, \@expected_a, "$test_name: ':skipdull' filter specified, with default filter off");

      }                         # end skip -- $term matches path
    }

    {                           #12, #13, #14, #15
      my $test_name = "Testing relate_complex method with case-insensitive switch";
      my $loc = "$tree/test11";
      my $modifiers = 'i';
      my $lfr   = App::Relate::Complex->new( {
                                                   storage  => $stash,
                                                   locatedb => $db,
                                                  } );
      my $lfr_i = App::Relate::Complex->new( {
                                                   storage   => $stash,
                                                   locatedb  => $db,
                                                   modifiers => $modifiers,
                                                  } );
      my @files = qw(
                      aaaaaaaaaaaaaaaaaa
                      bbbbbbbbbbbbbbbbbb
                      Bbbbbbbbbbbbbbbbbb
                      cccccccccccccccccc
                      dddddddddddddddddd
                      dddddddddDdddddddd
                      ddddDDDDDDdDDDdddd
                      eeeeeeeeeeeeeeeeee
                      EEEEEEEEEEEEEEEEEE
                   );
    SKIP:
      {                         #12, #13
        my @terms = ('dddddddddddddddddd');
        my $how_many = 2;
        foreach my $term (@terms) {
          if ($loc =~ m/$term/i) {
            skip "tests invalid because $term matches the path, $loc", $how_many;
            last;
          }
        }

        my @expected    = "$loc/dddddddddddddddddd";
        my @expected_i = sort( (
                                "$loc/dddddddddddddddddd",
                                "$loc/dddddddddDdddddddd",
                                "$loc/ddddDDDDDDdDDDdddd",
                               ) );

        my $matches   = [ sort( @{   $lfr->relate_complex( \@terms ) } ) ];
        my $matches_i = [ sort( @{ $lfr_i->relate_complex( \@terms ) } ) ];

        my @sorted_matches   = sort @{ $matches   };
        my @sorted_matches_i = sort @{ $matches_i };

        is_deeply( \@sorted_matches,   \@expected,   "$test_name: case sensitive  ");
        is_deeply( \@sorted_matches_i, \@expected_i, "$test_name: case insensitive");
      }                         # end skip - $term matches path


    SKIP:
      {                         #14, #15
        my @terms = ('EEEEEEEEEEEEEEEEEE');
        my $how_many = 2;
        foreach my $term (@terms) {
          if ($loc =~ m/$term/i) {
            skip "tests invalid because $term matches the path, $loc", $how_many;
            last;
          }
        }

        my @expected = sort( (
                              "$loc/EEEEEEEEEEEEEEEEEE",
                             ) );
        my @expected_i = sort( (
                                "$loc/eeeeeeeeeeeeeeeeee",
                                "$loc/EEEEEEEEEEEEEEEEEE",
                               ) );

        my $matches   = [ sort( @{   $lfr->relate_complex( \@terms ) } ) ];
        my $matches_i = [ sort( @{ $lfr_i->relate_complex( \@terms ) } ) ];

        my @sorted_matches   = sort @{ $matches   };
        my @sorted_matches_i = sort @{ $matches_i };

        is_deeply( \@sorted_matches,   \@expected,   "$test_name: case sensitive  ");
        is_deeply( \@sorted_matches_i, \@expected_i, "$test_name: case insensitive");
      }                         # end skip -- $term matches path
    }
  }                          # end skip -- can't create locate db


  # The following tests are intended to simulate what would happen during operations such as this:

  # relate_complex relate_complex.t doom
  # relate_complex -a -f :doom-omit relate_complex.t doom
  # relate_complex -f :doom-omit relate_complex.t doom
  # relate_complex -a -f ':doom-omit :jpeg' relate_complex.t doom

  {                             #16 - #19
    my $test_name = "Testing internal method setup_filter_names";
    my $lfr = App::Relate::Complex->new();

    my ($test_case, $opt, $default_filters, $filter_names, $expected_filters);

    #16
    $test_case = "multiple additional filters with no defaults";
    $opt = { add_filters => ':doverboys :donkeytails littleamseydivey',
             no_default_filters => 1
           };
    $default_filters = [':skipdull'];
    $filter_names = $lfr->setup_filter_names( $opt, $default_filters );
    $expected_filters = [
                         qw( :doverboys :donkeytails littleamseydivey )
                        ];
    is_deeply( [ sort @{ $filter_names } ], [ sort @{ $expected_filters } ],
               "$test_name: $test_case");

    #17
    $test_case = "extra-quotes on multiple filters adds, no defaults";
    $opt = { add_filters => '\':doverboys :donkeytails littleamseydivey\'',
             no_default_filters => 1
           };
    $default_filters = [':skipdull'];
    $filter_names = $lfr->setup_filter_names( $opt, $default_filters );
    $expected_filters = [
                         qw( :doverboys :donkeytails littleamseydivey )
                        ];
    is_deeply( [ sort @{ $filter_names } ], [ sort @{ $expected_filters } ],
               "$test_name: $test_case");

    #18
    $test_case = "a single addition to the default";
    $opt = { add_filters => 'but_keep_me_anyway',
           };
    $default_filters = [':skipdull'];
    $filter_names = $lfr->setup_filter_names( $opt, $default_filters );
    $expected_filters = [
                         qw( :skipdull but_keep_me_anyway )
                        ];
    is_deeply( [ sort @{ $filter_names } ], [ sort @{ $expected_filters } ],
               "$test_name: $test_case");

    #19
    $test_case = "a single filter, without the default";
    $opt = { add_filters => 'but_keep_me_anyway',
             no_default_filters => 1
           };
    $default_filters = [':skipdull'];
    $filter_names = $lfr->setup_filter_names( $opt, $default_filters );
    $expected_filters = [
                         qw( but_keep_me_anyway )
                        ];
    is_deeply( [ sort @{ $filter_names } ], [ sort @{ $expected_filters } ],
               "$test_name: $test_case");
  }


 SKIP:
  { my $test_name = "Testing relate_complex method using the image selection filters";
    # Initialize for another series of tests (working the jpeg filters)
    my $db_loc = "$Bin/dat/slocate3";
    my $db     = "$db_loc/slocate.db";
    my $tree   = "$Bin/dat/tree3";
    my $stash  = "$Bin/dat/stash3/stash-not_used.yaml";

    my $flh = File::Locate::Harder->new( db => undef );
    my $why = '';
    if ( not(
             $flh->create_database( $tree, $db )
            ) ) {
      $why = "Could not create locate database $db";
    } elsif ( not( $flh->probe_db ) ) {
      $why = "Can't get File::Locate::Harder to work with $db";
    }
    if ($why) {
      my $how_many = 4;
      skip $why, $how_many;
    }

    {
      my $lfr = App::Relate::Complex->new( {
                                                 storage  => $stash,
                                                 locatedb => $db
                                                } );
    SKIP:
      {
        my $loc = "$tree";
        my @terms = ( 'AAA111', 'the_s', 'pixies' );
        my $how_many = 4;
        foreach my $term (@terms) {
          if ($loc =~ m/$term/i) {
            skip "tests invalid because $term matches the path, $loc", $how_many;
            last;
          }
        }

        my @terms_original = @terms;

        my $opt_a = {
                     add_filters => ":jpeg",
                    };

        my $opt_b = {          # should be the same as opt_a case
                     no_default_filters => 1,
                     add_filters => ":jpeg",
                    };

        my $opt_c = {
                     add_filters => ":web_img",
                    };

        my $opt_d = {          # should be the same as opt_c case
                     no_default_filters => 1,
                     add_filters => ":web_img",
                    };


        my $matches_a = $lfr->relate_complex( \@terms, $opt_a );
        my $matches_b = $lfr->relate_complex( \@terms, $opt_b );
        my $matches_c = $lfr->relate_complex( \@terms, $opt_c );
        my $matches_d = $lfr->relate_complex( \@terms, $opt_d );

        #
        is_deeply( [ sort( @terms ) ], [ sort( @terms_original ) ],
                   "Testing that the relate_complex method does not modify search terms array");

        ($DEBUG) && print STDERR "matches_a: ", Data::Dumper::Dumper($matches_a), "\n";
        ($DEBUG) && print STDERR "matches_b: ", Data::Dumper::Dumper($matches_b), "\n";
        ($DEBUG) && print STDERR "matches_c: ", Data::Dumper::Dumper($matches_c), "\n";
        ($DEBUG) && print STDERR "matches_d: ", Data::Dumper::Dumper($matches_d), "\n";

        my @expected_a = sort( (
                                "$tree/AAA111/pixies/the_second.jpg",
                                "$tree/AAA111/pixies/the_sixth.jpg",
                                "$tree/AAA111/pixies/the_second.JPG",
                                "$tree/AAA111/pixies/the_sixth.JPG",
                               ));

        my @expected_c = sort( (
                                "$tree/AAA111/pixies/the_second.jpg",
                                "$tree/AAA111/pixies/the_sixth.jpg",
                                "$tree/AAA111/pixies/the_second.GIF",
                                "$tree/AAA111/pixies/the_sixth.GIF",
                                "$tree/AAA111/pixies/the_second.JPG",
                                "$tree/AAA111/pixies/the_sixth.JPG",
                                "$tree/AAA111/pixies/the_second.png",
                                "$tree/AAA111/pixies/the_sixth.png",
                               ));

        my @sorted_matches_a = sort @{ $matches_a };
        is_deeply( \@sorted_matches_a, \@expected_a, "$test_name: ':jpeg' with default filter on");

        my @sorted_matches_b = sort @{ $matches_b };
        is_deeply( \@sorted_matches_b, \@expected_a, "$test_name: ':jpeg' with default off");

        my @sorted_matches_c = sort @{ $matches_c };
        is_deeply( \@sorted_matches_c, \@expected_c, "$test_name: ':web_img' filter with default on");

        my @sorted_matches_d = sort @{ $matches_d };
        is_deeply( \@sorted_matches_d, \@expected_c, "$test_name: ':web_img' filter with default off");

      } # end skip -- $term matches path
    }

    { #25, #26, #27, #28
      # This is a contrived test to use two sets of filters together: there are *.JPG files
      # hidden insides a CVS directory so they'll be screened out by the ':hide_vc'
      my $test_name = "Testing relate_complex method using stacked filters and a regexp search with dwim trans";
      my $lfr = App::Relate::Complex->new( {
                                                 storage  => $stash,
                                                 locatedb => $db
                                                } );
    SKIP:
      {
        my $loc = "$tree";
        my @terms = ( 'BBB222', 'the_', 'da_' ); # we will use two together as a regexp: 'the_|da_'
        my $how_many = 4;
        foreach my $term (@terms) {
          if ($loc =~ m/$term/i) {
            skip "tests invalid because $term matches the path, $loc", $how_many;
            last;
          }
        }

        my @terms_original = @terms;

        # first try should match all of them
        my $test_case_a = ":web_img filter, w/o default";
        my $opt_a = {
                     no_default_filters => 1,
                     add_filters => ':web_img',
                    };

        # this should screen out the ones inside the CVS directory
        my $test_case_b = ":web_img and :dires-x-omit filters, w/o default";
        my $opt_b = {
                     no_default_filters => 1,
                     add_filters => ":web_img :hide_vc",
                    };

        # two relatively inane tests: the same deal with :jpeg instead of :web_img
        my $test_case_c = ":jpeg filter, w/o default";
        my $opt_c = {           # same as set a
                     no_default_filters => 1,
                     add_filters => ":jpeg",
                    };

        my $test_case_d = ":jpeg and :dires-x-omit filters, w/o default";
        my $opt_d = {           # same as set b
                     no_default_filters => 1,
                     add_filters => ":jpeg :hide_vc",
                    };

        my ($dir, $pre1, $pre2) = @terms;
        my @search = ( $dir, "^$pre1|^$pre2"); # using a regexp, and also the dwim transform
        my @search_original = @search;

        my $matches_a = $lfr->relate_complex( \@search, $opt_a );
        my $matches_b = $lfr->relate_complex( \@search, $opt_b );
        my $matches_c = $lfr->relate_complex( \@search, $opt_c );
        my $matches_d = $lfr->relate_complex( \@search, $opt_d );

        is_deeply( [ sort( @search) ], [ sort( @search_original ) ],
                   "Testing that the relate_complex method does not modify search terms array");

        ($DEBUG) && print STDERR "matches_a: ", Data::Dumper::Dumper($matches_a), "\n";
        ($DEBUG) && print STDERR "matches_b: ", Data::Dumper::Dumper($matches_b), "\n";
        ($DEBUG) && print STDERR "matches_c: ", Data::Dumper::Dumper($matches_c), "\n";
        ($DEBUG) && print STDERR "matches_d: ", Data::Dumper::Dumper($matches_d), "\n";

        my @expected_a = sort( (
                                "$tree/BBB222/pyx/the_first.jpg",
                                "$tree/BBB222/pyx/the_second.jpg",
                                "$tree/BBB222/pyx/the_third.jpg",
                                "$tree/BBB222/pyx/the_fourth.jpg",
                                "$tree/BBB222/pyx/the_fifth.jpg",
                                "$tree/BBB222/pyx/the_sixth.jpg",
                                "$tree/BBB222/pyx/CVS/da_fifth.JPG",
                                "$tree/BBB222/pyx/CVS/da_first.JPG",
                                "$tree/BBB222/pyx/CVS/da_fourth.JPG",
                                "$tree/BBB222/pyx/CVS/da_second.JPG",
                                "$tree/BBB222/pyx/CVS/da_sixth.JPG",
                                "$tree/BBB222/pyx/CVS/da_third.JPG",
                               ));

        my @expected_b = sort( (
                                "$tree/BBB222/pyx/the_first.jpg",
                                "$tree/BBB222/pyx/the_second.jpg",
                                "$tree/BBB222/pyx/the_third.jpg",
                                "$tree/BBB222/pyx/the_fourth.jpg",
                                "$tree/BBB222/pyx/the_fifth.jpg",
                                "$tree/BBB222/pyx/the_sixth.jpg",
                               ));

        my @sorted_matches_a = sort @{ $matches_a };
        is_deeply( \@sorted_matches_a, \@expected_a, "$test_name: $test_case_a");

        my @sorted_matches_b = sort @{ $matches_b };
        is_deeply( \@sorted_matches_b, \@expected_b, "$test_name:  $test_case_b");

        my @sorted_matches_c = sort @{ $matches_c };
        is_deeply( \@sorted_matches_c, \@expected_a, "$test_name:  $test_case_c");

        my @sorted_matches_d = sort @{ $matches_d };
        is_deeply( \@sorted_matches_d, \@expected_b, "$test_name: $test_case_d");
      } # end skip -- $term matches path
    }

    {
      # Testing first term as a posix regexp behavior.
      # Exploiting the change in behavior of . (matches anything, including '_' if regexp)
      my $test_name =
        "Testing relate_complex with posix regexp feature on lead term";
      my $lfr = App::Relate::Complex->new( {
                                                 storage  => $stash,
                                                 locatedb => $db
                                                } );
    SKIP:
      {
        my $loc = "$tree";
        my @terms = ( 'th.funny_ext', 'CCC333', '^s' );
        my $how_many = 4;
        foreach my $term (@terms) {
          if ($loc =~ m/$term/i) {
            skip "tests invalid because $term matches the path, $loc", $how_many;
            last;
          }
        }

        # first try should match all of them
        my $test_case_a = "lead term not a regexp, (default filter on)";
        my $opt_a = {
                     regexp => 0,
                    };

        # this should match more files because of the first term is a regexp
        my $test_case_b = "lead term a posix regexp (default filter on)";
        my $opt_b = {
                     regexp => 1,
                    };

        # two relatively inane tests: same deal with default filters shut-off
        my $test_case_c = "not a regexp, default filter off";
        my $opt_c = { # same as set a
                     no_default_filters => 1,
                     regexp => 0,
                    };

        my $test_case_d = "regexp with default filter off, but :hide_vc filter added";
        my $opt_d = { # same as set b
                     no_default_filters => 1,
                     add_filters => ":hide_vc",
                     regexp => 1,
                    };

        my @search = @terms;
        my @search_original = @search;

        my $matches_a = $lfr->relate_complex( \@search, $opt_a );
        my $matches_b = $lfr->relate_complex( \@search, $opt_b );
        my $matches_c = $lfr->relate_complex( \@search, $opt_c );
        my $matches_d = $lfr->relate_complex( \@search, $opt_d );

        ($DEBUG) && print STDERR "search: " . Data::Dumper::Dumper( \@search ), "\n";
        ($DEBUG) && print STDERR "orig:   " . Data::Dumper::Dumper( \@search_original ), "\n";

        is_deeply( [ sort( @search) ], [ sort( @search_original ) ],
                   "Testing that the relate_complex method does not modify search terms array");

        ($DEBUG) && print STDERR "matches_a: ", Data::Dumper::Dumper($matches_a), "\n";
        ($DEBUG) && print STDERR "matches_b: ", Data::Dumper::Dumper($matches_b), "\n";
        ($DEBUG) && print STDERR "matches_c: ", Data::Dumper::Dumper($matches_c), "\n";
        ($DEBUG) && print STDERR "matches_d: ", Data::Dumper::Dumper($matches_d), "\n";

        my @expected_a = sort( (
                                "$tree/CCC333/sam_the_fifth.funny_ext",
                                "$tree/CCC333/sam_the_fourth.funny_ext",
                                "$tree/CCC333/sam_the_sixth.funny_ext",
                               ));

        my @expected_b = sort( (
                                "$tree/CCC333/sam_the_fifth.funny_ext",
                                "$tree/CCC333/sam_the_fourth.funny_ext",
                                "$tree/CCC333/sam_the_sixth.funny_ext",
                                "$tree/CCC333/slim_the_fifth_funny_ext",
                                "$tree/CCC333/slim_the_fourth_funny_ext",
                                "$tree/CCC333/slim_the_sixth_funny_ext",
                               ));

        my @sorted_matches_a = sort @{ $matches_a };
        is_deeply( \@sorted_matches_a, \@expected_a, "$test_name: $test_case_a");

        my @sorted_matches_b = sort @{ $matches_b };
        is_deeply( \@sorted_matches_b, \@expected_b, "$test_name:  $test_case_b");

        my @sorted_matches_c = sort @{ $matches_c };
        is_deeply( \@sorted_matches_c, \@expected_a, "$test_name:  $test_case_c");

        my @sorted_matches_d = sort @{ $matches_d };
        is_deeply( \@sorted_matches_d, \@expected_b, "$test_name: $test_case_d");
      } # end skip -- $term matches path
    }

  } # end skip -- can't create locate db
} # end skip -- problem with installation of locate





