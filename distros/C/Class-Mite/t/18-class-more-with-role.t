package Animal;

use Role;
requires 'speak';

package Dog;

use Class::More;
with qw/Animal/;

has name => (default => 'Tuffy');

sub speak {
    my($self) = @_;
    return $self->name . ' bark';
}

package main;

use Test::More;

is(Dog->new->speak, "Tuffy bark");
is(Dog->new(name => 'Tommy')->speak, "Tommy bark");

done_testing;
