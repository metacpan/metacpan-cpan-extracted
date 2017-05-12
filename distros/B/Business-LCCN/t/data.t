#!perl

use Test::More;
use strict;
use warnings;

my @tests = ( {  orig           => 'n78-890351',
                 canonical      => 'n  78890351 ',
                 normalized     => 'n78890351',
                 prefix         => 'n',
                 year_cataloged => 1978,
                 serial         => '890351',
              },
              {  orig           => 'n 78890351 ',
                 canonical      => 'n  78890351 ',
                 normalized     => 'n78890351',
                 prefix         => 'n',
                 year_cataloged => 1978,
                 serial         => '890351',
              },
              {  orig           => ' 85000002 ',
                 canonical      => '   85000002 ',
                 normalized     => '85000002',
                 year_cataloged => 1985,
                 serial         => '000002',
              },
              {  orig           => '85-2 ',
                 canonical      => '   85000002 ',
                 normalized     => '85000002',
                 year_cataloged => 1985,
                 serial         => '000002',
              },
              {  orig           => '2001-000002',
                 canonical      => '  2001000002',
                 normalized     => '2001000002',
                 year_cataloged => 2001,
                 serial         => '000002',
              },
              {  orig                  => '75-425165//r75',
                 canonical             => '   75425165 //r75',
                 normalized            => '75425165',
                 prefix                => '',
                 year_cataloged        => undef,
                 serial                => '425165',
                 revision_year         => 1975,
                 revision_year_encoded => '75',
                 revision_number       => undef,
              },
              {  orig                          => ' 79139101 /AC/r932',
                 canonical                     => '   79139101 /AC/r932',
                 normalized                    => '79139101',
                 prefix                        => '',
                 year_cataloged                => undef,
                 serial                        => '139101',
                 suffix_encoded                => '/AC',
                 suffix_alphabetic_identifiers => [qw( AC )],
                 revision_year                 => 1993,
                 revision_year_encoded         => '93',
                 revision_number               => 2,
              },
              {  orig           => '89-4',
                 canonical      => '   89000004 ',
                 normalized     => '89000004',
                 year_cataloged => 1989,
                 serial         => '000004',
              },
              {  orig           => '89-45',
                 canonical      => '   89000045 ',
                 normalized     => '89000045',
                 year_cataloged => 1989,
                 serial         => '000045',
              },
              {  orig           => '89-456',
                 canonical      => '   89000456 ',
                 normalized     => '89000456',
                 year_cataloged => 1989,
                 serial         => '000456',
              },
              {  orig           => '89-1234',
                 canonical      => '   89001234 ',
                 normalized     => '89001234',
                 year_cataloged => 1989,
                 serial         => '001234',
              },
              {  orig           => '89-001234',
                 canonical      => '   89001234 ',
                 normalized     => '89001234',
                 year_cataloged => 1989,
                 serial         => '001234',
              },
              {  orig           => '89001234',
                 canonical      => '   89001234 ',
                 normalized     => '89001234',
                 year_cataloged => 1989,
                 serial         => '001234',
              },
              {  orig           => '2002-1234',
                 canonical      => '  2002001234',
                 normalized     => '2002001234',
                 year_cataloged => 2002,
                 serial         => '001234',
              },
              {  orig           => '2002-001234',
                 canonical      => '  2002001234',
                 normalized     => '2002001234',
                 year_cataloged => 2002,
                 serial         => '001234',
              },
              {  orig           => '2002001234',
                 canonical      => '  2002001234',
                 normalized     => '2002001234',
                 year_cataloged => 2002,
                 serial         => '001234',
              },
              {  orig           => '   89001234 ',
                 canonical      => '   89001234 ',
                 normalized     => '89001234',
                 year_cataloged => 1989,
                 serial         => '001234',
              },
              {  orig           => '  2002001234',
                 canonical      => '  2002001234',
                 normalized     => '2002001234',
                 year_cataloged => 2002,
                 serial         => '001234',
              },
              {  orig           => 'a89-1234',
                 canonical      => 'a  89001234 ',
                 normalized     => 'a89001234',
                 prefix         => 'a',
                 year_cataloged => 1989,
                 serial         => '001234',
              },
              {  orig           => 'a89-001234',
                 canonical      => 'a  89001234 ',
                 normalized     => 'a89001234',
                 prefix         => 'a',
                 year_cataloged => 1989,
                 serial         => '001234',
              },
              {  orig           => 'a89001234',
                 canonical      => 'a  89001234 ',
                 normalized     => 'a89001234',
                 prefix         => 'a',
                 year_cataloged => 1989,
                 serial         => '001234',
              },
              {  orig           => 'a2002-1234',
                 canonical      => 'a 2002001234',
                 normalized     => 'a2002001234',
                 prefix         => 'a',
                 year_cataloged => 2002,
                 serial         => '001234',
              },
              {  orig           => 'a2002-001234',
                 canonical      => 'a 2002001234',
                 normalized     => 'a2002001234',
                 prefix         => 'a',
                 year_cataloged => 2002,
                 serial         => '001234',
              },
              {  orig           => 'a2002001234',
                 canonical      => 'a 2002001234',
                 normalized     => 'a2002001234',
                 prefix         => 'a',
                 year_cataloged => 2002,
                 serial         => '001234',
              },
              {  orig           => 'a 89001234 ',
                 canonical      => 'a  89001234 ',
                 normalized     => 'a89001234',
                 prefix         => 'a',
                 year_cataloged => 1989,
                 serial         => '001234',
              },
              {  orig           => 'a 89-001234 ',
                 canonical      => 'a  89001234 ',
                 normalized     => 'a89001234',
                 prefix         => 'a',
                 year_cataloged => 1989,
                 serial         => '001234',
              },
              {  orig           => 'a 2002001234',
                 canonical      => 'a 2002001234',
                 normalized     => 'a2002001234',
                 prefix         => 'a',
                 year_cataloged => 2002,
                 serial         => '001234',
              },
              {  orig           => 'ab89-1234',
                 canonical      => 'ab 89001234 ',
                 normalized     => 'ab89001234',
                 prefix         => 'ab',
                 year_cataloged => 1989,
                 serial         => '001234',
              },
              {  orig           => 'ab89-001234',
                 canonical      => 'ab 89001234 ',
                 normalized     => 'ab89001234',
                 prefix         => 'ab',
                 year_cataloged => 1989,
                 serial         => '001234',
              },
              {  orig           => 'ab89001234',
                 canonical      => 'ab 89001234 ',
                 normalized     => 'ab89001234',
                 prefix         => 'ab',
                 year_cataloged => 1989,
                 serial         => '001234',
              },
              {  orig           => 'ab2002-1234',
                 canonical      => 'ab2002001234',
                 normalized     => 'ab2002001234',
                 prefix         => 'ab',
                 year_cataloged => 2002,
                 serial         => '001234',
              },
              {  orig           => 'ab2002-001234',
                 canonical      => 'ab2002001234',
                 normalized     => 'ab2002001234',
                 prefix         => 'ab',
                 year_cataloged => 2002,
                 serial         => '001234',
              },
              {  orig           => 'ab2002001234',
                 canonical      => 'ab2002001234',
                 normalized     => 'ab2002001234',
                 prefix         => 'ab',
                 year_cataloged => 2002,
                 serial         => '001234',
              },
              {  orig           => 'ab 89001234 ',
                 canonical      => 'ab 89001234 ',
                 normalized     => 'ab89001234',
                 prefix         => 'ab',
                 year_cataloged => 1989,
                 serial         => '001234',
              },
              {  orig           => 'ab 2002001234',
                 canonical      => 'ab2002001234',
                 normalized     => 'ab2002001234',
                 prefix         => 'ab',
                 year_cataloged => 2002,
                 serial         => '001234',
              },
              {  orig           => 'ab 89-1234',
                 canonical      => 'ab 89001234 ',
                 normalized     => 'ab89001234',
                 prefix         => 'ab',
                 year_cataloged => 1989,
                 serial         => '001234',
              },
              {  orig           => 'abc89-1234',
                 canonical      => 'abc89001234 ',
                 normalized     => 'abc89001234',
                 prefix         => 'abc',
                 year_cataloged => 1989,
                 serial         => '001234',
              },
              {  orig           => 'abc89-001234',
                 canonical      => 'abc89001234 ',
                 normalized     => 'abc89001234',
                 prefix         => 'abc',
                 year_cataloged => 1989,
                 serial         => '001234',
              },
              {  orig           => 'abc89001234',
                 canonical      => 'abc89001234 ',
                 normalized     => 'abc89001234',
                 prefix         => 'abc',
                 year_cataloged => 1989,
                 serial         => '001234',
              },
              {  orig           => 'abc89001234 ',
                 canonical      => 'abc89001234 ',
                 normalized     => 'abc89001234',
                 prefix         => 'abc',
                 year_cataloged => 1989,
                 serial         => '001234',
              },
              {  orig           => 'http://lccn.loc.gov/89001234',
                 canonical      => '   89001234 ',
                 normalized     => '89001234',
                 year_cataloged => 1989,
                 serial         => '001234',
              },
              {  orig           => 'http://lccn.loc.gov/a89001234',
                 canonical      => 'a  89001234 ',
                 normalized     => 'a89001234',
                 serial         => '001234',
                 prefix         => 'a',
                 year_cataloged => 1989,
                 serial         => '001234',
              },
              {  orig           => 'http://lccn.loc.gov/ab89001234',
                 canonical      => 'ab 89001234 ',
                 normalized     => 'ab89001234',
                 prefix         => 'ab',
                 year_cataloged => 1989,
                 serial         => '001234',
              },
              {  orig           => 'http://lccn.loc.gov/abc89001234',
                 canonical      => 'abc89001234 ',
                 normalized     => 'abc89001234',
                 prefix         => 'abc',
                 year_cataloged => 1989,
                 serial         => '001234',
              },
              {  orig           => 'http://lccn.loc.gov/2002001234',
                 canonical      => '  2002001234',
                 normalized     => '2002001234',
                 year_cataloged => 2002,
                 serial         => '001234',
              },
              {  orig           => 'http://lccn.loc.gov/a2002001234',
                 canonical      => 'a 2002001234',
                 normalized     => 'a2002001234',
                 prefix         => 'a',
                 year_cataloged => 2002,
                 serial         => '001234',
              },
              {  orig           => 'http://lccn.loc.gov/ab2002001234',
                 canonical      => 'ab2002001234',
                 normalized     => 'ab2002001234',
                 prefix         => 'ab',
                 year_cataloged => 2002,
                 serial         => '001234',
              },
              {  orig           => '00-21595',
                 canonical      => '   00021595 ',
                 normalized     => '00021595',
                 year_cataloged => 2000,
                 serial         => '021595',
              },
              {  orig           => '2001001599',
                 canonical      => '  2001001599',
                 normalized     => '2001001599',
                 year_cataloged => 2001,
                 serial         => '001599',
              },
              {  orig           => '99-18233',
                 canonical      => '   99018233 ',
                 normalized     => '99018233',
                 year_cataloged => 1999,
                 serial         => '018233',
              },
              {  orig           => '98000595',
                 canonical      => '   98000595 ',
                 normalized     => '98000595',
                 year_cataloged => 1898,
                 serial         => '000595',
              },
              {  orig           => '99005074',
                 canonical      => '   99005074 ',
                 normalized     => '99005074',
                 year_cataloged => 1899,
                 serial         => '005074',
              },
              {  orig           => '00003373',
                 canonical      => '   00003373 ',
                 normalized     => '00003373',
                 year_cataloged => 1900,
                 serial         => '003373',
              },
              {  orig           => '01001599',
                 canonical      => '   01001599 ',
                 normalized     => '01001599',
                 year_cataloged => 1901,
                 serial         => '001599',
              },
              {  orig           => '   95156543 ',
                 canonical      => '   95156543 ',
                 normalized     => '95156543',
                 year_cataloged => 1995,
                 serial         => '156543',
              },
              {  orig                          => '   94014580 /AC/r95',
                 canonical                     => '   94014580 /AC/r95',
                 normalized                    => '94014580',
                 year_cataloged                => 1994,
                 serial                        => '014580',
                 suffix_encoded                => '/AC',
                 suffix_alphabetic_identifiers => [qw( AC )],
                 revision_year_encoded         => '95',
                 revision_year                 => 1995,
              },
              {  orig                  => '   79310919 //r86',
                 canonical             => '   79310919 //r86',
                 normalized            => '79310919',
                 year_cataloged        => 1979,
                 serial                => '310919',
                 revision_year_encoded => '86',
                 revision_year         => 1986,
              },
              {  orig           => 'gm 71005810  ',
                 canonical      => 'gm 71005810 ',
                 normalized     => 'gm71005810',
                 prefix         => 'gm',
                 year_cataloged => 1971,
                 serial         => '005810',
              },
              {  orig           => 'sn2006058112  ',
                 canonical      => 'sn2006058112',
                 normalized     => 'sn2006058112',
                 prefix         => 'sn',
                 year_cataloged => 2006,
                 serial         => '058112',
              },
              {  orig           => 'gm 71-2450',
                 canonical      => 'gm 71002450 ',
                 normalized     => 'gm71002450',
                 prefix         => 'gm',
                 year_cataloged => 1971,
                 serial         => '002450',
              },
              {  orig           => '2001-1114',
                 canonical      => '  2001001114',
                 normalized     => '2001001114',
                 year_cataloged => 2001,
                 serial         => '001114',
              },
);

my $num_subtests_per_test = 10;
plan tests => 1 + ( @tests * $num_subtests_per_test );

use_ok('Business::LCCN') || BAIL_OUT('Could not load Business::LCCN');

my %orig_seen;

foreach my $test (@tests) {
    my $lccn = new Business::LCCN( $test->{orig} );

    if ( $orig_seen{ $test->{orig} } ) {
        diag(q{Test for "[$test->{orig}" repeated});
    } else {
        $orig_seen{ $test->{orig} } = 1;
    }

    if ($lccn) {

        is( $lccn->canonical, $test->{canonical},
            qq{LCCN input "$test->{orig}" canonical form is $test->{canonical}}
        );

        # normalized
        is( $lccn->normalized, $test->{normalized},
            qq{LCCN input "$test->{orig}" normalizes to $test->{normalized}}
        );

        # serial
        is( $lccn->serial, $test->{serial},
            qq{LCCN input "$test->{orig}" serial number is $test->{serial}} );

        # year_cataloged
        my $year_cataloged_printable = ( defined $test->{year_cataloged}
                                         ? $test->{year_cataloged}
                                         : '[undef]'
        );
        {

            # catch "Use of uninitialized value in numeric eq (==)" error
            local $SIG{__WARN__} = sub { };
            cmp_ok( $lccn->year_cataloged,
                    '==',
                    $test->{year_cataloged},
                    qq{LCCN input "$test->{orig}" year_cataloged is $year_cataloged_printable}
            );
        }

        # prefix
        $test->{prefix} = ( defined $test->{prefix} ? $test->{prefix} : '' );
        my $prefix_printable = ( length $test->{prefix}
                                 ? qq{"$test->{prefix}"}
                                 : '[n/a]'
        );
        is( $lccn->prefix, $test->{prefix},
            qq{LCCN input "$test->{orig}" prefix is $prefix_printable} );

        # suffix alphabetic identifiers
        $test->{suffix_alphabetic_identifiers} = (
                                defined $test->{suffix_alphabetic_identifiers}
                                ? $test->{suffix_alphabetic_identifiers}
                                : []
        );
        my $suffix_alphabetic_identifiers_printable = (
                    @{ $test->{suffix_alphabetic_identifiers} }
                    ? join( ',', @{ $test->{suffix_alphabetic_identifiers} } )
                    : '[n/a]'
        );
        is_deeply( $lccn->suffix_alphabetic_identifiers,
                   $test->{suffix_alphabetic_identifiers},
                   qq{LCCN input "$test->{orig}" suffix alphabetic identifiers are $suffix_alphabetic_identifiers_printable}
        );

        # suffix encoded
        $test->{suffix_encoded} = (
             defined $test->{suffix_encoded} ? $test->{suffix_encoded} : '' );
        my $suffix_encoded_printable = ( length $test->{suffix_encoded}
                                         ? qq{"$test->{suffix_encoded}"}
                                         : '[n/a]'
        );
        is( $lccn->suffix_encoded, $test->{suffix_encoded},
            qq{LCCN input "$test->{orig}" suffix encoded is $suffix_encoded_printable}
        );

        # revision year
        my $revision_year_printable = ( defined $test->{revision_year}
                                        ? $test->{revision_year}
                                        : '[n/a]'
        );
        is( $lccn->revision_year, $test->{revision_year},
            qq{LCCN input "$test->{orig}" revision year is $revision_year_printable}
        );

        # revision year encoded
        $test->{revision_year_encoded} = (
                                        defined $test->{revision_year_encoded}
                                        ? $test->{revision_year_encoded}
                                        : ''
        );
        my $revision_year_encoded_printable = (
                                        defined $test->{revision_year_encoded}
                                        ? $test->{revision_year_encoded}
                                        : '[n/a]'
        );
        is( $lccn->revision_year_encoded, $test->{revision_year_encoded},
            qq{LCCN input "$test->{orig}" revision year encoded is $revision_year_encoded_printable}
        );

        # revision number
        my $revision_number_printable = ( defined $test->{revision_number}
                                          ? $test->{revision_number}
                                          : '[n/a]'
        );
        is( $lccn->revision_number, $test->{revision_number},
            qq{LCCN input "$test->{orig}" revision number is $revision_number_printable}
        );

    } else {
        fail(qq{LCCN input "$test->{orig}" not accepted});
        skip q{Can't run tests with invalid LCCN},
            ( $num_subtests_per_test - 1 );
    }
}

# Local Variables:
# mode: perltidy
# End:
