package Bubblegum::Object::Role::List;

use 5.10.0;
use namespace::autoclean;

use Bubblegum::Role 'requires', 'with';
use Bubblegum::Constraints -isas, -types;

with 'Bubblegum::Object::Role::Value';

our $VERSION = '0.45'; # VERSION

requires 'defined';
requires 'grep';
requires 'head';
requires 'join';
requires 'length';
requires 'map';
requires 'reverse';
requires 'sort';
requires 'tail';

sub reduce {
    my $self = CORE::shift;
    my $code = CORE::shift;

    $code = $code->codify if isa_string $code;
    type_coderef $code;

    my $a    = [0 .. $#{$self}];
    my $acc  = $a->head;
    $a->tail->map(sub { $acc = $code->($acc, $_, @_) });

    return $acc;
}

sub zip {
    my $self  = CORE::shift;

    my $other = type_arrayref CORE::shift;
    my $this  = $self->length < $other->length ? $other : $self;
    my $a     = [0 .. $#{$this}];

    return $this->keys->map(sub { [$self->get($_), $other->get($_)] });
}

1;
