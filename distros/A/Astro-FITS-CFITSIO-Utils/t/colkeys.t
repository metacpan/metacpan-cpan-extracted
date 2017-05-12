#!perl

use Test::More tests => 9;

BEGIN{ use_ok( 'Astro::FITS::CFITSIO::Utils', 'colkeys' ) };

my $file = 'data/bintbl.fits';

my %colkeys;

# find the first table
eval {
  %colkeys = colkeys( $file );
};
ok( ! $@, 'colkeys: first table'  )
    or diag $@;

is_deeply( \%colkeys, exp_colkeys(), 'colkeys: first table values' );

# give it a specific table
eval {
  %colkeys = colkeys( $file, { extname => 'events' } );
};
ok( ! $@, 'colkeys: events table'  )
    or diag $@;

is_deeply( \%colkeys, exp_colkeys(), 'colkeys: events table values' );


# give it a bogus table
eval {
  %colkeys = colkeys( $file, { extname => 'bogus' } );
};
ok( $@ && $@ =~ /bogus/, 'colkeys: expect exceptions' );


####################################################
# now test with an opened file

use Astro::FITS::CFITSIO qw[ READONLY ];
use Astro::FITS::CFITSIO::CheckStatus;

tie my $status, 'Astro::FITS::CFITSIO::CheckStatus';

my $fptr = Astro::FITS::CFITSIO::open_file( $file, READONLY, $status );

# move to second HDU just to test things
$fptr->get_hdu_num( my $init_hdu_num );
$fptr->movabs_hdu( ++$init_hdu_num, undef, $status );

my $hdu_num;

# give it a specific table
eval {
  %colkeys = colkeys( $fptr, { extname => 'events' } );
};
ok( ! $@, 'colkeys: events table'  )
    or diag $@;

is_deeply( \%colkeys, exp_colkeys(), 'colkeys: events table values' );

$fptr->get_hdu_num( $hdu_num );
ok ( $hdu_num == $init_hdu_num, "colkeys: init hdu" );


###################################################


sub exp_colkeys {

    return {
            'time' => {
                       'hdr' => {
                                 'ttype' => 'time',
                                 'tform' => '1D'
                                },
                       'idx' => 5
                      },
            'inclip' => {
                         'hdr' => {
                                   'ttype' => 'inclip',
                                   'tform' => '1L'
                                  },
                         'idx' => 9
                        },
            'x' => {
                    'hdr' => {
                              'ttype' => 'x',
                              'tform' => '1D'
                             },
                    'idx' => 7
                   },
            'y0' => {
                     'hdr' => {
                               'ttype' => 'y0',
                               'tform' => '1D'
                              },
                     'idx' => 2
                    },
            'fitx' => {
                       'hdr' => {
                                 'ttype' => 'fitx',
                                 'tform' => '1D'
                                },
                       'idx' => 3
                      },
            'x0' => {
                     'hdr' => {
                               'ttype' => 'x0',
                               'tform' => '1D',
			       'lonp'  => 33,
			       'lonpa' => 55
                              },
                     'idx' => 1
                    },
            'y' => {
                    'hdr' => {
                              'ttype' => 'y',
                              'tform' => '1D'
                             },
                    'idx' => 8
                   },
            'time0' => {
                        'hdr' => {
                                  'ttype' => 'time0',
                                  'tform' => '1D'
                                 },
                        'idx' => 6
                       },
            'fity' => {
                       'hdr' => {
                                 'ttype' => 'fity',
                                 'tform' => '1D'
                                },
                       'idx' => 4
                      }
           };
}
