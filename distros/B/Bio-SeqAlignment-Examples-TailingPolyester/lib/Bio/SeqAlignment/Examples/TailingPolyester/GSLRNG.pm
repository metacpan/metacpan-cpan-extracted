use strict;
use warnings;

package Bio::SeqAlignment::Examples::TailingPolyester::GSLRNG;
$Bio::SeqAlignment::Examples::TailingPolyester::GSLRNG::VERSION = '0.01';
use Carp;
use PDL::Lite;
use PDL::GSL::RNG;
use Role::Tiny;

sub init {
    my ( $self, $RNG_init_parameters ) = @_;
    my $rng = PDL::GSL::RNG->new( ${$RNG_init_parameters}[0] );
    $rng;
}

sub random {
    my ( $self, $random_dim ) = @_;
    if ( $self->{is_rng_an_object} ) {
        my $retvals = $self->{rng_object}->ran_flat( 0, 1, $random_dim->@* );
        return $retvals;
    }
    else {
        croak "RNG object is not initialized";
    }
}

sub seed {
    my ( $self, $seed ) = @_;
}

1;

