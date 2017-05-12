package Data::Mapper::Class;
use strict;
use warnings;
use Carp ();

sub new {
    my ($class, $args) = @_;
    Carp::croak '$args must be a HashRef' if $args && ref $args ne 'HASH';
    bless $args || {}, $class;
}

!!1;
