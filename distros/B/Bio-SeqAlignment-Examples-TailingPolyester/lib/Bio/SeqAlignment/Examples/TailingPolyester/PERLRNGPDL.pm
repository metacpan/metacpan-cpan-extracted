use strict;
use warnings;

package Bio::SeqAlignment::Examples::TailingPolyester::PERLRNGPDL;
$Bio::SeqAlignment::Examples::TailingPolyester::PERLRNGPDL::VERSION = '0.01';
use PDL::Lite;
use Role::Tiny;

sub init { undef; }

sub random {
    my ( $self, $random_dim ) = @_;
    my $num_rand_values = 1;
    $num_rand_values *= $_ for @$random_dim;
    my @retvals = map { rand() } 1 .. $num_rand_values;
    return pdl( \@retvals )->reshape( $random_dim->@* );
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

