use strict;
use warnings;

package Bio::SeqAlignment::Examples::TailingPolyester::SimulateMathGSL;
$Bio::SeqAlignment::Examples::TailingPolyester::SimulateMathGSL::VERSION = '0.01';
use Package::Stash;
use PDL::Lite;
use Math::GSL::CDF;
use subs        qw (seed  has_distr random is_rng_an_object);
use Class::Tiny qw(seed  has_distr seed ), { random => sub { } };
use Role::Tiny::With;
with 'Bio::SeqAlignment::Examples::TailingPolyester::SimulateTruncatedRNG';

sub has_distr {
    my ( $self, $distr ) = @_;
    return exists $self->{distributions}->{$distr};
}

sub cdf {
    my ( $self, $distr, $lmt, $params ) = @_;
    return $self->{distributions}->{$distr}{cdf}->( $lmt, $params->@* );
}

sub inv_cdf {
    my ( $self, $distr, $lmt, $params ) = @_;
    return $self->{distributions}->{$distr}{inv_cdf}->( $lmt, $params->@* );
}

sub BUILD {
    my ( $self, $args ) = @_;
    die "seed must be a number" unless $self->{seed} =~ /^[0-9]+$/;
    my @symbols_in_GSL =
      Package::Stash->new('Math::GSL::CDF')->list_all_symbols('CODE');
    for (@symbols_in_GSL) {
        if (/gsl_cdf_(\w+)_Pinv/) {
            $self->{distributions}->{$1} = {
                cdf     => $Math::GSL::CDF::{"gsl_cdf_$1_P"},
                inv_cdf => $Math::GSL::CDF::{$_}
            };
        }    ## store the CDF and inverse CDF functions
    }
    ## initialize and store the RNG here
    if ( $args->{RNG_init_parameters} ) {
        $self->{is_rng_an_object} = 1;
        $self->{rng_object} =
          $args->{rng_plugin}->init( $args->{RNG_init_parameters} );
    }
    die "RNG plugin does not provide the 'random' role"
      unless $args->{rng_plugin}->can('random');
    Role::Tiny->apply_roles_to_object( $self, $args->{rng_plugin} );
}

1;

