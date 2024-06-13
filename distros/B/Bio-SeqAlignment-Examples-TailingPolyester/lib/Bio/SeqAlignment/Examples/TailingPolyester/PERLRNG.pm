use strict;
use warnings;

package Bio::SeqAlignment::Examples::TailingPolyester::PERLRNG;
$Bio::SeqAlignment::Examples::TailingPolyester::PERLRNG::VERSION = '0.01';
use Role::Tiny;

sub init { undef; }

sub random {
    my ( $self, $random_dim ) = @_;
    my $num_rand_values = 1;
    $num_rand_values *= $_ for @$random_dim;
    my @retvals = map { rand() } 1 .. $num_rand_values;
    \@retvals;
}

sub seed {
    my ( $self, $seed ) = @_;
    if ($seed) {
        $self->{seed} = $seed;
        srand($seed);
    }
    $self->{seed};
}
1;

