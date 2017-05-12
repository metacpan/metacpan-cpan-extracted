use Test::More;

use_ok 'Data::Object::Immutable';

my $error1 = qr/modification of a read-only value/i;
my $error2 = qr/failed to write new value to hash/i;

my $object = '';

# array
ok $object = Data::Object::Immutable->new([1..9]);
ok $object->isa('Data::Object::Array');
is $object->count, 9;
ok !eval { $object->set(0,1) };
ok $@ =~ qr/$error1|$error2/;
ok !eval { $object->[0]++ };
ok $@ =~ qr/$error1|$error2/;

# hash
ok $object = Data::Object::Immutable->new({1..8});
ok $object->isa('Data::Object::Hash');
is $object->keys->count, 4;
ok !eval { $object->set(1,2) };
ok $@ =~ qr/$error1|$error2/;
ok !eval { $object->{1}++ };
ok $@ =~ qr/$error1|$error2/;

# string
ok $object = Data::Object::Immutable->new('abcedfghi');
ok $object->isa('Data::Object::String');
is $object->length, 9;
ok !eval { $$object = uc $$object } or diag $object;
ok $@ =~ qr/$error1|$error2/;

# number
ok $object = Data::Object::Immutable->new(1000);
ok $object->isa('Data::Object::Number');
ok !eval { $$object++ };
ok $@ =~ qr/$error1|$error2/;

# foreign
ok $object = Data::Object::Immutable->new(bless {}, 'main');
ok $object->isa('main');
ok !eval { $object->{0} = 1 };
ok $@ =~ qr/$error1|$error2/;

{
    package ImmutableClass;

    use Data::Object::Class;

    with 'Data::Object::Role::Immutable';

    has data => ( is => 'rw' );

    sub BUILD {

        return shift;

    }

    1;
}

# class
ok $object = ImmutableClass->new(data => {1..4});
ok $object->isa('ImmutableClass');
ok !eval { $object->data({4..8}) };
ok $@ =~ qr/$error1|$error2/;

ok 1 and done_testing;
