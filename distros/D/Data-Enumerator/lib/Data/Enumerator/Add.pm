package Data::Enumerator::Add;
use strict;
use warnings;
use base qw/Data::Enumerator::Base/;

sub each {
    my ( $self ,$f) = @_;
    my ($a,$b) = @{ $self->object };
    return ($a->each($f),$b->each($f));
}
1;
