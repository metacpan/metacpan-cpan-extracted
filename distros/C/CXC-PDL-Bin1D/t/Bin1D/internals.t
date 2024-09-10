#!perl

use Test2::V0 qw< :DEFAULT !float >;
use Test2::Tools::PDL;

use PDL;

use POSIX qw[ DBL_MAX ];

use CXC::PDL::Bin1D qw[ bin_adaptive_snr :constants ];

# these tests ensure that the results are internally consistent.

sub signal {
    return signal => short( random( 1000 ) * 100 );
}

sub error {
    return error => sqrt( random( 1000 ) * 100 ), error_algo => 'rss';
}

srand( 2 );

for my $set ( [ 'random error' => \&error ],
    [ 'standard deviation' => sub { error_algo => 'sdev' } ] )
{

    my ( $testname, $error ) = @$set;

    for my $data (

        {
            min_snr   => 20,
            min_nelem => 1,
        },

        {
            min_snr   => 20,
            min_nelem => 1,
            max_nelem => 6,
        },

        {
            min_snr   => 20,
            min_nelem => 1,
            max_nelem => 8,
        },

        {
            min_snr   => 20,
            min_nelem => 1,
            min_width => 1,
            width     => random( 1000 ) * 10,
        },

        {
            min_snr   => 20,
            min_nelem => 1,
            max_width => 3,
            width     => random( 1000 ) * 10,
        },

        {
            min_snr   => 20,
            min_nelem => 1,
            max_width => .01,
            width     => random( 1000 ) * 10,
        },

        {
            min_snr   => 20,
            min_nelem => 1,
            min_width => .1,
            max_width => 3,
            width     => random( 1000 ) * 10,
        },

      )
    {

        test_internals(
            testname => $testname,
            signal(),
            $error->(),
            %$data
        );

    }
}

sub test_internals {
    my %in     = @_;
    my $testid = delete( $in{testname} ) . ': ';

    $testid .= join(
        "; ",
        (
            map  { "$_ = @{[ $in{$_} ]} " }
            grep { defined $in{$_} } qw/ min_snr min_nelem max_nelem min_width max_width /
        ),
        ( defined $in{error} ? 'error' : 'sdev ' ),
    );

    my $got;
    ok( lives { $got = bin_adaptive_snr( %in ) }, "$testid: bin signal" )
      or note( $@ ), return;

    my $nbins = $got->{nbins}->at( 0 );
    $got->{$_} = $got->{$_}->mslice( [ 0, $nbins - 1 ] )->sever
      for grep { ( $got->{$_}->dims )[0] } qw/ nelem signal error width snr rc ifirst ilast /;

    # check if sum & error are calculated correctly

    my @error;
    my @signal;
    my @sn;
    my @snl;

    $in{error2} = defined $in{error} ? $in{error}**2 : undef;

    my $calc_error = defined $in{error} ? \&calc_error : \&calc_error_sdev;
    # ensure that the number of elements in each bin reflects the
    # indices for the range of data points included in a bin.
    {
        my $nelem = $got->{ilast} - $got->{ifirst} + 1;

        pdl_is( $got->{nelem}, $nelem, "number of elements in each bin" );
    }

    # ensure that the per-data point index is consistent with
    # the number of elements in each bin
    {
        my $index  = zeroes( long, $in{signal}->dims );
        my $ilast  = $got->{nelem}->cumusumover - 1;
        my $ifirst = $ilast - $got->{nelem} + 1;
        $index->mslice( [ $ifirst->at( $_ ), $ilast->at( $_ ) ] ) .= $_ for 0 .. $nbins - 1;
        pdl_is( $got->{index}, $index, 'index' );
    }

    for my $bin ( 0 .. $nbins - 1 ) {
        my ( $ifirst, $ilast )
          = ( $got->{ifirst}->at( $bin ), $got->{ilast}->at( $bin ) );

        my ( $signal, $noise ) = $calc_error->( $ifirst, $ilast, %in );

        push @signal, $signal;
        push @error,  $noise;

        push @sn, $error[-1] > 0 ? $signal[-1] / $error[-1] : 0;

        # this returns the S/N for each output bin using one less
        # input data point. this is used later on to test if the smallest
        # number of bins to reach the minimum S/N was used.

        # can't use less than one signal datum
        push @snl, $ilast == $ifirst
          ? 0
          : do {
            $ilast--;

            # it's possible that the noise is zero. random numbers'll do that.

            my ( $signal, $noise ) = $calc_error->( $ifirst, $ilast, %in );
            $noise > 0 ? $signal / $noise : 0;
          };
    }

    my ( $c_snl, $c_sn, $c_signal, $c_error ) = map { pdl( $_ ) } \@snl, \@sn, \@signal, \@error;
    my $gtminsn = defined $in{min_snr} ? $c_snl > $in{min_snr} : $c_snl->zeroes;

    pdl_is( $got->{signal}, $c_signal, "$testid: signal" );
    pdl_is( $got->{error},  $c_error,  "$testid: error" );


    # if the maximum number of elements is reached, or the maximum bin
    # width is reached, it's possible that the minimum S/N has not
    # been reached.  exclude those bins which might legally violate
    # the min S/N requirement.  It's also possible that requesting a
    # minimum width or number of elements has caused the S/N to be
    # higher than if those limits were not specified; exclude those as
    # well.

    my %mskd;
    my @mskd = qw( rc signal error nelem width ifirst ilast );

    ( $c_sn, $c_snl, @mskd{@mskd} )
      = where( $c_sn, $c_snl, @{$got}{@mskd}, $got->{rc} == BIN_RC_OK );

    # make sure that the minimum possible S/N was actually returned
    # recall that $msn is calculated using one fewer input bins, so that
    # it's S/N must be less than the minimum required S/N
    ok( all( $c_snl < $in{min_snr} ), "$testid: minimum actual S/N" );

    # make sure that the number of elements are correctly limited
    ok( all( $got->{nelem} >= $in{min_nelem} ),                     "$testid: minimum nelem" );
    ok( $in{max_nelem} ? all( $mskd{nelem} <= $in{max_nelem} ) : 1, "$testid: maximum nelem" );

    # make sure that the widths are correctly calculated
    if ( defined $in{width} ) {
        my $wsum = $in{width}->cumusumover;
        my $widths
          = $wsum->index( $got->{ilast} )
          - $wsum->index( $got->{ifirst} )
          + $in{width}->index( $got->{ifirst} );

        pdl_is( $widths, $got->{width}, "$testid: widths" );
    }

    # make sure that the bin widths are correctly limited
    ok( all( $mskd{width} >= $in{min_width} ), "$testid: minimum bin width" )
      if defined $in{min_width};

    ok( all( $mskd{width} <= $in{max_width} ), "$testid: maximum bin width" )
      if defined $in{max_width};

    # check if signal to noise ratio is greater than requested min
    ok( all( $mskd{signal} / $mskd{error} >= $in{min_snr} ), "$testid: minimum returned S/N" );

    # check per bin return code
    {
        my $rc = zeroes( byte, $nbins );

        $rc->where( $got->{nelem} >= $in{max_nelem} ) |= BIN_RC_GENMAX
          if defined $in{max_nelem};

        $rc->where( $got->{width} >= $in{max_width} ) |= BIN_RC_GEWMAX
          if defined $in{max_width};

        my $bin_ok = $rc->ones;

        $bin_ok &= ( $got->{nelem} >= $in{min_nelem} )
          if defined $in{min_nelem};

        $bin_ok &= ( $got->{snr} >= $in{min_snr} )
          if defined $in{min_snr};

        $bin_ok &= $got->{width} >= $in{min_width}
          if defined $in{min_width};

        $rc->where( $bin_ok ) |= BIN_RC_OK;

        # handle BIN_RC_GTMINSN
        $rc->where( $gtminsn ) |= BIN_RC_GTMINSN;

        # can't easily test if the last bin is folded, so don't foldedness.
        pdl_is( $got->{rc} & ~pdl( long, BIN_RC_FOLDED ), $rc, "$testid: rc" );
    }
}

sub calc_error {
    my ( $ifirst, $ilast, %in ) = @_;

    my $signal = $in{signal}->mslice( [ $ifirst, $ilast ] );
    my $nelem  = $ilast - $ifirst + 1;

    my $error = sqrt( $in{error2}->mslice( [ $ifirst, $ilast ] )->dsum );

    return ( $signal->dsum, $error );
}

sub calc_error_sdev {
    my ( $ifirst, $ilast, %in ) = @_;

    my $signal = $in{signal}->mslice( [ $ifirst, $ilast ] );
    my $nelem  = $ilast - $ifirst + 1;

    my $mean = $signal->dsum / $nelem;

    my $error
      = $nelem > 1
      ? sqrt( ( ( $signal - $mean )**2 )->dsum / ( $nelem - 1 ) )
      : DBL_MAX;

    return ( $signal->dsum, $error );
}

done_testing;
