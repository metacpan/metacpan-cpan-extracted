package Crypt::Perl::ECDSA::EC::FieldElement;

use strict;
use warnings;

#both bigint
sub new {
    my ($class, $q, $x) = @_;

    die Crypt::Perl::X::create('Generic', 'Need both q and x!') if grep { !defined } $q, $x;

    return bless { x => $x, q => $q }, $class;
}

#$other isa ECFieldElement
sub equals {
    my ($self, $other) = @_;

    if ($other eq $self) {  #???
        return 1;
    }

    return $self->{q}->beq($other->{q}) && $self->{x}->beq($other->{x});
}

sub to_bigint {
    my ($self) = @_;

    return $self->{'x'};
}

sub negate {
    my ($self) = @_;

    return (ref $self)->new(
        $self->{'q'},
        $self->{'x'}->copy()->bneg()->bmod($self->{'q'}),
    );
}

sub add {
    my ($self, $b) = @_;

    return $self->new(
        $self->{'q'},
        $self->{'x'}->copy()->badd($b->to_bigint())->bmod($self->{'q'}),
    );
}

sub subtract {
    my ($self, $b) = @_;

    return $self->new(
        $self->{'q'},
        $self->{'x'}->copy()->bsub($b->to_bigint())->bmod($self->{'q'}),
    );
}

sub multiply {
    my ($self, $b) = @_;

    return $self->new(
        $self->{'q'},
        $self->{'x'}->copy()->bmul($b->to_bigint())->bmod($self->{'q'}),
    );
}

sub square {
    my ($self) = @_;

    return $self->new(
        $self->{'q'},
        $self->{'x'}->copy()->bmodpow(2, $self->{'q'}),
    );
}

#sub negate {
#    my ($self) = @_;
#
#    return $self->_spawn_mod( $self->{'x'}->copy()->bneg() );
#}
#
#sub add {
#    my ($self, $b) = @_;
#
#    return $self->_spawn_mod( $self->{'x'}->copy()->badd($b->to_bigint()) );
#}
#
#sub subtract {
#    my ($self, $b) = @_;
#
#    return $self->_spawn_mod( $self->{'x'}->copy()->bsub($b->to_bigint()) );
#}
#
#sub multiply {
#    my ($self, $b) = @_;
#
#    return $self->_spawn_mod( $self->{'x'}->copy()->bmul($b->to_bigint()) );
#}
#
#sub square {
#    my ($self) = @_;
#
#    return $self->_spawn( $self->{'x'}->copy()->bmodpow(2, $self->{'q'}) );
#}
#
#sub _spawn_mod {
#    my ($self, $num) = @_;
#
#    $num->bmod( $self->{'q'} );
#
#    return $self->_spawn($num);
#}
#
#sub _spawn {
#    my ($self, $num) = @_;
#
#    return (ref $self)->new( $self->{'q'}, $num );
#}
#
##Unused:
#sub divide {
#    my ($self, $b) = @_;
#
#    return $self->new(
#        $self->{'q'},
#        ($self->{'x'} * $b->to_bigint()->copy()->bmodinv($self->{'q'})) % $self->{'q'},
#    );
#}

1;
