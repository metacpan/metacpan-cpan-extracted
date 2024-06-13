use strict;
use warnings;

package Bio::SeqAlignment::Examples::TailingPolyester::SimulateTruncatedRNGPDL;
$Bio::SeqAlignment::Examples::TailingPolyester::SimulateTruncatedRNGPDL::VERSION = '0.01';
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
        $cdf_val_at_left_trunc_lmt = pdl(0);
    }
    else {
        $left_trunc_lmt = pdl($left_trunc_lmt);
        $cdf_val_at_left_trunc_lmt =
          $self->cdf( $distr, $left_trunc_lmt, $params );

    }
    if ( $right_trunc_lmt eq 'missing' ) {
        $cdf_val_at_right_trunc_lmt = pdl(1);
    }
    else {
        $right_trunc_lmt = pdl($right_trunc_lmt);
        $cdf_val_at_right_trunc_lmt =
          $self->cdf( $distr, $right_trunc_lmt, $params );
    }
    my $domain_lengh_trunc_distr =
      $cdf_val_at_right_trunc_lmt - $cdf_val_at_left_trunc_lmt;

    ## now simulate the truncated distribution
    my $simulated_values = $self->random($random_dim);
    $simulated_values->inplace->mult($domain_lengh_trunc_distr);
    $simulated_values->inplace->plus($cdf_val_at_left_trunc_lmt);
    return $self->inv_cdf( $distr, $simulated_values, $params );
}

1;

