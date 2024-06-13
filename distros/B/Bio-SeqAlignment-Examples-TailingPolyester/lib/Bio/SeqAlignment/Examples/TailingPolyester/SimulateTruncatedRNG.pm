use strict;
use warnings;

package Bio::SeqAlignment::Examples::TailingPolyester::SimulateTruncatedRNG;
$Bio::SeqAlignment::Examples::TailingPolyester::SimulateTruncatedRNG::VERSION = '0.01';
use Carp;
use PDL;
use Role::Tiny;
requires qw(random has_distr cdf inv_cdf);


sub simulate_trunc {
    my $self       = shift;
    my %args       = @_;
    my $random_dim = $args{random_dim} || [1];     ## default to 1 random number
    my $distr      = $args{distr}      || 'flat';
    my $left_trunc_lmt  = $args{left_trunc_lmt}  || 'missing';
    my $right_trunc_lmt = $args{right_trunc_lmt} || 'missing';
    my $params          = $args{params}          || 'missing';
    my $cdf_val_at_left_trunc_lmt;
    my $cdf_val_at_right_trunc_lmt;

    ## set up sanity checks
    croak "The distribution $distr is not available"
      unless $self->has_distr($distr);             ## distr must exist
    if ( $params eq 'missing' && $distr ne 'flat' ) {
        croak "Must provide parameters for the distribution $distr";
    }    ##and parameters cannot be missing unless it is a flat distribution

    ## set up CDF computations at the truncation limits

    if ( $left_trunc_lmt eq 'missing' ) {
        $cdf_val_at_left_trunc_lmt = 0;
    }
    else {
        $cdf_val_at_left_trunc_lmt =
          $self->cdf( $distr, $left_trunc_lmt, $params );

    }
    if ( $right_trunc_lmt eq 'missing' ) {
        $cdf_val_at_right_trunc_lmt = 1;
    }
    else {
        $cdf_val_at_right_trunc_lmt =
          $self->cdf( $distr, $right_trunc_lmt, $params );
    }
    my $domain_lengh_trunc_distr =
      $cdf_val_at_right_trunc_lmt - $cdf_val_at_left_trunc_lmt;

    ## now simulate the truncated distribution - non vectorized code
    my $simulated_values = $self->random($random_dim);
    my $num_rand_values  = scalar $simulated_values->@*;
    for my $i ( 0 .. $num_rand_values - 1 ) {
        $simulated_values->[$i] =
          $simulated_values->[$i] * $domain_lengh_trunc_distr +
          $cdf_val_at_left_trunc_lmt;
        $simulated_values->[$i] =
          $self->inv_cdf( $distr, $simulated_values->[$i], $params );
    }
    return $simulated_values;
}

1;

