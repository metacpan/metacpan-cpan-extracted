#!perl

# Bug report that initiated this debugging:
# https://rt.cpan.org/Ticket/Display.html?id=81519

use strict;
use warnings;

use Test::More tests => 1;

use Data::Visitor::Callback;

BEGIN {
    package W3C::XHTML::Image;
    use Moose;

    package W3C::XHTML::Body;
    use Moose;
    has 'images' => (
        is     => 'ro',
        isa    => 'ArrayRef[W3C::XHTML::Image]',
    );
}

my $body = W3C::XHTML::Body->new( images => [ W3C::XHTML::Image->new ] );
my $tc = $body->meta->get_attribute('images')->type_constraint;

note "TC contains only one instance of W3C::XHTML::Image - $tc";

# Figure out classes mentioned in type constraint (isa)
my @classes;
Data::Visitor::Callback->new({
    object => 'visit_ref',
    'Moose::Meta::TypeConstraint::Union'         => sub { return $_[1]->type_constraints; },
    'Moose::Meta::TypeConstraint::Class'         => sub { push @classes, $_[1]->class; return $_[1]; },
    'Moose::Meta::TypeConstraint::Parameterized' => sub { return $_[1]->type_parameter; },
})->visit($tc);

note "Classes found: " . join(", ", @classes);

# On 5.16.2 it gives me only one item if mentioned once in TC,
# but on 5.17.6 it occasionally gives two items in @classes
is( scalar @classes, 1, "Only one case of W3C::XHTML::Image should be present");
