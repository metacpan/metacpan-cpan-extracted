package Retrier;
use strict;
use utf8;
use warnings qw(all);

use Moo;
use MooX::Types::MooseLike::Base qw(InstanceOf Int Num Str);

extends 'AnyEvent::Net::Curl::Queued::Easy';

has attr1 => (is => 'ro', isa => Num, required => 1);
has attr2 => (is => 'ro', isa => Int, required => 1);
has attr3 => (is => 'rw', isa => InstanceOf['URI']);
has attr4 => (is => 'rw', isa => Str, default => sub { 'A' });

around clone => sub {
    my $orig = shift;
    my $self = shift;
    my $param = shift;

    $param->{$_} = $self->$_
        for qw(
            attr1
            attr2
            attr3
        );

    return $self->$orig($param);
};

around has_error => sub {
    return 1;
};

1;
