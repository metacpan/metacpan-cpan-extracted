#!/usr/bin/env perl
use warnings;
use strict;

package Foo;
use warnings;
use strict;
use Carp::Source 'source_cluck';
use parent 'Class::Accessor::Constructor';
__PACKAGE__
    ->mk_constructor
    ->mk_scalar_accessors(qw(firstname lastname));

sub MUNGE_CONSTRUCTOR_ARGS {
    my $self = shift;
    $self->report;
    (scalar(@_ == 1) && ref($_[0]) eq 'HASH') ? %{ $_[0] } : @_;
}

sub report {
    my $self = shift;
    source_cluck 'munging', lines => 5, number => 0, color => 'yellow on_blue';
}

package main;
my $obj = Foo->new(
    lastname  => 'Shindou',
    firstname => 'Hikaru',
);
