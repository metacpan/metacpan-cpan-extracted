package Data::Gimei::Random;

use warnings;
use v5.22;

use Math::Random;

use Class::Tiny qw(
  seed
);

sub set_seed {
    my ( $self, $seed_num ) = @_;
    random_set_seed_from_phrase(13 * ($seed_num % 2 ** 26));
    my @seed = random_get_seed();

    $self->seed( \@seed );
}

sub next_int {
    my ( $self, $size ) = @_;

    if ( $self->seed ) {
        random_set_seed( @{ $self->seed } );
    } else {
        # to change result next_sample in each seconds.
        $self->set_seed( time );
    }

    my $ret = random_uniform_integer( 1, 0, $size );

    my @seed = random_get_seed();
    $self->seed( \@seed );

    return $ret;
}

sub next_sample {
    my ( $self, $array_ref ) = @_;

    my $i = $self->next_int($#$array_ref);
    return $array_ref->[$i];
}

1;
