<%
{
    package BinCounter;

    sub new {
      my $class = shift;
      bless { type => $_[0], name => $_[1], comment => $_[2] }, $class;
    }

    sub new_from_str {
      my $class = shift;
      ( my $str = $_[0] ) =~ s/^\s+//;
      $class->new( split( /\s+/, $str, 3 ) );
    }

    sub declare {
      sprintf( "%s\t%s = 0;\t\t/* %s */",
               $_[0]->{type},
               $_[0]->{name},
               $_[0]->{comment} );
    }

    sub reset {
      sprintf( "%s = 0;", $_[0]->{name} );
    }

}


my @bin_counters =
  map { BinCounter->new_from_str( $_ ) }
      # <<< noperltidy
      q[ int      rc           status                                ],
      q[ double   bsignal      sum of signal                         ],
      q[ double   bmean        mean of (weighted) signal             ],
      q[ double   bwidth       width (if applicable)                 ],
      q[ double   bsnr         SNR                                   ],
      q[ double   berror2      sum of error^2                        ],
      q[ double   berror       sqrt( berror2 ) or DBL_MAX            ],
      q[ double   bm2          unnormalized variance                 ],
      q[ double   bsignal2     sum of signal^2                       ],
      q[ double   bweight      sum of 1/error*2                      ],
      q[ double   bweight_sig  sum of weight * signal                ],
      q[ double   bweight_sig2 sum of weight * signal**2             ],
      q[ int      bad_error    if error2 is not good                 ],
      q[ int      lastrc       carryover status from previous loop   ],
      q[ PDL_Indx nin          number of elements in the current bin ],
      # >>>
      ;

sub declare_bin_counters {

    fill_in_string(
        join( "\n",
            '/* Declare bin counters */',
              map $_->declare, @bin_counters,
        ),
    );
}

sub reset_bin_counters {

  fill_in_string(  join( "\n",
        '/* Reset bin counters */',
         map $_->reset, @bin_counters,
  )    );
}

sub sdev_algo {
    my %args = @_;
    my ( $algo, $phase, $error ) = @args{qw[ algo phase error ]};

    die( "unknown phase: $phase" )
      unless $phase eq 'bin' || $phase eq 'fold';

    my @fargs;
    my $tpl;

    # this is the naive implementation of a weighted standard deviation
    # keep around for comparison with the incremental one
    if ( $algo eq 'naive' ) {

        $tpl = q[
              /* naive algorithm for (possibly weighted) standard deviation */
                double _weight          = <% $weight %>;
                double _signal          = <% $signal %>;
                double _wsignal         = <% $wsignal %>;
                double _wsignal2        = <% $wsignal2 %>;
                double _sum_weight      = <% $sum_weight %>;
                double _sum_wsignal     = <% $sum_wsignal %>;
                double _sum_wsignal2    = <% $sum_wsignal2 %>;

                bmean = _sum_wsignal / _sum_weight;

                bad_error = nin <= 1;
                berror = bad_error
                  ? DBL_MAX
                  : sqrt( ( _sum_wsignal2  * <% $sdev_norm %>
                            - nin * bmean * bmean  )
                          / ( nin - 1 ) );
            ];

        @fargs = do {

            if ( $error ) {

                (
                    sum_weight   => 'bweight       += _weight',
                    sum_wsignal  => 'bweight_sig   += _wsignal',
                    sum_wsignal2 => 'bweight_sig2  += _wsignal2',
                    sdev_norm    => 'nin / bweight',

                    $phase eq 'bin'
                    ? (
                        wsignal  => '_weight  * _signal',
                        wsignal2 => '_wsignal * _signal',
                      )
                    : (
                        wsignal  => '$b_weight_sig( nwsdev => curind )',
                        wsignal2 => '$b_weight_sig2( nwsdev => curind )',
                    ),


                );

            }
            else {

                (
                    weight       => 1,
                    sum_weight   => 'nin',
                    sum_wsignal  => 'bsignal',
                    sum_wsignal2 => 'bsignal2 += _wsignal2',
                    sdev_norm    => 1,

                    $phase eq 'bin'
                    ? (
                        wsignal  => '_signal',
                        wsignal2 => '_signal * _signal',
                      )
                    : ( wsignal2 => '$b_signal2( nsdev => curind )', ),
                );
            }
        };

    }

    elsif ( $algo eq 'incremental' ) {

        if ( $phase eq 'bin' ) {

            $tpl = q[
              /* incremental algorithm for possibly weighted standard deviation; see
                 https://en.wikipedia.org/wiki/Algorithms_for_calculating_variance
                 */
                double _weight      = <% $weight %>;
                double _sum_weight  = <% $sum_weight %>;
                double delta        = signal - bmean;
                bmean              += delta * _weight / _sum_weight;
                bm2                += _weight * delta * ( signal - bmean );

                bad_error = nin <= 1;
                berror = bad_error
                       ? DBL_MAX
                       : sqrt( bm2 * <% $sdev_norm %> / (nin - 1) );
           ];

            @fargs
              = $error
              ? (
                sum_weight => 'bweight += _weight',
                sdev_norm  => 'nin / bweight',
              )
              : (
                weight     => 1,
                sum_weight => 'nin',
                sdev_norm  => 1,
              );


        }

        elsif ( $phase eq 'fold' ) {

            $tpl = q[
              /* parallel algorithm (as we're adding bins together) for
                 (possibly) weighted standard deviation; see
                 https://en.wikipedia.org/wiki/Algorithms_for_calculating_variance
                 */
                double _weight  = <% $weight %>;
                double mean_a   = <% $mean_a %>;
                double mean_b   = <% $mean_b %>;
                double weight_a = <% $weight_a %>;
                double weight_b = <% $weight_b %>;
                double weight_x = <% $weight_x %>;
                double delta    = mean_b  - mean_a;
                bmean           = mean_a + delta * weight_b / weight_x;
                bm2            += $b_m2( nsdev => curind )
                                  + delta * delta * weight_a * weight_b / weight_x;

                bad_error = nin <= 1;
                berror = bad_error
                       ? DBL_MAX
                       : sqrt( bm2 * <% $sdev_norm %> / (nin - 1) );
           ];

            @fargs = (
                mean_a => '$b_mean( n => curind )',
                mean_b => 'bmean',
            );

            push @fargs,
              $error
              ? (
                weight_a  => '_weight',
                weight_b  => 'bweight',
                weight_x  => 'bweight += weight_a',
                sdev_norm => 'nin / bweight',
              )
              : (
                weight_a => '$nelem( n => curind )',
                weight_b => 'nin_last',
                weight_x => 'nin',                  # error_calc sets nin += n_a
                                                    # so reuse that instead of n_b + n_a
                sdev_norm => '1',
              );

        }
    }


    fill_in( string => $tpl, hash => {@fargs}, localize => 1 );
}

sub calc_rss {
    my %args = @_;
    my ( $phase ) = @args{qw[ phase ]};

    die( "unknown phase: $phase" )
      unless $phase eq 'bin' || $phase eq 'fold';

    my @fargs;
    my $tpl;

    if ( $phase eq 'bin' ) {

        $tpl = q[
              /* incremental algorithm for mean; see
                 https://en.wikipedia.org/wiki/Algorithms_for_calculating_variance
                 */
                double _error2      = <% $error2 %>;
                double _weight      = <% $weight %>;
                double delta        = signal - bmean;

                bweight            += _weight;
                bmean              += delta * _weight / bweight;
                berror2            += _error2;
                berror              = sqrt( berror2 );
           ];
    }

    elsif ( $phase eq 'fold' ) {

        $tpl = q[
              /* parallel algorithm (as we're adding bins together) for
                 mean; see
                 https://en.wikipedia.org/wiki/Algorithms_for_calculating_variance
                 */
                double _error2  = <% $error2 %>;
                double _weight  = <% $weight %>;
                double mean_a   = <% $mean_a %>;
                double mean_b   = <% $mean_b %>;
                double weight_a = <% $weight_a %>;
                double weight_b = <% $weight_b %>;
                double weight_x = <% $weight_x %>;
                double delta    = mean_b - mean_a;
                bmean           = mean_a + delta * weight_b / weight_x;

                berror2        += _error2;
                berror          = sqrt( berror2 );
        ];

        @fargs = (
            mean_a   => '$b_mean( n => curind )',
            mean_b   => 'bmean',
            weight_a => '_weight',
            weight_b => 'bweight',
            weight_x => 'bweight += weight_a',
        );


    }

    fill_in ( string => $tpl, hash => {@fargs}, localize => 1 );
}


sub error_calc {
    fill_in( string =>
        q[
          bsignal  += <% $signal %>;
          nin      += <% $ninc %>;

          /* calculate error */
          if ( error_sdev ) {

            /* weighted standard deviation */
            if ( have_error ) {
               <% sdev_algo( algo  => $sdev_algo, phase => $phase, error => 1,); %>
            }

            else {
               <% sdev_algo( algo  => $sdev_algo, phase => $phase, error => 0,); %>
            }
          }

          else if ( error_rss ) {
            <% calc_rss( phase => $phase ) %>
          }

          else if ( error_poisson ) {
            berror = sqrt( nin );
            bmean = bsignal / nin;
          }

          else {
            croak( "internal error" );
          }
            ],
        hash     => {@_},
        localize => 1,
    );
}

sub set_results {
    fill_in( string =>
        q[
          $rc( n => curind )       = rc;
          $b_signal( n => curind ) = bsignal;
          $b_mean( n => curind ) = bmean;
          if ( have_width ) $b_width( nwidth => curind )  = bwidth;
          <% $PDL_BAD_CODE
             ? q[
                 if ( set_bad && bad_error ) { $SETBAD(b_error( n => curind ) ); }
                 else { $b_error( n => curind )  = berror; }
                ]
             : q[
                 $b_error( n => curind )  = berror;
                ]
          %>
          $b_snr( n => curind )   = bsnr;
          $nelem( n => curind )   = nin;
          $ilast( n => curind )   = n;
          if ( error_sdev ) {
            $b_m2( nsdev => curind )      = bm2;
            if ( have_error ) {
              $b_weight( nweight => curind )      = bweight;
              $b_weight_sig( nwsdev => curind )  = bweight_sig;
              $b_weight_sig2( nwsdev => curind ) = bweight_sig2;
            }
            else {
              $b_signal2( nsdev => curind ) = bsignal2;
            }
          }
         else if ( error_rss ) {
            $b_error2( nrss => curind )    = berror2;
            $b_weight( nweight => curind )  = bweight;
         }
            ], localize => 1,
    );
}

sub set_rc {
    q[
          rc |=                                               \
            (   nin     >= max_nelem  ? BIN_RC_GENMAX : 0 )   \
            |                                                 \
            (   bwidth  >= max_width  ? BIN_RC_GEWMAX : 0 )   \
            |                                                 \
            (    nin    >= min_nelem                          \
                 && bwidth >= min_width                       \
                 && snr_ok            ? BIN_RC_OK     : 0 )   \
            ;                                                 \
      ]
}

#$sdev_algo = 'naive';
$sdev_algo = 'incremental';

# must return a string
''%>

<% if ( $PDL_Indx ne "PDL_Indx" ) {"
typedef $PDL_Indx PDL_Indx;
"}%>


int flags = $COMP(optflags);

int have_width    = flags & BIN_ARG_HAVE_WIDTH;
int have_error    = flags & BIN_ARG_HAVE_ERROR;
int error_sdev    = flags & BIN_ARG_ERROR_SDEV;
int error_poisson = flags & BIN_ARG_ERROR_POISSON;
int error_rss     = flags & BIN_ARG_ERROR_RSS;
int fold_last_bin = flags & BIN_ARG_FOLD;
int set_bad       = flags & BIN_ARG_SET_BAD;

PDL_Indx   min_nelem    = $COMP(min_nelem);
PDL_Indx   max_nelem    = $COMP(max_nelem);
double     max_width    = $COMP(max_width);
double     min_width    = $COMP(min_width);
double     min_snr      = $COMP(min_snr);

/* simplify the logic below by setting bounds values to their most
   permissive extremes if they aren't needed. */

if ( max_width == 0 )
  max_width = DBL_MAX;

if ( max_nelem == 0 )
  max_nelem = LONG_MAX;

threadloop %{

  PDL_Indx curind = 0;         /* index of current bin */

  <%  declare_bin_counters(); %>

  loop(n) %{

    double signal = $signal();
    double error;
    double error2;
    double width;

    int snr_ok = 0;

    if ( have_error ) {
      error = $error();
      error2 = error * error;
    }

    if ( have_width )
      width = $width();

#ifdef PDL_BAD_CODE
    if ( $ISBADVAR(signal,signal)
         ||
         have_error && $ISBADVAR(error,error) ) {
      $SETBAD(index());
      continue;
    }
#endif /* PDL_BAD_CODE */
    $index() = curind;

    <% error_calc(
                  phase         => 'bin',
                  signal        => 'signal',
                  error2        => 'error2',
                  ninc          => 1,
                  weight        => '1 / ( error * error )',
                  sdev_algo     => $sdev_algo,
    );
    %>

    bsnr = bsignal / berror;
    snr_ok = bsnr >= min_snr;

    if ( have_width )
      bwidth += width;

    if ( nin == 1 )
      $ifirst( n => curind ) = n;

    <% set_rc() %>;

    if ( rc ) {
        rc |= lastrc;

        <% set_results() %>

        curind++;

        <% reset_bin_counters() %>

      }

    else if ( snr_ok ) {
      lastrc = BIN_RC_GTMINSN;
    }

    else {
      lastrc = 0;
    }
  %}


  /* record last bin if it's not empty */
  if ( nin ) {

    /* needed for SET_RESULTS */
    PDL_Indx n = $SIZE(n) - 1;

    rc = 0;
    bad_error = 0;

    /* a non empty bin means that we didn't meet constraints.  fold it into
       the previous bin if requested & possible.  sometimes that will
       actually lower the S/N of the previous bin; keep going until
       we can't fold anymore or we get the proper S/N
    */
    if ( fold_last_bin && curind > 0 ) {


        while ( --curind > 0  ) {
            double tmp;
            int snr_ok = 0;
            PDL_Indx nin_last = nin;

            <% error_calc(
                        phase           => 'fold',
                        error2          => '$b_error2( nrss => curind )',
                        signal          => '$b_signal( n => curind )',
                        weight          => '$b_weight( nweight => curind )',
                        ninc            => '$nelem( n => curind )',
                        sdev_algo       => $sdev_algo,
                );
            %>

            bsnr = bsignal / berror;
            snr_ok = bsnr >= min_snr;

            <% set_rc() %>;

            if (rc)
              break;
          }

        /* fix up index for events initially stuck in folded bins */
        PDL_Indx curind1 = curind+1;
        PDL_Indx ni;

        for ( ni = $ifirst( n => curind1 ) ;
              ni < $SIZE(n) ;
              ni++ ) {
#ifdef PDL_BAD_CODE
            if ( $ISGOOD(index(n => ni)) )
#endif /* PDL_BAD_CODE */
              $index( n => ni ) = curind;
        }
        $ilast( n => curind ) = n;
        rc |= BIN_RC_FOLDED;
      }

    <% set_results() %>
  }
  /* adjust for possibility of last bin being empty */
  $nbins() = curind + ( nin != 0 );
%}
