#!perl

use Test2::V0;
use Test2::Tools::PDL;

use PDL       ();
use PDL::Core qw[ topdl ];

use POSIX qw[ DBL_MAX ];

use CXC::PDL::Bin1D qw[ bin_adaptive_snr :constants ];

################################################################
#
# test that all of the machinery works (apart from the error
# algorithm)
#
# the expected results are based the fact that the signal, and
# signal/error ratio are constant, so it's easy to calculate
# the binned results, essentially each bin is independent of
# which signal is the first in the bin; only the number of
# signal data points in a bin matters.

# signal => $signal->cumusumover
# error => sqrt( ($error**2)->cumusumover )
# snr => $signal->cumusumover / sqrt( ($error**2)->cumusumover )


subtest 'test machinery' => sub {

    my $signal = PDL->ones( 10 );
    my $error  = PDL->zeros( 10 ) + 0.1;
    my $width  = PDL->zeros( 10 ) + 0.01;

    my $signal_sum = $signal->dcumusumover;
    my $error_sum  = sqrt( ( $error**2 )->dcumusumover );
    my $snr        = $signal_sum / $error_sum;

    my %signal = (
        signal => $signal,
        error  => $error,
    );

    my $mkd = sub {

        my ( $in, $exp ) = @_;

        $in->{$_}         = $signal{$_} foreach keys %signal;
        $in->{error_algo} = 'rss';
        $exp->{$_}        = topdl( $exp->{$_} ) for keys %$exp;

        my $index = $exp->{nelem} - 1;
        $exp->{error} = $error_sum->index( $index );
        $exp->{snr}   = $snr->index( $index );

        return [ $in, $exp ];
    };


    test_explicit( @{$_} )
      foreach (

        $mkd->( {
                min_snr => 20,
                fold    => 0,
            },
            {
                signal => [ 4,         4,         2 ],
                nelem  => [ 4,         4,         2 ],
                rc     => [ BIN_RC_OK, BIN_RC_OK, 0, ],
            },
        ),


        $mkd->( {
                min_snr => 20,
                fold    => 1,
            },
            {
                signal => [ 4,         6 ],
                nelem  => [ 4,         6 ],
                rc     => [ BIN_RC_OK, BIN_RC_FOLDED | BIN_RC_OK, ],
            },
        ),


        $mkd->( {
                min_snr   => 20,
                min_width => .04,
                width     => $width,
            },
            {
                signal => [ 4,         4,         2 ],
                nelem  => [ 4,         4,         2 ],
                rc     => [ BIN_RC_OK, BIN_RC_OK, 0, ],
            },
        ),

        $mkd->( {
                min_snr   => 20,
                min_width => .01,
                max_width => .02,
                fold      => 1,
                width     => $width,
            },
            {
                signal => [ 2,             2,             2,             2,             2 ],
                nelem  => [ 2,             2,             2,             2,             2 ],
                rc     => [ BIN_RC_GEWMAX, BIN_RC_GEWMAX, BIN_RC_GEWMAX, BIN_RC_GEWMAX, BIN_RC_GEWMAX, ],
            },
        ),

        $mkd->( {
                min_snr   => 20,
                max_width => .04,
                width     => $width,
            },
            {
                signal => [ 4,                         4,                         2 ],
                nelem  => [ 4,                         4,                         2 ],
                rc     => [ BIN_RC_OK | BIN_RC_GEWMAX, BIN_RC_OK | BIN_RC_GEWMAX, 0, ],
            },
        ),

        $mkd->( {
                min_snr   => 20,
                max_width => .04,
                fold      => 1,
                width     => $width,
            },
            {
                signal => [ 4,                         6 ],
                nelem  => [ 4,                         6 ],
                rc     => [ BIN_RC_OK | BIN_RC_GEWMAX, BIN_RC_OK | BIN_RC_FOLDED, ],
            },
        ),

        $mkd->( {
                min_snr   => 15,
                min_nelem => 3,
            },
            {
                signal => [ 3,         3,         3,         1 ],
                nelem  => [ 3,         3,         3,         1 ],
                rc     => [ BIN_RC_OK, BIN_RC_OK, BIN_RC_OK, 0, ],
            },
        ),

        $mkd->( {
                min_snr   => 20,
                max_nelem => 3,
            },
            {
                signal => [ 3,             3,             3,             1 ],
                nelem  => [ 3,             3,             3,             1 ],
                rc     => [ BIN_RC_GENMAX, BIN_RC_GENMAX, BIN_RC_GENMAX, 0, ],
            },
        ),

        $mkd->( {
                min_snr   => 22,
                min_nelem => 3,
                max_nelem => 4,
            },
            {
                signal => [ 4,             4,             2 ],
                nelem  => [ 4,             4,             2 ],
                rc     => [ BIN_RC_GENMAX, BIN_RC_GENMAX, 0, ],
            },
        ),

        $mkd->( {
                min_snr   => 1,
                min_nelem => 3,
                max_nelem => 4,
            },
            {
                signal => [ 3, 3, 3, 1 ],
                nelem  => [ 3, 3, 3, 1 ],
                rc => [ BIN_RC_OK | BIN_RC_GTMINSN, BIN_RC_OK | BIN_RC_GTMINSN, BIN_RC_OK | BIN_RC_GTMINSN, 0, ],
            },
        ),

      );

};

############################################################
# test different error algorithms

# use max_nelem to constrain the bins to make it easy to
# calculate things

subtest 'rss error' => sub {

    my %in = (
        signal     => PDL->random( 1000 ),
        error      => PDL->random( 1000 ) / 10,
        error_algo => 'rss',
        min_nelem  => 10,
        max_nelem  => 10,
        min_snr    => 1000,
    );

    my %exp = (
        index => PDL->sequence( PDL::long, 1000 ) / 10,
        nelem => PDL->zeroes( 100 ) + 10,
    );

    $exp{index}->double->whistogram( $in{error}**2, ( $exp{error} = PDL->null ), 1, 0, 100 );

    $exp{error}->inplace->sqrt;
    my $got;

    ok(
        lives {
            $got = bin_adaptive_snr( %in );
        },
        "bin signal"
    ) or note( $@ ), return;

    my $nbins = delete $got->{nbins};

    pdl_is( $got->{error}->mslice( [ 0, $nbins - 1 ] ), $exp{error}, 'error' );

};



sub test_explicit {

    my %in  = %{ shift() };
    my %exp = %{ shift() };

    # print "signal = ",  $in{signal},  "\n";
    # print "bsignal = ", $exp{signal}, "\n";
    # print "error = ",   $exp{error},  "\n";
    # print "snr = ",     $exp{snr},    "\n";
    # print "rc = ",      $exp{rc},     "\n";


    my $testid = join( "; ",
        map { "$_ = @{[ $in{$_} ]} " }
        grep { defined $in{$_} } qw/ min_snr min_nelem max_nelem min_width max_width / );

    my $got;
    ok( lives { $got = bin_adaptive_snr( %in ) }, "$testid: bin signal" )
      or note( $@ ), return;

    my $nbins = $got->{nbins}->at( 0 );

    my @exp_binned = grep { defined $exp{$_} } qw/ nelem signal width error snr rc /;



    $got->{$_} = $got->{$_}->mslice( [ 0, $nbins - 1 ] )->sever for @exp_binned;

    for ( @exp_binned ) {
        pdl_is( $got->{$_}, $exp{$_}, "$testid: $_" )
          || note "$_ : @{[ $got->{$_} ]}";
    }

    {
        my $index  = PDL->zeroes( PDL::long, $in{signal}->dims );
        my $ilast  = $exp{nelem}->cumusumover - 1;
        my $ifirst = $ilast - $exp{nelem} + 1;
        $index->mslice( [ $ifirst->at( $_ ), $ilast->at( $_ ) ] ) .= $_ for 0 .. $nbins - 1;
        pdl_is( $got->{index}, $index, 'index' );
    }

}


done_testing;

1;

