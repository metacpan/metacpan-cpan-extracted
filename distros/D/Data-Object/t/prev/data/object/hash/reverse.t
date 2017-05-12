use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Hash';
can_ok 'Data::Object::Hash', 'reverse';

use Scalar::Util 'refaddr';

subtest 'test the reverse method' => sub {
    my $hash = Data::Object::Hash->new({1..8,9,undef});

    my @argument = ();
    my $reverse = $hash->reverse(@argument);

    isnt refaddr($hash), refaddr($reverse);
    is_deeply $reverse, {8=>7,6=>5,4=>3,2=>1};

    isa_ok $hash, 'Data::Object::Hash';
    isa_ok $reverse, 'Data::Object::Hash';
};

ok 1 and done_testing;
