
no namespace::clean;

use Types::Common::Numeric qw[ PositiveNum PositiveInt PositiveOrZeroInt ];
use Types::Standard        qw[ Optional InstanceOf slurpy Dict Bool Enum ];
use Type::Params           qw[ compile ];

use Carp      ();
use PDL::Lite ();

use namespace::clean;

use constant PP_PASS_TMPS => do { require version; PDL->VERSION < version->parse( '2.073' ) };

my $bin_adaptive_snr_check;

BEGIN {

    $bin_adaptive_snr_check = compile(
        slurpy Dict [
            signal     => InstanceOf ['PDL'],
            error      => Optional [ InstanceOf ['PDL'] ],
            width      => Optional [ InstanceOf ['PDL'] ],
            min_snr    => PositiveNum,
            min_nelem  => Optional [PositiveInt],
            max_nelem  => Optional [PositiveInt],
            min_width  => Optional [PositiveNum],
            max_width  => Optional [PositiveNum],
            fold       => Optional [Bool],
            error_algo => Optional [ Enum [ keys %MapErrorAlgo ] ],
            set_bad    => Optional [Bool],
        ] );
}

## no critic (Subroutines::ProhibitExcessComplexity)
sub bin_adaptive_snr {

    my ( $opts ) = $bin_adaptive_snr_check->( @_ );

    # specify defaults
    my %opt = (
        error_algo => 'sdev',
        min_nelem  => 1,
        %$opts,
    );

    Carp::croak( "width must be specified if either of min_width or max_width is specified\n" )
      if ( defined $opt{min_width} || defined $opt{max_width} )
      && !defined $opt{width};

    Carp::croak( "must specify error attribute if 'rss' errors selected\n" )
      if !defined $opt{error} && $opt{error_algo} eq 'rss';

    $opt{min_width} ||= 0;
    $opt{max_width} ||= 0;
    $opt{max_nelem} ||= 0;

    # if the user hasn't specified whether to fold the last bin,
    # turn it on if there aren't *maximum* constraints
    $opt{fold} = !defined $opt{max_width} || !defined $opt{max_nelem}
      unless defined $opt{fold};

    $opt{flags}
      = ( ( defined $opt{error} && BIN_ARG_HAVE_ERROR ) || 0 )
      | ( ( defined $opt{width} && BIN_ARG_HAVE_WIDTH ) || 0 )
      | ( ( $opt{fold}          && BIN_ARG_FOLD ) || 0 ) | ( ( $opt{set_bad} && BIN_ARG_SET_BAD ) || 0 )
      | $MapErrorAlgo{ $opt{error_algo} };

    my @pin  = qw[ signal error width ];
    my @pout = qw[ index nbins nelem b_signal b_error b_mean b_snr
      b_width ifirst ilast rc ];
    my @oargs = qw[ flags min_snr min_nelem max_nelem min_width max_width ];

    # several of the input piddles are optional.  the PP routine
    # doesn't know that and will complain about the wrong number of
    # dimensions if we pass a null piddle. A 1D zero element piddle
    # will have its dimensions auto-expanded without much
    # wasted memory.
    $opt{$_} = PDL->new( 0 ) for grep { !defined $opt{$_} } @pin;
    $opt{$_} = PDL->null     for grep { !defined $opt{$_} } @pout;

    my @pars;
    if ( PP_PASS_TMPS ) {
        my @ptmp = qw[ berror2 bsignal2 b_m2 b_weight b_weight_sig b_weight_sig2 ];
        $opt{$_} = PDL->null for grep { !defined $opt{$_} } @ptmp;
        @pars = ( @pin, @pout, @ptmp, @oargs );
    }
    else {
        @pars = ( @pin, @pout, @oargs );
    }

    _bin_adaptive_snr_int( @opt{@pars} );

    my %results = map {    ## no critic (BuiltinFunctions::ProhibitComplexMappings)
        ( my $nkey = $_ ) =~ s/^b_//;
        ( $nkey, $opt{$_} )
    } @pout;


    return wantarray ? %results : \%results;    ## no critic(Community::Wantarray)
}

=pod

=head2 bin_adaptive_snr

=for usage

  %hash = bin_adaptive_snr( %options  );

=for stopwords
Adaptively

=for ref

Adaptively bin a data set to achieve a minimum signal to noise ratio
in each bin.

This routine ignores data with bad values or with errors that have
bad values.

B<bin_adaptive_snr> groups data into bins such that each bin meets
one or more conditions:

=over

=item *

a minimum signal to noise ratio (S/N).

=item *

A minimum number of data elements (optional).

=item *

A maximum number of data elements (optional).

=item *

A maximum data I<width> (see below) (optional).

=item *

A minimum data I<width> (see below) (optional).

=back

The data are typically dependent values (e.g. flux as a function of
energy or counts as a function of radius).  The data should be sorted
by the independent variable (e.g. energy or radius).

Calculation of the S/N requires an estimate of the error associated
with each datum.  The error may be provided or may be estimated from
the population using either the number of data elements in a bin
(e.g. Poisson errors) or the standard deviation of the signal in a bin.
If errors are provided, they may be used to weight the population standard
deviation or may be added in quadrature.

Binning begins at the start of the signal vector.  Data are accumulated
into a bin until one or more of the possible criteria is met. If the
final bin does not meet the required criteria, it may optionally be
successively folded into preceding bins until the final bin passes the
criteria or there are no bins left.

Each datum may be assigned an extra parameter, its I<width>,
which is summed for each bin, and can be used as an additional constraint
on bin membership.

=head3 Parameters

B<bin_adaptive_snr> is passed a hash or a reference to a hash containing
its parameters.  The available parameters are:

=over

=item C<signal>

A piddle containing the signal data.  This is required.

=item C<error>

A piddle with the error for signal datum. Optional.

=item C<width>

A piddle with the I<width> of each element of the signal. Optional.

=item C<error_algo>

A string indicating how the error is to be handled or calculated.  It
may be have one of the following values:

=over

=item * C<poisson>

Poisson errors will be calculated based upon the number of elements in a bin,

  error**2 = N

Any input errors are ignored.

=item * C<sdev>

The error is the population standard deviation of the signal in a bin.

  error**2 = Sum [ ( signal - mean ) **2 ] / ( N - 1 )

If errors are provided, they are used to calculated the weighted population
standard deviation.

  error**2 = ( Sum [ (signal/error)**2 ] / Sum [ 1/error**2 ] - mean**2 )
             * N / ( N - 1 )

=item * C<rss>

Errors must be provided; the errors of elements in a bin are added in
quadrature.

=back

=item C<min_snr>

The minimum signal to noise ratio to be achieved in each bin.  Required.

=item C<min_nelem>

=item C<max_nelem>

The minimum and/or maximum number of elements to be achieved in each bin. Optional

=item C<min_width>

=item C<max_width>

The minimum and/or maximum width of the elements to be achieved in each bin. Optional.

=item C<fold> I<boolean>

If true, the last bin may be folded into the preceding bin in order to
ensure that the last bin meets one or more of the criteria. It defaults to false.

=back

=head3 Results

B<bin_adaptive_snr> returns a hashref with the following entries:

=over

=item C<index>

A piddle containing the bin indices for the elements in the input
data piddle.  Data which were skipped because of bad values will have
their index set to the bad value.

=item C<nbins>

A piddle containing the number of bins which spanned the range of the
input data.

=item C<signal>

A piddle containing the sum of the data values in each bin.  Only
indices C<0> through C<nbins -1> are valid.

=item C<nelem>

A piddle containing the number of data elements in each bin. Only
indices C<0> through C<nbins -1> are valid.

=item C<error>

A piddle containing the errors in each bin, calculated using the
algorithm specified via C<error_algo>. Only indices C<0> through
C<nbins -1> are valid.

=item C<mean>

A piddle containing the weighted mean of the signal in each bin. Only
indices C<0> through C<nbins -1 > are valid.

=item C<ifirst>

A piddle containing the index into the input data piddle of the first
data value in a bin. Only indices C<0> through C<nbins -1 > are valid.

=item C<ilast>

A piddle containing the index into the input data piddle of the last
data value in a bin. Only indices C<0> through C<nbins -1 > are valid.

=item C<rc>

A piddle containing a results code for each output bin.  Only indices
C<0> through C<nbins -1 > are valid.  The code is the bitwise "or" of
the following constants (available in the C<CXC::PDL::Bin1D>
namespace)

=over

=item BIN_RC_OK

The bin met the minimum S/N, data element count and weight requirements

=item BIN_RC_GEWMAX

The bin weight was greater or equal to that requested.

=item BIN_RC_GENMAX

The number of data elements was greater or equal to that requested.

=item BIN_RC_FOLDED

The bin is the result of folding bins at the end of the bin vector to
achieve a minimum S/N.

=item BIN_RC_GTMINSN

The bin accumulated more data elements than was necessary to meet the
S/N requirements.  This results from constraints on the minimum number
of data elements or bin weight.

=back

=back

=cut
