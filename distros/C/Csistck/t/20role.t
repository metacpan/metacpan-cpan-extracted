package test_role_inheritance;
use base 'Csistck::Role';
sub defaults {
    my $self = shift;
    $self->{example} = 42;
    $self->{override} = 21;
}
sub tests {
    my $self = shift;
    $self->add(noop(0));
    $self->add(noop(1));
}
1;
use Test::More;
use Csistck;

plan tests => 6;

my $role_obj = test_role_inheritance->new(override => 42);

isa_ok($role_obj, 'Csistck::Role');
isa_ok($role_obj->get_tests(), 'ARRAY');

for my $test (@{$role_obj->get_tests()}) {
    isa_ok($test, 'Csistck::Test');
}

is($role_obj->{example}, 42);
is($role_obj->{override}, 42);

