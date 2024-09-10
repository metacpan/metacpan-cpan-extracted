#!perl

use Test2::V0 qw( :DEFAULT !float );
use Test2::Tools::PDL;

use PDL;

use POSIX qw[ DBL_MAX ];

use CXC::PDL::Bin1D qw[ bin_adaptive_snr];

############################################################
# test different error algorithms

my $NBINS = 100;
my $NDATA = 1000;
my $NELEM = 10;

srand( 2 );

sub _whistogram {

    my ( $index, $what ) = @_;

    # as of (at least) PDL 2.007, the output type from whistogram
    # depends upon the type of the _index_, not the _weight_.
    # in the hopes that the latter eventually happens, set the type of
    # the _index_ to that of the weight.

    if ( $index->type != $what->type ) {
        my $convert_func = $what->type->convertfunc;
        $index = $index->$convert_func;
    }

    my $result = $index->whistogram( $what, 1, 0, $NBINS );
    return $result;
}


# use max_nelem to constrain the bins to make it easy to
# calculate things
sub piddles {

    my %in = (
        signal    => random( $NDATA ),
        error     => random( $NDATA ) / 10,
        min_nelem => $NELEM,
        max_nelem => $NELEM,
        min_snr   => 1000,
    );

    my %exp = (
        index => sequence( PDL::long, $NDATA ) / $NELEM,
        nelem => zeroes( double, $NBINS ) + $NELEM,
    );

    $exp{signal} = _whistogram( $exp{index}, $in{signal} );
    $exp{mean}   = _whistogram( $exp{index}, $in{signal} ) / $exp{nelem};
    $exp{weight} = _whistogram( $exp{index}, 1 / $in{error}**2 );

    return \%in, \%exp;
}

# similar to piddles(), but fold the last bin
sub piddles_fold {

    my %in = (
        signal    => random( $NDATA + 2 ),
        error     => random( $NDATA + 2 ) / 10,
        min_nelem => $NELEM,
        max_nelem => $NELEM,
        min_snr   => 1000,
    );

    my %exp = (
        index => sequence( PDL::long, $NDATA + 2 ) / $NELEM,
        nelem => zeroes( double, $NBINS ) + $NELEM,
    );

    $exp{index}->mslice( [ -2, -1 ] ) .= $NBINS - 1;
    $exp{nelem}->mslice( [-1] ) += 2;

    $exp{signal} = _whistogram( $exp{index}, $in{signal} );
    $exp{mean}   = _whistogram( $exp{index}, $in{signal} ) / $exp{nelem};
    $exp{weight} = _whistogram( $exp{index}, 1 / $in{error}**2 );

    return \%in, \%exp, fold => 1;
}

my @setups = (

    sub {
        my ( $in, $exp ) = @_;

        $exp->{mean} = _whistogram( $exp->{index}, $in->{signal} / $in->{error}**2 ) / $exp->{weight};

        $exp->{error}     = sqrt( _whistogram( $exp->{index}, $in->{error}**2, ) );
        $in->{error_algo} = 'rss';

    },

    sub {
        my ( $in, $exp ) = @_;

        $exp->{error} = sqrt( $exp->{nelem} );
        delete $in->{error};

        $in->{error_algo} = 'poisson';
    },

    sub {

        my ( $in, $exp ) = @_;

        my $mean = $exp->{mean}->index( $exp->{index} );
        $exp->{error}
          = sqrt( _whistogram( $exp->{index}, ( $in->{signal} - $mean )**2 ) / ( $exp->{nelem} - 1 ) );

        delete $in->{error};
        $in->{error_algo} = 'sdev';
    },

    sub {
        my ( $in, $exp ) = @_;

        $exp->{mean} = _whistogram( $exp->{index}, $in->{signal} / $in->{error}**2 ) / $exp->{weight};
        my $mean = $exp->{mean}->index( $exp->{index} );

        $exp->{error}
          = sqrt( $exp->{nelem}
              / ( $exp->{nelem} - 1 )
              * _whistogram( $exp->{index}, ( $in->{signal} - $mean )**2 / $in->{error}**2 )
              / $exp->{weight} );

        $in->{error_algo} = 'sdev';
        return 'weighted sdev: individual';
    },

    sub {
        my ( $in, $exp ) = @_;

        $exp->{signal} = _whistogram( $exp->{index}, $in->{signal} );
        $exp->{twt_sig}
          = _whistogram( $exp->{index}, $in->{signal} / $in->{error}**2 );
        $exp->{twt} = _whistogram( $exp->{index}, 1 / $in->{error}**2 );

        $exp->{mean} = _whistogram( $exp->{index}, $in->{signal} / $in->{error}**2 ) / $exp->{weight};

        $exp->{error} = sqrt(
            $exp->{nelem} / ( $exp->{nelem} - 1 ) * (
                _whistogram( $exp->{index}, ( $in->{signal} / $in->{error} )**2 ) / $exp->{weight}
                  - $exp->{mean}**2
            ) );

        $in->{error_algo} = 'sdev';
        return 'weighted sdev: binned';
    },
);


for my $setup ( @setups ) {

    for my $datafactory ( \&piddles, \&piddles_fold ) {

        my ( $in, $exp, %args ) = $datafactory->();

        my $label = 'bin_adaptive_snr: '
          . join( ', ', $setup->( $in, $exp ), map { "$_ => $args{$_}" } keys %args );

        subtest $label => sub {

            my $got;
            ok(
                lives {
                    $got = bin_adaptive_snr( %$in, %args );
                },
                "bin signal"
            ) or note( $@ ), return;

            my $nbins = delete $got->{nbins};

            for my $field ( grep { exists $got->{$_} && exists $exp->{$_} } qw/ mean error nelem signal / ) {

                pdl_is( $got->{$field}->mslice( [ 0, $nbins - 1 ] ), $exp->{$field}, $field );

            }

            for my $field ( qw/ index / ) {

                pdl_is( $got->{$field}, $exp->{$field}, $field );

            }

        }

    }
}

done_testing;

1;
