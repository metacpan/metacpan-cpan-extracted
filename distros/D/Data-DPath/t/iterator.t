#! /usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Deep;
use Data::DPath 'dpathi';
use Data::Dumper;

# local $Data::DPath::DEBUG = 1;

use_ok( 'Data::DPath' );

# This is basically how the Benchmark::Perl::Formance suite utilizes
# Iterator Style approach.

my $RESULTS = {
               'perlformance' => {
                                  'overall_runtime' => '2.13346099853516',
                                  'config' => {
                                               'use_forks' => 0,
                                               'fastmode' => 1
                                              }
                                 },
               'results' => {
                             'Rx' => {
                                      'regexes' => {
                                                    'pathological' => {
                                                                       'goal' => 5,
                                                                       'count' => 5,
                                                                       'Benchmark' => [
                                                                                       '0.000167131423950195',
                                                                                       0,
                                                                                       0,
                                                                                       0,
                                                                                       0,
                                                                                       5
                                                                                      ]
                                                                      },
                                                    'fieldsplitratio' => '2.3750',
                                                    'fieldsplit2' => {
                                                                      'goal' => 5,
                                                                      'count' => 5,
                                                                      'Benchmark' => [
                                                                                      '0.165295839309692',
                                                                                      '0.16',
                                                                                      0,
                                                                                      0,
                                                                                      0,
                                                                                      5
                                                                                     ]
                                                                     },
                                                    'fieldsplit1' => {
                                                                      'goal' => 5,
                                                                      'count' => 5,
                                                                      'Benchmark' => [
                                                                                      '0.394932270050049',
                                                                                      '0.38',
                                                                                      0,
                                                                                      0,
                                                                                      0,
                                                                                      5
                                                                                     ]
                                                                     }
                                                   }
                                     },
                             'DPath' => {
                                         'dpath' => {
                                                     'goal' => 15,
                                                     'data_size' => 254242,
                                                     'Benchmark' => [
                                                                     '1.39033102989197',
                                                                     '1.37',
                                                                     0,
                                                                     0,
                                                                     0,
                                                                     5
                                                                    ],
                                                     'result' => '2'
                                                    }
                                        }
                            }
              };

# ==================================================

my @all_keys = ();
my $root = dpathi($RESULTS);

cmp_deeply ($root->ref,
            \$RESULTS,
            "dpathi initial root ref");
cmp_deeply ($root->deref,
            $RESULTS,
            "dpathi initial root deref");

my $benchmarks = $root->isearch("//Benchmark");
my $i = 0;
while ($benchmarks->isnt_exhausted)
{
        $i++;
        my @keys;
        my $benchmark = $benchmarks->value;

        {
            my $copy = Data::DPath::Context->new->current_points( $benchmark->current_points );
            my $ancestors = $copy->isearch ("/::ancestor");

            my $j = 0;
            while ($ancestors->isnt_exhausted) {
                $j++;
                my $ancestor = $ancestors->value;
                my $key = $ancestor->first_point->{attrs}{key};
                push @keys, $key if defined $key;
                if ($key) {
                    is ($key, $ancestor->first_point->attrs->key, "accessor methods $i.$j");
                }
            }
        }

        {
            for my $test ( [ ANYSTEP => '/*' ],
                           [ ANYWHERE => '//.[! is_reftype( "ARRAY" )]' ] ) {

                my ( $label, $path )  = @$test;
                subtest $label => sub {
                    my $copy = Data::DPath::Context->new->current_points( $benchmark->current_points );
                    my $idx_exp = 0;
                    my $iter = $copy->isearch( $path );

                    my $j = 0;
                    while ( $iter->isnt_exhausted ) {
                        my $idx_got = $iter->value->first_point->attrs->idx;
                        is( $idx_got, $idx_exp, "idx attr $i.$j" );
                    }
                    continue {
                        ++$idx_exp;
                        ++$j;
                    }
                };
            }
        }

        pop @keys;
        push @all_keys, join(".", reverse @keys);
}

cmp_bag(\@all_keys,
        [ qw(DPath.dpath
             Rx.regexes.pathological
             Rx.regexes.fieldsplit2
             Rx.regexes.fieldsplit1
           ) ],
        "KEY + FILTER int 0" );

done_testing();
