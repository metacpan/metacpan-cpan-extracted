package Crypt::Perl::ECDSA::EC::FieldElement;

use strict;
use warnings;

#both bigint
sub new {
    my ($class, $q, $x) = @_;

    die Crypt::Perl::X::create('Generic', 'Need both q and x!') if grep { !defined } $q, $x;

    return bless { x => $x, q => $q }, $class;
}

sub to_bigint {
    my ($self) = @_;

    return $self->{'x'};
}

1;
