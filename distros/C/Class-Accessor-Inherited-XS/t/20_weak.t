use strict;
use Test::More;

use parent 'Class::Accessor::Inherited::XS::Compat';
use Class::Accessor::Inherited::XS::Constants;

__PACKAGE__->mk_object_accessors(['foo', 'foo', IsWeak]);
__PACKAGE__->mk_class_accessors(['bar', undef, 0, IsWeak]);
__PACKAGE__->mk_class_accessors(['baz', sub {{}}, 0, IsWeak]);
__PACKAGE__->mk_inherited_accessors(['foobar', 'foobar', IsWeak]);

sub exception (&) {
    $@ = undef;
    eval { shift->() };
    $@
}

my $self = bless {};
like exception {$self->foo(12)}, qr/nonreference/;
is($self->foo, 12);

$self->foo({});
is($self->foo, undef);

{
    my $ref = {a => 42};
    $self->foo($ref);
    is($self->foo->{a}, 42);
}
is($self->foo, undef);

__PACKAGE__->bar({});
is(__PACKAGE__->bar, undef);

is(__PACKAGE__->baz, undef);
is(__PACKAGE__->baz, undef);

__PACKAGE__->baz({});
is(__PACKAGE__->baz, undef);

__PACKAGE__->foobar({});
is(__PACKAGE__->foobar, undef);

done_testing;
