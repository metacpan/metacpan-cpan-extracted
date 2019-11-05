package Op::Retrieve;

use strict;
use warnings;
use Test::Roo::Role;

with 'Op::Create';

has _foo => ( is => 'rw' );

test 'rs->search' => sub {
    my $self = shift;
    my $schema = $self->schema;
    my $foo_rs = $schema->resultset('Foo');
    ok( $self->_foo( $foo_rs->find({ name => 'Foo' }) ), 'found Foo' );
};

1;
