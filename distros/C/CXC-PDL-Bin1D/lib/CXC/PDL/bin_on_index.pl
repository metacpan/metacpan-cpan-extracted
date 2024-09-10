
use v5.10;
no namespace::clean;

use Types::Common::Numeric qw[ PositiveOrZeroInt ];
use Types::Standard        qw[ Optional Bool StrMatch Undef Int ];
use Types::PDL -types;
use Type::Params qw[ compile_named ];

use Carp      ();
use PDL::Lite ();

use Hash::Wrap ( { -class => __PACKAGE__ . '::bin_on_index' } );

use constant PP_PASS_TMPS => do { require version; PDL->VERSION < version->parse( '2.073' ) };

# this is ugly
sub CoercedPiddle {

    my $to_type = shift;

    my $convert = sprintf(
        <<'EOS',
do { local $@;
     require PDL::Core;
     my $new = eval { PDL::Core::convert( $_, PDL::%s )  };
     length($@) ? $_ : $new
     }
EOS
        $to_type,
    );
    return Piddle( [ type => $to_type ] )->plus_coercions( map { $_ => $convert } Piddle, @_ );
}

use namespace::clean;

{

    my $check;
    my $range_RE;

    BEGIN {
        $range_RE = qr/(flat|slice)(?:,(minmax|min|max))?/;

        $check = compile_named(
            index  => CoercedPiddle( 'indx' ),
            data   => Piddle,
            nbins  => Optional [ CoercedPiddle( indx => PositiveOrZeroInt ) ],
            weight => Optional [ Piddle | Undef ],
            # Enum is preferred for the following, but see https://rt.cpan.org/Ticket/Display.html?id=129729
            oob => Optional [ StrMatch( [qr/^start-end|start-nbins|end|nbins$/] ) | Bool ] => { default => 0 },
            want_sum_weight  => Optional [Bool],
            want_sum_weight2 => Optional [Bool],
            imin             => Optional [ CoercedPiddle( indx => Int ) ],
            imax             => Optional [ CoercedPiddle( indx => Int ) ],
            range            => Optional [ StrMatch( [$range_RE] ) ] );
    }

    my %Map_OOB = (
        'start-end'   => BIN_ARG_SAVE_OOB_START_END,
        'start-nbins' => BIN_ARG_SAVE_OOB_START_NBINS,
        'end'         => BIN_ARG_SAVE_OOB_END,
        'nbins'       => BIN_ARG_SAVE_OOB_NBINS,
    );

    sub bin_on_index {

        my $opt = $check->( @_ );

        _bin_on_index_parse_range_opts( $opt );

        $opt->{flags}
          = ( ( defined $opt->{weight}   && BIN_ARG_HAVE_WEIGHT )      || 0 )
          | ( ( $opt->{want_sum_weight}  && BIN_ARG_WANT_SUM_WEIGHT )  || 0 )
          | ( ( $opt->{want_sum_weight2} && BIN_ARG_WANT_SUM_WEIGHT2 ) || 0 )
          | ( ( $opt->{want_extrema}     && BIN_ARG_WANT_EXTREMA )     || 0 );

        $opt->{flags}
          |= $Map_OOB{ lc( $opt->{oob} ) }    # prefer fc, but requires 5.16
          // ( $opt->{oob} && BIN_ARG_SAVE_OOB_START_END )
          || 0;

        my @pin   = qw[ data index weight imin nbins ];
        my @pout  = qw[ b_count b_data b_weight b_weight2 b_mean b_dmin b_dmax b_dev2 ];
        my @oargs = qw[ flags nbins_max ];

        # several of the input piddles are optional.  the PP routine
        # doesn't know that and will complain about the wrong number of
        # dimensions if we pass a null piddle. A 1D one-element piddle
        # will have its dimensions auto-expanded without much
        # wasted memory.

        $opt->{$_} = $opt->{data}->zeroes( 1 ) for grep { !defined $opt->{$_} } @pin;

        # output and temp piddles will be auto-inflated, so we can use
        # null piddles. In a perfect world PDL::PP would have a mechanism
        # to avoid inflating the optional ones.
        # TODO: use nullcreate here to get correct piddle type?

        $opt->{$_} = PDL->null for grep { !defined $opt->{$_} } @pout;

        my @pars;
        if ( PP_PASS_TMPS ) {
            my @ptmp = qw[ b_data_error b_weight_error b_weight2_error ];
            $opt->{$_} = PDL->null for grep { !defined $opt->{$_} } @ptmp;
            @pars = ( @pin, @pout, @ptmp, @oargs );
        }
        else {
            @pars = ( @pin, @pout, @oargs );
        }

        _bin_on_index_int( @{$opt}{@pars} );
        my %results = map {    ## no critic (BuiltinFunctions::ProhibitComplexMappings)
            ( my $nkey = $_ ) =~ s/^b_//;
            ( $nkey, $opt->{$_} )
        } @pout;

        if ( $opt->{flags} & BIN_ARG_HAVE_WEIGHT ) {
            delete $results{weight}
              unless $opt->{flags} & BIN_ARG_WANT_SUM_WEIGHT;
            delete $results{weight2}
              unless $opt->{flags} & BIN_ARG_WANT_SUM_WEIGHT2;
        }
        else {
            delete @results{qw( weight weight2)};
        }

        $results{imin}  = $opt->{imin};
        $results{nbins} = $opt->{nbins};

        return wrap_hash( \%results );
    }


    sub _bin_on_index_parse_range_opts {

        my $opt = shift;

        if ( $opt->{range} ) {

            my ( $dims, $range ) = $opt->{range} =~ $range_RE;
            $range //= 'minmax';

            eval {

                # treat the index as a one big pool of numbers, or
                # as threaded piddles.
                my ( $imin, $imax )
                  = $dims eq 'slice'
                  ? map { $_->dummy( 0 ) } $opt->{index}->minmaximum
                  : map { PDL::indx( [$_] ) } $opt->{index}->minmax;

                if ( $range eq 'minmax' ) {

                    die( "do not specify $_ when specifying 'minmax'\range with " )
                      for grep { defined $opt->{$_} } qw[ imin imax nbins ];

                    $opt->{imin} = $imin;
                    $opt->{imax} = $imax;
                }

                elsif ( $range eq 'min' ) {

                    die( "do not specify imin when specifying 'min'\n" )
                      if defined $opt->{imin};

                    die( "specify exactly one of 'imax' or 'nbins'\n" )
                      if defined $opt->{imax} && defined $opt->{nbins};

                    $opt->{imin} = $imin;
                }

                elsif ( $range eq 'max' ) {
                    die( "do not specify imax\n" )
                      if defined $opt->{imax};

                    die( "specify exactly one of 'imin' or 'nbins'\n" )
                      if defined $opt->{imin} && defined $opt->{nbins};

                    $opt->{imax} = $imax;
                }
                1;
            } // do {
                my $error = $@;
                chomp $error;
                Carp::croak( $opt->{range}, ": error: $error\n" );
            };

        }
        else {

            my $nrange_opts = grep { defined $opt->{$_} } qw[ imin imax nbins ];

            if ( $nrange_opts == 0 ) {

                @{$opt}{ 'imin', 'imax' }
                  = map { PDL::indx( $_ ) } $opt->{index}->minmax;
            }

            elsif ( $nrange_opts == 1 ) {

                if ( defined $opt->{nbins} ) {
                    $opt->{imin} = PDL::indx( 0 );
                }
                elsif ( defined $opt->{imax} ) {
                    $opt->{imin} = PDL::indx( 0 );
                }
                elsif ( defined $opt->{imin} ) {
                    $opt->{imax} = PDL::indx( $opt->{index}->max );
                }
            }
            elsif ( $nrange_opts == 3 ) {
                Carp::croak( "error: too many options. specify only two of imin, imax, nbins\n" );
            }
        }

        # don't care about imax.

        $opt->{imin}  //= $opt->{imax} - $opt->{nbins} + 1;
        $opt->{nbins} //= $opt->{imax} - $opt->{imin} + 1;
        $opt->{nbins_max} = $opt->{nbins}->max;
    }

}

=pod

=for stopwords
ACM
Bevington
Commun
Golub
Higham
Kahan
LeVeque
McGraw
superset

=head2 bin_on_index

=for usage

  $hashref = bin_on_index( %pars  );

=for ref

Calculate basic statistics on optionally weighted, binned data using a
provided index.  The input data are assumed to be one-dimensional; extra
dimensions are threaded over.

This routine ignores data with bad values or with weights that have bad values.

=head3 Description

When generating statistics for multiple-component data binned on a
common component, it's more efficient to calculate a bin index for the
common component and then use it to generate statistics for each component.

For example, if a time dependent stream of events is binned into time
intervals, statistics of the events' properties (such as position or
energy) must be evaluated on data binned on the intervals.

Some statistics (such as the summed squared deviation from the mean)
may be calculated in two passes over the data, but may suffer from
numerical inaccuracies depending upon the magnitude of the
intermediate values.

C<bin_on_index> uses numerically stable algorithms to calculate
various statistics on binned data in a single pass.  It uses an index
piddle to assign data to bins and calculates basic statistics on the
data in those bins.  Data may have associated weights, and the index
piddle need not be sorted.  It by default ignores out-of-bounds data, but
can be directed to operate on them.

The statistics which are returned for each bin are:

=over

=item *

The number of elements, I<N>

=item *

The (weighted) sum of the data,
I<< Sum(x_i) >>,
I<< Sum(w_i * x_i) >>.

=item *

The (weighted) mean of the data,
I<< Sum(x_i) / N >>,
I<< Sum(w_i * x_i) / Sum(w_i) >>

=item *

The sum of the weights, I<< Sum(w_i) >>

=item *

The sum of the square of the weights, I<< Sum(w_i^2) >>

=item *

The sum of the (weighted) squared deviation of the data from mean,
 I<< Sum( (x_i-u)^2 ) >>,
 I<< Sum( w_i(x_i-u)^2 ) >>.  These are I<not> normalized!.

=item *

The minimum and maximum data values

=back

The sum of the squared deviations are I<not> normalized, to allow the
user to handle it according to their needs.

For unweighted data, the typical normalization factor is I<N-1>,
while for weighted data, the normalization factor varies depending
upon whether the weights represent errors or quality weights.  In the
former case, where I<< w_i = 1 / sigma^2 >>, the normalization factor
is typically I<< N / (N - 1) / Sum(w_i) >>, while for the latter the
normalization is typically I<< Sum(w_i) / ( Sum(w_i)^2 - Sum(w_i^2) ) >>.
See L</[Robinson]> and L</[Bevington]>.

The algorithms used are chosen for their numerical stability.  Sums
are computed using Kahan summation and the mean and squared deviations are
calculated with stable updating algorithms.  See L</[Chan83]>, L</[West79]>, L</[Higham]>.

=head4 Threading

The parameters L</data>, L</index>, L</weight>, L</imin>, L</imax>, and
L</nbins> are threaded over.  This keeps things quite flexible, as one
can specialize things for complex datasets or keep them simple by
specifying the minimum information for a given parameter to have it
remain constant over the threaded dimensions. (Note that C<data>
must have the same shape or be a superset of the other parameters).

Unless otherwise specified, the term I<extents> refers to those of the
core (non-threaded) one-dimensional slices of the input and output
piddles.

For some parameters there is value in applying an algorithm to
either the entire dataset (including threaded dimensions) or just
the core one-dimensional data.  For example, the L</range>
option can indicate that the in-bounds bins are defined by the range
in each one-dimensional slice of L</index> or in L</index> as a whole.

=head4 Minimum Bin Index, Number of Bins, Out-Of-Bounds Data

By default, the minimum bin index and the number of bins are
determined from the values in the L</index> piddle, treating it as if
it were one-dimensional.  Statistics for data with the minimum index
are stored in the results piddles at index I<0>.

The caller may use the options L</imin>, L</imax>, and
L</nbins>, and L</range> to change how the index range is mapped onto
the results piddles, and whether the range should be specific to each
one-dimensional slice of L</index>. If none of these are specified,
the default is equivalent to setting L</range> to C<flat,minmax>.
To most efficiently store the statistics, set L</range> to C<slice,minmax>.

Data with indices outside of the range C<[$imin, $imin + $nbins - 1]>
are treated as I<out-of-bounds> data, and by default are ignored.  If the
user wishes to accumulate statistics on these data, the L</oob> option
may be used to indicate where in the results piddles the statistics
should be stored.

=head3 Parameters

B<bin_on_index> is passed a hash or a reference to a hash containing
its parameters.  The possible parameters are:

=over

=item C<data> I<piddle>

The data.
I<Required>

=item C<index> I<piddle>

The bin index. It should be of type C<indx>, but will be converted to that if not.
It must be thread compatible with L</data>.
I<Required>

=item C<weight> I<piddle>

Data weight.
It must be thread compatible with L</data>.
I<Optional>

=item C<nbins>  I<integer> | I<piddle>

The number of bins.
It must be thread compatible with L</data>.

If C<nbins> is set and neither of C<imin> or C<imax> are set, C<imin> is set to C<0>.

Use L</range> for more control over automatic determination of the range.

=item C<imin> I<integer> | I<piddle>

The index value associated with the first in-bounds index in the
result piddle.
It must be thread compatible with L</data>.

If C<imin> is set and neither of C<nbins> or C<imax> are set, C<imax> is set to C<< $index->max >>.

Use L</range> for more control over automatic determination of the range.

=item C<imax> I<integer> | I<piddle>

The index value associated with the last in-bounds index in the
result piddle. It must be thread compatible with L</data>.

If C<imax> is set and neither of C<nbins> or C<imin> are set, C<imin> is set to C<< 0 >>.

Use L</range> for more control over automatic determination of the range.

=item C<range> I<"spec,spec,...">

Determine the in-bounds range of indices from L</index>.  The value is
a string containing a list of comma separated specifications.

The first element must be one of the following values:

=over

=item C<flat>

Treat L</index> as one-dimensional, and determine a single range which
covers it.

=item C<slice>

Determine a separate range for each one-dimensional slice of L</index>.

=back

It may optionally be followed by one of the following

=over

=item C<minmax>

Determine the full range (i.e. both minimum and maximum) from
L</index>.  This is the default.  Do not specify L</nbins>,
L</imax>, or L</imin>.

=item C<min>

Determine the minimum of the range from L</index>.  Specify only one of L</nbins>
or L</imax>.

=item C<max>

Determine the maximum of the range from L</index>.  Specify only one of L</nbins>
or L</imin>.

=back

=item C<oob>

An index is out-of-bounds if it is not within the range

  [ $imin, $imin + $nbins )

By default, it will be ignored.

This option specifies where in the results piddles the out-of-bound
data statistics should be stored.  It may be one of:

=over

=item C<start-end>

The extent of the results piddle is increased by two, and out-of-bound
statistics are written as follows:

  $index - $imin < 0          ==> $result->at(0)
  $index - $imin >= $nbins    ==> $result->at(-1)

=item C<start-nbins>

The extent of the results piddle is increased by two, and out-of-bound
statistics are written as follows:

  $index - $imin < 0          ==> $result->at(0)
  $index - $imin >= $nbins    ==> $result->at($nbins)

This differs from C<start-end> if C<$nbins> is different for each
one-dimensional slice.


=item C<end>

The extent of the results piddle is increased by two, and out-of-bound
statistics are written as follows:

  $index - $imin < 0          ==> $result->at(-2)
  $index - $imin >=  $nbins   ==> $result->at(-1)

=item C<nbins>

The extent of the results piddle is increased by two, and out-of-bound
statistics are written as follows:

  $index - $imin < 0          ==> $result->at($nbins-1)
  $index - $imin >=  $nbins   ==> $result->at($nbins)

This differs from C<end> if C<$nbins> is different for each
one-dimensional slice.

=item I<boolean>

If false (the default) out-of-bounds data are ignored.  If true, it is
equivalent to specifying L</start-end>

=back


=item C<want_sum_weight> I<boolean> I<[false]>

if true, the sum of the bins' weights are calculated.

=item C<want_sum_weight2> I<boolean> I<[false]>

if true, the sum of square of the bins' weights are calculated.

=back


=head3 Results

B<bin_on_index> returns a reference which may be used either a hash
or object reference.

The keys (or methods) and their values are as follows:

=over

=item C<data>

A piddle containing the (possibly weighted) sum of the data in each bin.

=item C<count>

A piddle containing the number of data elements in each bin.

=item C<weight>

A piddle containing the sum of the weights in each bin (only if
L</weight> was provided and L</want_sum_weight> specified).

=item C<weight2>

A piddle containing the sum of the square of the weights in each bin
(only if L</weight> was provided and L</want_sum_weight2> specified).

=item C<mean>

A piddle containing the (possibly weighted) mean of the data in each bin.

=item C<dmin>

=item C<dmax>

Piddles containing the minimum and maximum values of the data in each bin.

=item C<imin>

=item C<nbins>

The index value associated with the first in-bounds index
in the statistics piddles, and the number of in-bounds bins.

=back

=head3 References

=over


=item [Chan83]

Chan, Tony F., Golub, Gene H., and LeVeque, Randall J., Algorithms for
Computing the Sample Variance: Analysis and Recommendations, The
American Statistician, August 1983, Vol. 37, No.3, p 242.

=item [West79]

D. H. D. West. 1979. Updating mean and variance estimates: an improved
method. Commun. ACM 22, 9 (September 1979), 532-535.

=item [Higham]

Higham, N. (1996). Accuracy and stability of numerical
algorithms. Philadelphia: Society for Industrial and Applied
Mathematics.

=item [Robinson]

Robinson, E.L., Data Analysis for Scientists and Engineers, 2016,
Princeton University Press. ISBN 978-0-691-16992-7.

=item [Bevington]

Bevington, P.R., Robinson, D.K., Data Reduction and Error Analysis for
the Physical Sciences, Second Edition, 1992, McGraw-Hill, ISBN
0-07-91243-9.


=back


=cut
