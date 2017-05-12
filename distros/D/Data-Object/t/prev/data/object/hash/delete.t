use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Hash';
can_ok 'Data::Object::Hash', 'delete';

use Scalar::Util 'refaddr';

subtest 'test the delete method' => sub {
    my $hash = Data::Object::Hash->new({1..8});

    my @argument = (1);
    my $delete = $hash->delete(@argument);

    isnt refaddr($hash), refaddr($delete);
    is $delete, 2;
    is_deeply $hash, {3..8};

    isa_ok $hash, 'Data::Object::Hash';
    isa_ok $delete, 'Data::Object::Number';
};

ok 1 and done_testing;
