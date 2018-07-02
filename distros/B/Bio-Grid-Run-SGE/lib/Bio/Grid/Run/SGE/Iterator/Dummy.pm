package Bio::Grid::Run::SGE::Iterator::Dummy;

use Mouse;

use warnings;
use strict;

our $VERSION = '0.064'; # VERSION

has cur_comb     => ( is => 'rw', lazy_build => 1 );
has cur_comb_idx => ( is => 'rw', lazy_build => 1 );

with 'Bio::Grid::Run::SGE::Role::Iterable';

sub BUILD {
    my ($self) = @_;

    confess "can only take one index"
        if ( @{ $self->indices } != 1 );
}

sub next_comb {
    my ($self) = @_;
    confess 'function not implemented, yet';

}

sub num_comb {
    my ($self) = @_;
    
    return $self->indices->[0]->num_elem;
}

sub range {


}

sub peek_comb_idx {
    confess 'function not implemented, yet';
}

__PACKAGE__->meta->make_immutable;

1;
