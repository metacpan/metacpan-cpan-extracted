use strict;
use warnings;

package Bio::SeqAlignment::Examples::TailingPolyester::PDLRNG;
$Bio::SeqAlignment::Examples::TailingPolyester::PDLRNG::VERSION = '0.01';
use PDL::Lite;
use Role::Tiny;

sub init { undef; }

sub random {
    my ( $self, $random_dim ) = @_;
    my $retvals = PDL->random( $random_dim->@* );
    return $retvals;
}

sub seed {
    my ( $self, $seed ) = @_;
    if ($seed) {
        $self->{seed} = $seed;
        PDL::srand($seed);
    }
    $self->{seed};
}

1;

