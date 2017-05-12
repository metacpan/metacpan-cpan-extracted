use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Hash';
can_ok 'Data::Object::Hash', 'reset';

use Scalar::Util 'refaddr';

subtest 'test the reset method' => sub {
    my $hash = Data::Object::Hash->new({1..8});

    my @argument = ();
    my $reset = $hash->reset(@argument);

    is refaddr($hash), refaddr($reset);
    is_deeply $reset, {1=>undef,3=>undef,5=>undef,7=>undef};

    isa_ok $hash, 'Data::Object::Hash';
    isa_ok $reset, 'Data::Object::Hash';
};

ok 1 and done_testing;
